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
