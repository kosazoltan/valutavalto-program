package hu.puzzleir.valuta.service;

import com.puzzleir.backend.entity.Branch;
import com.puzzleir.backend.repository.BranchRepository;
import hu.puzzleir.valuta.dto.dashboard.DashboardSummaryDto;
import hu.puzzleir.valuta.entity.Notification;
import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.repository.NotificationRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.*;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * DashboardService UNIT tesztek — Mockito.
 */
@ExtendWith(MockitoExtension.class)
class DashboardServiceTest {

    @InjectMocks
    private DashboardService service;

    @Mock
    private TransactionRepository transactionRepository;

    @Mock
    private BranchRepository branchRepository;

    @Mock
    private NotificationRepository notificationRepository;

    private static final UUID BRANCH_ID = UUID.randomUUID();
    private static final Long WORKER_ID = 42L;

    // =====================================================================
    // getSummary — normál eset
    // =====================================================================
    @Test
    @DisplayName("getSummary → visszaad DashboardSummary-t")
    void testGetSummary() {
        try (MockedStatic<SecurityUtils> secUtils = mockStatic(SecurityUtils.class)) {
            secUtils.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);
            secUtils.when(SecurityUtils::getCurrentWorkerId).thenReturn(WORKER_ID);

            // Mock tranzakciók
            Transaction tx = Transaction.builder()
                    .hufAmount(new BigDecimal("500000"))
                    .build();
            when(transactionRepository.findActiveByBranchAndDate(eq(BRANCH_ID), any(LocalDate.class)))
                    .thenReturn(List.of(tx));

            // Mock aktív irodák
            Branch branch = new Branch();
            branch.setCode("B01");
            branch.setName("Teszt Iroda");
            when(branchRepository.findByIsActiveTrue()).thenReturn(List.of(branch));

            // Mock notifications
            when(notificationRepository.findByUserIdAndIsReadFalseOrderByCreatedAtDesc(anyString()))
                    .thenReturn(Collections.emptyList());

            DashboardSummaryDto result = service.getSummary(BRANCH_ID);

            assertThat(result).isNotNull();
            assertThat(result.getTodayVolume()).isEqualByComparingTo(new BigDecimal("500000"));
            assertThat(result.getActiveBranches()).isEqualTo(1);
            assertThat(result.getAlertCount()).isEqualTo(0);
        }
    }

    // =====================================================================
    // getSummary — üres iroda → 0 forgalom
    // =====================================================================
    @Test
    @DisplayName("getSummary — üres branch → 0 forgalom")
    void testGetSummary_emptyBranch() {
        try (MockedStatic<SecurityUtils> secUtils = mockStatic(SecurityUtils.class)) {
            secUtils.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);
            secUtils.when(SecurityUtils::getCurrentWorkerId).thenReturn(WORKER_ID);

            // Nincs tranzakció
            when(transactionRepository.findActiveByBranchAndDate(eq(BRANCH_ID), any(LocalDate.class)))
                    .thenReturn(Collections.emptyList());

            // Nincs aktív iroda
            when(branchRepository.findByIsActiveTrue()).thenReturn(Collections.emptyList());

            // Nincs notification
            when(notificationRepository.findByUserIdAndIsReadFalseOrderByCreatedAtDesc(anyString()))
                    .thenReturn(Collections.emptyList());

            DashboardSummaryDto result = service.getSummary(BRANCH_ID);

            assertThat(result).isNotNull();
            assertThat(result.getTodayVolume()).isEqualByComparingTo(BigDecimal.ZERO);
            assertThat(result.getActiveBranches()).isEqualTo(0);
            assertThat(result.getOpenTransactions()).isEqualTo(0);
            assertThat(result.getAlertCount()).isEqualTo(0);
            assertThat(result.getRecentTransactions()).isEmpty();
        }
    }
}
