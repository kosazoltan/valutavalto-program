package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.BranchDto;
import hu.puzzleir.valuta.dto.CreateBranchDto;
import hu.puzzleir.valuta.dto.UpdateBranchDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Dictionary;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.mapper.BranchMapper;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.repository.DictionaryRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import tools.jackson.core.JacksonException;
import tools.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

import java.time.LocalDate;
import java.util.ArrayList;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Lazy;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@Slf4j
@Transactional(rollbackFor = Exception.class)
public class BranchService {

    private final BranchRepository branchRepository;
    private final CompanyRepository companyRepository;
    private final DictionaryRepository dictionaryRepository;
    private final BranchMapper branchMapper;
    // Issue #110: kassza egyenleg auto-init új branch-nél. @Lazy a potenciális circular
    // dependency elkerülésére (CashBalanceService branchRepository-t is használ).
    private final CashBalanceService cashBalanceService;
    // 2026-04-29 v2.3.27 (B3 P0 fix): denomination auto-init új branch-nél.
    // FK-080 (FR-2, 2026-08-11): az új fiók címletsorai — a HUF is — a
    // `denomination_allowed` katalógusból jönnek (V376 deviza-seed + V379 HUF-seed).
    // A korábban itt hivatkozott `DenominationService.HUF_DENOMINATIONS` 14 elemű
    // konstans megszűnt: érme kizárólag HUF 200/100/50/20/10/5 és EUR 2/1 lehet,
    // az 1 és 2 forintos érme-sor nem jön létre többé (2008-ban bevonták).
    // A `create()` változatlanul hívja az `initializeBranchDenominations(branchId)`-t.
    private final DenominationService denominationService;
    // #891 self-review P0-1: ERTEKTAR-szintű territorialis ellenőrzéshez a saját region_code lookup.
    private final AccessScopeService accessScopeService;
    // FK-022 FR-7: iroda-módosítás audit logja before/after értékkel (hash-láncolt audit_log).
    private final AuditLogService auditLogService;
    private final ObjectMapper objectMapper;
    // FK-096/D18/W4: új irodának automatikus LIVE kezelési díj konfiguráció — a fail-closed
    // (FR-5) védelme a HIBÁS beállítás ellen szól, nem a helyes iroda-provisioning büntetése.
    // Egyetlen közös seedDefaultLive implementáció, hogy a két kódot ne tudjon széttartani.
    private final BranchHandlingFeeConfigService branchHandlingFeeConfigService;

    @Autowired
    public BranchService(BranchRepository branchRepository,
                         CompanyRepository companyRepository,
                         DictionaryRepository dictionaryRepository,
                         BranchMapper branchMapper,
                         @Lazy CashBalanceService cashBalanceService,
                         @Lazy DenominationService denominationService,
                         AccessScopeService accessScopeService,
                         AuditLogService auditLogService,
                         ObjectMapper objectMapper,
                         BranchHandlingFeeConfigService branchHandlingFeeConfigService) {
        this.branchRepository = branchRepository;
        this.companyRepository = companyRepository;
        this.dictionaryRepository = dictionaryRepository;
        this.branchMapper = branchMapper;
        this.cashBalanceService = cashBalanceService;
        this.denominationService = denominationService;
        this.accessScopeService = accessScopeService;
        this.auditLogService = auditLogService;
        this.objectMapper = objectMapper;
        this.branchHandlingFeeConfigService = branchHandlingFeeConfigService;
    }

    /**
     * Összes fiók lekérése
     */
    @Transactional(readOnly = true)
    public List<BranchDto> findAll() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        log.debug("Finding all branches for company: {}", companyId);
        List<Branch> branches = branchRepository.findByCompanyId(companyId);
        return branchMapper.toDtoList(branches);
    }

    /**
     * Aktív fiókok lekérése
     */
    @Transactional(readOnly = true)
    public List<BranchDto> findAllActive() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        log.debug("Finding all active branches for company: {}", companyId);
        // Multi-tenant-safe: company-scoped query + no post-filter stream
        List<Branch> branches = branchRepository.findByCompanyIdAndIsActiveTrue(companyId);
        return branchMapper.toDtoList(branches);
    }

    /**
     * Bali Henriett FK-013 (2026-05-28): az egységes értéktári átadás-átvétel menüpont
     * "Cél iroda" dropdown 3-csoportos listája.
     *
     * <ul>
     *   <li><b>territorialCashiers</b>: a saját régió aktív lakossági pénztárai
     *       (a vault-scope ∩ branch_type='PENZTAR' ∩ is_active=true).</li>
     *   <li><b>peerVaults</b>: a cég többi értéktára (saját értéktár-branch kihagyva).</li>
     *   <li><b>fixedCounterparties</b>: 10 fix VAULT_COUNTERPARTY (V277 seed).</li>
     * </ul>
     *
     * <p>A meghívó user értéktáros / főértéktáros — a controller @PreAuthorize garantálja.
     * Pénztáros (CASHIER/PENZTAR) user-ek a meglévő {@link #findAllActive()} vagy
     * {@code listMyTerritory} endpointokat használják.</p>
     */
    @Transactional(readOnly = true)
    public hu.puzzleir.valuta.dto.VaultCounterpartiesDto findVaultCounterparties() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        UUID ownBranchId = SecurityUtils.getCurrentBranchIdOrNull();

        // FK-013 follow-up #1 (Kasza Helga 2026-05-28 visszajelzés): a "saját régió"
        // azonosításához a worker branch regionCode-ját olvassuk ki (KESZLEX numerikus:
        // SZEGED=20, KECSKEMET=40, DEBRECEN=50, NYIREGYHAZA=63, BEKESCSABA=75, PECS=120,
        // KAPOSVAR=145, SZEKSZARD=10). Helga (Főértéktáros) branchId=Tisza Sarok (BR035),
        // regionCode="20" → saját régió=SZEGED → a Szeged Ertektar (BR020) és Szeged-területi
        // pénztárak alkotják a saját területet.
        // FK (2026-06-01): a régiót a `region` oszlopból (V145/V254, pl. 'SZEGED'), NEM a
        // `region_code`-ból (KESZLEX, pénztáraknál NULL) olvassuk — a régi region_code üres
        // territorialCashiers-t adott.
        final String ownRegion = (ownBranchId != null)
                ? branchRepository.findById(ownBranchId).map(Branch::getRegion).orElse(null)
                : null;
        log.info("FK-013 findVaultCounterparties: companyId={}, ownBranchId={}, ownRegion={}",
                companyId, ownBranchId, ownRegion);

        // 1. territorialCashiers — saját régió aktív PÉNZTÁRAI (NEM értéktárai).
        // A korábbi `vaultScope ∩ branch_type='PENZTAR'` szűrés a Főértéktárosnak
        // (`vaultScope=null` → minden PENZTAR országosan) NEM a docx szerinti szűkítést
        // adta. Most a regionCode-egyezés a kulcs: ugyanaz a régió, mint a user branch.
        java.util.Set<UUID> vaultScope = accessScopeService.vaultRegionBranchScopeOrNull();
        log.info("FK-013 findVaultCounterparties: vaultScope={} (null=nincs szűkítés)",
                vaultScope != null ? vaultScope.size() + " branch" : "null");

        List<Branch> allActive = branchRepository.findByCompanyIdAndIsActiveTrue(companyId);
        log.info("FK-013 findVaultCounterparties: allActive cég-szintű={}", allActive.size());

        List<BranchDto> territorialCashiers = allActive.stream()
                .filter(b -> b.getBranchType() != null && "PENZTAR".equals(b.getBranchType().getCode()))
                // NEM értéktár (Builder.Default=false, de a régi V69/V83 seedek NULL-ja is
                // pénztár-szerű kell legyen — defenzív: !TRUE.equals(...) NULL is átengedi).
                .filter(b -> !Boolean.TRUE.equals(b.getIsVault()))
                // Régió-egyezés: a saját régió pénztárai. Ha nincs ownRegionCode (pl. központi
                // user branchId nélkül), VAGY a user vault-scope NEM null (értéktáros), akkor
                // a vault-scope ∩ branchId-szűrés az eredeti viselkedés szerint.
                .filter(b -> {
                    if (vaultScope != null) {
                        return vaultScope.contains(b.getId());
                    }
                    if (ownRegion != null) {
                        return ownRegion.equals(b.getRegion());
                    }
                    return true;
                })
                .map(branchMapper::toDto)
                .toList();
        log.info("FK-013 findVaultCounterparties: territorialCashiers.size={}", territorialCashiers.size());

        // 2. peerVaults — a cég többi értéktára, a SAJÁT RÉGIÓ értéktárai kihagyva.
        // A korábbi `ownBranchId.equals(b.getId())` szűrés CSAK akkor működött, ha a user
        // branchId-je MAGA az értéktár-branch. Kasza Helga branch=Tisza Sarok (pénztár-típus),
        // NEM értéktár → minden 8 értéktár átment a peerVaults-ba. Most a regionCode-egyezés
        // a kulcs: a saját régió értéktárai (általában 1 — pl. Szeged) kihagyandók.
        List<BranchDto> peerVaults = branchRepository
                .findByCompanyIdAndIsVaultTrueAndIsActiveTrue(companyId).stream()
                .filter(b -> {
                    // A saját értéktár-branchet közvetlen ID-egyezés szerint is kihagyni (defenzív).
                    if (ownBranchId != null && ownBranchId.equals(b.getId())) return false;
                    // A saját régió értéktárait region-egyezés szerint kihagyni.
                    if (ownRegion != null && ownRegion.equals(b.getRegion())) return false;
                    return true;
                })
                .map(branchMapper::toDto)
                .toList();
        log.info("FK-013 findVaultCounterparties: peerVaults.size={} (ownRegion kihagyva)", peerVaults.size());

        // 3. fixedCounterparties — 10 fix banki/speciális partner (V277 seed-je)
        List<BranchDto> fixedCounterparties = branchRepository
                .findByCompanyIdAndBranchTypeCode(companyId, "VAULT_COUNTERPARTY").stream()
                .filter(b -> Boolean.TRUE.equals(b.getIsActive()))
                .map(branchMapper::toDto)
                .toList();
        log.info("FK-013 findVaultCounterparties: fixedCounterparties.size={}", fixedCounterparties.size());

        return hu.puzzleir.valuta.dto.VaultCounterpartiesDto.builder()
                .territorialCashiers(territorialCashiers)
                .peerVaults(peerVaults)
                .fixedCounterparties(fixedCounterparties)
                .build();
    }

    /**
     * Bali Henriett / Kasza Helga FK-013 (2026-05-28) PÉNZTÁRI OLDAL: a pénztári F4
     * "Átadás-átvétel" menü "Cél iroda" legördülő tartalma — csak 3 elem szerepelhet:
     * <ol>
     *   <li>A pénztárhoz tartozó értéktár (regionCode-egyezéssel, is_vault=true)</li>
     *   <li>TH pénztár (a 10 VAULT_COUNTERPARTY közül a 'TH' kóddal)</li>
     *   <li>1-es főpénztár (a 10 VAULT_COUNTERPARTY közül a 'FOP1' kóddal)</li>
     * </ol>
     *
     * <p>A docx: "A pénztári programban az átadás-átvétel menü (F4) marad a jelenlegi
     * működés szerint – ott csak az alábbiak szerepelnek: A pénztárhoz tartozó értéktár,
     * TH pénztár, 1-es főpénztár".</p>
     *
     * <p>A meghívó user pénztáros (CASHIER/PENZTAR) — a controller @PreAuthorize garantálja.
     * Értéktáros user a {@link #findVaultCounterparties()}-t használja a 3-csoportos dropdown-hoz.</p>
     */
    @Transactional(readOnly = true)
    public List<BranchDto> findCashierShipmentTargets() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        UUID ownBranchId = SecurityUtils.getCurrentBranchIdOrNull();

        // FK (2026-06-01): a `region` oszlop (V145/V254, pl. 'SZEGED') a feltöltött, NEM a
        // region_code (KESZLEX, pénztáraknál NULL) — különben a pénztáros nem találja a saját értéktárát.
        final String ownRegion = (ownBranchId != null)
                ? branchRepository.findById(ownBranchId).map(Branch::getRegion).orElse(null)
                : null;
        log.info("FK-013 cashier-shipment-targets: companyId={}, ownBranchId={}, ownRegion={}",
                companyId, ownBranchId, ownRegion);

        List<BranchDto> result = new ArrayList<>();

        // 1. A pénztárhoz tartozó értéktár (region-egyezés, is_vault=true)
        if (ownRegion != null) {
            List<Branch> regionVaults = branchRepository
                    .findByCompanyIdAndIsVaultTrueAndIsActiveTrue(companyId).stream()
                    .filter(b -> ownRegion.equals(b.getRegion()))
                    .toList();
            for (Branch v : regionVaults) {
                result.add(branchMapper.toDto(v));
            }
            log.info("FK-013 cashier-shipment-targets: ownVault count={} (region={})",
                    regionVaults.size(), ownRegion);
        } else {
            log.warn("FK-013 cashier-shipment-targets: ownRegion=null → saját értéktár nem található");
        }

        // 2-3. TH pénztár + 1-es főpénztár (VAULT_COUNTERPARTY 'TH' és 'FOP1')
        List<Branch> fixed = branchRepository
                .findByCompanyIdAndBranchTypeCode(companyId, "VAULT_COUNTERPARTY").stream()
                .filter(b -> Boolean.TRUE.equals(b.getIsActive()))
                .filter(b -> "TH".equals(b.getCode()) || "FOP1".equals(b.getCode()))
                .toList();
        for (Branch f : fixed) {
            result.add(branchMapper.toDto(f));
        }
        log.info("FK-013 cashier-shipment-targets: fixed (TH+FOP1) count={}", fixed.size());

        log.info("FK-013 cashier-shipment-targets: total={}", result.size());
        return result;
    }

    /**
     * v2.5.1-C B6: Csak ÉRTÉKTÁRI (is_vault=TRUE) fiókok — a SetupWizard értéktár
     * módú telepítéskor használja. Multi-tenant-safe.
     */
    @Transactional(readOnly = true)
    public List<BranchDto> findVaultBranches(boolean activeOnly) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        log.debug("Finding vault branches (activeOnly={}) for company: {}", activeOnly, companyId);
        List<Branch> branches = activeOnly
                ? branchRepository.findByCompanyIdAndIsVaultTrueAndIsActiveTrue(companyId)
                : branchRepository.findByCompanyIdAndIsVaultTrue(companyId);
        return branchMapper.toDtoList(branches);
    }

    /**
     * v2.5.1-C B6: is_vault flag módosítása — admin/foertektar/ugyvezeto használja.
     * Multi-tenant-safe (cross-tenant access denied).
     */
    @Transactional
    public BranchDto updateIsVault(UUID branchId, boolean isVault) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        Branch branch = branchRepository.findById(branchId)
                .orElseThrow(() -> new hu.puzzleir.valuta.exception.ResourceNotFoundException(
                        "Branch nem található: " + branchId));
        if (branch.getCompany() == null || !companyId.equals(branch.getCompany().getId())) {
            throw new hu.puzzleir.valuta.exception.ValidationException(
                    "Branch más céghez tartozik (cross-tenant access denied).");
        }
        branch.setIsVault(isVault);
        Branch saved = branchRepository.save(branch);
        log.info("Branch is_vault updated: branchId={} code={} isVault={}", branchId, saved.getCode(), isVault);
        return branchMapper.toDto(saved);
    }

    /**
     * Fiók keresése ID alapján
     */
    @Transactional(readOnly = true)
    public BranchDto findById(UUID id) {
        log.debug("Finding branch by id: {}", id);
        Branch branch = branchRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Fiók nem található: " + id));

        // IDOR védelem: csak saját cég fiókai érhetők el
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        if (branch.getCompany() != null && !branch.getCompany().getId().equals(companyId)) {
            throw new ResourceNotFoundException("Fiók nem található: " + id);
        }

        BranchDto dto = branchMapper.toDto(branch);
        
        // Load children IDs
        List<Branch> children = branchRepository.findByParentBranchId(id);
        dto.setChildBranchIds(children.stream()
                .map(Branch::getId)
                .collect(Collectors.toList()));
        
        return dto;
    }

    /**
     * Fiók keresése kód alapján
     */
    @Transactional(readOnly = true)
    public BranchDto findByCode(String code) {
        log.debug("Finding branch by code: {}", code);
        // Multi-tenant-safe: ceg-scoped lookup (cross-tenant leak elkerulese)
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        Branch branch = branchRepository.findByCompanyIdAndCode(companyId, code)
                .orElseThrow(() -> new ResourceNotFoundException("Fiók nem található kóddal: " + code));
        // (korabbi IDOR redundans ellenorzes megszunt, mert a query eleve szur)

        return branchMapper.toDto(branch);
    }

    /**
     * Keresés név vagy kód szerint
     */
    @Transactional(readOnly = true)
    public List<BranchDto> search(String searchTerm) {
        log.debug("Searching branches with term: {}", searchTerm);
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        List<Branch> branches = branchRepository.searchByCompanyIdAndNameOrCode(companyId, searchTerm);
        return branchMapper.toDtoList(branches);
    }

    /**
     * Fiókok típus szerint
     */
    @Transactional(readOnly = true)
    public List<BranchDto> findByType(String branchTypeCode) {
        log.debug("Finding branches by type: {}", branchTypeCode);
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        List<Branch> branches = branchRepository.findByCompanyIdAndBranchTypeCode(companyId, branchTypeCode);
        return branchMapper.toDtoList(branches);
    }

    /**
     * Fiókok státusz szerint
     */
    @Transactional(readOnly = true)
    public List<BranchDto> findByStatus(String statusCode) {
        log.debug("Finding branches by status: {}", statusCode);
        // PP-05: SQL-szintű cég-szűrés (a korábbi memóriabeli post-filter helyett)
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        List<Branch> branches = branchRepository.findByCompanyIdAndBranchStatusCode(companyId, statusCode);
        return branchMapper.toDtoList(branches);
    }

    /**
     * Gyökér fiókok (nincs szülő)
     */
    @Transactional(readOnly = true)
    public List<BranchDto> findRootBranches() {
        log.debug("Finding root branches");
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        List<Branch> branches = branchRepository.findRootBranchesByCompanyId(companyId);
        return branchMapper.toDtoList(branches);
    }

    /**
     * Szülő alatti közvetlen gyermekek
     */
    @Transactional(readOnly = true)
    public List<BranchDto> findChildren(UUID parentId) {
        log.debug("Finding children of branch: {}", parentId);
        // FINDING #4 IDOR fix: a kiinduló branch-et a scope-olt findById-vel töltjük be
        // (cross-tenant esetén dob), majd a gyermekek company-ját is a hívóéhoz kötjük.
        // A findByParentBranchId nem company-szűrt → defenzív utószűrés a hívó cégére.
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        assertBranchInCompany(parentId, companyId);
        List<Branch> branches = branchRepository.findByParentBranchId(parentId).stream()
                .filter(b -> isInCompany(b, companyId))
                .toList();
        return branchMapper.toDtoList(branches);
    }

    /**
     * Útvonal a gyökérig (breadcrumb)
     */
    @Transactional(readOnly = true)
    public List<BranchDto> findPathToRoot(UUID branchId) {
        log.debug("Finding path to root for branch: {}", branchId);
        // FINDING #4 IDOR fix: a kiinduló branch ownership-ellenőrzése (scope-olt findById
        // mintára) cross-tenant branchId-re dob. A rekurzív CTE path-elemei is csak a hívó
        // cégéhez tartozhatnak — defenzív utószűrés (a hierarchia cégen belül zárt, de a
        // path elemeit explicit a hívó cégére korlátozzuk).
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        assertBranchInCompany(branchId, companyId);
        List<Branch> path = branchRepository.findPathToRoot(branchId).stream()
                .filter(b -> isInCompany(b, companyId))
                .toList();
        return branchMapper.toDtoList(path);
    }

    /**
     * FINDING #4 (multi-tenant IDOR): a megadott branch a hívó cégéhez tartozik-e.
     * A {@link #findById(UUID)} scope-olt mintáját követi: cross-tenant vagy nem létező
     * branch → ResourceNotFoundException (nem leak-elő üzenet).
     */
    private void assertBranchInCompany(UUID branchId, UUID companyId) {
        Branch branch = branchRepository.findById(branchId)
                .orElseThrow(() -> new ResourceNotFoundException("Fiók nem található: " + branchId));
        if (!isInCompany(branch, companyId)) {
            throw new ResourceNotFoundException("Fiók nem található: " + branchId);
        }
    }

    /** FINDING #4: branch a megadott céghez tartozik-e (null-company → nem). */
    private boolean isInCompany(Branch branch, UUID companyId) {
        return branch.getCompany() != null && companyId.equals(branch.getCompany().getId());
    }

    /**
     * Új fiók létrehozása
     */
    public BranchDto create(CreateBranchDto dto) {
        log.info("Creating new branch with code: {}", dto.getCode());

        // Validációk
        validateBranchCode(dto.getCode());
        validateBranchHierarchy(dto.getBranchTypeId(), dto.getParentBranchId());

        // Multi-tenant izoláció (CLAUDE.md B.3 / audit 2026-05-31, P1 IDOR): a fiók KÖTELEZŐEN a
        // hívó cégéhez jön létre. Korábban a kliens dto.getCompanyId()-ját bíztuk meg, így egy A cég
        // jogosultja companyId=B megadásával B cég alá hozhatott létre fiókot (auto-init cash_balance
        // + denomination is B alá futott). A céget a SecurityContextből oldjuk fel; ha a kliens eltérő
        // companyId-t küld, elutasítjuk (a createSimpleCashier mintája).
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        if (dto.getCompanyId() != null && !companyId.equals(dto.getCompanyId())) {
            throw new ValidationException("A fiók nem hozható létre másik céghez.");
        }
        Company company = companyRepository.findById(companyId)
                .orElseThrow(() -> new ResourceNotFoundException("Cég nem található: " + companyId));

        Dictionary branchType = dictionaryRepository.findById(dto.getBranchTypeId())
                .orElseThrow(() -> new ResourceNotFoundException("Fiók típus nem található: " + dto.getBranchTypeId()));

        Dictionary country = dictionaryRepository.findById(dto.getCountryId())
                .orElseThrow(() -> new ResourceNotFoundException("Ország nem található: " + dto.getCountryId()));

        Dictionary branchStatus = dictionaryRepository.findById(dto.getBranchStatusId())
                .orElseThrow(() -> new ResourceNotFoundException("Státusz nem található: " + dto.getBranchStatusId()));

        Branch parentBranch = null;
        if (dto.getParentBranchId() != null) {
            parentBranch = branchRepository.findById(dto.getParentBranchId())
                    .orElseThrow(() -> new ResourceNotFoundException("Szülő fiók nem található: " + dto.getParentBranchId()));
        }

        // Entity létrehozása
        Branch branch = Branch.builder()
                .code(dto.getCode())
                .company(company)
                .bankCode(dto.getBankCode())
                .branchType(branchType)
                .parentBranch(parentBranch)
                .name(dto.getName())
                .address(dto.getAddress())
                .city(dto.getCity())
                .zipCode(dto.getZipCode())
                .country(country)
                .phone(dto.getPhone())
                .email(dto.getEmail())
                .branchStatus(branchStatus)
                .openingDate(dto.getOpeningDate())
                .denominationRuleId(dto.getDenominationRuleId())
                .isActive(true)
                // Pénztár Törzs alapmodul (V293): opcionális mezők; a flagek null → FALSE default.
                .shortName(dto.getShortName())
                .hasAfa(Boolean.TRUE.equals(dto.getHasAfa()))
                .hasWu(Boolean.TRUE.equals(dto.getHasWu()))
                .hasMg(Boolean.TRUE.equals(dto.getHasMg()))
                .hasPos(Boolean.TRUE.equals(dto.getHasPos()))
                .closedSaturday(Boolean.TRUE.equals(dto.getClosedSaturday()))
                .closedSunday(Boolean.TRUE.equals(dto.getClosedSunday()))
                .build();

        Branch saved = branchRepository.save(branch);
        log.info("Branch created successfully: {}", saved.getId());

        // Issue #110: automatikus kassza egyenleg inicializálás.
        // Idempotens — ha bármi okból már létezne, skip. Nem dob hibát.
        // Sourcery PR #112: narrow catch + full stack trace.
        // 2026-04-29 v2.3.29 (Sourcery P2 #292 follow-up):
        // A catch továbbra is RuntimeException-t fog (Spring DataAccessException +
        // egyéb tx-runtime-bug-okat is el akarjuk fogni), DE a log message
        // EXPLICIT TARTALMAZZA a root-cause exception-osztályt (`e.getClass()`),
        // hogy az unexpected programming error-ok detektálhatók legyenek a log-ban.
        // A Codex P1 #292 fix: a `cashBalanceService.initializeBranchBalances` és
        // `denominationService.initializeBranchDenominations` `Propagation.REQUIRES_NEW`-t
        // használ — független tx, NEM rolls back parent.
        try {
            int created = cashBalanceService.initializeBranchBalances(saved.getId());
            log.info("Branch {} cash_balance auto-init: {} új rekord", saved.getId(), created);
        } catch (RuntimeException e) {
            log.error("Branch {} cash_balance auto-init FAILED [{}: {}] (admin kézi init szükséges)",
                    saved.getId(), e.getClass().getSimpleName(), e.getMessage(), e);
        }

        // 2026-04-29 v2.3.27 (B3 P0 fix): denomination auto-init új branch-nél.
        try {
            denominationService.initializeBranchDenominations(saved.getId());
            log.info("Branch {} denomination auto-init: 14 HUF + külföldi címlet beállítva",
                    saved.getId());
        } catch (RuntimeException e) {
            log.error("Branch {} denomination auto-init FAILED [{}: {}] (admin kézi init szükséges)",
                    saved.getId(), e.getClass().getSimpleName(), e.getMessage(), e);
        }

        // FK-096/D18: új iroda azonnal kereshessen — alap kezelési díj konfiguráció
        // (a V383-mal azonos D6 precedencia + D5 verbatim cap) UGYANEBBEN a tranzakcióban.
        branchHandlingFeeConfigService.seedDefaultLive(companyId, saved.getId(),
                SecurityUtils.getCurrentWorkerCode());

        return branchMapper.toDto(saved);
    }

    /**
     * Bali Henriett 2. pont (2026-05-27) — egyszerűsített lakossági pénztár-felrögzítés
     * értéktáros / főértéktáros által. Csak 3 kötelező mezőt vár (code, address, regionCode);
     * a többi mezőt (bankCode, branchType, country, branchStatus, openingDate) automatikusan
     * sensible default-okkal tölti ki (HU/PENZTAR/ACTIVE/today). A multi-tenant scope
     * KÖTELEZŐEN a jelenlegi felhasználó cége — a dto NEM tartalmaz companyId-t.
     */
    /**
     * #891 self-review/AI-review (Copilot P0): a {@code branch.region_code} oszlop a
     * legacy NUMERIKUS KESZLEX kódot tárolja (length 10), míg a {@code dictionary} REGION
     * kategória SZÖVEGES kódot ad (SZEGED, KECSKEMET, …). A {@link AccessScopeService}
     * a numerikus értékre szűr — ezért a kliens-küldött szöveges kódot szervizoldalon
     * át kell mappelni a numerikus KESZLEX-kódra, hogy az új pénztár a megfelelő ÉRTÉKTÁR
     * scope-jába kerüljön. Forrás: {@link StockSnapshotService#REGION_NAMES} (numerikus →
     * szöveges) — itt inverz használat.
     */
    private static final java.util.Map<String, String> REGION_DICT_TO_KESZLEX = java.util.Map.ofEntries(
            java.util.Map.entry("SZEKSZARD",  "10"),
            java.util.Map.entry("SZEGED",     "20"),
            java.util.Map.entry("KECSKEMET",  "40"),
            java.util.Map.entry("DEBRECEN",   "50"),
            java.util.Map.entry("NYIREGYHAZA","63"),
            java.util.Map.entry("BEKESCSABA", "75"),
            java.util.Map.entry("PECS",       "120"),
            java.util.Map.entry("KAPOSVAR",   "145")
    );

    /**
     * FK-098 FR-9: IRODA (central office) is a legal, active REGION dictionary entry
     * (V145 seed) with NO physical KESZLEX district. It maps to a null region_code instead
     * of a placeholder number, because a fake numeric code would leak into the region scope
     * filters (AccessScopeService.vaultRegionCodeOrNull, BankService region filtering) and
     * create a phantom district.
     */
    private static final String REGION_CENTRAL_OFFICE = "IRODA";

    /** Returns the numeric KESZLEX code, or null for the exempt IRODA region. */
    private static String toKeszlexRegionCode(String dictRegionCode) {
        if (REGION_CENTRAL_OFFICE.equals(dictRegionCode)) {
            return null;
        }
        String mapped = REGION_DICT_TO_KESZLEX.get(dictRegionCode);
        if (mapped == null) {
            throw new ValidationException(
                    "A(z) " + dictRegionCode + " régióhoz nincs KESZLEX-területi-kód mappelve. "
                            + "Engedélyezett régiók: " + allowedRegionCodes());
        }
        return mapped;
    }

    private static java.util.Set<String> allowedRegionCodes() {
        java.util.Set<String> codes = new java.util.TreeSet<>(REGION_DICT_TO_KESZLEX.keySet());
        codes.add(REGION_CENTRAL_OFFICE);
        return codes;
    }

    public BranchDto createSimpleCashier(hu.puzzleir.valuta.dto.CreateSimpleCashierBranchDto dto) {
        log.info("Creating simple cashier branch with code: {}", dto.getCode());

        // Sourcery P2 + Copilot: server-side code-normalize (trim + uppercase), hogy
        // ne függjön a frontend-implementációtól. A DTO Pattern már `[A-Z0-9]+` szűr.
        final String normalizedCode = dto.getCode() != null ? dto.getCode().trim().toUpperCase() : null;

        // Copilot: a `branch.code` GLOBÁLISAN UNIQUE (uk_branch_code), nem cég-scoped.
        // Egy másik cég foglalt kódjánál a `branchRepository.save` DataIntegrity-t dobna —
        // user-friendly üzenet a service-szinten.
        if (normalizedCode == null || normalizedCode.isBlank()) {
            throw new ValidationException("A pénztár-kód üres.");
        }
        if (branchRepository.existsByCode(normalizedCode)) {
            throw new ValidationException(
                    "A(z) " + normalizedCode + " pénztár-kód már foglalt a rendszerben — válasszon másikat.");
        }

        // Sourcery P3 + Copilot: a REGION dict-lookup-ot explicit `is_active=true` szűrés
        // — az `Optional.filter` egy plusz ág, mert a `findByCategoryAndCode` nem szűr.
        Dictionary region = dictionaryRepository.findByCategoryAndCode("REGION", dto.getRegionCode())
                .filter(d -> Boolean.TRUE.equals(d.getIsActive()))
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Ismeretlen régió kód: " + dto.getRegionCode()
                                + " (a Beállítások → Törzsadatok → Régiók listából válasszon)"));

        // Copilot P0: a kliens-küldött szöveges régió-kódot KESZLEX numerikusra mappeljük,
        // hogy a `Branch.regionCode` konzisztens legyen a meglévő ÉRTÉKTÁR seed-ekkel
        // (V145/V239: region_code='20'/'40'/...). NÉLKÜLE a területi scope NEM matchelne.
        final String keszlexRegionCode = toKeszlexRegionCode(dto.getRegionCode());

        // P0 self-review #891 fix + Codex P1: ERTEKTAR (területi értéktáros) csak a saját
        // KESZLEX-régiójához tartozó pénztárt rögzíthet fel. A vaultRegionCodeOrNull() a
        // user `branch.region_code`-jából jön — numerikus érték. Egyezés-ellenőrzés a
        // numerikus KESZLEX-kóddal.
        String userVaultRegion = accessScopeService.vaultRegionCodeOrNull();
        if (userVaultRegion != null && !userVaultRegion.equals(keszlexRegionCode)) {
            log.warn("Cross-region branch-create blocked: user-keszlex={}, requested-keszlex={} ({}), code={}",
                    userVaultRegion, keszlexRegionCode, dto.getRegionCode(), normalizedCode);
            throw new ValidationException(
                    "Értéktárosként csak a saját területéhez tartozó pénztárt rögzíthet fel, "
                            + "NEM " + dto.getRegionCode() + " régióhoz tartozót. "
                            + "Más régióhoz a főértéktáros vagy ügyvezető jogosult.");
        }

        UUID companyId = SecurityUtils.getCurrentCompanyId();
        Company company = companyRepository.findById(companyId)
                .orElseThrow(() -> new ResourceNotFoundException("Cég nem található: " + companyId));

        // Default master-dictionary lookup
        Dictionary penztarType = dictionaryRepository.findByCategoryAndCode("BRANCH_TYPE", "PENZTAR")
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Hiányzó dictionary entry: BRANCH_TYPE/PENZTAR (rendszer adat)"));
        Dictionary huCountry = dictionaryRepository.findByCategoryAndCode("COUNTRY", "HU")
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Hiányzó dictionary entry: COUNTRY/HU (rendszer adat)"));
        Dictionary activeStatus = dictionaryRepository.findByCategoryAndCode("BRANCH_STATUS", "ACTIVE")
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Hiányzó dictionary entry: BRANCH_STATUS/ACTIVE (rendszer adat)"));

        String name = (dto.getName() != null && !dto.getName().isBlank())
                ? dto.getName().trim()
                : "Pénztár " + normalizedCode;
        // A város default-ja a régió kód name_hu-jából (pl. SZEGED → "Szeged"), ha a kliens üresen hagyta.
        String city = (dto.getCity() != null && !dto.getCity().isBlank())
                ? dto.getCity().trim()
                : (region.getNameHu() != null && !region.getNameHu().isBlank()
                        ? region.getNameHu()
                        : capitalize(dto.getRegionCode()));
        // Codex P1: a `branch.zip_code` NOT NULL (V0_1__base_tables); üres string default.
        String zipCode = (dto.getZipCode() != null && !dto.getZipCode().isBlank())
                ? dto.getZipCode().trim()
                : "";

        // FK-021 (2026-06-05): a teljes törzsadat-mezők a DTO-ból, null esetén a korábbi default.
        String resolvedBankCode = (dto.getBankCode() != null && !dto.getBankCode().isBlank())
                ? dto.getBankCode().trim()
                : normalizedCode;                    // default: bankCode == code (kézzel szerkeszthető)
        String resolvedShortName = (dto.getShortName() != null && !dto.getShortName().isBlank())
                ? dto.getShortName().trim() : null;
        String resolvedPhone = (dto.getPhone() != null && !dto.getPhone().isBlank())
                ? dto.getPhone().trim() : null;
        String resolvedEmail = (dto.getEmail() != null && !dto.getEmail().isBlank())
                ? dto.getEmail().trim() : null;
        boolean isVault = Boolean.TRUE.equals(dto.getIsVault());                 // null → pénztár
        boolean isActive = dto.getIsActive() == null || Boolean.TRUE.equals(dto.getIsActive()); // null → aktív; "tartósan zárva" → false

        Branch branch = Branch.builder()
                .code(normalizedCode)
                .company(company)
                .bankCode(resolvedBankCode)
                .branchType(penztarType)
                .name(name)
                .shortName(resolvedShortName)
                .address(dto.getAddress().trim())
                .city(city)
                .zipCode(zipCode)
                .phone(resolvedPhone)
                .email(resolvedEmail)
                .country(huCountry)
                .branchStatus(activeStatus)
                .openingDate(LocalDate.now())
                .regionCode(keszlexRegionCode)       // ← NUMERIKUS KESZLEX (region-scope kulcs)
                .region(dto.getRegionCode())          // ← SZÖVEGES (legacy display + transfer/stock view) — Copilot P2
                .isActive(isActive)
                .isVault(isVault)                     // FK-021: Pénztár (false) / Értéktár (true)
                .hasAfa(Boolean.TRUE.equals(dto.getHasAfa()))
                .hasWu(Boolean.TRUE.equals(dto.getHasWu()))
                .hasMg(Boolean.TRUE.equals(dto.getHasMg()))
                .hasPos(Boolean.TRUE.equals(dto.getHasPos()))
                .closedSaturday(Boolean.TRUE.equals(dto.getClosedSaturday()))
                .closedSunday(Boolean.TRUE.equals(dto.getClosedSunday()))
                .build();

        Branch saved = branchRepository.save(branch);
        log.info("Simple cashier branch created: {} (code={}, region={})",
                saved.getId(), saved.getCode(), saved.getRegionCode());

        // Cash balance + denomination auto-init (mint a standard create()-ben). Idempotens.
        try {
            int created = cashBalanceService.initializeBranchBalances(saved.getId());
            log.info("Branch {} cash_balance auto-init: {} új rekord", saved.getId(), created);
        } catch (RuntimeException e) {
            log.error("Branch {} cash_balance auto-init FAILED [{}: {}] (admin kézi init szükséges)",
                    saved.getId(), e.getClass().getSimpleName(), e.getMessage(), e);
        }
        try {
            denominationService.initializeBranchDenominations(saved.getId());
            log.info("Branch {} denomination auto-init: 14 HUF + külföldi címlet beállítva",
                    saved.getId());
        } catch (RuntimeException e) {
            log.error("Branch {} denomination auto-init FAILED [{}: {}] (admin kézi init szükséges)",
                    saved.getId(), e.getClass().getSimpleName(), e.getMessage(), e);
        }

        // FK-096/D18: az egyszerű pénztár is kap alap kezelési díj konfigurációt (lásd create()).
        branchHandlingFeeConfigService.seedDefaultLive(companyId, saved.getId(),
                SecurityUtils.getCurrentWorkerCode());

        return branchMapper.toDto(saved);
    }

    /** Capitalize a string ("SZEGED" → "Szeged"). Null-safe. */
    private static String capitalize(String s) {
        if (s == null || s.isEmpty()) return s;
        return Character.toUpperCase(s.charAt(0)) + s.substring(1).toLowerCase();
    }

    /**
     * Fiók frissítése
     */
    public BranchDto update(UUID id, UpdateBranchDto dto) {
        log.info("Updating branch: {}", id);

        Branch branch = branchRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Fiók nem található: " + id));

        // IDOR védelem: kereszt-bérlő írás elleni védelem (PP-02)
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        if (branch.getCompany() == null || !branch.getCompany().getId().equals(companyId)) {
            log.warn("IDOR gyanús módosítás blokkolva! userCompany={}, branchCompany={}, branchId={}",
                    companyId, branch.getCompany() != null ? branch.getCompany().getId() : "null", id);
            throw new ResourceNotFoundException("Fiók nem található: " + id);
        }

        // FK-022 FR-10: a név partial-update-ben megadható, de üresre nem törölhető.
        if (dto.getName() != null && dto.getName().isBlank()) {
            throw new ValidationException("A megjelenítendő név nem lehet üres.");
        }

        // FK-022 FR-7: audit before-pillanatkép a mutáció ELŐTT (DTO-másolat, nem a managed entity).
        BranchDto before = branchMapper.toDto(branch);

        // Frissíthető mezők
        if (dto.getName() != null) {
            branch.setName(dto.getName());
        }
        if (dto.getAddress() != null) {
            branch.setAddress(dto.getAddress());
        }
        // FK-025 + Codex P2 (#1093): a DTO blank→null normalizál (Bean Validation miatt),
        // a clear* jelző hordozza az explicit törlési szándékot. NOT NULL oszlop (city,
        // zip_code, bank_code) törlése = "", nullable (phone, email, short_name) = null.
        if (dto.getCity() != null) {
            branch.setCity(dto.getCity());
        } else if (dto.isClearCity()) {
            branch.setCity("");
        }
        if (dto.getZipCode() != null) {
            branch.setZipCode(dto.getZipCode());
        } else if (dto.isClearZipCode()) {
            branch.setZipCode("");
        }
        if (dto.getCountryId() != null) {
            Dictionary country = dictionaryRepository.findById(dto.getCountryId())
                    .orElseThrow(() -> new ResourceNotFoundException("Ország nem található: " + dto.getCountryId()));
            branch.setCountry(country);
        }
        if (dto.getPhone() != null) {
            branch.setPhone(dto.getPhone());
        } else if (dto.isClearPhone()) {
            branch.setPhone(null);
        }
        if (dto.getEmail() != null) {
            branch.setEmail(dto.getEmail());
        } else if (dto.isClearEmail()) {
            branch.setEmail(null);
        }
        if (dto.getBankCode() != null) {
            branch.setBankCode(dto.getBankCode());
        } else if (dto.isClearBankCode()) {
            branch.setBankCode("");
        }
        if (dto.getBranchStatusId() != null) {
            Dictionary status = dictionaryRepository.findById(dto.getBranchStatusId())
                    .orElseThrow(() -> new ResourceNotFoundException("Státusz nem található: " + dto.getBranchStatusId()));
            branch.setBranchStatus(status);
        }
        if (dto.getOpeningDate() != null) {
            branch.setOpeningDate(dto.getOpeningDate());
        }
        if (dto.getDenominationRuleId() != null) {
            branch.setDenominationRuleId(dto.getDenominationRuleId());
        }
        if (dto.getIsActive() != null) {
            branch.setIsActive(dto.getIsActive());
        }
        // Pénztár Törzs alapmodul (V293): partial update — csak a nem-null mezők íródnak felül.
        if (dto.getShortName() != null) {
            branch.setShortName(dto.getShortName());
        } else if (dto.isClearShortName()) {
            branch.setShortName(null);
        }
        if (dto.getHasAfa() != null) {
            branch.setHasAfa(dto.getHasAfa());
        }
        if (dto.getHasWu() != null) {
            branch.setHasWu(dto.getHasWu());
        }
        if (dto.getHasMg() != null) {
            branch.setHasMg(dto.getHasMg());
        }
        if (dto.getHasPos() != null) {
            branch.setHasPos(dto.getHasPos());
        }
        if (dto.getClosedSaturday() != null) {
            branch.setClosedSaturday(dto.getClosedSaturday());
        }
        if (dto.getClosedSunday() != null) {
            branch.setClosedSunday(dto.getClosedSunday());
        }
        // FK-022: az iroda típusa (Pénztár/Értéktár) is módosítható a szerkesztő formról.
        if (dto.getIsVault() != null) {
            branch.setIsVault(dto.getIsVault());
        }
        // FK-022: területi besorolás módosítása — ugyanaz a REGION-dict validáció + KESZLEX
        // numerikus mapping, mint createSimpleCashier-nél, hogy a területi scope konzisztens maradjon.
        if (dto.getRegionCode() != null && !dto.getRegionCode().isBlank()) {
            dictionaryRepository.findByCategoryAndCode("REGION", dto.getRegionCode())
                    .filter(d -> Boolean.TRUE.equals(d.getIsActive()))
                    .orElseThrow(() -> new ResourceNotFoundException(
                            "Ismeretlen régió kód: " + dto.getRegionCode()
                                    + " (a Beállítások → Törzsadatok → Régiók listából válasszon)"));
            String keszlexRegionCode = toKeszlexRegionCode(dto.getRegionCode());
            branch.setRegionCode(keszlexRegionCode);
            branch.setRegion(dto.getRegionCode());
        }

        Branch updated = branchRepository.save(branch);
        log.info("Branch updated successfully: {}", id);

        BranchDto after = branchMapper.toDto(updated);

        // FK-022 FR-7: audit log a módosítás előtti és utáni teljes állapottal (§3 — hash-láncolt
        // audit_log, action=BRANCH_UPDATE). Ugyanabban a tranzakcióban fut, rollback esetén
        // az audit-bejegyzés is visszagörgetődik.
        auditLogService.logWithDetails(
                "BRANCH_UPDATE",
                "BRANCH",
                id.toString(),
                currentWorkerIdOrNull(),
                currentWorkerCodeOrNull(),
                id.toString(),
                updated.getName(),
                toJsonSafe(before),
                toJsonSafe(after),
                null,
                null);

        return after;
    }

    /**
     * FK-022: worker-id az audit loghoz — rendszer-kontextusban (nincs auth) null.
     * Sourcery P2: a kivételt nem nyeljük le némán — WARN-on látható marad egy esetleges
     * valódi security-context hiba, miközben az audit nem-fatális marad.
     */
    private static String currentWorkerIdOrNull() {
        try {
            Long workerId = SecurityUtils.getCurrentWorkerId();
            return workerId != null ? workerId.toString() : null;
        } catch (RuntimeException e) {
            log.warn("Audit worker-id feloldás sikertelen (rendszer-kontextus?): {}", e.getMessage());
            return null;
        }
    }

    /** FK-022: worker-kód az audit loghoz — rendszer-kontextusban (nincs auth) null. */
    private static String currentWorkerCodeOrNull() {
        try {
            return SecurityUtils.getCurrentWorkerCode();
        } catch (RuntimeException e) {
            log.warn("Audit worker-kód feloldás sikertelen (rendszer-kontextus?): {}", e.getMessage());
            return null;
        }
    }

    /**
     * FK-022: audit-mező JSON-serializálás — hiba esetén nem buktatja a mentést.
     * Sourcery P2: a fallback nem a semmitmondó Object.toString(), hanem egy minimális,
     * de értelmezhető kulcsmező-pillanatkép (id/code/name), hogy az audit trail hiba
     * esetén is használható maradjon.
     */
    private String toJsonSafe(BranchDto dto) {
        try {
            return objectMapper.writeValueAsString(dto);
        } catch (JacksonException e) {
            log.warn("Branch audit JSON serialization failed: {}", e.getMessage());
            try {
                java.util.Map<String, Object> fallback = new java.util.LinkedHashMap<>();
                fallback.put("id", dto.getId());
                fallback.put("code", dto.getCode());
                fallback.put("name", dto.getName());
                return objectMapper.writeValueAsString(fallback);
            } catch (JacksonException inner) {
                // Copilot P2: az oldValue/newValue mindig parse-olható JSON marad — a végső
                // fallback sem nyers toString, hanem garantáltan JSON error-wrapper.
                log.warn("Branch audit fallback serialization failed: {}", inner.getMessage());
                return "{\"auditSerializationError\":\"" + inner.getClass().getSimpleName() + "\"}";
            }
        }
    }

    /**
     * Fiók törlése (soft delete)
     */
    public void delete(UUID id) {
        log.info("Deleting branch: {}", id);

        Branch branch = branchRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Fiók nem található: " + id));

        // IDOR védelem: kereszt-bérlő törlés elleni védelem (PP-02)
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        if (branch.getCompany() == null || !branch.getCompany().getId().equals(companyId)) {
            log.warn("IDOR gyanús törlés blokkolva! userCompany={}, branchCompany={}, branchId={}",
                    companyId, branch.getCompany() != null ? branch.getCompany().getId() : "null", id);
            throw new ResourceNotFoundException("Fiók nem található: " + id);
        }

        // Ellenőrzés: van-e gyermeke
        List<Branch> children = branchRepository.findByParentBranchId(id);
        if (!children.isEmpty()) {
            throw new ValidationException("Nem törölhető fiók, aminek vannak alá rendelt fiókok");
        }

        // Soft delete
        branch.setIsActive(false);
        branchRepository.save(branch);

        log.info("Branch deleted successfully: {}", id);
    }

    // ===== Private Helper Methods =====

    private void validateBranchCode(String code) {
        // Multi-tenant-safe: csak a sajat cegben ellenorizni
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        if (branchRepository.existsByCompanyIdAndCode(companyId, code)) {
            throw new ValidationException("Már létezik fiók ezzel a kóddal: " + code);
        }
    }

    private void validateBranchHierarchy(UUID branchTypeId, UUID parentBranchId) {
        Dictionary branchType = dictionaryRepository.findById(branchTypeId)
                .orElseThrow(() -> new ResourceNotFoundException("Fiók típus nem található: " + branchTypeId));

        String typeCode = branchType.getCode();

        // KÖZPONT: nincs szülő
        if ("KOZPONT".equals(typeCode) && parentBranchId != null) {
            throw new ValidationException("Központ nem lehet más alá rendelve");
        }

        // FŐÉRTÉKTÁR: szülő kötelező és csak KÖZPONT lehet
        if ("FOERTEKTAR".equals(typeCode)) {
            if (parentBranchId == null) {
                throw new ValidationException("Főértéktárnak kötelező szülő");
            }
            Branch parent = branchRepository.findById(parentBranchId)
                    .orElseThrow(() -> new ResourceNotFoundException("Szülő fiók nem található"));
            assertParentInCurrentCompany(parent, parentBranchId);
            if (!"KOZPONT".equals(parent.getBranchType().getCode())) {
                throw new ValidationException("Főértéktár csak központ alá helyezhető");
            }
        }

        // ÉRTÉKTÁR: szülő kötelező és KÖZPONT vagy FŐÉRTÉKTÁR lehet
        if ("ERTEKTAR".equals(typeCode)) {
            if (parentBranchId == null) {
                throw new ValidationException("Értéktárnak kötelező szülő");
            }
            Branch parent = branchRepository.findById(parentBranchId)
                    .orElseThrow(() -> new ResourceNotFoundException("Szülő fiók nem található"));
            assertParentInCurrentCompany(parent, parentBranchId);
            String parentCode = parent.getBranchType().getCode();
            if (!"KOZPONT".equals(parentCode) && !"FOERTEKTAR".equals(parentCode)) {
                throw new ValidationException("Értéktár csak központ vagy főértéktár alá helyezhető");
            }
        }

        // PÉNZTÁR: szülő kötelező és csak ÉRTÉKTÁR lehet
        if ("PENZTAR".equals(typeCode)) {
            if (parentBranchId == null) {
                throw new ValidationException("Pénztárnak kötelező szülő");
            }
            Branch parent = branchRepository.findById(parentBranchId)
                    .orElseThrow(() -> new ResourceNotFoundException("Szülő fiók nem található"));
            assertParentInCurrentCompany(parent, parentBranchId);
            if (!"ERTEKTAR".equals(parent.getBranchType().getCode())) {
                throw new ValidationException("Pénztár csak értéktár alá helyezhető");
            }
        }
    }

    /**
     * IDOR-guard: a user által megadott szülő-fiók ({@code dto.getParentBranchId()}) eddig csak
     * típusra volt ellenőrizve, cég-scope-ra nem. A szülőnek az aktuális céghez kell tartoznia;
     * cross-tenant → ResourceNotFoundException (a betöltés-mintával összhangban).
     */
    private void assertParentInCurrentCompany(Branch parent, UUID parentBranchId) {
        if (parent.getCompany() == null
                || !parent.getCompany().getId().equals(SecurityUtils.getCurrentCompanyId())) {
            throw new ResourceNotFoundException("Szülő fiók nem található: " + parentBranchId);
        }
    }
}
