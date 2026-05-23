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
}
