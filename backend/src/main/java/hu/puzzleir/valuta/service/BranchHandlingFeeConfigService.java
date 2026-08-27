package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.handlingfee.BracketSetDto;
import hu.puzzleir.valuta.dto.handlingfee.BranchFeeConfigDraftRequest;
import hu.puzzleir.valuta.dto.handlingfee.BranchFeeConfigDto;
import hu.puzzleir.valuta.dto.handlingfee.BranchFeeConfigListDto;
import hu.puzzleir.valuta.dto.handlingfee.BranchFeeConfigLiveDto;
import hu.puzzleir.valuta.dto.handlingfee.BranchFeeConfigRowDto;
import hu.puzzleir.valuta.dto.handlingfee.BranchFeeSummaryDto;
import hu.puzzleir.valuta.dto.handlingfee.HandlingFeeBracketDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.BranchHandlingFeeConfig;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.FeeConfigStatus;
import hu.puzzleir.valuta.entity.HandlingFeeBracket;
import hu.puzzleir.valuta.entity.HandlingFeeType;
import hu.puzzleir.valuta.entity.SystemParameter;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchHandlingFeeConfigRepository;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.repository.HandlingFeeBracketRepository;
import hu.puzzleir.valuta.repository.SystemParameterRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.util.HungarianRounding;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.orm.ObjectOptimisticLockingFailureException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

/**
 * FK-096 — iroda-szintű kezelési díj konfiguráció alkalmazási réteg
 * (use case-ek + tranzakciós határ + audit).
 *
 * <p>Szabályok:</p>
 * <ul>
 *   <li>FR-8: a DRAFT mentés SOHA nem érinti a LIVE sort.</li>
 *   <li>FR-9/NFR-5: a publish atomi csere a D17 sorrendben (inaktiválás → flush →
 *       előléptetés → flush → audit), egyetlen KAT:RATE audit-bejegyzéssel (D9).</li>
 *   <li>FR-13: minden írás a {@code branchRepository.findByIdAndCompanyId} tenant-guardon
 *       megy át — idegen iroda → 404, soha nem 403.</li>
 *   <li>D8/B2: {@code expectedVersion = 0} LEGITIM első publikálás (V383 seed version=0);
 *       csak a null → 400 (N9), az elavult nem-null → 409.</li>
 *   <li>D5: az írási út (draft-save) a per_mille_cap-et 5 Ft-ra kerekíti; a seed VERBATIM.</li>
 *   <li>D18/W4: {@link #seedDefaultLive} az új irodáknak a V383-mal azonos (D6 precedencia,
 *       D5 verbatim cap) szabályokkal seed-el — ugyanazon a tranzakción belül.</li>
 *   <li>FR-11: a közös sáv-készlet publikálása SOROS írási út (PESSIMISTIC_WRITE zár).</li>
 * </ul>
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
@Slf4j
public class BranchHandlingFeeConfigService {

    private final BranchHandlingFeeConfigRepository configRepository;
    private final BranchRepository branchRepository;
    private final HandlingFeeBracketRepository bracketRepository;
    private final SystemParameterRepository systemParameterRepository;
    private final CompanyRepository companyRepository;
    private final AuditLogService auditLogService;

    private static final String ACTION_PUBLISHED = "BRANCH_FEE_CONFIG_PUBLISHED";
    private static final String ACTION_BRACKET_PUBLISHED = "HANDLING_FEE_BRACKET_PUBLISHED";
    /** ITEM 2 (round 2): RBAC/cross-tenant megtagadás forenzikus auditja (FR-12/FR-13). */
    public static final String ACTION_ACCESS_DENIED = "BRANCH_FEE_CONFIG_ACCESS_DENIED";
    private static final String ERR_ACCESS_DENIED = "VV-AUTH-001";
    private static final String ENTITY_TYPE = "BranchHandlingFeeConfig";

    // =====================================================================
    // Admin lista (D7: counterparty-irodák nélkül)
    // =====================================================================

    public BranchFeeConfigListDto listForCompany() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();

        List<Branch> branches = branchRepository.findByCompanyIdAndIsActiveTrueExcludingCounterparties(companyId);
        Map<UUID, BranchHandlingFeeConfig> liveByBranch = new HashMap<>();
        Map<UUID, BranchHandlingFeeConfig> draftByBranch = new HashMap<>();
        for (BranchHandlingFeeConfig config : configRepository.findByCompanyIdAndActiveTrue(companyId)) {
            if (config.getStatus() == FeeConfigStatus.LIVE) {
                liveByBranch.put(config.getBranchId(), config);
            } else if (config.getStatus() == FeeConfigStatus.DRAFT) {
                draftByBranch.put(config.getBranchId(), config);
            }
        }

        long configured = 0;
        long bracketCount = 0;
        long perMilleCount = 0;
        List<BranchFeeConfigRowDto> rows = new java.util.ArrayList<>();
        for (Branch branch : branches) {
            BranchHandlingFeeConfig live = liveByBranch.get(branch.getId());
            BranchHandlingFeeConfig draft = draftByBranch.get(branch.getId());

            if (live != null) {
                configured++;
                if (live.getFeeMode() == HandlingFeeType.BRACKET) {
                    bracketCount++;
                } else if (live.getFeeMode() == HandlingFeeType.PER_MILLE) {
                    perMilleCount++;
                }
            }

            rows.add(BranchFeeConfigRowDto.builder()
                    .branchId(branch.getId())
                    .branchCode(branch.getCode())
                    .branchName(branch.getName())
                    .region(branch.getRegionCode())
                    .liveFeeMode(live != null ? live.getFeeMode().name() : null)
                    .livePerMilleRate(live != null ? live.getPerMilleRate() : null)
                    .livePerMilleCap(live != null ? live.getPerMilleCap() : null)
                    .hasDraft(draft != null)
                    .draftFeeMode(draft != null ? draft.getFeeMode().name() : null)
                    .draftPerMilleRate(draft != null ? draft.getPerMilleRate() : null)
                    .draftPerMilleCap(draft != null ? draft.getPerMilleCap() : null)
                    .version(draft != null ? draft.getVersion()
                            : (live != null ? live.getVersion() : null))
                    .build());
        }

        BranchFeeSummaryDto summary = BranchFeeSummaryDto.builder()
                .totalBranches(rows.size())
                .configuredBranches(configured)
                .bracketBranches(bracketCount)
                .perMilleBranches(perMilleCount)
                .build();
        return BranchFeeConfigListDto.builder().summary(summary).rows(rows).build();
    }

    // =====================================================================
    // DRAFT mentés (FR-8: a LIVE sorhoz nem nyúl)
    // =====================================================================

    @Transactional(rollbackFor = Exception.class)
    public BranchFeeConfigDto saveDraft(UUID branchId, BranchFeeConfigDraftRequest request) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        String workerCode = SecurityUtils.getCurrentWorkerCode();
        Branch branch = findBranchInCompany(branchId, companyId);

        BranchHandlingFeeConfig draft = configRepository
                .findByCompanyIdAndBranchIdAndStatusAndActiveTrue(companyId, branchId, FeeConfigStatus.DRAFT)
                .orElseGet(() -> BranchHandlingFeeConfig.builder()
                        .companyId(companyId)
                        .branchId(branchId)
                        .status(FeeConfigStatus.DRAFT)
                        .active(true)
                        .createdBy(workerCode)
                        .createdAt(LocalDateTime.now())
                        .build());

        draft.setFeeMode(HandlingFeeType.valueOf(request.getFeeMode()));
        draft.setPerMilleRate(request.getPerMilleRate());
        // D5/NFR-2: az írási út 5 Ft-ra kerekíti a sapkát (a seed verbatim, a feloldás
        // a 0-t "nincs sapka"-ként kezeli — így minden új érték 5 többszöröse).
        draft.setPerMilleCap(request.getPerMilleCap() != null
                ? HungarianRounding.roundToFive(request.getPerMilleCap())
                : null);
        // ITEM 4 (round 2): draft-time = publish-time szabály (R2-D5) — a PER_MILLE
        // null/negatív mérték itt 400 ValidationException, így a ck_bhfc_per_mille
        // CHECK-hez vezető DataIntegrityViolationException-út elérhetetlen.
        draft.assertPublishable();
        // R2-D9: a @Version csak flush-kor áll be — saveAndFlush nélkül egy ÚJ draft
        // versionje null lenne a válaszon belül, és a modal expectedVersion: null-lal
        // publikálna → 400 az első szerkesztésnél.
        configRepository.saveAndFlush(draft);

        log.info("FK-096: kezelési díj DRAFT mentve — iroda={}, mód={}", branch.getCode(), draft.getFeeMode());
        return toDto(branchId, draft);
    }

    // =====================================================================
    // Publish (FR-9/NFR-5 atomi csere, D17 sorrend, D8/B2 verziókezelés)
    // =====================================================================

    @Transactional(rollbackFor = Exception.class)
    public BranchFeeConfigDto publish(UUID branchId, Long expectedVersion) {
        if (expectedVersion == null) {
            throw new ValidationException("Az expectedVersion kötelező (0 legitim első publikálás).");
        }
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        String workerCode = SecurityUtils.getCurrentWorkerCode();
        Branch branch = findBranchInCompany(branchId, companyId);

        BranchHandlingFeeConfig draft = configRepository
                .findByCompanyIdAndBranchIdAndStatusAndActiveTrue(companyId, branchId, FeeConfigStatus.DRAFT)
                .orElseThrow(() -> new ValidationException(
                        "Nincs publikálható piszkozat az irodához (" + branchId + ") — előbb ments egyet."));

        // D8/B2: 0 legitim (V383 seed version=0); csak az ELAVULT nem-null verzió → 409.
        if (!expectedVersion.equals(draft.getVersion())) {
            throw new ObjectOptimisticLockingFailureException(BranchHandlingFeeConfig.class, draft.getId());
        }

        draft.assertPublishable();

        // D17 — fix sorrend: 1. régi LIVE inaktiválása, 2. KÖTELEZŐ flush (a parciális
        // egyedi index csak ezután szabadul fel), 3. DRAFT előléptetése, 4. flush + audit.
        BranchHandlingFeeConfig oldLive = configRepository
                .findByCompanyIdAndBranchIdAndStatusAndActiveTrue(companyId, branchId, FeeConfigStatus.LIVE)
                .orElse(null);
        if (oldLive != null) {
            oldLive.setActive(false);
            configRepository.save(oldLive);
            configRepository.flush();
        }

        draft.setStatus(FeeConfigStatus.LIVE);
        draft.setPublishedBy(workerCode);
        draft.setPublishedAt(LocalDateTime.now());
        configRepository.save(draft);
        configRepository.flush();

        auditLogService.log(
                ACTION_PUBLISHED,
                ENTITY_TYPE,
                draft.getId().toString(),
                workerCode,
                workerCode,
                branchId.toString(),
                branch.getName(),
                buildPublishChangesJson(branchId, oldLive, draft),
                null,
                null);
        log.info("FK-096: kezelési díj konfiguráció publikálva — iroda={}, mód={}",
                branch.getCode(), draft.getFeeMode());
        return toDto(branchId, draft);
    }

    // =====================================================================
    // D18/W4 — új iroda seed (a V383-mal azonos D6/D5 szabályok)
    // =====================================================================

    @Transactional(rollbackFor = Exception.class)
    public void seedDefaultLive(UUID companyId, UUID branchId, String createdBy) {
        if (configRepository.findByCompanyIdAndBranchIdAndStatusAndActiveTrue(
                companyId, branchId, FeeConfigStatus.LIVE).isPresent()) {
            return; // idempotens
        }

        HandlingFeeType feeMode = canonicalFeeMode(effectiveValue("HANDLING_FEE_TYPE", companyId));
        BigDecimal perMilleRate = null;
        BigDecimal perMilleCap = null;
        if (feeMode == HandlingFeeType.PER_MILLE) {
            perMilleRate = parseDecimalOrDefault(effectiveValue("HANDLING_FEE_PER_MILLE", companyId), BigDecimal.ZERO);
            // D5: VERBATIM cap — nincs 5 Ft kerekítés; 0 / hiányzó → null ("nincs sapka").
            BigDecimal parsedCap = parseDecimalOrDefault(
                    effectiveValue("HANDLING_FEE_PER_MILLE_MAX", companyId), null);
            perMilleCap = (parsedCap != null && parsedCap.compareTo(BigDecimal.ZERO) > 0) ? parsedCap : null;
        }

        configRepository.save(BranchHandlingFeeConfig.builder()
                .companyId(companyId)
                .branchId(branchId)
                .feeMode(feeMode)
                .perMilleRate(perMilleRate)
                .perMilleCap(perMilleCap)
                .status(FeeConfigStatus.LIVE)
                .active(true)
                .createdBy(createdBy)
                .createdAt(LocalDateTime.now())
                .publishedBy(createdBy)
                .publishedAt(LocalDateTime.now())
                .build());
        log.info("FK-096/D18: alap kezelési díj konfiguráció seed-elve — cég={}, iroda={}, mód={}",
                companyId, branchId, feeMode);
    }

    // =====================================================================
    // Olvasók — own / live (DRAFT sosem kerül ki, FR-097-8)
    // =====================================================================

    public BranchFeeConfigLiveDto getOwnLive() {
        return getLiveForBranch(SecurityUtils.getCurrentBranchId());
    }

    public BranchFeeConfigLiveDto getLiveForBranch(UUID branchId) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        // C3: kizárólag a SAJÁT iroda konfigurációja olvasható itt — idegen → 404.
        UUID ownBranchId = SecurityUtils.getCurrentBranchId();
        if (ownBranchId == null || !ownBranchId.equals(branchId)) {
            // ITEM 2 (round 2): a megtagadás forenzikus auditja REQUIRES_NEW tranzakcióban —
            // túléli a 404-et kísérő rollbacket. A HTTP-válasz továbbra is 404 (FR-13:
            // a tenant-guard sem árulja el az iroda létezését, a 403 tenant-enumerációs
            // orákulum lenne).
            auditAccessDenied(branchId, companyId, "FOREIGN_BRANCH_LIVE_READ");
            throw new ResourceNotFoundException("Ehhez az irodához nincs hozzáférése: " + branchId);
        }
        Branch branch = findBranchInCompany(branchId, companyId);

        BranchHandlingFeeConfig live = configRepository
                .findByCompanyIdAndBranchIdAndStatusAndActiveTrue(companyId, branchId, FeeConfigStatus.LIVE)
                .orElseThrow(() -> new ValidationException(
                        "Nincs élő kezelési díj konfiguráció ehhez az irodához (" + branchId + ")."
                                + " Kérj beállítást az ügyvezetőtől / főértéktárostól."));

        List<HandlingFeeBracketDto> brackets = bracketRepository
                .findByCompanyIdAndStatusAndActiveOrderByBracketOrder(companyId, FeeConfigStatus.LIVE, true)
                .stream()
                .map(this::toBracketDto)
                .toList();

        return BranchFeeConfigLiveDto.builder()
                .branchId(branchId)
                .branchCode(branch.getCode())
                .feeMode(live.getFeeMode().name())
                .perMilleRate(live.getPerMilleRate())
                .perMilleCap(live.getPerMilleCap())
                .validFrom(live.getValidFrom())
                .brackets(brackets)
                .build();
    }

    // =====================================================================
    // Közös sáv-készlet (FR-6/FR-11)
    // =====================================================================

    public BracketSetDto getBrackets() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return BracketSetDto.builder()
                .live(bracketDtos(companyId, FeeConfigStatus.LIVE))
                .draft(bracketDtos(companyId, FeeConfigStatus.DRAFT))
                .build();
    }

    @Transactional(rollbackFor = Exception.class)
    public BracketSetDto saveBracketDraft(List<HandlingFeeBracketDto> rows) {
        // ITEM 3 (round 2): batch-validáció ELŐBB, mint bármilyen archíválás/insert —
        // érvénytelen payload nem törölheti a meglévő piszkozat-készletet (fail-closed).
        validateBracketRows(rows);
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        Company company = companyRepository.findById(companyId)
                .orElseThrow(() -> new ResourceNotFoundException("Cég nem található: " + companyId));

        // A korábbi piszkozat-készlet archiválódik (active=false), nem törlődik.
        List<HandlingFeeBracket> existingDrafts = bracketRepository
                .findByCompanyIdAndStatusAndActiveOrderByBracketOrder(companyId, FeeConfigStatus.DRAFT, true);
        for (HandlingFeeBracket bracket : existingDrafts) {
            bracket.setActive(false);
        }
        bracketRepository.saveAll(existingDrafts);

        int order = 1;
        for (HandlingFeeBracketDto row : rows) {
            bracketRepository.save(HandlingFeeBracket.builder()
                    .company(company)
                    .bracketOrder(order++)
                    .upperLimit(row.getUpperLimit())
                    .feeAmount(row.getFeeAmount())
                    .active(true)
                    .status(FeeConfigStatus.DRAFT)
                    .build());
        }
        return getBrackets();
    }

    @Transactional(rollbackFor = Exception.class)
    public BracketSetDto publishBrackets() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        String workerCode = SecurityUtils.getCurrentWorkerCode();

        // FR-11/D8: a közös sáv-készlet SOROS írási út — előbb a cég sáv-sorainak
        // PESSIMISTIC_WRITE zárolása, írás CSAK a zár birtokában.
        List<HandlingFeeBracket> locked = bracketRepository.lockAllForCompany(companyId);

        List<HandlingFeeBracket> drafts = bracketRepository
                .findByCompanyIdAndStatusAndActiveOrderByBracketOrder(companyId, FeeConfigStatus.DRAFT, true);
        if (drafts.isEmpty()) {
            throw new ValidationException("Nincs publikálandó sáv-piszkozat.");
        }

        int liveCountBefore = 0;
        for (HandlingFeeBracket bracket : locked) {
            if (bracket.getStatus() == FeeConfigStatus.LIVE && Boolean.TRUE.equals(bracket.getActive())) {
                liveCountBefore++;
                bracket.setActive(false);
                bracketRepository.save(bracket);
            }
        }
        for (HandlingFeeBracket draft : drafts) {
            draft.setStatus(FeeConfigStatus.LIVE);
            bracketRepository.save(draft);
        }

        auditLogService.log(
                ACTION_BRACKET_PUBLISHED,
                "HandlingFeeBracket",
                companyId.toString(),
                workerCode,
                workerCode,
                null,
                null,
                String.format("{\"KAT\":\"RATE\",\"company_id\":\"%s\",\"before\":{\"live_brackets\":%d},"
                        + "\"after\":{\"live_brackets\":%d}}", companyId, liveCountBefore, drafts.size()),
                null,
                null);
        log.info("FK-096: közös kezelési díj sávok publikálva — cég={}, sávok={}", companyId, drafts.size());
        return getBrackets();
    }

    // ============================ SEGÉDMETÓDUSOK ============================

    /**
     * ITEM 3 (round 2): batch-validáció — a hívó egyszerre látja az összes hibás sort
     * (API-doktrína: a validációs hibákat kötegeljük, nem az elsőnél állunk meg).
     * A dobott entitások eldobhatóak — soha nem kerülnek save-be (R2 pitfall #2:
     * a @Builder.Default status=LIVE csapda itt nem számít, mert nincs perzisztálás).
     */
    private static void validateBracketRows(List<HandlingFeeBracketDto> rows) {
        if (rows == null) {
            throw new ValidationException("A sáv-lista kötelező.");
        }
        List<String> errors = new java.util.ArrayList<>();
        for (int i = 0; i < rows.size(); i++) {
            HandlingFeeBracketDto row = rows.get(i);
            try {
                HandlingFeeBracket.builder()
                        .upperLimit(row != null ? row.getUpperLimit() : null)
                        .feeAmount(row != null ? row.getFeeAmount() : null)
                        .build()
                        .assertValid();
            } catch (ValidationException e) {
                errors.add((i + 1) + ". sáv: " + e.getMessage());
            }
        }
        if (!errors.isEmpty()) {
            throw new ValidationException("Érvénytelen sáv-készlet — " + String.join(" ", errors));
        }
    }

    private Branch findBranchInCompany(UUID branchId, UUID companyId) {
        // FR-13: tenant-guard — másik cég irodája → 404, soha nem 403.
        // ITEM 2 (round 2): a 404 ELŐTT REQUIRES_NEW audit-sor íródik a HÍVÓ tenantjába —
        // az audit-nak túl kell élnie a rollbacket (security trail).
        return branchRepository.findByIdAndCompanyId(branchId, companyId)
                .orElseThrow(() -> {
                    auditAccessDenied(branchId, companyId, "CROSS_TENANT_BRANCH");
                    return new ResourceNotFoundException("Iroda nem található: " + branchId);
                });
    }

    /**
     * ITEM 2 (round 2): BRANCH_FEE_CONFIG_ACCESS_DENIED forenzikus sor. A payload-alak a
     * repo-konvenciót követi (ShipmentStockBookingService.assertReceiver): KAT:AUTH +
     * error_code + reason. A companyId explicit paraméter — a hívó tenantjába kerül a sor,
     * soha nem kerül újra-feloldásra a SecurityContextből (multi-tenant invariáns).
     */
    private void auditAccessDenied(UUID branchId, UUID companyId, String reason) {
        auditLogService.logInNewTransaction(
                ACTION_ACCESS_DENIED, ENTITY_TYPE,
                branchId != null ? branchId.toString() : null,
                workerCodeOrNull(), workerCodeOrNull(),
                branchId != null ? branchId.toString() : null, null,
                String.format("{\"KAT\":\"AUTH\",\"error_code\":\"%s\",\"reason\":\"%s\","
                        + "\"branch_id\":\"%s\",\"company_id\":\"%s\"}",
                        ERR_ACCESS_DENIED, reason, branchId, companyId),
                companyId);
        log.warn("FK-096: kezelési díj konfiguráció hozzáférés megtagadva — ok={}, iroda={}, cég={}",
                reason, branchId, companyId);
    }

    /** A 404-et SOHA nem cserélheti 400-ra egy hiányzó SecurityContext (audit-only olvasás). */
    private static String workerCodeOrNull() {
        try {
            return SecurityUtils.getCurrentWorkerCode();
        } catch (RuntimeException e) {
            return null;
        }
    }

    private static BranchFeeConfigDto toDto(UUID branchId, BranchHandlingFeeConfig config) {
        return BranchFeeConfigDto.builder()
                .branchId(branchId)
                .feeMode(config.getFeeMode() != null ? config.getFeeMode().name() : null)
                .perMilleRate(config.getPerMilleRate())
                .perMilleCap(config.getPerMilleCap())
                .hasDraft(config.getStatus() == FeeConfigStatus.DRAFT)
                .status(config.getStatus() != null ? config.getStatus().name() : null)
                .version(config.getVersion())
                .build();
    }

    private HandlingFeeBracketDto toBracketDto(HandlingFeeBracket bracket) {
        return HandlingFeeBracketDto.builder()
                .id(bracket.getId())
                .bracketOrder(bracket.getBracketOrder())
                .upperLimit(bracket.getUpperLimit())
                .feeAmount(bracket.getFeeAmount())
                .active(bracket.getActive())
                .build();
    }

    private List<HandlingFeeBracketDto> bracketDtos(UUID companyId, FeeConfigStatus status) {
        return bracketRepository
                .findByCompanyIdAndStatusAndActiveOrderByBracketOrder(companyId, status, true)
                .stream()
                .map(this::toBracketDto)
                .toList();
    }

    /**
     * D9/NFR-4: publish audit JSON — KAT:RATE, before/after értékekkel.
     */
    private static String buildPublishChangesJson(UUID branchId,
                                                  BranchHandlingFeeConfig before,
                                                  BranchHandlingFeeConfig after) {
        return String.format("{\"KAT\":\"RATE\",\"branch_id\":\"%s\",\"before\":%s,\"after\":%s}",
                branchId, configJson(before), configJson(after));
    }

    private static String configJson(BranchHandlingFeeConfig config) {
        if (config == null) {
            return "null";
        }
        return String.format("{\"fee_mode\":\"%s\",\"per_mille_rate\":%s,\"per_mille_cap\":%s}",
                config.getFeeMode(),
                jsonValue(config.getPerMilleRate()),
                jsonValue(config.getPerMilleCap()));
    }

    private static String jsonValue(BigDecimal value) {
        return value == null ? "null" : "\"" + value.toPlainString() + "\"";
    }

    /**
     * D6 precedencia (SystemParameterService.findEffective paritás, explicit companyId-vel):
     * cég-scope aktív sor → globális aktív sor → üres (a hívó kezeli a defaultot).
     */
    private Optional<String> effectiveValue(String key, UUID companyId) {
        Optional<SystemParameter> scoped = systemParameterRepository
                .findEffectiveByParameterKeyAndCompanyId(key, companyId);
        if (scoped.isPresent()) {
            return Optional.ofNullable(scoped.get().getParameterValue());
        }
        return systemParameterRepository.findEffectiveGlobalByParameterKey(key)
                .map(SystemParameter::getParameterValue);
    }

    /**
     * B1 whitelist-map paritás: TRIM+UPPER kanonizáció; minden nem kanonikus érték → BRACKET
     * (a mai runtime-fallback, HandlingFeeService.resolveFeeType).
     */
    private static HandlingFeeType canonicalFeeMode(Optional<String> raw) {
        if (raw.isEmpty()) {
            return HandlingFeeType.BRACKET;
        }
        String normalized = raw.get().trim().toUpperCase(Locale.ROOT);
        return switch (normalized) {
            case "NONE" -> HandlingFeeType.NONE;
            case "PER_MILLE" -> HandlingFeeType.PER_MILLE;
            default -> HandlingFeeType.BRACKET;
        };
    }

    /**
     * Nem numerikus parameter-érték nem ronthatja el a seed-et — regex-guardolt parse
     * (V383 paritás); hiba/hiány esetén a megadott default.
     */
    private static BigDecimal parseDecimalOrDefault(Optional<String> raw, BigDecimal defaultValue) {
        if (raw.isEmpty()) {
            return defaultValue;
        }
        String value = raw.get().trim();
        if (!value.matches("^[0-9]+(\\.[0-9]+)?$")) {
            return defaultValue;
        }
        return new BigDecimal(value);
    }
}
