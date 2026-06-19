package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.BanknoteInventoryRepository;
import hu.puzzleir.valuta.repository.BranchRepository;
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

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class BanknoteInventoryServiceTest {

    private static final UUID COMPANY_ID = UUID.fromString("11111111-1111-1111-1111-111111111111");
    private static final UUID BRANCH_ID = UUID.fromString("22222222-2222-2222-2222-222222222222");

    @Mock
    private BanknoteInventoryRepository repository;

    @Mock
    private BranchRepository branchRepository;

    @InjectMocks
    private BanknoteInventoryService service;

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

    @Test
    @DisplayName("currency szurt olvasas idegen branchre -> ResourceNotFoundException")
    void getByBranchAndCurrency_otherCompanyBranch_throws() {
        when(branchRepository.existsByIdAndCompanyId(BRANCH_ID, COMPANY_ID)).thenReturn(false);

        assertThatThrownBy(() -> service.getByBranchAndCurrency(BRANCH_ID, "EUR"))
                .isInstanceOf(ResourceNotFoundException.class);

        verify(repository, never()).findByBranchIdAndCurrencyCode(BRANCH_ID, "EUR");
    }

    @Test
    @DisplayName("low-stock olvasas idegen branchre -> ResourceNotFoundException")
    void getLowStock_otherCompanyBranch_throws() {
        when(branchRepository.existsByIdAndCompanyId(BRANCH_ID, COMPANY_ID)).thenReturn(false);

        assertThatThrownBy(() -> service.getLowStock(BRANCH_ID))
                .isInstanceOf(ResourceNotFoundException.class);

        verify(repository, never()).findLowStock(BRANCH_ID);
    }

    @Test
    @DisplayName("over-stock olvasas idegen branchre -> ResourceNotFoundException")
    void getOverStock_otherCompanyBranch_throws() {
        when(branchRepository.existsByIdAndCompanyId(BRANCH_ID, COMPANY_ID)).thenReturn(false);

        assertThatThrownBy(() -> service.getOverStock(BRANCH_ID))
                .isInstanceOf(ResourceNotFoundException.class);

        verify(repository, never()).findOverStock(BRANCH_ID);
    }
}
