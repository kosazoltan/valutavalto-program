package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.entity.TransactionStatus;
import hu.puzzleir.valuta.entity.TransactionType;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.repository.TransferRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.security.WorkerAuthenticationDetails;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class NbReportGeneratorTest {

    @InjectMocks
    private NbReportGenerator generator;

    @Mock private TransactionRepository transactionRepository;
    @Mock private CurrencyRepository currencyRepository;
    @Mock private WorkerRepository workerRepository;
    @Mock private TransferRepository transferRepository;

    private final UUID companyId = UUID.randomUUID();
    private final UUID branchId = UUID.randomUUID();

    @BeforeEach
    void setUpSecurityContext() {
        var auth = new UsernamePasswordAuthenticationToken("P001", null, List.of());
        auth.setDetails(new WorkerAuthenticationDetails(7L, companyId, branchId, "MANAGER"));
        SecurityContextHolder.getContext().setAuthentication(auth);
    }

    @AfterEach
    void clearSecurityContext() {
        SecurityContextHolder.clearContext();
    }

    @Test
    @DisplayName("Pénztáros riport: company-szűrt worker és tranzakciók, kompatibilis mezők és valuta-bontás")
    void generateWorkerPerformanceReport_returnsFrontendCompatibleCurrencyBreakdown() {
        Long workerId = 7L;
        LocalDate start = LocalDate.of(2026, 5, 1);
        LocalDate end = LocalDate.of(2026, 5, 7);
        Currency eur = Currency.builder().code("EUR").name("Euró").build();
        Currency usd = Currency.builder().code("USD").name("Amerikai dollár").build();
        Currency huf = Currency.builder().code("HUF").name("Forint").build();

        when(workerRepository.findByIdAndCompanyId(workerId, companyId))
                .thenReturn(Optional.of(Worker.builder()
                        .id(workerId)
                        .code("P001")
                        .name("Teszt Pénztáros")
                        .build()));
        when(transactionRepository.findByCompanyIdAndWorkerIdAndTransactionDateBetween(companyId, workerId, start, end))
                .thenReturn(List.of(
                        transaction(TransactionType.SELL, usd, "50", "18000", "700"),
                        transaction(TransactionType.BUY, eur, "100", "39000", "500"),
                        transaction(TransactionType.REVERSAL, huf, "0", "0", "0")));

        ReportService.WorkerPerformanceReport report =
                generator.generateWorkerPerformanceReport(workerId, start, end);

        assertThat(report.getTotalTransactionCount()).isEqualTo(2);
        assertThat(report.getTotalTransactions()).isEqualTo(2);
        assertThat(report.getTotalBuyCount()).isEqualTo(1);
        assertThat(report.getBuyTransactions()).isEqualTo(1);
        assertThat(report.getTotalSellCount()).isEqualTo(1);
        assertThat(report.getSellTransactions()).isEqualTo(1);
        assertThat(report.getReversalCount()).isEqualTo(1);
        assertThat(report.getTotalHandlingFees()).isEqualByComparingTo("1200");
        assertThat(report.getAverageDailyTransactions()).isEqualByComparingTo("0.29");
        assertThat(report.getCurrencyTurnovers())
                .extracting(ReportService.CurrencyTurnover::getCurrencyCode)
                .containsExactly("EUR", "USD");
        assertThat(report.getCurrencyTurnovers().get(0).getBuyAmount()).isEqualByComparingTo("100");
        assertThat(report.getCurrencyTurnovers().get(1).getSellAmount()).isEqualByComparingTo("50");

        verify(workerRepository).findByIdAndCompanyId(workerId, companyId);
        verify(transactionRepository)
                .findByCompanyIdAndWorkerIdAndTransactionDateBetween(eq(companyId), eq(workerId), eq(start), eq(end));
    }

    private static Transaction transaction(
            TransactionType type,
            Currency currency,
            String currencyAmount,
            String hufAmount,
            String handlingFee) {
        return Transaction.builder()
                .transactionType(type)
                .status(TransactionStatus.COMPLETED)
                .currency(currency)
                .currencyAmount(new BigDecimal(currencyAmount))
                .hufAmount(new BigDecimal(hufAmount))
                .handlingFee(new BigDecimal(handlingFee))
                .build();
    }
}
