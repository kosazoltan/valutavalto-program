package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.shipment.ShipmentRequestItemResponseDto;
import hu.puzzleir.valuta.dto.shipment.ShipmentRequestResponseDto;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.ExchangeRate;
import hu.puzzleir.valuta.entity.ShipmentRequest;
import hu.puzzleir.valuta.entity.ShipmentRequestItem;
import hu.puzzleir.valuta.entity.ShipmentRequestStatus;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.repository.ShipmentRequestRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.util.HungarianRounding;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Szállítmánykérés szolgáltatás.
 */
@Service
@RequiredArgsConstructor
@Transactional(rollbackFor = Exception.class)
@Slf4j
public class ShipmentService {

    private final ShipmentRequestRepository shipmentRequestRepository;
    private final BranchRepository branchRepository;
    private final CurrencyRepository currencyRepository;
    private final WorkerRepository workerRepository;
    private final ExchangeRateService exchangeRateService;
    private final TransferSerialSequenceService transferSerialSequenceService;
    private final ShipmentStockBookingService stockBookingService;

    /**
     * v2.5.70 P0 multi-tenant fix (companyId audit follow-up): a régi findByStatus /
     * findAllOrdered globális queries voltak (NEM cég-szintű szűréssel), helyettük a
     * tenant-aware *ByCompanyId variánsokat hívjuk SecurityUtils.getCurrentCompanyId()-val.
     */
    @Transactional(readOnly = true)
    public Page<ShipmentRequest> findAll(ShipmentRequestStatus status, UUID branchId, Pageable pageable) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        Page<ShipmentRequest> page;
        // F2 (2026-06-01): natív, DB-szintű branch-szűrő — megszünteti a kliens-oldali
        // "összes letöltése + filter" mintát. branchId opcionális; ha megadott, a status is szűr.
        if (branchId != null) {
            page = shipmentRequestRepository.findByBranchAndCompanyId(branchId, status, companyId, pageable);
        } else if (status != null) {
            page = shipmentRequestRepository.findByStatusAndCompanyId(status, companyId, pageable);
        } else {
            page = shipmentRequestRepository.findAllOrderedByCompanyId(companyId, pageable);
        }
        // P0 LazyInit hotfix (2026-05-28, Bali Henriett/Kasza Helga prod-bug): a ShipmentRequest
        // entitást a controller direkt JSON-ra serializálja a session lezárása UTÁN (OSIV=false),
        // és a Jackson érinti a lazy `items` kollekciót → LazyInitializationException 500.
        // Csak az ÉRTÉKTÁR/FŐÉRTÉKTÁR role engedélyezése (#886, v2.27.40) hozta felszínre — előtte
        // 403-at kapott a UI. Pattern: TransactionService.initMultiLineForMapping (architect-mode
        // audit). Lapozás-biztos init a page-content sorain (nem JOIN FETCH a Pageable mellé).
        page.getContent().forEach(ShipmentService::initLazyForSerialization);
        return page;
    }

    @Transactional(readOnly = true)
    public Page<ShipmentRequestResponseDto> findAllResponse(
            ShipmentRequestStatus status, UUID branchId, Pageable pageable) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        Map<UUID, Branch> branchCache = new HashMap<>();
        Map<Long, Worker> workerCache = new HashMap<>();
        return findAll(status, branchId, pageable)
                .map(request -> toResponseDto(request, companyId, branchCache, workerCache));
    }

    @Transactional(readOnly = true)
    public ShipmentRequest findById(UUID id) {
        ShipmentRequest sr = shipmentRequestRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Szállítmánykérés nem található: " + id));
        // v2.5.70 P0 fix + #890 self-review P1-2: cross-tenant IDOR guard — MIND A KÉT
        // branch (from + to) Branch.company.id-jét összevetjük a jelenlegi user
        // company-jával. A korábbi fix csak a fromBranchId-t ellenőrizte; ha egy shipment
        // toBranchId-je másik cégre mutat (data-bug vagy admin-create), a UI-t serializáló
        // entitás sérthette a tenant-izolációt.
        UUID currentCompanyId = SecurityUtils.getCurrentCompanyId();
        assertBranchInCompany(sr.getFromBranchId(), currentCompanyId, id, "fromBranchId");
        assertBranchInCompany(sr.getToBranchId(), currentCompanyId, id, "toBranchId");
        // P0 LazyInit hotfix: a controller direkt entity-t serializál, items lazy.
        initLazyForSerialization(sr);
        return sr;
    }

    @Transactional(readOnly = true)
    public ShipmentRequestResponseDto findByIdResponse(UUID id) {
        return toResponseDto(findById(id));
    }

    /**
     * #890 P1-2 self-review fix: branch ownership-check helper. ResourceNotFound-ot dob,
     * ha a branch nem létezik VAGY más céghez tartozik (id-enumeráció ellen 404 a 403 helyett).
     */
    private void assertBranchInCompany(UUID branchId, UUID currentCompanyId, UUID shipmentId, String which) {
        UUID branchCompanyId = branchRepository.findById(branchId)
                .map(b -> b.getCompany() != null ? b.getCompany().getId() : null)
                .orElse(null);
        if (branchCompanyId == null || !currentCompanyId.equals(branchCompanyId)) {
            log.warn("Cross-tenant access blocked: shipmentRequest={}, {}={}, branchCompany={}, currentCompany={}",
                    shipmentId, which, branchId, branchCompanyId, currentCompanyId);
            throw new ValidationException("A szállítmánykérés nem tartozik a jelenlegi céghez (cross-tenant access blocked, " + which + ")");
        }
    }

    /**
     * P0 LazyInit hotfix helper (2026-05-28): a {@link ShipmentRequest#items} `FetchType.LAZY`
     * kollekciót a tranzakción belül inicializáljuk, hogy a controller-utáni Jackson-serialize
     * NE fusson LazyInitializationException-be (OSIV=false). Null-safe.
     */
    private static void initLazyForSerialization(ShipmentRequest sr) {
        if (sr != null && sr.getItems() != null) {
            org.hibernate.Hibernate.initialize(sr.getItems());
        }
    }

    public ShipmentRequest create(ShipmentRequest request) {
        validateCreateRequest(request);
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        request.setCompanyId(companyId);
        RequestNumberParts requestNumberParts = generateRequestNumber(request);
        request.setRequestNumber(requestNumberParts.value());
        request.setSerialPrefix(requestNumberParts.prefix());
        request.setSerialNumber(requestNumberParts.serialNumber());
        request.setStatus(ShipmentRequestStatus.DRAFT);
        request.setRequestedById(SecurityUtils.getCurrentWorkerId());
        request.setRequestDate(LocalDate.now());

        // D követelmény (Bali Henriett 2026-05-27): minden tételen kötelezően az AKTUÁLIS
        // elszámoló árfolyam (officialRate / J) és a forintosított érték (HUF kerekítve).
        applyExchangeRateAndHufValue(request);

        // FK (készletkönyvelés): a transfer_type-ot a from/to fiók is_vault flagjéből deriváljuk
        // SZERVEROLDALON (a kliens nem hamisíthatja a könyvelés irányát). Mindkét fióknak a
        // jelenlegi céghez kell tartoznia (tenant-izoláció).
        Branch fromBranch = branchRepository.findByIdAndCompanyId(request.getFromBranchId(), companyId)
                .orElseThrow(() -> new ValidationException(
                        "Forrás fiók nem található a jelenlegi cégben: " + request.getFromBranchId()));
        Branch toBranch = branchRepository.findByIdAndCompanyId(request.getToBranchId(), companyId)
                .orElseThrow(() -> new ValidationException(
                        "Cél fiók nem található a jelenlegi cégben: " + request.getToBranchId()));
        request.setTransferType(stockBookingService.deriveTransferType(fromBranch, toBranch));

        log.info("Szállítmánykérés létrehozva: {}, from={}, to={}",
                request.getRequestNumber(), request.getFromBranchId(), request.getToBranchId());
        ShipmentRequest saved = shipmentRequestRepository.save(request);
        // P0 self-review #890: minden controller-felé visszaadott entity-n meg kell hívni az
        // init-et, hogy a Jackson OSIV=false-lal NE fusson LazyInit-be.
        initLazyForSerialization(saved);
        return saved;
    }

    public ShipmentRequestResponseDto createResponse(ShipmentRequest request) {
        return toResponseDto(create(request));
    }

    /**
     * D követelmény (Bali Henriett 2026-05-27): a tétel {@code appliedRate}-jét és
     * {@code hufValue}-ját MINDIG a szerveroldali aktuális elszámoló árfolyamból
     * (officialRate) számoljuk. A kliens által esetleg küldött értékeket figyelmen
     * kívül hagyjuk — a követelmény szövege: „kötelezően és automatikusan a
     * rendszerben lévő aktuális elszámoló árból kell beemelnie" (Codex P1
     * follow-up: server-side authoritative source, audit-célból nem manipulálható
     * a klienstől).
     *
     * <p>Best-effort: ha a getCurrentRate exception-t dob (lejárt 24h TTL vagy nem
     * létezik a rate), warn-loggolunk és az oszlopok NULL-ban maradnak — egyetlen
     * ritka/lejárt árfolyam ne bukja a teljes szállítmány-create-et.</p>
     */
    private void applyExchangeRateAndHufValue(ShipmentRequest request) {
        if (request.getItems() == null) return;
        for (ShipmentRequestItem item : request.getItems()) {
            // Audit-szigorúság: a kliens által küldött appliedRate / hufValue mezőt
            // EL DOBJUK, hogy ne legyen manipulálható a beemelt rate. A server-side
            // értékek az authoritative source.
            item.setAppliedRate(null);
            item.setHufValue(null);

            if (item.getCurrencyId() == null) {
                throw new ValidationException("A szállítmány-tétel currencyId-je nem lehet üres.");
            }
            // Codex P1 (overrides earlier P0-1 tolerance): a D pont szövege „kötelezően és
            // automatikusan a rendszerben lévő aktuális elszámoló árból" — ha nincs aktív
            // rate (24h TTL lejárt vagy hiányzik), NEM mentjük a tételt rate nélkül,
            // hanem explicit validation hibát dobunk. Audit-szigorúság: minden szállítmány-
            // tételhez kötelezően tartozik elszámoló rate.
            try {
                Currency currency = currencyRepository.findById(item.getCurrencyId())
                        .orElseThrow(() -> new ValidationException(
                                "Ismeretlen valuta a szállítmány-tételben: currencyId=" + item.getCurrencyId()));
                if ("HUF".equalsIgnoreCase(currency.getCode())) {
                    item.setAppliedRate(BigDecimal.ONE);
                } else {
                    ExchangeRate er = exchangeRateService.getCurrentRate(item.getCurrencyId());
                    if (er == null || er.getOfficialRate() == null) {
                        throw new ValidationException(
                                "A currencyId=" + item.getCurrencyId() + " valutához nincs aktuális "
                                        + "elszámoló árfolyam (officialRate). Frissítse az árfolyamot "
                                        + "a szállítmánykérés rögzítése előtt.");
                    }
                    item.setAppliedRate(er.getOfficialRate());
                }
            } catch (ResourceNotFoundException ex) {
                throw new ValidationException(
                        "A currencyId=" + item.getCurrencyId() + " valutához nincs aktuális "
                                + "elszámoló árfolyam. Ok: " + ex.getMessage());
            }
            // requestedAmount × appliedRate → BigDecimal, majd HUF 5-Ft kerekítés (Hungarian).
            if (item.getRequestedAmount() != null) {
                BigDecimal rawHuf = item.getRequestedAmount().multiply(item.getAppliedRate());
                item.setHufValue(HungarianRounding.roundToFive(rawHuf));
            }
        }
    }

    public ShipmentRequest update(UUID id, ShipmentRequest updated) {
        ShipmentRequest existing = findById(id);
        if (existing.getStatus() != ShipmentRequestStatus.DRAFT) {
            throw new ValidationException("Csak DRAFT státuszú kérés módosítható!");
        }
        validateEditableRequest(updated);

        existing.setFromBranchId(updated.getFromBranchId());
        existing.setToBranchId(updated.getToBranchId());
        existing.setDeliveryDate(updated.getDeliveryDate());
        existing.setNotes(updated.getNotes());
        // FK02: a szállító + plombaszám módosítás is perzisztáljon szerkesztéskor.
        // Trim (Sourcery bug_risk): a create flow trimmel, az update-en is normalizáljunk, hogy
        // ne tároljunk véletlen whitespace-t (search/equality konzisztencia create↔update közt).
        existing.setCarrierName(updated.getCarrierName() != null ? updated.getCarrierName().trim() : null);
        existing.setSealNumber(updated.getSealNumber() != null ? updated.getSealNumber().trim() : null);

        // Codex P1 + P2 kompromisszum: csak akkor futtatjuk az autofill-t, ha a kliens
        // ÚJ items listát küldött (= currency/amount változás). Notes/date-only update
        // esetén az `updated.getItems() == null` → az eredeti tételek (és a rögzítéskor
        // beemelt appliedRate / hufValue) érintetlenül maradnak (audit-preservation).
        if (updated.getItems() != null) {
            existing.setItems(updated.getItems());
            applyExchangeRateAndHufValue(existing);
        }

        log.info("Szállítmánykérés frissítve: {}", id);
        ShipmentRequest saved = shipmentRequestRepository.save(existing);
        initLazyForSerialization(saved);
        return saved;
    }

    public ShipmentRequestResponseDto updateResponse(UUID id, ShipmentRequest updated) {
        return toResponseDto(update(id, updated));
    }

    public ShipmentRequest submit(UUID id) {
        ShipmentRequest request = findById(id);
        validateStatusTransition(request, ShipmentRequestStatus.DRAFT, ShipmentRequestStatus.SUBMITTED);
        // FK (TBD-1 döntés): az ÁTADÓ oldal készlete a beküldéskor AZONNAL csökken (OUT-könyvelés),
        // pesszimista lockkal + elégség-ellenőrzéssel (FR-2/5/7/8). Ha elégtelen → 422 VV-VALID-003,
        // a teljes @Transactional rollbackel (a státusz nem vált), az audit REQUIRES_NEW-ban megmarad.
        stockBookingService.bookStockOut(request, SecurityUtils.getCurrentCompanyId());
        request.setStatus(ShipmentRequestStatus.SUBMITTED);
        log.info("Szállítmánykérés beküldve: {}", request.getRequestNumber());
        ShipmentRequest saved = shipmentRequestRepository.save(request);
        initLazyForSerialization(saved);
        return saved;
    }

    public ShipmentRequestResponseDto submitResponse(UUID id) {
        return toResponseDto(submit(id));
    }

    public ShipmentRequest approve(UUID id) {
        ShipmentRequest request = findById(id);
        validateStatusTransition(request, ShipmentRequestStatus.SUBMITTED, ShipmentRequestStatus.APPROVED);
        request.setStatus(ShipmentRequestStatus.APPROVED);
        log.info("Szállítmánykérés jóváhagyva: {}", request.getRequestNumber());
        ShipmentRequest saved = shipmentRequestRepository.save(request);
        initLazyForSerialization(saved);
        return saved;
    }

    public ShipmentRequestResponseDto approveResponse(UUID id) {
        return toResponseDto(approve(id));
    }

    public ShipmentRequest deliver(UUID id) {
        ShipmentRequest request = findById(id);
        if (request.getStatus() != ShipmentRequestStatus.APPROVED
                && request.getStatus() != ShipmentRequestStatus.IN_TRANSIT) {
            throw new ValidationException("Csak APPROVED vagy IN_TRANSIT státuszú kérés szállítható le!");
        }
        // FR-4: a visszaigazolást (DELIVERED) KIZÁRÓLAG az átvevő (to) fiók felhasználója végezheti.
        // Ha az átadó (vagy más fiók) próbálja → 403 VV-AUTH-001 + ACCESS_DENIED audit.
        stockBookingService.assertReceiver(request);
        // FR-3: az ÁTVEVŐ oldal készlete a visszaigazoláskor nő (IN-könyvelés), get-or-create + lock.
        stockBookingService.bookStockIn(request, SecurityUtils.getCurrentCompanyId());
        request.setStatus(ShipmentRequestStatus.DELIVERED);
        request.setDeliveryDate(LocalDate.now());
        log.info("Szállítmánykérés leszállítva: {}", request.getRequestNumber());
        ShipmentRequest saved = shipmentRequestRepository.save(request);
        initLazyForSerialization(saved);
        return saved;
    }

    public ShipmentRequestResponseDto deliverResponse(UUID id) {
        return toResponseDto(deliver(id));
    }

    public ShipmentRequest cancel(UUID id) {
        ShipmentRequest request = findById(id);
        if (request.getStatus() == ShipmentRequestStatus.DELIVERED
                || request.getStatus() == ShipmentRequestStatus.CANCELLED) {
            throw new ValidationException("DELIVERED vagy CANCELLED státuszú kérés nem vonható vissza!");
        }
        // TBD-1: a készlet az átadó oldalon a beküldéskor (SUBMITTED) csökkent. Ha egy már OUT-könyvelt
        // (SUBMITTED/APPROVED/IN_TRANSIT) kérést visszavonnak, a készletet vissza kell pótolni, különben
        // elveszne. DRAFT-ból visszavonáskor nem volt OUT-könyvelés → nincs reverzió (dupla-jóváírás elkerülés).
        if (wasStockBookedOut(request.getStatus())) {
            stockBookingService.reverseStockOut(request, SecurityUtils.getCurrentCompanyId());
        }
        request.setStatus(ShipmentRequestStatus.CANCELLED);
        log.info("Szállítmánykérés visszavonva: {}", request.getRequestNumber());
        ShipmentRequest saved = shipmentRequestRepository.save(request);
        initLazyForSerialization(saved);
        return saved;
    }

    public ShipmentRequestResponseDto cancelResponse(UUID id) {
        return toResponseDto(cancel(id));
    }

    /**
     * F3 (2026-06-01): dedikált ELUTASÍTÁS — külön a visszavonástól (cancel). A státuszt
     * REJECTED-re állítja és rögzíti az audit-mezőket (rejectionReason + rejectedByWorkerId).
     * Tenant IDOR-védelem a {@link #findById}-on át.
     *
     * <p>Codex P2 (2026-06-01): az elutasítás az approve párja — CSAK SUBMITTED állapotból
     * megengedett (a UI is csak SUBMITTED-nél mutatja a reject akciót, az approve SUBMITTED→APPROVED-ot
     * validál). Így APPROVED/IN_TRANSIT/DRAFT NEM érvényteleníthető közvetlen API-hívással.
     */
    public ShipmentRequest reject(UUID id, String reason) {
        ShipmentRequest request = findById(id);
        validateStatusTransition(request, ShipmentRequestStatus.SUBMITTED, ShipmentRequestStatus.REJECTED);
        // Biztonság: az elutasító dolgozó a HITELESÍTETT user (nem kliens-trusted param) — mint create().
        Long workerId = SecurityUtils.getCurrentWorkerId();
        // TBD-1: a reject CSAK SUBMITTED-ből megengedett, ami mindig OUT-könyvelt állapot → a készletet
        // mindig vissza kell pótolni az átadó oldalra (SHIPMENT_STOCK_REVERSAL audit).
        stockBookingService.reverseStockOut(request, SecurityUtils.getCurrentCompanyId());
        request.setStatus(ShipmentRequestStatus.REJECTED);
        request.setRejectionReason(reason);
        request.setRejectedByWorkerId(workerId);
        log.info("Szállítmánykérés elutasítva: {} (elutasító worker={})", request.getRequestNumber(), workerId);
        ShipmentRequest saved = shipmentRequestRepository.save(request);
        initLazyForSerialization(saved);
        return saved;
    }

    public ShipmentRequestResponseDto rejectResponse(UUID id, String reason) {
        return toResponseDto(reject(id, reason));
    }

    public ShipmentRequestResponseDto toResponseDto(ShipmentRequest request) {
        if (request == null) {
            return null;
        }
        UUID companyId = request.getCompanyId() != null
                ? request.getCompanyId()
                : SecurityUtils.getCurrentCompanyId();
        return toResponseDto(request, companyId, new HashMap<>(), new HashMap<>());
    }

    private ShipmentRequestResponseDto toResponseDto(
            ShipmentRequest request,
            UUID companyId,
            Map<UUID, Branch> branchCache,
            Map<Long, Worker> workerCache) {
        Branch fromBranch = findBranchInCompany(request.getFromBranchId(), companyId, branchCache);
        Branch toBranch = findBranchInCompany(request.getToBranchId(), companyId, branchCache);
        Worker requestedBy = findWorkerInCompany(request.getRequestedById(), companyId, workerCache);
        Worker rejectedBy = findWorkerInCompany(request.getRejectedByWorkerId(), companyId, workerCache);

        String fromName = fromBranch != null ? fromBranch.getName() : null;
        String toName = toBranch != null ? toBranch.getName() : null;

        return ShipmentRequestResponseDto.builder()
                .id(request.getId())
                .requestNumber(request.getRequestNumber())
                .companyId(request.getCompanyId())
                .serialPrefix(request.getSerialPrefix())
                .serialNumber(request.getSerialNumber())
                .fromBranchId(request.getFromBranchId())
                .fromBranchCode(fromBranch != null ? fromBranch.getCode() : null)
                .fromBranchName(fromName)
                .toBranchId(request.getToBranchId())
                .toBranchCode(toBranch != null ? toBranch.getCode() : null)
                .toBranchName(toName)
                .requestedById(request.getRequestedById())
                .requestedByWorkerName(requestedBy != null ? requestedBy.getName() : null)
                .status(request.getStatus())
                .requestDate(request.getRequestDate())
                .deliveryDate(request.getDeliveryDate())
                .notes(request.getNotes())
                .carrierName(request.getCarrierName())
                .sealNumber(request.getSealNumber())
                .rejectionReason(request.getRejectionReason())
                .rejectedByWorkerId(request.getRejectedByWorkerId())
                .rejectedByWorkerName(rejectedBy != null ? rejectedBy.getName() : null)
                .createdAt(request.getCreatedAt())
                .items(toItemDtos(request.getItems()))
                .requestingBranchId(request.getFromBranchId())
                .requestingBranchName(fromName)
                .targetBranchId(request.getToBranchId())
                .targetBranchName(toName)
                .requestStatus(request.getStatus())
                .requestedDeliveryDate(request.getDeliveryDate())
                .requestedByWorkerId(request.getRequestedById())
                .requestedAt(request.getCreatedAt())
                .build();
    }

    private Branch findBranchInCompany(UUID branchId, UUID companyId, Map<UUID, Branch> cache) {
        if (branchId == null || companyId == null) {
            return null;
        }
        if (!cache.containsKey(branchId)) {
            cache.put(branchId, branchRepository.findByIdAndCompanyId(branchId, companyId).orElse(null));
        }
        return cache.get(branchId);
    }

    private Worker findWorkerInCompany(Long workerId, UUID companyId, Map<Long, Worker> cache) {
        if (workerId == null || companyId == null) {
            return null;
        }
        if (!cache.containsKey(workerId)) {
            cache.put(workerId, workerRepository.findByIdAndCompanyId(workerId, companyId).orElse(null));
        }
        return cache.get(workerId);
    }

    private static List<ShipmentRequestItemResponseDto> toItemDtos(List<ShipmentRequestItem> items) {
        if (items == null) {
            return List.of();
        }
        return items.stream()
                .map(item -> ShipmentRequestItemResponseDto.builder()
                        .id(item.getId())
                        .currencyId(item.getCurrencyId())
                        .requestedAmount(item.getRequestedAmount())
                        .approvedAmount(item.getApprovedAmount())
                        .deliveredAmount(item.getDeliveredAmount())
                        .appliedRate(item.getAppliedRate())
                        .hufValue(item.getHufValue())
                        .build())
                .toList();
    }

    /**
     * TBD-1: igaz, ha a kérés státusza olyan, amiben az ÁTADÓ oldal készlete már OUT-könyvelve van
     * (a beküldés — SUBMITTED — könyvel OUT-ot, a visszaigazolás — DELIVERED — már IN-t az átvevőn).
     * Ezekből az állapotokból visszavonáskor a készletet vissza kell pótolni az átadóra; DRAFT-ból nem.
     */
    private boolean wasStockBookedOut(ShipmentRequestStatus status) {
        return status == ShipmentRequestStatus.SUBMITTED
                || status == ShipmentRequestStatus.APPROVED
                || status == ShipmentRequestStatus.IN_TRANSIT;
    }

    private void validateStatusTransition(ShipmentRequest request,
                                          ShipmentRequestStatus expectedCurrent,
                                          ShipmentRequestStatus targetStatus) {
        if (request.getStatus() != expectedCurrent) {
            throw new ValidationException(
                    String.format("A kérés státusza %s, de %s kellene a(z) %s művelethez!",
                            request.getStatus(), expectedCurrent, targetStatus));
        }
    }

    private void validateCreateRequest(ShipmentRequest request) {
        validateEditableRequest(request);
        if (request.getItems() == null) {
            throw new ValidationException("Legalább egy szállítmány tétel kötelező!");
        }
    }

    private void validateEditableRequest(ShipmentRequest request) {
        if (request == null || request.getFromBranchId() == null || request.getToBranchId() == null) {
            throw new ValidationException("Forrás és cél iroda megadása kötelező!");
        }
        if (request.getFromBranchId().equals(request.getToBranchId())) {
            throw new ValidationException("A forrás és cél iroda nem lehet ugyanaz!");
        }
        if (request.getDeliveryDate() != null && request.getDeliveryDate().isBefore(LocalDate.now())) {
            throw new ValidationException("A kézbesítési dátum nem lehet múltbeli!");
        }
        if (request.getItems() != null && request.getItems().isEmpty()) {
            throw new ValidationException("Legalább egy szállítmány tétel kötelező!");
        }
        if (request.getItems() != null) {
            validateItems(request);
        }
    }

    private void validateItems(ShipmentRequest request) {
        request.getItems().forEach(item -> {
            BigDecimal requestedAmount = item.getRequestedAmount();
            if (item.getCurrencyId() == null || requestedAmount == null || requestedAmount.signum() <= 0) {
                throw new ValidationException("Minden tételnél valuta és pozitív összeg kötelező!");
            }
        });
    }

    private RequestNumberParts generateRequestNumber(ShipmentRequest request) {
        ShipmentRequestItem firstItem = request.getItems().get(0);
        Currency currency = currencyRepository.findById(firstItem.getCurrencyId())
                .orElseThrow(() -> new ValidationException(
                        "Ismeretlen valuta a szállítmány-tételben: currencyId=" + firstItem.getCurrencyId()));
        String prefix = determineSerialPrefix(currency.getCode(), request);
        UUID companyId = request.getCompanyId() != null ? request.getCompanyId() : SecurityUtils.getCurrentCompanyId();
        long serialNumber = transferSerialSequenceService.next(companyId, prefix);
        return new RequestNumberParts(prefix, serialNumber, prefix + "-" + String.format("%06d", serialNumber));
    }

    private String determineSerialPrefix(String currencyCode, ShipmentRequest request) {
        boolean huf = "HUF".equalsIgnoreCase(currencyCode);
        UUID currentBranchId = SecurityUtils.getCurrentBranchIdOrNull();
        boolean receipt = currentBranchId != null && currentBranchId.equals(request.getToBranchId());
        if (huf) {
            return receipt ? "UF" : "FF";
        }
        return receipt ? "AV" : "AT";
    }

    private record RequestNumberParts(String prefix, long serialNumber, String value) {}
}
