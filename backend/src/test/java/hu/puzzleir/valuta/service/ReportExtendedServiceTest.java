package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.repository.CashBalanceRepository;
import hu.puzzleir.valuta.repository.DenominationRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.repository.TransferRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ReportExtendedServiceTest {

    @InjectMocks private ReportExtendedService service;
    @Mock private TransactionRepository transactionRepository;
    @Mock private CashBalanceRepository cashBalanceRepository;
    @Mock private TransferRepository transferRepository;
    @Mock private DenominationRepository denominationRepository;

    private static final UUID BRANCH_ID = UUID.randomUUID();
    private static final UUID COMPANY_ID = UUID.randomUUID();

    @Test
    @DisplayName("getMonthlyInventory — idegen branchId: JWT-companyId-szűrt lookup üres → üres balances, nincs kivétel")
    void getMonthlyInventory_crossTenantBranch_emptyFailClosed() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(cashBalanceRepository.findByBranchIdAndCompanyId(BRANCH_ID, COMPANY_ID))
                    .thenReturn(List.of());
            when(denominationRepository.findByBranchId(BRANCH_ID)).thenReturn(List.of());

            Map<String, Object> result = service.getMonthlyInventory(2026, 7, BRANCH_ID);

            assertThat((List<?>) result.get("balances")).isEmpty();
            verify(cashBalanceRepository).findByBranchIdAndCompanyId(BRANCH_ID, COMPANY_ID);
        }
    }
}
