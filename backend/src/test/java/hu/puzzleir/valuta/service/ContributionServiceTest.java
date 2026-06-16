package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Contribution;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.ContributionRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDate;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.when;

/**
 * ContributionService multi-tenant IDOR guard tesztek (audit 2026-06-15, FINDING #9).
 */
@ExtendWith(MockitoExtension.class)
class ContributionServiceTest {

    private static final UUID COMPANY_ID = UUID.randomUUID();
    private static final UUID BRANCH_ID = UUID.randomUUID();

    @Mock private ContributionRepository repository;
    @Mock private TransactionRepository transactionRepository;
    @Mock private SystemParameterService systemParameterService;
    @Mock private BranchRepository branchRepository;
    @InjectMocks private ContributionService service;

    private MockedStatic<SecurityUtils> securityUtilsMock;

    @BeforeEach
    void setUp() {
        securityUtilsMock = mockStatic(SecurityUtils.class);
        securityUtilsMock.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
    }

    @AfterEach
    void tearDown() {
        if (securityUtilsMock != null) securityUtilsMock.close();
    }

    private Contribution contribution(UUID branchId) {
        return Contribution.builder()
                .id(UUID.randomUUID()).contributionType("MNB_SUPERVISORY_FEE").branchId(branchId)
                .periodStart(LocalDate.of(2026, 5, 1)).periodEnd(LocalDate.of(2026, 5, 31))
                .build();
    }

    @Test
    @DisplayName("findById: saját cég branch-éhez tartozó hozzájárulás → visszaadja")
    void findById_owned_returns() {
        Contribution c = contribution(BRANCH_ID);
        when(repository.findById(c.getId())).thenReturn(Optional.of(c));
        when(branchRepository.existsByIdAndCompanyId(BRANCH_ID, COMPANY_ID)).thenReturn(true);

        assertThat(service.findById(c.getId())).isSameAs(c);
    }

    @Test
    @DisplayName("findById: más cég branch-éhez tartozó hozzájárulás → ResourceNotFoundException (404)")
    void findById_crossTenant_throws() {
        Contribution c = contribution(BRANCH_ID);
        when(repository.findById(c.getId())).thenReturn(Optional.of(c));
        when(branchRepository.existsByIdAndCompanyId(BRANCH_ID, COMPANY_ID)).thenReturn(false);

        assertThatThrownBy(() -> service.findById(c.getId()))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("Contribution not found");
    }

    @Test
    @DisplayName("findByPeriod: idegen cég branchId paraméterrel → ResourceNotFoundException")
    void findByPeriod_crossTenantBranch_throws() {
        when(branchRepository.existsByIdAndCompanyId(BRANCH_ID, COMPANY_ID)).thenReturn(false);

        assertThatThrownBy(() -> service.findByPeriod(BRANCH_ID, LocalDate.of(2026, 5, 1), LocalDate.of(2026, 5, 31)))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("Branch not found");
    }
}
