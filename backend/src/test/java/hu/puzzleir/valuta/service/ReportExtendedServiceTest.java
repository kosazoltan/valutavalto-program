package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CashBalanceRepository;
import hu.puzzleir.valuta.repository.DenominationRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.repository.TransferRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.Arguments;
import org.junit.jupiter.params.provider.MethodSource;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.function.BiConsumer;
import java.util.stream.Stream;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ReportExtendedServiceTest {

    @InjectMocks private ReportExtendedService service;
    @Mock private TransactionRepository transactionRepository;
    @Mock private CashBalanceRepository cashBalanceRepository;
    @Mock private TransferRepository transferRepository;
    @Mock private DenominationRepository denominationRepository;
    @Mock private BranchRepository branchRepository;

    private static final UUID BRANCH_ID = UUID.randomUUID();
    private static final UUID FOREIGN_BRANCH_ID = UUID.randomUUID();
    private static final UUID COMPANY_ID = UUID.randomUUID();
    private static final LocalDate DAY = LocalDate.of(2026, 7, 1);

    // ============ CROSS-TENANT GUARD — mind a 11 belépő ============

    static Stream<Arguments> guardedInvocations() {
        return Stream.of(
                inv("getTransactionList", (s, b) -> s.getTransactionList(b, DAY, DAY)),
                inv("getReceiptList", (s, b) -> s.getReceiptList(b, DAY, DAY)),
                inv("getFeeSummary", (s, b) -> s.getFeeSummary(b, DAY, DAY)),
                inv("getMonthlyInventory", (s, b) -> s.getMonthlyInventory(2026, 7, b)),
                inv("getMonthlyTurnover", (s, b) -> s.getMonthlyTurnover(2026, 7, b)),
                inv("getMonthlyTransfers", (s, b) -> s.getMonthlyTransfers(2026, 7, b)),
                inv("getHandlingCost", (s, b) -> s.getHandlingCost(b, DAY, DAY)),
                inv("getDailyCashDesk", (s, b) -> s.getDailyCashDesk(b, DAY)),
                inv("getCurrentCashDeskStatus", (s, b) -> s.getCurrentCashDeskStatus(b)),
                inv("getSuspiciousTransactions", (s, b) -> s.getSuspiciousTransactions(b, DAY, DAY)),
                inv("getCardTransactionFees", (s, b) -> s.getCardTransactionFees(b, DAY, DAY)));
    }

    private static Arguments inv(String name, BiConsumer<ReportExtendedService, UUID> call) {
        return Arguments.of(name, call);
    }

    @ParameterizedTest(name = "{0} — idegen branchId: guard fail-closed, adat-repo érintetlen")
    @MethodSource("guardedInvocations")
    void crossTenantBranch_rejectedFailClosed(String name, BiConsumer<ReportExtendedService, UUID> call) {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(branchRepository.existsByIdAndCompanyId(FOREIGN_BRANCH_ID, COMPANY_ID)).thenReturn(false);

            assertThatThrownBy(() -> call.accept(service, FOREIGN_BRANCH_ID))
                    .isInstanceOf(ResourceNotFoundException.class)
                    .hasMessageContaining(FOREIGN_BRANCH_ID.toString());

            verifyNoInteractions(transactionRepository, cashBalanceRepository,
                    transferRepository, denominationRepository);
        }
    }

    // ============ JWT-FALLBACK ZÖLD ÚT (pénztári fő útvonal) ============

    @Test
    @DisplayName("getTransactionList — null branchId: JWT-branch fallback, branchRepository-hívás NÉLKÜL")
    void nullBranchId_fallsBackToJwtBranch_withoutGuardLookup() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);
            when(transactionRepository.findByBranchAndDate(eq(BRANCH_ID), any(LocalDate.class)))
                    .thenReturn(List.of());

            Map<String, Object> result = service.getTransactionList(null, DAY, DAY);

            assertThat(result).containsKeys("transactions", "summary", "generatedAt");
            verify(transactionRepository).findByBranchAndDate(BRANCH_ID, DAY);
            verifyNoInteractions(branchRepository);
        }
    }

    // ============ SAJÁT CÉG MÁSIK FIÓKJA — legit supervisor-út ============

    @Test
    @DisplayName("getTransactionList — saját cégbeli explicit branchId: elfogadva, a KÉRT branch kérdeződik le")
    void ownCompanyExplicitBranch_accepted_queriesRequestedBranch() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(branchRepository.existsByIdAndCompanyId(BRANCH_ID, COMPANY_ID)).thenReturn(true);
            when(transactionRepository.findByBranchAndDate(eq(BRANCH_ID), any(LocalDate.class)))
                    .thenReturn(List.of());

            service.getTransactionList(BRANCH_ID, DAY, DAY);

            verify(transactionRepository).findByBranchAndDate(BRANCH_ID, DAY);
            su.verify(SecurityUtils::getCurrentBranchId, never());
        }
    }
}
