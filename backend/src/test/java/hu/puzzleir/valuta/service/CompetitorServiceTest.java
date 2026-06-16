package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Competitor;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CompetitorRepository;
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

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.when;

/**
 * CompetitorService multi-tenant IDOR guard tesztek (audit 2026-06-15, FINDING #8).
 */
@ExtendWith(MockitoExtension.class)
class CompetitorServiceTest {

    private static final UUID COMPANY_ID = UUID.randomUUID();
    private static final UUID BRANCH_ID = UUID.randomUUID();

    @Mock private CompetitorRepository repository;
    @Mock private BranchRepository branchRepository;
    @InjectMocks private CompetitorService service;

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

    private Competitor competitor(UUID branchId) {
        return Competitor.builder().id(UUID.randomUUID()).name("Rival Kft.").branchId(branchId).isActive(true).build();
    }

    @Test
    @DisplayName("findById: saját cég branch-éhez tartozó versenytárs → visszaadja")
    void findById_owned_returns() {
        Competitor c = competitor(BRANCH_ID);
        when(repository.findById(c.getId())).thenReturn(Optional.of(c));
        when(branchRepository.existsByIdAndCompanyId(BRANCH_ID, COMPANY_ID)).thenReturn(true);

        assertThat(service.findById(c.getId())).isSameAs(c);
    }

    @Test
    @DisplayName("findById: más cég branch-éhez tartozó versenytárs → ResourceNotFoundException (404)")
    void findById_crossTenant_throws() {
        Competitor c = competitor(BRANCH_ID);
        when(repository.findById(c.getId())).thenReturn(Optional.of(c));
        when(branchRepository.existsByIdAndCompanyId(BRANCH_ID, COMPANY_ID)).thenReturn(false);

        assertThatThrownBy(() -> service.findById(c.getId()))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("Competitor not found");
    }

    @Test
    @DisplayName("findAll: csak a hívó cégéhez tartozó branch-ek versenytársai maradnak")
    void findAll_filtersToCurrentCompany() {
        Competitor own = competitor(BRANCH_ID);
        UUID foreignBranch = UUID.randomUUID();
        Competitor foreign = competitor(foreignBranch);
        when(repository.findByIsActiveTrueOrderByNameAsc()).thenReturn(List.of(own, foreign));
        when(branchRepository.existsByIdAndCompanyId(BRANCH_ID, COMPANY_ID)).thenReturn(true);
        when(branchRepository.existsByIdAndCompanyId(foreignBranch, COMPANY_ID)).thenReturn(false);

        assertThat(service.findAll()).containsExactly(own);
    }

    @Test
    @DisplayName("create: idegen cég branch-ére hivatkozó versenytárs → ResourceNotFoundException")
    void create_foreignBranch_throws() {
        Competitor c = competitor(UUID.randomUUID());
        when(branchRepository.existsByIdAndCompanyId(c.getBranchId(), COMPANY_ID)).thenReturn(false);

        assertThatThrownBy(() -> service.create(c))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("Branch not found");
    }
}
