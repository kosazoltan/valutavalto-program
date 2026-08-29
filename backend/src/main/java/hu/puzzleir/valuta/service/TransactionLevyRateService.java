package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.levy.TransactionLevyRateCreateRequest;
import hu.puzzleir.valuta.dto.levy.TransactionLevyRateDto;
import hu.puzzleir.valuta.entity.TransactionLevyRateHistory;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.TransactionLevyRateHistoryRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.util.TransactionLevyCalculator;
import hu.puzzleir.valuta.util.TransactionLevyCalculator.LevyRate;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import java.util.UUID;

/**
 * FK-099 — append-only illeték-ráta history írása/olvasása.
 *
 * <p>RBAC (D10/FR-18): olvasás bővebb kör (IRODAVEZETO nélkül), írás szűkebb;
 * a megtagadás ACCESS_DENIED audit-sort kap, nem csak a Spring filter 403-at.</p>
 *
 * <p>Append-only (FR-1): a service MINDEN szabályt EGY kivételbe batchel (D8):
 * {@code effectiveFrom > ma} és {@code effectiveFrom > max(existing)}. A
 * konkurens duplikátum a {@code uk_tlrh_company_effective} unique-indexbe ütközik:
 * {@code saveAndFlush} + {@code DataIntegrityViolationException} catch →
 * ValidationException (HTTP 400), soha 500 (D16, pitfall 17: plain {@code save}
 * esetén a constraint commit-időben, a catch-en KÍVÜL sülne el).</p>
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class TransactionLevyRateService {

    /** FK-099 hibakód: az illeték-ráta művelet szerep-megtagadása. */
    public static final String ERR_RATE_ROLE = "VV-AUTH-007";
    public static final String ACTION_ACCESS_DENIED = "ACCESS_DENIED";
    private static final String AUDIT_ENTITY_TYPE = "TRANSACTION_LEVY_RATE";

    private static final Set<String> READ_ROLES = Set.of(
            "ROLE_FOERTEKTAR", "ROLE_UGYVEZETO", "ROLE_ADMIN", "ROLE_BELSO_ELLENOR");
    private static final Set<String> WRITE_ROLES = Set.of(
            "ROLE_FOERTEKTAR", "ROLE_UGYVEZETO", "ROLE_ADMIN");

    private final TransactionLevyRateHistoryRepository rateHistoryRepository;
    private final AuditLogService auditLogService;

    /** A cég teljes ráta-historyja, effectiveFrom DESC, derived küszöbbel. */
    @Transactional(readOnly = true)
    public List<TransactionLevyRateDto> list() {
        assertAuthorized(READ_ROLES);
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return rateHistoryRepository.findByCompanyIdOrderByEffectiveFromDesc(companyId)
                .stream()
                .map(TransactionLevyRateService::toDto)
                .toList();
    }

    /**
     * Új append-only ráta-sor. Sorrend: RBAC → batchelt üzleti validáció →
     * {@code saveAndFlush} (D16 race-védelem) → audit CSAK a sikeres úton
     * (a vesztő versenyfutás nem produkálhat CREATE audit-sort nem létező sorra).
     */
    @Transactional
    public TransactionLevyRateDto create(TransactionLevyRateCreateRequest request) {
        assertAuthorized(WRITE_ROLES);
        UUID companyId = SecurityUtils.getCurrentCompanyId();

        LocalDate maxExisting = rateHistoryRepository
                .findFirstByCompanyIdOrderByEffectiveFromDesc(companyId)
                .map(TransactionLevyRateHistory::getEffectiveFrom)
                .orElse(null);
        validateEffectiveFrom(request.getEffectiveFrom(), maxExisting);

        TransactionLevyRateHistory entity = TransactionLevyRateHistory.builder()
                .companyId(companyId)
                .effectiveFrom(request.getEffectiveFrom())
                .baseRatePercent(request.getBaseRatePercent())
                .baseRateCapHuf(request.getBaseRateCapHuf())
                .supplementRatePercent(request.getSupplementRatePercent())
                .supplementRateCapHuf(request.getSupplementRateCapHuf())
                .conversionSingleSideFlag(Boolean.TRUE.equals(request.getConversionSingleSideFlag()))
                .createdBy(SecurityUtils.getCurrentWorkerCode())
                .build();

        TransactionLevyRateHistory saved;
        try {
            // D16/pitfall 17: saveAndFlush — a constraint-sértés ITT sül el, a catch-en belül.
            saved = rateHistoryRepository.saveAndFlush(entity);
        } catch (DataIntegrityViolationException e) {
            // D16: a vesztes versenyfutás operátori hibajelzés, nem nyelhető el, nem retry.
            log.info("FK-099 konkurens ráta-beszúrás ütközött a unique-indexbe: effectiveFrom={}",
                    request.getEffectiveFrom());
            throw new ValidationException(
                    "Erre a hatálybalépési dátumra időközben már rögzítettek rátát: "
                            + request.getEffectiveFrom());
        }

        auditLogService.logInNewTransactionForCompany(
                "CREATE",
                String.format(
                        "{\"KAT\":\"RATE\",\"effective_from\":\"%s\","
                                + "\"base\":{\"rate\":\"%s\",\"cap\":\"%s\"},"
                                + "\"supplement\":{\"rate\":\"%s\",\"cap\":\"%s\"},"
                                + "\"conversion_single_side\":%s}",
                        saved.getEffectiveFrom(),
                        saved.getBaseRatePercent(), saved.getBaseRateCapHuf(),
                        saved.getSupplementRatePercent(), saved.getSupplementRateCapHuf(),
                        saved.isConversionSingleSideFlag()),
                saved.getId().toString(),
                companyId);

        return toDto(saved);
    }

    // ============================ VALIDÁCIÓ ============================

    /**
     * FR-1 append-only szabályok BATCH-elve (D8): mindkét szabálysértés EGY
     * ValidationException üzenetbe kerül, nem az elsőnél megállva.
     */
    private void validateEffectiveFrom(LocalDate effectiveFrom, LocalDate maxExisting) {
        List<String> problems = new ArrayList<>();
        if (!effectiveFrom.isAfter(LocalDate.now())) {
            problems.add("A hatálybalépés dátuma csak jövőbeli lehet.");
        }
        if (maxExisting != null && !effectiveFrom.isAfter(maxExisting)) {
            problems.add("A hatálybalépés dátuma nem lehet korábbi vagy azonos "
                    + "a legutolsó rögzített sorénál: " + maxExisting);
        }
        if (!problems.isEmpty()) {
            throw new ValidationException(String.join(" ", problems));
        }
    }

    // ============================ MAPPING ============================

    private static TransactionLevyRateDto toDto(TransactionLevyRateHistory row) {
        LevyRate levyRate = new LevyRate(
                row.getEffectiveFrom(),
                row.getBaseRatePercent(),
                row.getBaseRateCapHuf(),
                row.getSupplementRatePercent(),
                row.getSupplementRateCapHuf(),
                row.isConversionSingleSideFlag());
        return TransactionLevyRateDto.builder()
                .id(row.getId())
                .effectiveFrom(row.getEffectiveFrom())
                .baseRatePercent(row.getBaseRatePercent())
                .baseRateCapHuf(row.getBaseRateCapHuf())
                .supplementRatePercent(row.getSupplementRatePercent())
                .supplementRateCapHuf(row.getSupplementRateCapHuf())
                .conversionSingleSideFlag(row.isConversionSingleSideFlag())
                .createdBy(row.getCreatedBy())
                .createdAt(row.getCreatedAt())
                .thresholdHuf(TransactionLevyCalculator.thresholdHuf(levyRate))
                .build();
    }

    // ============================ RBAC ============================

    /**
     * FR-18: explicit kód-szintű RBAC, hogy a megtagadás ACCESS_DENIED audit-sort
     * kapjon (HandlingFeeDailySummaryService minta). Fail-closed.
     */
    private void assertAuthorized(Set<String> allowedRoles) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        boolean allowed = authentication != null && authentication.getAuthorities().stream()
                .map(GrantedAuthority::getAuthority)
                .anyMatch(allowedRoles::contains);
        if (allowed) {
            return;
        }

        auditLogService.logInNewTransaction(
                ACTION_ACCESS_DENIED,
                AUDIT_ENTITY_TYPE,
                null,
                workerIdOrNull(),
                null,
                null,
                null,
                String.format(
                        "{\"KAT\":\"AUTH\",\"error_code\":\"%s\",\"endpoint\":\"/transaction-levy-rates\"}",
                        ERR_RATE_ROLE));
        log.warn("FK-099 illeték-ráta hozzáférés megtagadva");
        throw new AccessDeniedException(
                ERR_RATE_ROLE + ": nincs jogosultsága az illeték-ráta művelethez.");
    }

    private String workerIdOrNull() {
        try {
            return SecurityUtils.getCurrentWorkerId().toString();
        } catch (ValidationException e) {
            log.debug("FK-099 hozzáférés-megtagadás audit worker-azonosító nélkül: {}", e.getMessage());
            return null;
        }
    }
}
