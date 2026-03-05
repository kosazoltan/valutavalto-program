package hu.puzzleir.valuta.service;

import com.puzzleir.backend.entity.Branch;
import com.puzzleir.backend.repository.BranchRepository;
import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.entity.TransactionStatus;
import hu.puzzleir.valuta.entity.TransactionType;
import hu.puzzleir.valuta.repository.TransactionRepository;
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
 * ProfitCalculationService UNIT tesztek — Mockito.
 *
 * Napi és havi haszon számítás tesztelése.
 * Bevétel = eladási HUF - vételi HUF
 * Nettó haszon = bevétel - kezelési díjak
 */
@ExtendWith(MockitoExtension.class)
class ProfitCalculationServiceTest {

    @InjectMocks
    private ProfitCalculationService service;

    @Mock
    private TransactionRepository transactionRepository;

    @Mock
    private BranchRepository branchRepository;

    private final UUID BRANCH_ID = UUID.randomUUID();

    /**
     * Segéd: tranzakció létrehozás valuta adatokkal.
     */
    private Transaction createTransaction(TransactionType type, BigDecimal hufAmount,
                                           BigDecimal handlingFee, String currencyCode) {
        hu.puzzleir.valuta.entity.Currency currency = hu.puzzleir.valuta.entity.Currency.builder().code(currencyCode).build();

        return Transaction.builder()
                .transactionType(type)
                .hufAmount(hufAmount)
                .handlingFee(handlingFee)
                .currency(currency)
                .status(TransactionStatus.COMPLETED)
                .build();
    }

    // =====================================================================
    // Napi haszon számítás
    // =====================================================================
    @Test
    @DisplayName("Napi haszon: eladási HUF - vételi HUF - díjak")
    void testDailyProfit_calculation() {
        // Arrange — napi tranzakciók:
        // BUY: 300K (vettünk EUR-t, kifizettünk 300K HUF-ot)
        // SELL: 350K (eladtunk EUR-t, kaptunk 350K HUF-ot)
        // Díj: 2000 + 1500 = 3500
        List<Transaction> transactions = List.of(
                createTransaction(TransactionType.BUY, new BigDecimal("300000"),
                        new BigDecimal("2000"), "EUR"),
                createTransaction(TransactionType.SELL, new BigDecimal("350000"),
                        new BigDecimal("1500"), "EUR")
        );

        when(transactionRepository.findActiveByBranchAndDate(eq(BRANCH_ID), any(LocalDate.class)))
                .thenReturn(transactions);

        // Act
        ProfitCalculationService.ProfitReport report = service.calculateDailyProfit(
                BRANCH_ID, LocalDate.of(2026, 1, 15));

        // Assert
        // Bevétel = 350K (sell) - 300K (buy) = 50K
        assertThat(report.getRevenue()).isEqualByComparingTo(new BigDecimal("50000"));
        // Költségek = 2000 + 1500 = 3500
        assertThat(report.getExpenses()).isEqualByComparingTo(new BigDecimal("3500"));
        // Bruttó haszon = bevétel = 50K
        assertThat(report.getGrossProfit()).isEqualByComparingTo(new BigDecimal("50000"));
        // Nettó haszon = 50K - 3.5K = 46.5K
        assertThat(report.getNetProfit()).isEqualByComparingTo(new BigDecimal("46500"));
        // Tranzakció szám
        assertThat(report.getTotalTransactions()).isEqualTo(2);
        // Valuta bontás
        assertThat(report.getProfitByCurrency()).hasSize(1);
    }

    // =====================================================================
    // Havi haszon aggregáció — több valutanem
    // =====================================================================
    @Test
    @DisplayName("Havi haszon: több valutanem aggregálása")
    void testMonthlyProfit_aggregation() {
        // Arrange — havi tranzakciók, több valutanem
        List<Transaction> transactions = List.of(
                // EUR: buy 500K, sell 550K → 50K profit
                createTransaction(TransactionType.BUY, new BigDecimal("500000"),
                        new BigDecimal("3000"), "EUR"),
                createTransaction(TransactionType.SELL, new BigDecimal("550000"),
                        new BigDecimal("2000"), "EUR"),
                // USD: buy 200K, sell 220K → 20K profit
                createTransaction(TransactionType.BUY, new BigDecimal("200000"),
                        new BigDecimal("1000"), "USD"),
                createTransaction(TransactionType.SELL, new BigDecimal("220000"),
                        new BigDecimal("500"), "USD"),
                // GBP: buy 100K, sell 108K → 8K profit
                createTransaction(TransactionType.BUY, new BigDecimal("100000"),
                        BigDecimal.ZERO, "GBP"),
                createTransaction(TransactionType.SELL, new BigDecimal("108000"),
                        new BigDecimal("1000"), "GBP")
        );

        when(transactionRepository.findByBranchAndMonth(eq(BRANCH_ID), any(LocalDate.class), any(LocalDate.class)))
                .thenReturn(transactions);

        // Act
        ProfitCalculationService.ProfitReport report = service.calculateMonthlyProfit(
                BRANCH_ID, "2026-01");

        // Assert
        // Összesített:
        // Sell: 550K + 220K + 108K = 878K
        // Buy: 500K + 200K + 100K = 800K
        // Bevétel = 878K - 800K = 78K
        assertThat(report.getRevenue()).isEqualByComparingTo(new BigDecimal("78000"));
        // Díjak: 3K + 2K + 1K + 0.5K + 0 + 1K = 7.5K
        assertThat(report.getExpenses()).isEqualByComparingTo(new BigDecimal("7500"));
        // Nettó = 78K - 7.5K = 70.5K
        assertThat(report.getNetProfit()).isEqualByComparingTo(new BigDecimal("70500"));
        // 3 különböző valutanem
        assertThat(report.getProfitByCurrency()).hasSize(3);
        // 6 tranzakció összesen
        assertThat(report.getTotalTransactions()).isEqualTo(6);
    }
}
