package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.CashBalance;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.DailyBalance;
import hu.puzzleir.valuta.repository.CashBalanceRepository;
import hu.puzzleir.valuta.repository.DailyBalanceRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Collections;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * DailyBalanceReconciliationService UNIT tesztek.
 */
@ExtendWith(MockitoExtension.class)
@org.mockito.junit.jupiter.MockitoSettings(strictness = org.mockito.quality.Strictness.LENIENT)
class DailyBalanceReconciliationServiceTest {

    @InjectMocks
    private DailyBalanceReconciliationService service;

    @Mock
    private DailyBalanceRepository dailyBalanceRepository;

    @Mock
    private CashBalanceRepository cashBalanceRepository;

    @Mock
    private AuditLogService auditLogService;

    private static final UUID BRANCH_ID = UUID.randomUUID();
    private static final LocalDate TEST_DATE = LocalDate.of(2026, 3, 16);

    // ============================================================
    // Segéd metódusok
    // ============================================================

    private DailyBalance makeDailyBalance(String currencyCode, BigDecimal closing) {
        DailyBalance db = new DailyBalance();
        db.setBranchId(BRANCH_ID);
        db.setBalanceDate(TEST_DATE);
        db.setCurrencyCode(currencyCode);
        db.setOpeningBalance(BigDecimal.ZERO);
        db.setPurchases(BigDecimal.ZERO);
        db.setTransfersIn(BigDecimal.ZERO);
        db.setSales(BigDecimal.ZERO);
        db.setTransfersOut(BigDecimal.ZERO);
        db.setClosingBalance(closing);
        return db;
    }

    private CashBalance makeCashBalance(String currencyCode, BigDecimal currentBalance) {
        Currency currency = new Currency();
        currency.setCode(currencyCode);
        CashBalance cb = new CashBalance();
        cb.setCurrency(currency);
        cb.setCurrentBalance(currentBalance);
        return cb;
    }

    // ============================================================
    // Tesztek
    // ============================================================

    @Test
    @DisplayName("Egyeztetés: eltérés felfedezése → riasztás visszaadva")
    void testReconcile_mismatchDetected() {
        // Számított záró: 1000, tényleges: 950 → diff = 50
        when(dailyBalanceRepository.findByBranchIdAndBalanceDate(BRANCH_ID, TEST_DATE))
            .thenReturn(List.of(makeDailyBalance("EUR", new BigDecimal("1000.00"))));
        when(cashBalanceRepository.findAllByBranchId(BRANCH_ID))
            .thenReturn(List.of(makeCashBalance("EUR", new BigDecimal("950.00"))));

        List<DailyBalanceReconciliationService.ReconciliationAlert> alerts =
            service.reconcile(BRANCH_ID, TEST_DATE);

        assertThat(alerts).hasSize(1);
        DailyBalanceReconciliationService.ReconciliationAlert alert = alerts.get(0);
        assertThat(alert.getCurrencyCode()).isEqualTo("EUR");
        assertThat(alert.getCalculatedBalance()).isEqualByComparingTo("1000.00");
        assertThat(alert.getActualBalance()).isEqualByComparingTo("950.00");
        assertThat(alert.getDifference()).isEqualByComparingTo("50.00");

        verify(auditLogService).log(
            eq("DAILY_BALANCE_RECONCILIATION_MISMATCH"),
            anyString(),
            eq(BRANCH_ID.toString())
        );
    }

    @Test
    @DisplayName("Egyeztetés: tolerancián belüli eltérés → nincs riasztás")
    void testReconcile_withinTolerance_noAlert() {
        // Eltérés: 0.005 < 0.01 tűréshatár
        when(dailyBalanceRepository.findByBranchIdAndBalanceDate(BRANCH_ID, TEST_DATE))
            .thenReturn(List.of(makeDailyBalance("EUR", new BigDecimal("1000.005"))));
        when(cashBalanceRepository.findAllByBranchId(BRANCH_ID))
            .thenReturn(List.of(makeCashBalance("EUR", new BigDecimal("1000.00"))));

        List<DailyBalanceReconciliationService.ReconciliationAlert> alerts =
            service.reconcile(BRANCH_ID, TEST_DATE);

        assertThat(alerts).isEmpty();
        verifyNoInteractions(auditLogService);
    }

    @Test
    @DisplayName("Egyeztetés: számított > tényleges → isOverage() = true")
    void testReconcile_calculatedGreaterThanActual_isOverage() {
        when(dailyBalanceRepository.findByBranchIdAndBalanceDate(BRANCH_ID, TEST_DATE))
            .thenReturn(List.of(makeDailyBalance("USD", new BigDecimal("500.00"))));
        when(cashBalanceRepository.findAllByBranchId(BRANCH_ID))
            .thenReturn(List.of(makeCashBalance("USD", new BigDecimal("400.00"))));

        List<DailyBalanceReconciliationService.ReconciliationAlert> alerts =
            service.reconcile(BRANCH_ID, TEST_DATE);

        assertThat(alerts).hasSize(1);
        assertThat(alerts.get(0).isOverage()).isTrue();
        assertThat(alerts.get(0).isShortage()).isFalse();
        assertThat(alerts.get(0).getDifference()).isEqualByComparingTo("100.00");
    }

    @Test
    @DisplayName("Egyeztetés: számított < tényleges → isShortage() = true")
    void testReconcile_calculatedLessThanActual_isShortage() {
        when(dailyBalanceRepository.findByBranchIdAndBalanceDate(BRANCH_ID, TEST_DATE))
            .thenReturn(List.of(makeDailyBalance("GBP", new BigDecimal("300.00"))));
        when(cashBalanceRepository.findAllByBranchId(BRANCH_ID))
            .thenReturn(List.of(makeCashBalance("GBP", new BigDecimal("350.00"))));

        List<DailyBalanceReconciliationService.ReconciliationAlert> alerts =
            service.reconcile(BRANCH_ID, TEST_DATE);

        assertThat(alerts).hasSize(1);
        assertThat(alerts.get(0).isShortage()).isTrue();
        assertThat(alerts.get(0).isOverage()).isFalse();
        // diff = 300 - 350 = -50
        assertThat(alerts.get(0).getDifference()).isEqualByComparingTo("-50.00");
    }

    @Test
    @DisplayName("Egyeztetés: nincs napi mérleg → üres lista")
    void testReconcile_noDailyBalances_emptyResult() {
        when(dailyBalanceRepository.findByBranchIdAndBalanceDate(BRANCH_ID, TEST_DATE))
            .thenReturn(Collections.emptyList());

        List<DailyBalanceReconciliationService.ReconciliationAlert> alerts =
            service.reconcile(BRANCH_ID, TEST_DATE);

        assertThat(alerts).isEmpty();
        verifyNoInteractions(cashBalanceRepository);
        verifyNoInteractions(auditLogService);
    }

    @Test
    @DisplayName("Egyeztetés: több valuta, csak az egyik tér el → egy riasztás")
    void testReconcile_multipleCurrencies_oneMismatch() {
        when(dailyBalanceRepository.findByBranchIdAndBalanceDate(BRANCH_ID, TEST_DATE))
            .thenReturn(List.of(
                makeDailyBalance("EUR", new BigDecimal("1000.00")),
                makeDailyBalance("USD", new BigDecimal("500.00"))
            ));
        when(cashBalanceRepository.findAllByBranchId(BRANCH_ID))
            .thenReturn(List.of(
                makeCashBalance("EUR", new BigDecimal("1000.00")),  // egyezik
                makeCashBalance("USD", new BigDecimal("450.00"))    // eltér: 50
            ));

        List<DailyBalanceReconciliationService.ReconciliationAlert> alerts =
            service.reconcile(BRANCH_ID, TEST_DATE);

        assertThat(alerts).hasSize(1);
        assertThat(alerts.get(0).getCurrencyCode()).isEqualTo("USD");
        assertThat(alerts.get(0).getDifference()).isEqualByComparingTo("50.00");
    }
}
