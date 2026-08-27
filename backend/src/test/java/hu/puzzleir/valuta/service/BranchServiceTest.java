package hu.puzzleir.valuta.service;

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
import hu.puzzleir.valuta.dto.BranchDto;
import hu.puzzleir.valuta.dto.CreateBranchDto;
import hu.puzzleir.valuta.dto.UpdateBranchDto;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

/**
 * PP-02 (kereszt-bérlő IDOR) + PP-05 (SQL-szintű cég-szűrés) tesztek a BranchService-re.
 */
@ExtendWith(MockitoExtension.class)
class BranchServiceTest {

    @Mock private BranchRepository branchRepository;
    @Mock private CompanyRepository companyRepository;
    @Mock private DictionaryRepository dictionaryRepository;
    @Mock private BranchMapper branchMapper;
    @Mock private CashBalanceService cashBalanceService;
    @Mock private DenominationService denominationService;
    @Mock private AccessScopeService accessScopeService;
    // FK-022: update() audit log + JSON-serializálás
    @Mock private AuditLogService auditLogService;
    @Mock private tools.jackson.databind.ObjectMapper objectMapper;
    // FK-096/D18: az új iroda seed-hívás mockja (a create/createSimpleCashier tesztekben no-op).
    @Mock private BranchHandlingFeeConfigService branchHandlingFeeConfigService;
    @InjectMocks private BranchService service;

    private static final UUID COMPANY_ID = UUID.randomUUID();
    private static final UUID OTHER_COMPANY = UUID.randomUUID();
    private static final UUID BRANCH_ID = UUID.randomUUID();

    private static Branch branchOf(UUID companyId) {
        return Branch.builder().id(BRANCH_ID)
                .company(Company.builder().id(companyId).build()).build();
    }

    @Test
    @DisplayName("update — más cég fiókja: IDOR-védelem (ResourceNotFound, nincs save)")
    void testUpdateOtherCompanyBlocked() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branchOf(OTHER_COMPANY)));

            assertThatThrownBy(() -> service.update(BRANCH_ID, new UpdateBranchDto()))
                    .isInstanceOf(ResourceNotFoundException.class);
            verify(branchRepository, never()).save(any());
        }
    }

    @Test
    @DisplayName("delete — más cég fiókja: IDOR-védelem (ResourceNotFound, nincs save)")
    void testDeleteOtherCompanyBlocked() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branchOf(OTHER_COMPANY)));

            assertThatThrownBy(() -> service.delete(BRANCH_ID))
                    .isInstanceOf(ResourceNotFoundException.class);
            verify(branchRepository, never()).save(any());
        }
    }

    @Test
    @DisplayName("create — kliens másik cég companyId-ja: IDOR-védelem (ValidationException, nincs save)")
    void testCreateForeignCompanyIdBlocked() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            UUID branchTypeId = UUID.randomUUID();
            CreateBranchDto dto = CreateBranchDto.builder()
                    .code("UJ01")
                    .companyId(OTHER_COMPANY)   // IDEGEN cég — el kell utasítani
                    .branchTypeId(branchTypeId)
                    .build();
            // hierarchia: KOZPONT típus, nincs szülő → átmegy a validáción
            when(branchRepository.existsByCompanyIdAndCode(COMPANY_ID, "UJ01")).thenReturn(false);
            when(dictionaryRepository.findById(branchTypeId))
                    .thenReturn(Optional.of(Dictionary.builder().code("KOZPONT").build()));

            assertThatThrownBy(() -> service.create(dto))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("másik céghez");
            verify(branchRepository, never()).save(any(Branch.class));
            verify(companyRepository, never()).findById(any());
        }
    }

    @Test
    @DisplayName("create — egyező companyId: átmegy a tenant-kapun, a céget a SecurityContextből oldja fel")
    void testCreateMatchingCompanyIdResolvesFromContext() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            UUID branchTypeId = UUID.randomUUID();
            CreateBranchDto dto = CreateBranchDto.builder()
                    .code("UJ02")
                    .companyId(COMPANY_ID)
                    .branchTypeId(branchTypeId)
                    .build();
            when(branchRepository.existsByCompanyIdAndCode(COMPANY_ID, "UJ02")).thenReturn(false);
            when(dictionaryRepository.findById(branchTypeId))
                    .thenReturn(Optional.of(Dictionary.builder().code("KOZPONT").build()));
            // A tenant-kapu UTÁN a SAJÁT companyId-val keres céget → üres → ResourceNotFound
            // (nem ValidationException) bizonyítja, hogy az egyező companyId átment a kapun.
            when(companyRepository.findById(COMPANY_ID)).thenReturn(Optional.empty());

            assertThatThrownBy(() -> service.create(dto))
                    .isInstanceOf(ResourceNotFoundException.class)
                    .hasMessageContaining("Cég nem található");
            verify(companyRepository).findById(COMPANY_ID);
        }
    }

    @Test
    @DisplayName("findByStatus — SQL-szintű cég-szűrt lekérdezést hív (PP-05, nem memóriabeli filter)")
    void testFindByStatusUsesSqlScopedQuery() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(branchRepository.findByCompanyIdAndBranchStatusCode(COMPANY_ID, "AKTIV"))
                    .thenReturn(List.of());
            when(branchMapper.toDtoList(any())).thenReturn(List.of());

            service.findByStatus("AKTIV");

            verify(branchRepository).findByCompanyIdAndBranchStatusCode(COMPANY_ID, "AKTIV");
            verify(branchRepository, never()).findByBranchStatusCode(any());
        }
    }

    // ============================================================
    // #891 Bali Henriett 2. pont (manuális pénztár-felrögzítés)
    // self-review fix: ERTEKTAR cross-region tiltás + happy path
    // ============================================================

    private static hu.puzzleir.valuta.dto.CreateSimpleCashierBranchDto simpleDto(String regionCode) {
        return hu.puzzleir.valuta.dto.CreateSimpleCashierBranchDto.builder()
                .code("BR999")
                .address("6720 Szeged, Teszt utca 1.")
                .regionCode(regionCode)
                .build();
    }

    private void stubDictionaries() {
        // Lenient: nem minden teszt használ minden dict-lookup-ot — Mockito strict-mode
        // unnecessary-stubbing miatt explicit lenient().
        // #891 follow-up: a service `.filter(d -> Boolean.TRUE.equals(d.getIsActive()))`-t
        // hív a REGION-en, ezért az `isActive(true)` kötelező a stub-ban.
        lenient().when(dictionaryRepository.findByCategoryAndCode(eq("REGION"), any())).thenAnswer(inv ->
                Optional.of(hu.puzzleir.valuta.entity.Dictionary.builder()
                        .category("REGION").code((String) inv.getArgument(1))
                        .nameHu("Szeged").isActive(true).build()));
        lenient().when(dictionaryRepository.findByCategoryAndCode("BRANCH_TYPE", "PENZTAR")).thenReturn(
                Optional.of(hu.puzzleir.valuta.entity.Dictionary.builder()
                        .category("BRANCH_TYPE").code("PENZTAR").build()));
        lenient().when(dictionaryRepository.findByCategoryAndCode("COUNTRY", "HU")).thenReturn(
                Optional.of(hu.puzzleir.valuta.entity.Dictionary.builder()
                        .category("COUNTRY").code("HU").build()));
        lenient().when(dictionaryRepository.findByCategoryAndCode("BRANCH_STATUS", "ACTIVE")).thenReturn(
                Optional.of(hu.puzzleir.valuta.entity.Dictionary.builder()
                        .category("BRANCH_STATUS").code("ACTIVE").build()));
    }

    @Test
    @DisplayName("createSimpleCashier — happy path cég-szintű user (FOERTEKTAR/ADMIN): bárhova rögzíthet")
    void testCreateSimpleCashierHappyPathCompanyLevel() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            stubDictionaries();
            lenient().when(branchRepository.existsByCode("BR999")).thenReturn(false);
            lenient().when(companyRepository.findById(COMPANY_ID))
                    .thenReturn(Optional.of(Company.builder().id(COMPANY_ID).build()));
            // accessScopeService.vaultRegionCodeOrNull() → null = cég-szintű (NEM ERTEKTAR)
            lenient().when(accessScopeService.vaultRegionCodeOrNull()).thenReturn(null);
            lenient().when(branchRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

            service.createSimpleCashier(simpleDto("DEBRECEN"));

            verify(branchRepository).save(any(Branch.class));
        }
    }

    @Test
    @DisplayName("createSimpleCashier — ERTEKTAR cross-region: ValidationException (saját régión kívülre nem rögzíthet)")
    void testCreateSimpleCashierBlockedCrossRegionForErtektar() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            stubDictionaries();
            lenient().when(branchRepository.existsByCode("BR999")).thenReturn(false);
            // ERTEKTAR Szegedről (KESZLEX "20") próbál DEBRECEN-be ("50") felvenni → blocked
            when(accessScopeService.vaultRegionCodeOrNull()).thenReturn("20");

            assertThatThrownBy(() -> service.createSimpleCashier(simpleDto("DEBRECEN")))
                    .isInstanceOf(hu.puzzleir.valuta.exception.ValidationException.class)
                    .hasMessageContaining("saját területéhez")
                    .hasMessageContaining("DEBRECEN");
            verify(branchRepository, never()).save(any());
        }
    }

    @Test
    @DisplayName("createSimpleCashier — ERTEKTAR same-region: létrejön a pénztár (saját területéhez)")
    void testCreateSimpleCashierAllowedSameRegionForErtektar() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            stubDictionaries();
            lenient().when(branchRepository.existsByCode("BR999")).thenReturn(false);
            lenient().when(companyRepository.findById(COMPANY_ID))
                    .thenReturn(Optional.of(Company.builder().id(COMPANY_ID).build()));
            // ERTEKTAR Szegedről (KESZLEX "20") felvesz SZEGED (KESZLEX "20") régiójú pénztárt → OK
            when(accessScopeService.vaultRegionCodeOrNull()).thenReturn("20");
            when(branchRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

            service.createSimpleCashier(simpleDto("SZEGED"));

            verify(branchRepository).save(any(Branch.class));
        }
    }

    @Test
    @DisplayName("createSimpleCashier — FK-021: kibővített törzsadat-mezők átmennek a Branch entityre (isVault, inaktív, szolgáltatás-flagek)")
    void testCreateSimpleCashierFullMasterData() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            stubDictionaries();
            lenient().when(branchRepository.existsByCode("BR777")).thenReturn(false);
            lenient().when(companyRepository.findById(COMPANY_ID))
                    .thenReturn(Optional.of(Company.builder().id(COMPANY_ID).build()));
            lenient().when(accessScopeService.vaultRegionCodeOrNull()).thenReturn(null);
            lenient().when(branchRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

            hu.puzzleir.valuta.dto.CreateSimpleCashierBranchDto dto =
                    hu.puzzleir.valuta.dto.CreateSimpleCashierBranchDto.builder()
                            .code("BR777")
                            .name("Szeged Belváros")
                            .shortName("Belváros")
                            .address("6720 Szeged, Tisza Lajos krt. 1.")
                            .regionCode("SZEGED")
                            .phone("06701234567")
                            .email("szeged@ebc.hu")
                            .bankCode("210")
                            .isVault(true)
                            // FR-5: "Tartósan zárva" → inaktív.
                            .isActive(false)
                            .hasAfa(true)
                            .hasWu(true)
                            .hasMg(false)
                            .hasPos(true)
                            .closedSaturday(true)
                            .closedSunday(false)
                            .build();

            service.createSimpleCashier(dto);

            ArgumentCaptor<Branch> captor = ArgumentCaptor.forClass(Branch.class);
            verify(branchRepository).save(captor.capture());
            Branch saved = captor.getValue();
            assertThat(saved.getShortName()).isEqualTo("Belváros");
            assertThat(saved.getPhone()).isEqualTo("06701234567");
            assertThat(saved.getEmail()).isEqualTo("szeged@ebc.hu");
            assertThat(saved.getBankCode()).isEqualTo("210");
            assertThat(saved.getIsVault()).isTrue();
            assertThat(saved.getIsActive()).isFalse();
            assertThat(saved.getHasAfa()).isTrue();
            assertThat(saved.getHasWu()).isTrue();
            assertThat(saved.getHasMg()).isFalse();
            assertThat(saved.getHasPos()).isTrue();
            assertThat(saved.getClosedSaturday()).isTrue();
            assertThat(saved.getClosedSunday()).isFalse();
        }
    }

    @Test
    @DisplayName("createSimpleCashier — FK-021: hiányzó opcionális mezők → biztonságos default (pénztár, aktív, bankkód=kód)")
    void testCreateSimpleCashierDefaultsWhenOptionalOmitted() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            stubDictionaries();
            lenient().when(branchRepository.existsByCode("BR999")).thenReturn(false);
            lenient().when(companyRepository.findById(COMPANY_ID))
                    .thenReturn(Optional.of(Company.builder().id(COMPANY_ID).build()));
            lenient().when(accessScopeService.vaultRegionCodeOrNull()).thenReturn(null);
            lenient().when(branchRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

            // simpleDto csak a kötelező mezőket adja (NewCashierBranchPage backward-compat).
            service.createSimpleCashier(simpleDto("SZEGED"));

            ArgumentCaptor<Branch> captor = ArgumentCaptor.forClass(Branch.class);
            verify(branchRepository).save(captor.capture());
            Branch saved = captor.getValue();
            assertThat(saved.getIsVault()).isFalse();
            assertThat(saved.getIsActive()).isTrue();
            assertThat(saved.getBankCode()).isEqualTo("BR999");
            assertThat(saved.getHasAfa()).isFalse();
            assertThat(saved.getHasWu()).isFalse();
            assertThat(saved.getHasMg()).isFalse();
            assertThat(saved.getHasPos()).isFalse();
        }
    }

    // ============================================================
    // #892 FK-013 — findVaultCounterparties self-review tests
    // ============================================================

    private static Branch branchWith(String code, String typeCode, boolean isVault, boolean isActive) {
        return Branch.builder()
                .id(UUID.randomUUID())
                .code(code)
                .branchType(hu.puzzleir.valuta.entity.Dictionary.builder()
                        .category("BRANCH_TYPE").code(typeCode).build())
                .isVault(isVault)
                .isActive(isActive)
                .build();
    }

    @Test
    @DisplayName("findVaultCounterparties — ERTEKTAR Szeged user: 3 csoport (territorial + peer + fixed), saját értéktár kihagyva")
    void testFindVaultCounterpartiesForRegionalErtektar() {
        UUID ownVaultId = UUID.randomUUID();
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            su.when(SecurityUtils::getCurrentBranchIdOrNull).thenReturn(ownVaultId);

            Branch territorial1 = branchWith("BR026", "PENZTAR", false, true);
            Branch territorial2 = branchWith("BR027", "PENZTAR", false, true);
            Branch fixedPrb = branchWith("PRB", "VAULT_COUNTERPARTY", false, true);
            Branch ownVault = Branch.builder().id(ownVaultId).code("BR020").isVault(true).isActive(true).build();
            Branch peerVault = Branch.builder().id(UUID.randomUUID()).code("BR050").isVault(true).isActive(true).build();

            // vault scope = SZEGED régió pénztárai (csak a 2 territorial)
            java.util.Set<UUID> vaultScope = new java.util.HashSet<>();
            vaultScope.add(territorial1.getId());
            vaultScope.add(territorial2.getId());
            vaultScope.add(ownVaultId);
            when(accessScopeService.vaultRegionBranchScopeOrNull()).thenReturn(vaultScope);
            // findAllActive → ezeket adja (territorial-ok + ownVault + peerVault)
            when(branchRepository.findByCompanyIdAndIsActiveTrue(COMPANY_ID)).thenReturn(
                    List.of(territorial1, territorial2, ownVault, peerVault));
            when(branchRepository.findByCompanyIdAndIsVaultTrueAndIsActiveTrue(COMPANY_ID)).thenReturn(
                    List.of(ownVault, peerVault));
            when(branchRepository.findByCompanyIdAndBranchTypeCode(COMPANY_ID, "VAULT_COUNTERPARTY")).thenReturn(
                    List.of(fixedPrb));
            when(branchMapper.toDto(any())).thenAnswer(inv -> {
                Branch b = inv.getArgument(0);
                return hu.puzzleir.valuta.dto.BranchDto.builder().id(b.getId()).code(b.getCode()).build();
            });

            hu.puzzleir.valuta.dto.VaultCounterpartiesDto result = service.findVaultCounterparties();

            // territorial: 2 db pénztár (NEM tartalmazza az ownVault-ot, mert az nem PENZTAR típus)
            assertThat(result.getTerritorialCashiers()).hasSize(2);
            assertThat(result.getTerritorialCashiers()).extracting("code").containsExactlyInAnyOrder("BR026", "BR027");
            // peerVaults: peerVault (a saját ownVault KIZÁRVA)
            assertThat(result.getPeerVaults()).hasSize(1);
            assertThat(result.getPeerVaults().getFirst().getCode()).isEqualTo("BR050");
            // fixedCounterparties: 10 helyett a teszt-stub 1-et ad — verifikáljuk
            assertThat(result.getFixedCounterparties()).hasSize(1);
            assertThat(result.getFixedCounterparties().getFirst().getCode()).isEqualTo("PRB");
        }
    }

    @Test
    @DisplayName("findVaultCounterparties — FOERTEKTAR null-scope: a territorialCashiers minden aktív pénztár (cégszint)")
    void testFindVaultCounterpartiesForFoertektarSeesAllCashiers() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            su.when(SecurityUtils::getCurrentBranchIdOrNull).thenReturn(null);

            Branch cashier1 = branchWith("BR001", "PENZTAR", false, true);
            Branch cashier2 = branchWith("BR050", "PENZTAR", false, true);
            // FOERTEKTAR-nak null scope (nincs területi szűkítés)
            when(accessScopeService.vaultRegionBranchScopeOrNull()).thenReturn(null);
            when(branchRepository.findByCompanyIdAndIsActiveTrue(COMPANY_ID)).thenReturn(List.of(cashier1, cashier2));
            when(branchRepository.findByCompanyIdAndIsVaultTrueAndIsActiveTrue(COMPANY_ID)).thenReturn(List.of());
            when(branchRepository.findByCompanyIdAndBranchTypeCode(COMPANY_ID, "VAULT_COUNTERPARTY")).thenReturn(List.of());
            when(branchMapper.toDto(any())).thenAnswer(inv -> {
                Branch b = inv.getArgument(0);
                return hu.puzzleir.valuta.dto.BranchDto.builder().code(b.getCode()).build();
            });

            hu.puzzleir.valuta.dto.VaultCounterpartiesDto result = service.findVaultCounterparties();

            // null scope → minden pénztár visszajön
            assertThat(result.getTerritorialCashiers()).hasSize(2);
        }
    }

    @Test
    @DisplayName("findVaultCounterparties — FOERTEKTAR Helga-szerű eset: branchId=Tisza Sarok pénztár, regionCode='20'. A territorialCashiers a Szeged régió pénztárai (regionCode='20'); a peerVaults kihagyja az ownRegion értéktárát.")
    void testFindVaultCounterpartiesForFoertektarHelgaCase() {
        UUID ownBranchId = UUID.randomUUID();
        Branch ownBranch = Branch.builder()
                .id(ownBranchId)
                .code("BR035")
                .region("SZEGED")   // SZEGED KESZLEX
                .isActive(true)
                .build();

        // Szeged régió pénztárai (regionCode='20')
        Branch szegedCashier1 = Branch.builder().id(UUID.randomUUID()).code("BR026")
                .region("SZEGED").isActive(true)
                .branchType(hu.puzzleir.valuta.entity.Dictionary.builder()
                        .category("BRANCH_TYPE").code("PENZTAR").build())
                .isVault(false).build();
        Branch szegedCashier2 = Branch.builder().id(UUID.randomUUID()).code("BR027")
                .region("SZEGED").isActive(true)
                .branchType(hu.puzzleir.valuta.entity.Dictionary.builder()
                        .category("BRANCH_TYPE").code("PENZTAR").build())
                .isVault(false).build();
        // MÁSIK régió pénztára (regionCode='50' Debrecen)
        Branch debrecenCashier = Branch.builder().id(UUID.randomUUID()).code("BR050")
                .region("DEBRECEN").isActive(true)
                .branchType(hu.puzzleir.valuta.entity.Dictionary.builder()
                        .category("BRANCH_TYPE").code("PENZTAR").build())
                .isVault(false).build();
        // Saját régió értéktára (Szeged Ertektar — KI kell hagyni a peerVaults-ból)
        Branch szegedVault = Branch.builder().id(UUID.randomUUID()).code("BR020")
                .region("SZEGED").isActive(true)
                .branchType(hu.puzzleir.valuta.entity.Dictionary.builder()
                        .category("BRANCH_TYPE").code("ERTEKTAR").build())
                .isVault(true).build();
        // Társ régió értéktára (Debrecen Ertektar — peerVaults-ba KELL)
        Branch debrecenVault = Branch.builder().id(UUID.randomUUID()).code("BR060")
                .region("DEBRECEN").isActive(true)
                .branchType(hu.puzzleir.valuta.entity.Dictionary.builder()
                        .category("BRANCH_TYPE").code("ERTEKTAR").build())
                .isVault(true).build();

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            su.when(SecurityUtils::getCurrentBranchIdOrNull).thenReturn(ownBranchId);

            // FOERTEKTAR-nak null vault-scope (nincs ROLE_ERTEKTAR authority)
            when(accessScopeService.vaultRegionBranchScopeOrNull()).thenReturn(null);
            // Helga branch lookup: Tisza Sarok regionCode='20'
            when(branchRepository.findById(ownBranchId)).thenReturn(Optional.of(ownBranch));

            when(branchRepository.findByCompanyIdAndIsActiveTrue(COMPANY_ID))
                    .thenReturn(List.of(szegedCashier1, szegedCashier2, debrecenCashier, szegedVault, debrecenVault));
            when(branchRepository.findByCompanyIdAndIsVaultTrueAndIsActiveTrue(COMPANY_ID))
                    .thenReturn(List.of(szegedVault, debrecenVault));
            when(branchRepository.findByCompanyIdAndBranchTypeCode(COMPANY_ID, "VAULT_COUNTERPARTY"))
                    .thenReturn(List.of());
            when(branchMapper.toDto(any())).thenAnswer(inv -> {
                Branch b = inv.getArgument(0);
                return hu.puzzleir.valuta.dto.BranchDto.builder().code(b.getCode()).build();
            });

            hu.puzzleir.valuta.dto.VaultCounterpartiesDto result = service.findVaultCounterparties();

            // territorialCashiers: SZEGED régió pénztárai (regionCode='20') — NEM Debrecen
            assertThat(result.getTerritorialCashiers()).extracting("code")
                    .containsExactlyInAnyOrder("BR026", "BR027");
            // peerVaults: a Szeged Ertektar (BR020) KIHAGYVA — csak Debrecen Ertektar (BR060)
            assertThat(result.getPeerVaults()).extracting("code")
                    .containsExactly("BR060");
        }
    }

    @Test
    @DisplayName("findVaultCounterparties — inaktív VAULT_COUNTERPARTY kiszűrve")
    void testFindVaultCounterpartiesFiltersInactiveCounterparties() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            su.when(SecurityUtils::getCurrentBranchIdOrNull).thenReturn(null);

            Branch activePrb = branchWith("PRB", "VAULT_COUNTERPARTY", false, true);
            Branch inactiveMnb = branchWith("MNB", "VAULT_COUNTERPARTY", false, false);
            when(accessScopeService.vaultRegionBranchScopeOrNull()).thenReturn(null);
            when(branchRepository.findByCompanyIdAndIsActiveTrue(COMPANY_ID)).thenReturn(List.of());
            when(branchRepository.findByCompanyIdAndIsVaultTrueAndIsActiveTrue(COMPANY_ID)).thenReturn(List.of());
            when(branchRepository.findByCompanyIdAndBranchTypeCode(COMPANY_ID, "VAULT_COUNTERPARTY")).thenReturn(
                    List.of(activePrb, inactiveMnb));
            when(branchMapper.toDto(any())).thenAnswer(inv -> {
                Branch b = inv.getArgument(0);
                return hu.puzzleir.valuta.dto.BranchDto.builder().code(b.getCode()).build();
            });

            hu.puzzleir.valuta.dto.VaultCounterpartiesDto result = service.findVaultCounterparties();

            assertThat(result.getFixedCounterparties()).hasSize(1);
            assertThat(result.getFixedCounterparties().getFirst().getCode()).isEqualTo("PRB");
        }
    }

    @Test
    @DisplayName("createSimpleCashier — ismeretlen régió: ResourceNotFoundException (nincs save)")
    void testCreateSimpleCashierRejectsUnknownRegion() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            lenient().when(branchRepository.existsByCode("BR999")).thenReturn(false);
            when(dictionaryRepository.findByCategoryAndCode("REGION", "MARS"))
                    .thenReturn(Optional.empty());

            assertThatThrownBy(() -> service.createSimpleCashier(simpleDto("MARS")))
                    .isInstanceOf(ResourceNotFoundException.class)
                    .hasMessageContaining("Ismeretlen régió kód");
            verify(branchRepository, never()).save(any());
        }
    }

    @Test
    @DisplayName("Pénztár Törzs (V293): create átviszi a short_name + szolgáltatás-flageket az entitásra")
    void testCreatePersistsPenztarTorzsFields() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            UUID branchTypeId = UUID.randomUUID();
            UUID countryId = UUID.randomUUID();
            UUID statusId = UUID.randomUUID();
            CreateBranchDto dto = CreateBranchDto.builder()
                    .code("PT01").companyId(COMPANY_ID)
                    .branchTypeId(branchTypeId).countryId(countryId).branchStatusId(statusId)
                    .name("Pénztár Törzs Teszt").address("Teszt utca 1.").city("Budapest").zipCode("1011")
                    .bankCode("PT01").openingDate(LocalDate.now())
                    .shortName("PT Teszt").hasAfa(true).hasWu(true).hasMg(false).hasPos(true)
                    .closedSaturday(false).closedSunday(true)
                    .build();
            when(branchRepository.existsByCompanyIdAndCode(COMPANY_ID, "PT01")).thenReturn(false);
            when(dictionaryRepository.findById(branchTypeId))
                    .thenReturn(Optional.of(Dictionary.builder().code("KOZPONT").build()));
            when(dictionaryRepository.findById(countryId))
                    .thenReturn(Optional.of(Dictionary.builder().code("HU").build()));
            when(dictionaryRepository.findById(statusId))
                    .thenReturn(Optional.of(Dictionary.builder().code("ACTIVE").build()));
            when(companyRepository.findById(COMPANY_ID))
                    .thenReturn(Optional.of(Company.builder().id(COMPANY_ID).build()));
            when(branchRepository.save(any(Branch.class))).thenAnswer(inv -> inv.getArgument(0));
            when(branchMapper.toDto(any())).thenReturn(BranchDto.builder().build());

            service.create(dto);

            ArgumentCaptor<Branch> captor = ArgumentCaptor.forClass(Branch.class);
            verify(branchRepository).save(captor.capture());
            Branch saved = captor.getValue();
            assertThat(saved.getShortName()).isEqualTo("PT Teszt");
            assertThat(saved.getHasAfa()).isTrue();
            assertThat(saved.getHasWu()).isTrue();
            assertThat(saved.getHasMg()).isFalse();
            assertThat(saved.getHasPos()).isTrue();
            assertThat(saved.getClosedSaturday()).isFalse();
            assertThat(saved.getClosedSunday()).isTrue();
        }
    }

    @Test
    @DisplayName("Pénztár Törzs (V293): create flag nélkül → entity FALSE default (null nem írja felül)")
    void testCreateWithoutFlags_defaultsFalse() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            UUID branchTypeId = UUID.randomUUID();
            UUID countryId = UUID.randomUUID();
            UUID statusId = UUID.randomUUID();
            CreateBranchDto dto = CreateBranchDto.builder()
                    .code("PT02").companyId(COMPANY_ID)
                    .branchTypeId(branchTypeId).countryId(countryId).branchStatusId(statusId)
                    .name("Flag nélküli").address("Teszt utca 2.").city("Budapest").zipCode("1011")
                    .bankCode("PT02").openingDate(LocalDate.now())
                    .build();
            when(branchRepository.existsByCompanyIdAndCode(COMPANY_ID, "PT02")).thenReturn(false);
            when(dictionaryRepository.findById(branchTypeId))
                    .thenReturn(Optional.of(Dictionary.builder().code("KOZPONT").build()));
            when(dictionaryRepository.findById(countryId))
                    .thenReturn(Optional.of(Dictionary.builder().code("HU").build()));
            when(dictionaryRepository.findById(statusId))
                    .thenReturn(Optional.of(Dictionary.builder().code("ACTIVE").build()));
            when(companyRepository.findById(COMPANY_ID))
                    .thenReturn(Optional.of(Company.builder().id(COMPANY_ID).build()));
            when(branchRepository.save(any(Branch.class))).thenAnswer(inv -> inv.getArgument(0));
            when(branchMapper.toDto(any())).thenReturn(BranchDto.builder().build());

            service.create(dto);

            ArgumentCaptor<Branch> captor = ArgumentCaptor.forClass(Branch.class);
            verify(branchRepository).save(captor.capture());
            Branch saved = captor.getValue();
            assertThat(saved.getHasAfa()).isFalse();
            assertThat(saved.getHasWu()).isFalse();
            assertThat(saved.getClosedSunday()).isFalse();
            assertThat(saved.getShortName()).isNull();
        }
    }

    @Test
    @DisplayName("Pénztár Törzs (V293): update partial — csak a megadott flageket írja, a többit változatlan hagyja")
    void testUpdatePartialPenztarTorzsFields() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            Branch existing = Branch.builder().id(BRANCH_ID)
                    .company(Company.builder().id(COMPANY_ID).build())
                    .hasAfa(false).hasWu(true).hasMg(false).hasPos(false)
                    .closedSaturday(false).closedSunday(false)
                    .build();
            when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(existing));
            when(branchRepository.save(any(Branch.class))).thenAnswer(inv -> inv.getArgument(0));
            when(branchMapper.toDto(any())).thenReturn(BranchDto.builder().build());

            UpdateBranchDto dto = new UpdateBranchDto();
            dto.setShortName("Rövid");
            dto.setHasAfa(true);          // false → true
            dto.setClosedSunday(true);    // false → true
            // hasWu NINCS megadva → marad true (változatlan)

            service.update(BRANCH_ID, dto);

            ArgumentCaptor<Branch> captor = ArgumentCaptor.forClass(Branch.class);
            verify(branchRepository).save(captor.capture());
            Branch saved = captor.getValue();
            assertThat(saved.getShortName()).isEqualTo("Rövid");
            assertThat(saved.getHasAfa()).isTrue();        // felülírva
            assertThat(saved.getClosedSunday()).isTrue();  // felülírva
            assertThat(saved.getHasWu()).isTrue();         // VÁLTOZATLAN (nem volt a DTO-ban)
            assertThat(saved.getHasMg()).isFalse();        // változatlan
        }
    }

    @Test
    @DisplayName("FK-025 Codex P2: üres string = explicit törlés — phone/email/shortName→null, city/zip/bankCode→üres")
    void testUpdate_blankOptionalFields_clearStoredValues() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            Branch existing = Branch.builder().id(BRANCH_ID)
                    .company(Company.builder().id(COMPANY_ID).build())
                    .code("BR100").name("Iroda").address("6720 Szeged, Régi utca 1.")
                    .phone("+36301234567").email("regi@example.hu").shortName("Rövid")
                    .city("Szeged").zipCode("6720").bankCode("210")
                    .build();
            when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(existing));
            when(branchRepository.save(any(Branch.class))).thenAnswer(inv -> inv.getArgument(0));
            when(branchMapper.toDto(any())).thenReturn(BranchDto.builder().build());

            // A FE teljes-form: az üres mező a felhasználó törlési szándéka (setter-út = Jackson-út).
            UpdateBranchDto dto = new UpdateBranchDto();
            dto.setPhone("");
            dto.setEmail("   ");
            dto.setShortName("");
            dto.setCity("");
            dto.setZipCode("");
            dto.setBankCode("");

            service.update(BRANCH_ID, dto);

            ArgumentCaptor<Branch> captor = ArgumentCaptor.forClass(Branch.class);
            verify(branchRepository).save(captor.capture());
            Branch saved = captor.getValue();
            assertThat(saved.getPhone()).isNull();         // nullable oszlop → null
            assertThat(saved.getEmail()).isNull();
            assertThat(saved.getShortName()).isNull();
            assertThat(saved.getCity()).isEmpty();         // NOT NULL oszlop → ""
            assertThat(saved.getZipCode()).isEmpty();
            assertThat(saved.getBankCode()).isEmpty();
        }
    }

    // ============================================================
    // FK-022 — Iroda adatainak szerkesztése (update audit + régió + típus + státusz)
    // ============================================================

    private Branch existingEditableBranch() {
        return Branch.builder().id(BRANCH_ID)
                .company(Company.builder().id(COMPANY_ID).build())
                .code("BR100").name("Régi Név").address("6720 Szeged, Régi utca 1.")
                .isActive(true).isVault(false)
                .hasAfa(false).hasWu(false).hasMg(false).hasPos(false)
                .closedSaturday(false).closedSunday(false)
                .build();
    }

    /** A mapper a mindenkori entity-állapotból épít DTO-t — így a before/after pillanatkép eltér. */
    private void stubMapperFromEntityState() {
        lenient().when(branchMapper.toDto(any(Branch.class))).thenAnswer(inv -> {
            Branch b = inv.getArgument(0);
            return BranchDto.builder().id(b.getId()).code(b.getCode()).name(b.getName())
                    .isActive(b.getIsActive()).isVault(b.getIsVault()).build();
        });
    }

    private void stubJsonFromDtoName() throws Exception {
        lenient().when(objectMapper.writeValueAsString(any()))
                .thenAnswer(inv -> "JSON:" + ((BranchDto) inv.getArgument(0)).getName()
                        + ":aktiv=" + ((BranchDto) inv.getArgument(0)).getIsActive());
    }

    @Test
    @DisplayName("FK-022 FR-7: update — audit log BRANCH_UPDATE before/after értékkel (régi és új állapot)")
    void testUpdateWritesAuditLogWithBeforeAndAfter() throws Exception {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            su.when(SecurityUtils::getCurrentWorkerId).thenReturn(42L);
            su.when(SecurityUtils::getCurrentWorkerCode).thenReturn("FOERT01");
            when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(existingEditableBranch()));
            when(branchRepository.save(any(Branch.class))).thenAnswer(inv -> inv.getArgument(0));
            stubMapperFromEntityState();
            stubJsonFromDtoName();

            UpdateBranchDto dto = new UpdateBranchDto();
            dto.setName("Új Név");

            service.update(BRANCH_ID, dto);

            verify(auditLogService).logWithDetails(
                    eq("BRANCH_UPDATE"), eq("BRANCH"), eq(BRANCH_ID.toString()),
                    eq("42"), eq("FOERT01"),
                    eq(BRANCH_ID.toString()), eq("Új Név"),
                    eq("JSON:Régi Név:aktiv=true"),   // oldValue — a mutáció ELŐTTI állapot
                    eq("JSON:Új Név:aktiv=true"),     // newValue — a mentett állapot
                    isNull(), isNull());
        }
    }

    @Test
    @DisplayName("FK-022 FR-11: update isActive=false (tartósan zárva) → az entity inaktív + audit tükrözi")
    void testUpdateTartosanZarvaSetsInactive() throws Exception {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(existingEditableBranch()));
            when(branchRepository.save(any(Branch.class))).thenAnswer(inv -> inv.getArgument(0));
            stubMapperFromEntityState();
            stubJsonFromDtoName();

            UpdateBranchDto dto = new UpdateBranchDto();
            dto.setIsActive(false);

            service.update(BRANCH_ID, dto);

            ArgumentCaptor<Branch> captor = ArgumentCaptor.forClass(Branch.class);
            verify(branchRepository).save(captor.capture());
            assertThat(captor.getValue().getIsActive()).isFalse();
            verify(auditLogService).logWithDetails(any(), any(), any(), any(), any(), any(), any(),
                    eq("JSON:Régi Név:aktiv=true"), eq("JSON:Régi Név:aktiv=false"), any(), any());
        }
    }

    @Test
    @DisplayName("FK-022 FR-5: update isActive=true (inaktív → aktív visszakapcsolás)")
    void testUpdateReactivatesInactiveBranch() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            Branch inactive = existingEditableBranch();
            inactive.setIsActive(false);
            when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(inactive));
            when(branchRepository.save(any(Branch.class))).thenAnswer(inv -> inv.getArgument(0));
            stubMapperFromEntityState();

            UpdateBranchDto dto = new UpdateBranchDto();
            dto.setIsActive(true);

            service.update(BRANCH_ID, dto);

            ArgumentCaptor<Branch> captor = ArgumentCaptor.forClass(Branch.class);
            verify(branchRepository).save(captor.capture());
            assertThat(captor.getValue().getIsActive()).isTrue();
        }
    }

    @Test
    @DisplayName("FK-022 FR-10: update üres név → ValidationException, nincs save, nincs audit")
    void testUpdateRejectsBlankName() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(existingEditableBranch()));

            UpdateBranchDto dto = new UpdateBranchDto();
            dto.setName("   ");

            assertThatThrownBy(() -> service.update(BRANCH_ID, dto))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("név nem lehet üres");
            verify(branchRepository, never()).save(any());
            verifyNoInteractions(auditLogService);
        }
    }

    @Test
    @DisplayName("FK-022: update regionCode=SZEGED → KESZLEX '20' + szöveges region frissül")
    void testUpdateRegionMapsToKeszlexCode() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            stubDictionaries();
            when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(existingEditableBranch()));
            when(branchRepository.save(any(Branch.class))).thenAnswer(inv -> inv.getArgument(0));
            stubMapperFromEntityState();

            UpdateBranchDto dto = new UpdateBranchDto();
            dto.setRegionCode("SZEGED");

            service.update(BRANCH_ID, dto);

            ArgumentCaptor<Branch> captor = ArgumentCaptor.forClass(Branch.class);
            verify(branchRepository).save(captor.capture());
            assertThat(captor.getValue().getRegionCode()).isEqualTo("20");
            assertThat(captor.getValue().getRegion()).isEqualTo("SZEGED");
        }
    }

    @Test
    @DisplayName("FK-022: update ismeretlen régió → ResourceNotFoundException, nincs save")
    void testUpdateRejectsUnknownRegion() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(existingEditableBranch()));
            when(dictionaryRepository.findByCategoryAndCode("REGION", "MARS")).thenReturn(Optional.empty());

            UpdateBranchDto dto = new UpdateBranchDto();
            dto.setRegionCode("MARS");

            assertThatThrownBy(() -> service.update(BRANCH_ID, dto))
                    .isInstanceOf(ResourceNotFoundException.class)
                    .hasMessageContaining("Ismeretlen régió kód");
            verify(branchRepository, never()).save(any());
        }
    }

    @Test
    @DisplayName("FK-022: update dict-ben létező, de KESZLEX-mappolatlan régió (IRODA) → ValidationException")
    void testUpdateRejectsUnmappedRegion() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            stubDictionaries();
            when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(existingEditableBranch()));

            UpdateBranchDto dto = new UpdateBranchDto();
            dto.setRegionCode("IRODA");

            assertThatThrownBy(() -> service.update(BRANCH_ID, dto))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("nincs KESZLEX-területi-kód");
            verify(branchRepository, never()).save(any());
        }
    }

    @Test
    @DisplayName("FK-022: update isVault=true → az iroda típusa Értéktárra vált")
    void testUpdateIsVaultFlag() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(existingEditableBranch()));
            when(branchRepository.save(any(Branch.class))).thenAnswer(inv -> inv.getArgument(0));
            stubMapperFromEntityState();

            UpdateBranchDto dto = new UpdateBranchDto();
            dto.setIsVault(true);

            service.update(BRANCH_ID, dto);

            ArgumentCaptor<Branch> captor = ArgumentCaptor.forClass(Branch.class);
            verify(branchRepository).save(captor.capture());
            assertThat(captor.getValue().getIsVault()).isTrue();
        }
    }

    @Test
    @DisplayName("FK-022 FR-3: az UpdateBranchDto-ban NINCS code mező — a pénztár kódja nem szerkeszthető")
    void testUpdateDtoHasNoCodeField() {
        assertThat(UpdateBranchDto.class.getDeclaredFields())
                .extracting(java.lang.reflect.Field::getName)
                .doesNotContain("code");
    }
}
