package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.entity.ExchangeRate;
import hu.puzzleir.valuta.entity.ShipmentRequest;
import hu.puzzleir.valuta.entity.ShipmentRequestItem;
import hu.puzzleir.valuta.entity.ShipmentRequestStatus;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.ShipmentRequestRepository;
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
import java.time.format.DateTimeFormatter;
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
    private final ExchangeRateService exchangeRateService;

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
        request.setRequestNumber(generateRequestNumber());
        request.setStatus(ShipmentRequestStatus.DRAFT);
        request.setRequestedById(SecurityUtils.getCurrentWorkerId());
        request.setRequestDate(LocalDate.now());

        // D követelmény (Bali Henriett 2026-05-27): minden tételen kötelezően az AKTUÁLIS
        // elszámoló árfolyam (officialRate / J) és a forintosított érték (HUF kerekítve).
        applyExchangeRateAndHufValue(request);

        log.info("Szállítmánykérés létrehozva: {}, from={}, to={}",
                request.getRequestNumber(), request.getFromBranchId(), request.getToBranchId());
        ShipmentRequest saved = shipmentRequestRepository.save(request);
        // P0 self-review #890: minden controller-felé visszaadott entity-n meg kell hívni az
        // init-et, hogy a Jackson OSIV=false-lal NE fusson LazyInit-be.
        initLazyForSerialization(saved);
        return saved;
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
                ExchangeRate er = exchangeRateService.getCurrentRate(item.getCurrencyId());
                if (er == null || er.getOfficialRate() == null) {
                    throw new ValidationException(
                            "A currencyId=" + item.getCurrencyId() + " valutához nincs aktuális "
                                    + "elszámoló árfolyam (officialRate). Frissítse az árfolyamot "
                                    + "a szállítmánykérés rögzítése előtt.");
                }
                item.setAppliedRate(er.getOfficialRate());
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
        existing.setCarrierName(updated.getCarrierName());
        existing.setSealNumber(updated.getSealNumber());

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

    public ShipmentRequest submit(UUID id) {
        ShipmentRequest request = findById(id);
        validateStatusTransition(request, ShipmentRequestStatus.DRAFT, ShipmentRequestStatus.SUBMITTED);
        request.setStatus(ShipmentRequestStatus.SUBMITTED);
        log.info("Szállítmánykérés beküldve: {}", request.getRequestNumber());
        ShipmentRequest saved = shipmentRequestRepository.save(request);
        initLazyForSerialization(saved);
        return saved;
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

    public ShipmentRequest deliver(UUID id) {
        ShipmentRequest request = findById(id);
        if (request.getStatus() != ShipmentRequestStatus.APPROVED
                && request.getStatus() != ShipmentRequestStatus.IN_TRANSIT) {
            throw new ValidationException("Csak APPROVED vagy IN_TRANSIT státuszú kérés szállítható le!");
        }
        request.setStatus(ShipmentRequestStatus.DELIVERED);
        request.setDeliveryDate(LocalDate.now());
        log.info("Szállítmánykérés leszállítva: {}", request.getRequestNumber());
        ShipmentRequest saved = shipmentRequestRepository.save(request);
        initLazyForSerialization(saved);
        return saved;
    }

    public ShipmentRequest cancel(UUID id) {
        ShipmentRequest request = findById(id);
        if (request.getStatus() == ShipmentRequestStatus.DELIVERED
                || request.getStatus() == ShipmentRequestStatus.CANCELLED) {
            throw new ValidationException("DELIVERED vagy CANCELLED státuszú kérés nem vonható vissza!");
        }
        request.setStatus(ShipmentRequestStatus.CANCELLED);
        log.info("Szállítmánykérés visszavonva: {}", request.getRequestNumber());
        ShipmentRequest saved = shipmentRequestRepository.save(request);
        initLazyForSerialization(saved);
        return saved;
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
        request.setStatus(ShipmentRequestStatus.REJECTED);
        request.setRejectionReason(reason);
        request.setRejectedByWorkerId(workerId);
        log.info("Szállítmánykérés elutasítva: {} (elutasító worker={})", request.getRequestNumber(), workerId);
        ShipmentRequest saved = shipmentRequestRepository.save(request);
        initLazyForSerialization(saved);
        return saved;
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

    private String generateRequestNumber() {
        String prefix = "SHR-" + LocalDate.now().format(DateTimeFormatter.ofPattern("yyyyMMdd")) + "-";
        int nextNum = shipmentRequestRepository.findMaxRequestNumber(prefix) + 1;
        return prefix + String.format("%04d", nextNum);
    }
}
