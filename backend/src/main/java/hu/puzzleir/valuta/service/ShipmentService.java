package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.shipment.ShipmentRequestItemResponseDto;
import hu.puzzleir.valuta.dto.shipment.ShipmentRequestResponseDto;
import hu.puzzleir.valuta.exception.ConflictException;
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
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import tools.jackson.core.JacksonException;
import tools.jackson.databind.ObjectMapper;

import java.math.BigDecimal;
import java.time.Duration;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.UUID;

/**
 * Szállítmánykérés szolgáltatás.
 */
@Service
@RequiredArgsConstructor
@Transactional(rollbackFor = Exception.class)
@Slf4j
public class ShipmentService {

    private static final ObjectMapper AUDIT_JSON_MAPPER = new ObjectMapper();

    private final ShipmentRequestRepository shipmentRequestRepository;
    private final BranchRepository branchRepository;
    private final CurrencyRepository currencyRepository;
    private final WorkerRepository workerRepository;
    private final ExchangeRateService exchangeRateService;
    private final TransferSerialSequenceService transferSerialSequenceService;
    private final ShipmentStockBookingService stockBookingService;
    private final ShipmentHandlingFeeSyncService handlingFeeSyncService;
    private final ShipmentVatSupplySyncService vatSupplySyncService;
    private final AccessScopeService accessScopeService;
    private final AuditLogService auditLogService;
    private final SystemParameterService systemParameterService;
    private final HufDaybookSequenceService hufDaybookSequenceService;

    public static final String ACTION_DIRECT_DELIVER = "SHIPMENT_DIRECT_DELIVER";
    public static final String ACTION_DELIVERED = "SHIPMENT_DELIVERED";
    public static final String ACTION_SUBMITTED = "SHIPMENT_SUBMITTED";
    public static final String ACTION_CANCELLED_BY_SENDER = "SHIPMENT_CANCELLED_BY_SENDER";
    public static final String ACTION_APPROVE_DEPRECATED = "SHIPMENT_APPROVE_DEPRECATED";
    public static final String ACTION_REJECT_DEPRECATED = "SHIPMENT_REJECT_DEPRECATED";
    public static final String ACTION_DELIVER_CONFIRMED_STALE = "SHIPMENT_DELIVER_CONFIRMED_STALE";
    public static final String PARAM_STALE_WARNING_HOURS = "SHIPMENT_STALE_DELIVERY_WARNING_HOURS";
    public static final int DEFAULT_STALE_HOURS = 48;

    private static final Set<ShipmentRequestStatus> STOCK_BOOKED_OUT_STATUSES = Set.of(
            ShipmentRequestStatus.SUBMITTED,
            ShipmentRequestStatus.APPROVED,
            ShipmentRequestStatus.IN_TRANSIT);

    private static final Set<ShipmentRequestStatus> CANCELLABLE_STATUSES = Set.of(
            ShipmentRequestStatus.DRAFT,
            ShipmentRequestStatus.SUBMITTED,
            ShipmentRequestStatus.APPROVED,
            ShipmentRequestStatus.IN_TRANSIT);

    /**
     * v2.5.70 P0 multi-tenant fix (companyId audit follow-up): a régi findByStatus /
     * findAllOrdered globális queries voltak (NEM cég-szintű szűréssel), helyettük a
     * tenant-aware *ByCompanyId variánsokat hívjuk SecurityUtils.getCurrentCompanyId()-val.
     */
    @Transactional(readOnly = true)
    public Page<ShipmentRequest> findAll(ShipmentRequestStatus status, UUID branchId, Pageable pageable) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        Page<ShipmentRequest> page;
        Set<UUID> scope = accessScopeService.vaultRegionBranchScopeOrNull();
        if (scope != null) {
            if (scope.isEmpty()) {
                return new PageImpl<>(List.of(), pageable, 0); // fail-closed
            }
            page = shipmentRequestRepository.findScopedByCompanyId(scope, branchId, status, companyId, pageable);
            page.getContent().forEach(ShipmentService::initLazyForSerialization);
            return page;
        }
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
        int staleThresholdHours = effectiveStaleThresholdHours();
        Map<UUID, Branch> branchCache = new HashMap<>();
        Map<Long, Worker> workerCache = new HashMap<>();
        return findAll(status, branchId, pageable)
                .map(request -> toResponseDto(
                        request, companyId, branchCache, workerCache, staleThresholdHours));
    }

    /** FKH-018: a bejelentkezett fiókhoz címzett, még átvehető shipmentek. */
    @Transactional(readOnly = true)
    public List<ShipmentRequestResponseDto> findPendingForCurrentBranchResponse() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        UUID branchId = SecurityUtils.getCurrentBranchIdOrNull();
        if (branchId == null) {
            return List.of();
        }
        Set<UUID> scope = accessScopeService.vaultRegionBranchScopeOrNull();
        if (scope != null && !scope.contains(branchId)) {
            return List.of();
        }
        Set<ShipmentRequestStatus> pendingStatuses = Set.of(
                ShipmentRequestStatus.SUBMITTED,
                ShipmentRequestStatus.APPROVED,
                ShipmentRequestStatus.IN_TRANSIT);
        List<ShipmentRequest> requests = shipmentRequestRepository.findPendingForToBranch(
                companyId, branchId, pendingStatuses);
        requests.forEach(ShipmentService::initLazyForSerialization);
        Map<UUID, Branch> branchCache = new HashMap<>();
        Map<Long, Worker> workerCache = new HashMap<>();
        int staleThresholdHours = effectiveStaleThresholdHours();
        return requests.stream()
                .map(request -> toResponseDto(
                        request, companyId, branchCache, workerCache, staleThresholdHours))
                .toList();
    }

    @Transactional(readOnly = true)
    public ShipmentRequest findById(UUID id) {
        UUID currentCompanyId = SecurityUtils.getCurrentCompanyId();
        ShipmentRequest sr = shipmentRequestRepository.findByIdAndCompanyId(id, currentCompanyId)
                .orElseThrow(() -> new ResourceNotFoundException("Szállítmánykérés nem található: " + id));
        // v2.5.70 P0 fix + #890 self-review P1-2: cross-tenant IDOR guard — MIND A KÉT
        // branch (from + to) Branch.company.id-jét összevetjük a jelenlegi user
        // company-jával. A korábbi fix csak a fromBranchId-t ellenőrizte; ha egy shipment
        // toBranchId-je másik cégre mutat (data-bug vagy admin-create), a UI-t serializáló
        // entitás sérthette a tenant-izolációt.
        assertBranchInCompany(sr.getFromBranchId(), currentCompanyId, id, "fromBranchId");
        assertBranchInCompany(sr.getToBranchId(), currentCompanyId, id, "toBranchId");
        // P0 LazyInit hotfix: a controller direkt entity-t serializál, items lazy.
        initLazyForSerialization(sr);
        return sr;
    }

    @Transactional(readOnly = true)
    public ShipmentRequestResponseDto findByIdResponse(UUID id) {
        ShipmentRequest sr = findById(id);
        assertTerritoryVisible(sr, id);
        return toResponseDto(sr);
    }

    /**
     * P1 (Codex review, PR #1243): pesszimista sor-zárral betöltött shipment a státuszváltásokhoz.
     * Ugyanaz a cross-tenant guard + lazy-init mint a {@link #findById}, de a sort {@code FOR UPDATE}
     * zárral olvassa — így két párhuzamos azonos átmenet (dupla-klikk/retry) szerializálódik, és a
     * második a friss státuszt látva elbukik a {@code validateStatusTransition}-ön (nincs dupla
     * készlet-könyvelés). NEM {@code readOnly}: a hívó {@code @Transactional} írási tranzakciójában fut.
     */
    private ShipmentRequest findByIdLocked(UUID id) {
        UUID currentCompanyId = SecurityUtils.getCurrentCompanyId();
        ShipmentRequest sr = shipmentRequestRepository.findByIdAndCompanyIdForUpdate(id, currentCompanyId)
                .orElseThrow(() -> new ResourceNotFoundException("Szállítmánykérés nem található: " + id));
        assertBranchInCompany(sr.getFromBranchId(), currentCompanyId, id, "fromBranchId");
        assertBranchInCompany(sr.getToBranchId(), currentCompanyId, id, "toBranchId");
        initLazyForSerialization(sr);
        return sr;
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
            throw new ResourceNotFoundException("Szállítmánykérés nem található: " + shipmentId);
        }
    }

    /**
     * Territory-scope guard OLVASÓ útvonalra (2026-07-15 hardening): scope-on kívüli
     * shipment → 404 (assertBranchInCompany-val azonos anti-enumeráció konvenció).
     * SZÁNDÉKOSAN nincs a findById/findByIdLocked-ban: azokat írási útvonalak
     * (update/approve/deliver/submit/cancel) hívják, amelyek viselkedése e slice-ban
     * nem változhat.
     */
    private void assertTerritoryVisible(ShipmentRequest sr, UUID idForMessage) {
        Set<UUID> scope = accessScopeService.vaultRegionBranchScopeOrNull();
        if (scope == null) {
            return;
        }
        String fromId = sr.getFromBranchId() != null ? sr.getFromBranchId().toString() : null;
        String toId = sr.getToBranchId() != null ? sr.getToBranchId().toString() : null;
        boolean visible = accessScopeService.isBranchVisible(scope, fromId)
                || accessScopeService.isBranchVisible(scope, toId);
        if (!visible) {
            throw new ResourceNotFoundException("Szállítmánykérés nem található: " + idForMessage);
        }
    }

    /** Publikus read-guard társ-service-eknek (handling-fee): betölt (tenant-guarddal) + territory-check. */
    @Transactional(readOnly = true)
    public void assertShipmentTerritoryVisible(UUID shipmentId) {
        assertTerritoryVisible(findById(shipmentId), shipmentId);
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
        return create(request, null);
    }

    public ShipmentRequest create(ShipmentRequest request, String serialPrefixOverride) {
        validateCreateRequest(request);
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        request.setCompanyId(companyId);
        RequestNumberParts requestNumberParts = generateRequestNumber(request, serialPrefixOverride);
        request.setRequestNumber(requestNumberParts.value());
        request.setSerialPrefix(requestNumberParts.prefix());
        request.setSerialNumber(requestNumberParts.serialNumber());
        if (isHufDaybookPrefix(requestNumberParts.prefix())) {
            request.setAnnualJournalSequence(
                    hufDaybookSequenceService.next(companyId, LocalDate.now().getYear()));
        }
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
        // A DRAFT update ugyanarról az állapotról versenyezhet a submit/cancel műveletekkel.
        // Sor-zár nélkül egy későn flush-oló szerkesztés visszaállíthatná a már SUBMITTED sort
        // DRAFT-ra, ami a beküldési OUT-könyvelés megismétlését tenné lehetővé.
        ShipmentRequest existing = findByIdLocked(id);
        if (existing.getStatus() != ShipmentRequestStatus.DRAFT) {
            throw new ValidationException("Csak DRAFT státuszú kérés módosítható!");
        }
        handlingFeeSyncService.assertNotHandlingFeeShipment(existing);
        vatSupplySyncService.assertNotVatSupplyShipment(existing);
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

        // P2 (Codex review, PR #1243): a DRAFT szerkesztés felülírhatja a from/to fiókot, ezért a
        // transfer_type-ot ÚJRA kell deriválni — különben a könyvelés az új fiókokkal mozog, de a
        // tárolt/auditált irány a régi maradna (félrevezető audit-nyom). Szerveroldalon, tenant-
        // ellenőrzött branch-ekből (kliens nem hamisíthatja az irányt).
        UUID currentCompanyId = SecurityUtils.getCurrentCompanyId();
        Branch fromBranch = branchRepository.findByIdAndCompanyId(existing.getFromBranchId(), currentCompanyId)
                .orElseThrow(() -> new ValidationException(
                        "Forrás fiók nem található a jelenlegi cégben: " + existing.getFromBranchId()));
        Branch toBranch = branchRepository.findByIdAndCompanyId(existing.getToBranchId(), currentCompanyId)
                .orElseThrow(() -> new ValidationException(
                        "Cél fiók nem található a jelenlegi cégben: " + existing.getToBranchId()));
        existing.setTransferType(stockBookingService.deriveTransferType(fromBranch, toBranch));

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
        ShipmentRequest request = findByIdLocked(id);
        validateStatusTransition(request, ShipmentRequestStatus.DRAFT, ShipmentRequestStatus.SUBMITTED);
        // FK (TBD-1 döntés): az ÁTADÓ oldal készlete a beküldéskor AZONNAL csökken (OUT-könyvelés),
        // pesszimista lockkal + elégség-ellenőrzéssel (FR-2/5/7/8). Ha elégtelen → 422 VV-VALID-003,
        // a teljes @Transactional rollbackel (a státusz nem vált), az audit REQUIRES_NEW-ban megmarad.
        // FKH-040: AS (ÁFA ellátmány) NEM currency_stock-ot mozgat — a vat_supply_stock a sync-ben él.
        if (!skipsCurrencyStockBooking(request)) {
            stockBookingService.bookStockOut(request, SecurityUtils.getCurrentCompanyId());
        }
        writeStatusAudit(ACTION_SUBMITTED, request, ShipmentRequestStatus.DRAFT,
                ShipmentRequestStatus.SUBMITTED);
        request.setStatus(ShipmentRequestStatus.SUBMITTED);
        log.info("Szállítmánykérés beküldve: {}", request.getRequestNumber());
        ShipmentRequest saved = shipmentRequestRepository.save(request);
        syncSpecialShipmentItems(saved);
        initLazyForSerialization(saved);
        return saved;
    }

    public ShipmentRequestResponseDto submitResponse(UUID id) {
        return toResponseDto(submit(id));
    }

    public ShipmentRequest approve(UUID id) {
        // A deprecated approve ugyanarról a SUBMITTED állapotról versenyezhet a közvetlen
        // deliver/cancel/reject műveletekkel. Ugyanazt a sor-zárat kell használnia, különben egy
        // korábban beolvasott SUBMITTED entity visszaírhatná az APPROVED státuszt egy már
        // DELIVERED sorra, és megnyitná a dupla készlet-IN útját.
        ShipmentRequest request = findByIdLocked(id);
        // FKH-018: a jóváhagyás csak vegyes kliensflotta miatti deprecated kompatibilitási út.
        // A KK négy-szem megszűnt; tenant- és küldő-branch guard változatlanul kötelező.
        stockBookingService.assertRequester(request);
        validateStatusTransition(request, ShipmentRequestStatus.SUBMITTED, ShipmentRequestStatus.APPROVED);
        writeStatusAudit(ACTION_APPROVE_DEPRECATED, request, ShipmentRequestStatus.SUBMITTED,
                ShipmentRequestStatus.APPROVED);
        request.setStatus(ShipmentRequestStatus.APPROVED);
        log.info("Szállítmánykérés jóváhagyva: {}", request.getRequestNumber());
        ShipmentRequest saved = shipmentRequestRepository.save(request);
        syncSpecialShipmentItems(saved);
        initLazyForSerialization(saved);
        return saved;
    }

    public ShipmentRequestResponseDto approveResponse(UUID id) {
        return toResponseDto(approve(id));
    }

    public ShipmentRequest deliver(UUID id) {
        return deliver(id, false);
    }

    public ShipmentRequest deliver(UUID id, boolean confirmedStale) {
        ShipmentRequest request = findByIdLocked(id);
        // Authz a státusz-ellenőrzés előtt: idegen/no-branch hívó nem tudja megkülönböztetni
        // a DELIVERED, érvénytelen és átvehető állapotokat, és mutációig sem juthat el.
        stockBookingService.assertReceiver(request);
        ShipmentRequestStatus previousStatus = request.getStatus();
        if (previousStatus == ShipmentRequestStatus.DELIVERED) {
            throw new ConflictException("VV-SHIP-409-DELIVERED: a szállítmány már kézbesítve lett"
                    + (request.getDeliveryDate() != null ? " (" + request.getDeliveryDate() + ")" : ""));
        }
        if (previousStatus != ShipmentRequestStatus.SUBMITTED
                && previousStatus != ShipmentRequestStatus.APPROVED
                && previousStatus != ShipmentRequestStatus.IN_TRANSIT) {
            throw new ValidationException("Csak SUBMITTED, APPROVED vagy IN_TRANSIT státuszú kérés vehető át!");
        }
        int staleThresholdHours = DEFAULT_STALE_HOURS;
        LocalDateTime staleCheckedAt = null;
        boolean auditConfirmedStale = false;
        if (confirmedStale) {
            staleThresholdHours = effectiveStaleThresholdHours();
            staleCheckedAt = LocalDateTime.now();
            auditConfirmedStale = isStaleForDelivery(request, staleThresholdHours, staleCheckedAt);
            if (!auditConfirmedStale) {
                log.info("A kliens stale megerősítést küldött, de a szerver szerint a Shipment nem stale: id={}", id);
            }
        }
        // FR-3: az ÁTVEVŐ oldal készlete a visszaigazoláskor nő (IN-könyvelés), get-or-create + lock.
        // FKH-040: AS → vat_supply_stock a sync-ben, nem currency_stock.
        if (!skipsCurrencyStockBooking(request)) {
            stockBookingService.bookStockIn(request, SecurityUtils.getCurrentCompanyId());
        }
        writeStatusAudit(
                previousStatus == ShipmentRequestStatus.SUBMITTED ? ACTION_DIRECT_DELIVER : ACTION_DELIVERED,
                request, previousStatus, ShipmentRequestStatus.DELIVERED);
        if (auditConfirmedStale) {
            writeConfirmedStaleAudit(request, staleThresholdHours, staleCheckedAt);
        }
        request.setStatus(ShipmentRequestStatus.DELIVERED);
        request.setDeliveryDate(LocalDate.now());
        log.info("Szállítmánykérés leszállítva: {}", request.getRequestNumber());
        ShipmentRequest saved = shipmentRequestRepository.save(request);
        syncSpecialShipmentItems(saved);
        initLazyForSerialization(saved);
        return saved;
    }

    public ShipmentRequestResponseDto deliverResponse(UUID id) {
        return toResponseDto(deliver(id));
    }

    public ShipmentRequestResponseDto deliverResponse(UUID id, boolean confirmedStale) {
        return toResponseDto(deliver(id, confirmedStale));
    }

    public ShipmentRequest cancel(UUID id) {
        ShipmentRequest request = findByIdLocked(id);
        stockBookingService.assertSender(request);
        ShipmentRequestStatus previousStatus = request.getStatus();
        validateStatusTransition(request, CANCELLABLE_STATUSES, ShipmentRequestStatus.CANCELLED);
        // TBD-1: a készlet az átadó oldalon a beküldéskor (SUBMITTED) csökkent. Ha egy már OUT-könyvelt
        // (SUBMITTED/APPROVED/IN_TRANSIT) kérést visszavonnak, a készletet vissza kell pótolni, különben
        // elveszne. DRAFT-ból visszavonáskor nem volt OUT-könyvelés → nincs reverzió (dupla-jóváírás elkerülés).
        if (wasStockBookedOut(previousStatus) && !skipsCurrencyStockBooking(request)) {
            stockBookingService.reverseStockOut(request, SecurityUtils.getCurrentCompanyId());
        }
        Long workerId = SecurityUtils.getCurrentWorkerId();
        LocalDateTime cancelledAt = LocalDateTime.now();
        writeStatusAudit(ACTION_CANCELLED_BY_SENDER, request, previousStatus, ShipmentRequestStatus.CANCELLED);
        request.setStatus(ShipmentRequestStatus.CANCELLED);
        request.setCancelledByWorkerId(workerId);
        request.setCancelledAt(cancelledAt);
        // FKH-022 FR-K2/3: a sztornó-sor SAJÁT naplókönyv-sorszámot kap (nem az eredetiét
        // ismétli), a sztornó pillanatának (cancelled_at) időrendi helyén. Az évet a
        // MEGRAGADOTT cancelledAt időbélyegből vesszük (Bugbot #2, PR #1518): így az élő
        // kiosztás és a V366 backfill év-szemantikája évhatáron is azonos.
        if (isHufDaybookPrefix(request.getSerialPrefix()) && request.getCompanyId() != null) {
            request.setStornoJournalSequence(hufDaybookSequenceService.next(
                    request.getCompanyId(), cancelledAt.getYear()));
        }
        log.info("Szállítmánykérés visszavonva: {}", request.getRequestNumber());
        ShipmentRequest saved = shipmentRequestRepository.save(request);
        syncSpecialShipmentItems(saved);
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
        ShipmentRequest request = findByIdLocked(id);
        stockBookingService.assertRequester(request);
        validateStatusTransition(request, ShipmentRequestStatus.SUBMITTED, ShipmentRequestStatus.REJECTED);
        // Biztonság: az elutasító dolgozó a HITELESÍTETT user (nem kliens-trusted param) — mint create().
        Long workerId = SecurityUtils.getCurrentWorkerId();
        // TBD-1: a reject CSAK SUBMITTED-ből megengedett, ami mindig OUT-könyvelt állapot → a készletet
        // mindig vissza kell pótolni az átadó oldalra (SHIPMENT_STOCK_REVERSAL audit).
        // FKH-040: AS nem currency_stock-ot könyvelt.
        if (!skipsCurrencyStockBooking(request)) {
            stockBookingService.reverseStockOut(request, SecurityUtils.getCurrentCompanyId());
        }
        writeStatusAudit(ACTION_REJECT_DEPRECATED, request, ShipmentRequestStatus.SUBMITTED,
                ShipmentRequestStatus.REJECTED);
        request.setStatus(ShipmentRequestStatus.REJECTED);
        request.setRejectionReason(reason);
        request.setRejectedByWorkerId(workerId);
        log.info("Szállítmánykérés elutasítva: {} (elutasító worker={})", request.getRequestNumber(), workerId);
        ShipmentRequest saved = shipmentRequestRepository.save(request);
        syncSpecialShipmentItems(saved);
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
        return toResponseDto(
                request, companyId, new HashMap<>(), new HashMap<>(), effectiveStaleThresholdHours());
    }

    private ShipmentRequestResponseDto toResponseDto(
            ShipmentRequest request,
            UUID companyId,
            Map<UUID, Branch> branchCache,
            Map<Long, Worker> workerCache,
            int staleThresholdHours) {
        Branch fromBranch = findBranchInCompany(request.getFromBranchId(), companyId, branchCache);
        Branch toBranch = findBranchInCompany(request.getToBranchId(), companyId, branchCache);
        Branch vaultBranch = findBranchInCompany(
                SecurityUtils.getCurrentBranchIdOrNull(), companyId, branchCache);
        Worker requestedBy = findWorkerInCompany(request.getRequestedById(), companyId, workerCache);
        Worker rejectedBy = findWorkerInCompany(request.getRejectedByWorkerId(), companyId, workerCache);
        Worker cancelledBy = findWorkerInCompany(request.getCancelledByWorkerId(), companyId, workerCache);

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
                .cancelledByWorkerId(request.getCancelledByWorkerId())
                .cancelledByWorkerName(cancelledBy != null ? cancelledBy.getName() : null)
                .cancelledAt(request.getCancelledAt())
                .createdAt(request.getCreatedAt())
                .vaultAddress(vaultBranch != null ? formatBranchAddress(vaultBranch) : null)
                .vaultPhone(vaultBranch != null ? normalizedPhone(vaultBranch.getPhone()) : null)
                .items(toItemDtos(request.getItems()))
                .requestingBranchId(request.getFromBranchId())
                .requestingBranchName(fromName)
                .targetBranchId(request.getToBranchId())
                .targetBranchName(toName)
                .requestStatus(request.getStatus())
                .requestedDeliveryDate(request.getDeliveryDate())
                .requestedByWorkerId(request.getRequestedById())
                .requestedAt(request.getCreatedAt())
                .staleForDelivery(isStaleForDelivery(request, staleThresholdHours, LocalDateTime.now()))
                .staleThresholdHours(staleThresholdHours)
                .build();
    }

    private int effectiveStaleThresholdHours() {
        String configured = systemParameterService.getRawValue(PARAM_STALE_WARNING_HOURS, null);
        if (configured == null) {
            return DEFAULT_STALE_HOURS;
        }
        try {
            int parsed = Integer.parseInt(configured.trim());
            if (parsed > 0) {
                return parsed;
            }
        } catch (NumberFormatException ignored) {
            // A közös WARN ág lent kezeli a jelen lévő, de hibás értéket.
        }
        log.warn("Érvénytelen Shipment stale küszöb, fallback 48 órára: key={}, value={}",
                PARAM_STALE_WARNING_HOURS, configured);
        return DEFAULT_STALE_HOURS;
    }

    static boolean isStaleForDelivery(ShipmentRequest request, int thresholdHours, LocalDateTime now) {
        if (request == null || request.getCreatedAt() == null) {
            log.warn("Shipment stale számítás createdAt nélkül, nem stale eredmény: shipmentId={}",
                    request != null ? request.getId() : null);
            return false;
        }
        return Duration.between(request.getCreatedAt(), now)
                .compareTo(Duration.ofHours(thresholdHours)) > 0;
    }

    private void writeConfirmedStaleAudit(
            ShipmentRequest request, int thresholdHours, LocalDateTime checkedAt) {
        long ageHours = Duration.between(request.getCreatedAt(), checkedAt).toHours();
        Long workerId = SecurityUtils.getCurrentWorkerId();
        UUID branchId = SecurityUtils.getCurrentBranchIdOrNull();
        Map<String, Object> changes = new LinkedHashMap<>();
        changes.put("KAT", "TX");
        changes.put("shipment_request_id", request.getId().toString());
        changes.put("request_number", request.getRequestNumber());
        changes.put("threshold_hours", thresholdHours);
        changes.put("age_hours", ageHours);
        changes.put("confirmed", true);
        auditLogService.log(ACTION_DELIVER_CONFIRMED_STALE, "ShipmentRequest", request.getId().toString(),
                workerId != null ? workerId.toString() : null, null,
                branchId != null ? branchId.toString() : null, null,
                serializeAuditChanges(changes),
                null, null);
    }

    private static String serializeAuditChanges(Map<String, Object> changes) {
        try {
            return AUDIT_JSON_MAPPER.writeValueAsString(changes);
        } catch (JacksonException e) {
            throw new IllegalStateException("Shipment stale audit JSON serialization failed", e);
        }
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

    /** FKH-006: a Transfer-bizonylattal azonos, blank-safe fejléc-cím formázás. */
    private String formatBranchAddress(Branch branch) {
        java.util.List<String> parts = new java.util.ArrayList<>();
        if (branch.getCity() != null && !branch.getCity().isBlank()) {
            parts.add(branch.getCity().trim());
        }
        if (branch.getAddress() != null && !branch.getAddress().isBlank()) {
            parts.add(branch.getAddress().trim());
        }
        if (branch.getZipCode() != null && !branch.getZipCode().isBlank()) {
            parts.add(branch.getZipCode().trim());
        }
        return parts.isEmpty() ? null : String.join(", ", parts);
    }

    /** FKH-006: üres telefonszámnál a bizonylat ne rendereljen telefon sort. */
    private String normalizedPhone(String phone) {
        return (phone == null || phone.isBlank()) ? null : phone.trim();
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

    private List<ShipmentRequestItemResponseDto> toItemDtos(List<ShipmentRequestItem> items) {
        if (items == null) {
            return List.of();
        }
        Map<Long, String> currencyCodes = resolveCurrencyCodes(items);
        return items.stream()
                .map(item -> ShipmentRequestItemResponseDto.builder()
                        .id(item.getId())
                        .currencyId(item.getCurrencyId())
                        .currencyCode(currencyCodes.get(item.getCurrencyId()))
                        .requestedAmount(item.getRequestedAmount())
                        .approvedAmount(item.getApprovedAmount())
                        .deliveredAmount(item.getDeliveredAmount())
                        .appliedRate(item.getAppliedRate())
                        .hufValue(item.getHufValue())
                        .build())
                .toList();
    }

    private Map<Long, String> resolveCurrencyCodes(List<ShipmentRequestItem> items) {
        List<Long> currencyIds = items.stream()
                .map(ShipmentRequestItem::getCurrencyId)
                .filter(Objects::nonNull)
                .distinct()
                .toList();
        if (currencyIds.isEmpty()) {
            return Map.of();
        }
        Map<Long, String> currencyCodes = new HashMap<>();
        currencyRepository.findAllById(currencyIds)
                .forEach(currency -> currencyCodes.put(currency.getId(), currency.getCode()));
        return currencyCodes;
    }

    /**
     * TBD-1: igaz, ha a kérés státusza olyan, amiben az ÁTADÓ oldal készlete már OUT-könyvelve van
     * (a beküldés — SUBMITTED — könyvel OUT-ot, a visszaigazolás — DELIVERED — már IN-t az átvevőn).
     * Ezekből az állapotokból visszavonáskor a készletet vissza kell pótolni az átadóra; DRAFT-ból nem.
     */
    private boolean wasStockBookedOut(ShipmentRequestStatus status) {
        return STOCK_BOOKED_OUT_STATUSES.contains(status);
    }

    private void writeStatusAudit(String action, ShipmentRequest request,
                                  ShipmentRequestStatus fromStatus, ShipmentRequestStatus toStatus) {
        Long workerId = SecurityUtils.getCurrentWorkerId();
        UUID branchId = SecurityUtils.getCurrentBranchIdOrNull();
        auditLogService.log(action, "ShipmentRequest", request.getId().toString(),
                workerId != null ? workerId.toString() : null, null,
                branchId != null ? branchId.toString() : null, null,
                String.format("{\"KAT\":\"TX\",\"shipment_request_id\":\"%s\","
                                + "\"from_status\":\"%s\",\"to_status\":\"%s\"}",
                        request.getId(), fromStatus, toStatus),
                null, null);
    }

    private void validateStatusTransition(ShipmentRequest request,
                                          ShipmentRequestStatus expectedCurrent,
                                          ShipmentRequestStatus targetStatus) {
        validateStatusTransition(request, Set.of(expectedCurrent), targetStatus);
    }

    private void validateStatusTransition(ShipmentRequest request,
                                          Set<ShipmentRequestStatus> expectedCurrent,
                                          ShipmentRequestStatus targetStatus) {
        if (!expectedCurrent.contains(request.getStatus())) {
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

    private RequestNumberParts generateRequestNumber(ShipmentRequest request, String prefixOverride) {
        ShipmentRequestItem firstItem = request.getItems().get(0);
        Currency currency = currencyRepository.findById(firstItem.getCurrencyId())
                .orElseThrow(() -> new ValidationException(
                        "Ismeretlen valuta a szállítmány-tételben: currencyId=" + firstItem.getCurrencyId()));
        String prefix = prefixOverride != null
                ? prefixOverride
                : determineSerialPrefix(currency.getCode(), request);
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

    private static boolean isHufDaybookPrefix(String prefix) {
        return "FF".equalsIgnoreCase(prefix) || "UF".equalsIgnoreCase(prefix);
    }

    /**
     * FKH-040: ÁFA ellátmány (AS) — a currency_stock könyvelést KI kell hagyni, mert az
     * ÁFA-pénz a {@code vat_supply_stock} területi egyenlegben él (a mozgást a
     * {@link ShipmentVatSupplySyncService} könyveli). A prefix az elsődleges, gyors jel;
     * a napló-sor léte a tartalék (régi/prefix nélküli sorokra is fail-closed).
     */
    private boolean skipsCurrencyStockBooking(ShipmentRequest request) {
        return ShipmentVatSupplyService.SERIAL_PREFIX_VAT_SUPPLY.equalsIgnoreCase(request.getSerialPrefix())
                || vatSupplySyncService.isVatSupplyShipment(request);
    }

    private void syncSpecialShipmentItems(ShipmentRequest saved) {
        handlingFeeSyncService.syncFromShipment(saved);
        vatSupplySyncService.syncFromShipment(saved);
    }
}
