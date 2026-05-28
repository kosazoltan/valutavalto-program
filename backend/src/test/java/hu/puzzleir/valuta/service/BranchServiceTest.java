package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.mapper.BranchMapper;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.repository.DictionaryRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.dto.UpdateBranchDto;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;

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
}
