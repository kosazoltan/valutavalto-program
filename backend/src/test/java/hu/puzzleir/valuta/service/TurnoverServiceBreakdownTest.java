package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.turnover.TurnoverReportDto;
import hu.puzzleir.valuta.repository.TransactionRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;

/**
 * TurnoverService byCurrency / byWorker breakdown + sztornó kizárás tesztek.
 */
@ExtendWith(MockitoExtension.class)
class TurnoverServiceBreakdownTest {

    @InjectMocks
    private TurnoverService service;

    @Mock
    private TransactionRepository transactionRepository;

    private static final UUID BRANCH_ID = UUID.randomUUID();
    private static final LocalDate TODAY = LocalDate.of(2026, 3, 16);

    // =========================================================================
    // byCurrency lista nem üres, ha van adat
    // =========================================================================

    @Test
    @DisplayName("getDailyTurnover → byCurrency lista nem üres, ha vannak tranzakciók")
    void testByCurrencyNotEmpty() {
        // Főösszegek — sztornó-kizáró metódusok
        when(transactionRepository.sumHufAmountByBranchAndTypeAndPeriodExcludingReversals(
                eq(BRANCH_ID), eq("BUY"), any(LocalDate.class), any(LocalDate.class)))
            .thenReturn(new BigDecimal("1000000"));
        when(transactionRepository.sumHufAmountByBranchAndTypeAndPeriodExcludingReversals(
                eq(BRANCH_ID), eq("SELL"), any(LocalDate.class), any(LocalDate.class)))
            .thenReturn(new BigDecimal("1200000"));
        when(transactionRepository.sumFeeByBranchAndPeriodExcludingReversals(
                eq(BRANCH_ID), any(LocalDate.class), any(LocalDate.class)))
            .thenReturn(new BigDecimal("5000"));

        // Valuta bontás: EUR BUY és EUR SELL
        List<Object[]> currencyRows = new ArrayList<>();
        currencyRows.add(new Object[]{"EUR", "BUY",  new BigDecimal("2000"), new BigDecimal("800000"),  new BigDecimal("2000"), 4L});
        currencyRows.add(new Object[]{"EUR", "SELL", new BigDecimal("1500"), new BigDecimal("600000"),  new BigDecimal("1500"), 3L});
        currencyRows.add(new Object[]{"USD", "BUY",  new BigDecimal("500"),  new BigDecimal("200000"),  new BigDecimal("500"),  2L});
        when(transactionRepository.groupByCurrencyAndTypeForBranch(
                eq(BRANCH_ID), any(LocalDate.class), any(LocalDate.class)))
            .thenReturn(currencyRows);

        // Pénztáros bontás
        List<Object[]> workerRows = new ArrayList<>();
        workerRows.add(new Object[]{1L, "Kiss Péter", new BigDecimal("1000000"), new BigDecimal("3000"), 7L});
        when(transactionRepository.groupByWorkerForBranch(
                eq(BRANCH_ID), any(LocalDate.class), any(LocalDate.class)))
            .thenReturn(workerRows);

        TurnoverReportDto report = service.getDailyTurnover(BRANCH_ID, TODAY);

        // byCurrency
        assertThat(report.getByCurrency()).isNotEmpty();
        assertThat(report.getByCurrency()).hasSize(2); // EUR és USD
        TurnoverReportDto.CurrencyTurnoverDto eur = report.getByCurrency().stream()
            .filter(c -> "EUR".equals(c.getCurrencyCode()))
            .findFirst().orElseThrow();
        assertThat(eur.getBuyVolume()).isEqualByComparingTo("2000");
        assertThat(eur.getSellVolume()).isEqualByComparingTo("1500");
        assertThat(eur.getTransactionCount()).isEqualTo(7); // 4 + 3

        // byWorker
        assertThat(report.getByWorker()).isNotEmpty();
        assertThat(report.getByWorker()).hasSize(1);
        assertThat(report.getByWorker().get(0).getWorkerName()).isEqualTo("Kiss Péter");
        assertThat(report.getByWorker().get(0).getFee()).isEqualByComparingTo("3000");
    }

    // =========================================================================
    // REVERSED tranzakciók ki vannak zárva a főösszegekből
    // =========================================================================

    @Test
    @DisplayName("getDailyTurnover → sztornók kizárva: a storno-kizáró metódus eredménye jelenik meg")
    void testReversedTransactionsExcludedFromTotals() {
        // Sztornó-kizáró metódusok kisebb összeget adnak vissza
        BigDecimal buyExclReversals = new BigDecimal("800000");
        BigDecimal sellExclReversals = new BigDecimal("950000");
        BigDecimal feeExclReversals = new BigDecimal("4000");

        when(transactionRepository.sumHufAmountByBranchAndTypeAndPeriodExcludingReversals(
                eq(BRANCH_ID), eq("BUY"), any(LocalDate.class), any(LocalDate.class)))
            .thenReturn(buyExclReversals);
        when(transactionRepository.sumHufAmountByBranchAndTypeAndPeriodExcludingReversals(
                eq(BRANCH_ID), eq("SELL"), any(LocalDate.class), any(LocalDate.class)))
            .thenReturn(sellExclReversals);
        when(transactionRepository.sumFeeByBranchAndPeriodExcludingReversals(
                eq(BRANCH_ID), any(LocalDate.class), any(LocalDate.class)))
            .thenReturn(feeExclReversals);

        when(transactionRepository.groupByCurrencyAndTypeForBranch(
                eq(BRANCH_ID), any(LocalDate.class), any(LocalDate.class)))
            .thenReturn(new ArrayList<>());
        when(transactionRepository.groupByWorkerForBranch(
                eq(BRANCH_ID), any(LocalDate.class), any(LocalDate.class)))
            .thenReturn(new ArrayList<>());

        TurnoverReportDto report = service.getDailyTurnover(BRANCH_ID, TODAY);

        // A riport a sztornó-kizáró metódusok eredményét tükrözi
        assertThat(report.getTotalBuy()).isEqualByComparingTo(buyExclReversals);
        assertThat(report.getTotalSell()).isEqualByComparingTo(sellExclReversals);
        assertThat(report.getFees()).isEqualByComparingTo(feeExclReversals);
        assertThat(report.getSpread()).isEqualByComparingTo(
            sellExclReversals.subtract(buyExclReversals));
        assertThat(report.getNetProfit()).isEqualByComparingTo(
            sellExclReversals.subtract(buyExclReversals).add(feeExclReversals));
    }

    // =========================================================================
    // Üres adatbázis → üres listák, nulla összegek (NPE nincs)
    // =========================================================================

    @Test
    @DisplayName("getDailyTurnover → üres DB: üres listák, nulla összegek")
    void testEmptyDatabase() {
        when(transactionRepository.sumHufAmountByBranchAndTypeAndPeriodExcludingReversals(
                any(), any(), any(LocalDate.class), any(LocalDate.class)))
            .thenReturn(null);
        when(transactionRepository.sumFeeByBranchAndPeriodExcludingReversals(
                any(), any(LocalDate.class), any(LocalDate.class)))
            .thenReturn(null);
        when(transactionRepository.groupByCurrencyAndTypeForBranch(
                any(), any(LocalDate.class), any(LocalDate.class)))
            .thenReturn(new ArrayList<>());
        when(transactionRepository.groupByWorkerForBranch(
                any(), any(LocalDate.class), any(LocalDate.class)))
            .thenReturn(new ArrayList<>());

        TurnoverReportDto report = service.getDailyTurnover(BRANCH_ID, TODAY);

        assertThat(report.getTotalBuy()).isEqualByComparingTo(BigDecimal.ZERO);
        assertThat(report.getTotalSell()).isEqualByComparingTo(BigDecimal.ZERO);
        assertThat(report.getByCurrency()).isEmpty();
        assertThat(report.getByWorker()).isEmpty();
    }
}
