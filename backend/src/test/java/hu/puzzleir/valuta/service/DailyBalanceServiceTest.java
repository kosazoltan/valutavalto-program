package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.repository.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.TestingAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.*;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * DailyBalanceService UNIT tesztek.
 *
 * Lefedi:
 * - Háromszintű nyitó egyenleg fallback
 * - Per-valuta hibaizoláció calculateAllCurrenciesForDay()-ban
 */
@ExtendWith(MockitoExtension.class)
@org.mockito.junit.jupiter.MockitoSettings(strictness = org.mockito.quality.Strictness.LENIENT)
class DailyBalanceServiceTest {

    @InjectMocks
    private DailyBalanceService dailyBalanceService;

    @Mock
    private DailyBalanceRepository dailyBalanceRepository;

    @Mock
    private TransactionRepository transactionRepository;

    @Mock
    private TransactionLineRepository transactionLineRepository;

    @Mock
    private TransferRepository transferRepository;

    @Mock
    private CurrencyRepository currencyRepository;

    @Mock
    private CompanyRepository companyRepository;

    @Mock
    private AuditLogService auditLogService;

    @Mock
    private MonthlyClosingSummaryRepository monthlyClosingSummaryRepository;

    @Mock
    private CurrencyStockRepository currencyStockRepository;

    /**
     * FKH-029 FR-5: a nyitó-egyenleg Szint-3 fallback forrása a {@code cash_balance}
     * (korábban a holt CASHIER {@code CurrencyStock} réteg).
     */
    @Mock
    private CashBalanceRepository cashBalanceRepository;

    @Mock
    private BranchRepository branchRepository;

    @Mock
    private DenominationBalanceRepository denominationBalanceRepository;

    private static final UUID TEST_COMPANY_ID = UUID.randomUUID();
    private static final UUID TEST_BRANCH_ID = UUID.randomUUID();
    private static final LocalDate TEST_DATE = LocalDate.of(2026, 3, 16);

    @BeforeEach
    void setUp() {
        hu.puzzleir.valuta.security.WorkerAuthenticationDetails details =
            new hu.puzzleir.valuta.security.WorkerAuthenticationDetails(
                1L, TEST_COMPANY_ID, TEST_BRANCH_ID, "ADMIN");
        TestingAuthenticationToken auth = new TestingAuthenticationToken("test", "pass", "ROLE_ADMIN");
        auth.setDetails(details);
        SecurityContextHolder.getContext().setAuthentication(auth);

        Company mockCompany = new Company();
        mockCompany.setId(TEST_COMPANY_ID);
        when(companyRepository.findById(TEST_COMPANY_ID)).thenReturn(Optional.of(mockCompany));
    }

    // ============================================================
    // Nyitó egyenleg fallback tesztek
    // ============================================================

    @Test
    @DisplayName("Nyitó egyenleg: előző napi záró létezik → MonthlyClosingSummary nem hívódik")
    void testOpeningBalance_fromPreviousDay() {
        // Előző nap záró: 1000 EUR
        when(dailyBalanceRepository.findClosingBalance(org.mockito.ArgumentMatchers.eq(TEST_COMPANY_ID), org.mockito.ArgumentMatchers.eq(TEST_BRANCH_ID), org.mockito.ArgumentMatchers.eq("EUR"), org.mockito.ArgumentMatchers.eq(TEST_DATE.minusDays(1))))
            .thenReturn(Optional.of(new BigDecimal("1000.00")));

        BigDecimal result = dailyBalanceService.getOpeningBalance(TEST_BRANCH_ID, TEST_DATE, "EUR");

        assertThat(result).isEqualByComparingTo("1000.00");
        verifyNoInteractions(monthlyClosingSummaryRepository);
        verifyNoInteractions(currencyStockRepository);
    }

    @Test
    @DisplayName("Nyitó egyenleg: nincs előző nap → MonthlyClosingSummary-ra esik vissza")
    void testOpeningBalance_fallbackToMonthlyClosingSummary() {
        // Nincs előző nap
        when(dailyBalanceRepository.findClosingBalance(org.mockito.ArgumentMatchers.eq(TEST_COMPANY_ID), eq(TEST_BRANCH_ID), eq("EUR"), any(LocalDate.class)))
            .thenReturn(Optional.empty());

        // MonthlyClosingSummary tartalmaz EUR záró egyenleget
        MonthlyClosingSummary summary = new MonthlyClosingSummary();
        summary.setCurrencyBreakdown(
            "[{\"currencyCode\":\"EUR\",\"closingBalance\":2500.00,\"buyCount\":5}]"
        );
        when(monthlyClosingSummaryRepository.findClosingByBranchAndYearMonth(
                eq(TEST_BRANCH_ID), anyString()))
            .thenReturn(Optional.of(summary));

        BigDecimal result = dailyBalanceService.getOpeningBalance(TEST_BRANCH_ID, TEST_DATE, "EUR");

        assertThat(result).isEqualByComparingTo("2500.00");
        verifyNoInteractions(currencyStockRepository);
    }

    @Test
    @DisplayName("Nyitó egyenleg: nincs havi összesítő → cash_balance.current_balance-ra esik vissza (FKH-029 FR-5)")
    void testOpeningBalance_fallbackToCashBalance() {
        // Nincs előző nap
        when(dailyBalanceRepository.findClosingBalance(org.mockito.ArgumentMatchers.eq(TEST_COMPANY_ID), eq(TEST_BRANCH_ID), eq("EUR"), any(LocalDate.class)))
            .thenReturn(Optional.empty());

        // Nincs MonthlyClosingSummary
        when(monthlyClosingSummaryRepository.findClosingByBranchAndYearMonth(
                eq(TEST_BRANCH_ID), anyString()))
            .thenReturn(Optional.empty());

        // FKH-029 FR-5: a Szint-3 forrás a cash_balance (élő adat), nem a holt CASHIER
        // CurrencyStock réteg. A régi forrás nem is hívódik.
        CashBalance cashBalance = new CashBalance();
        cashBalance.setCurrentBalance(new BigDecimal("750.00"));
        when(cashBalanceRepository.findByBranchIdAndCurrencyCodeAndCompanyId(
                eq(TEST_BRANCH_ID), eq("EUR"), eq(TEST_COMPANY_ID)))
            .thenReturn(Optional.of(cashBalance));

        // FKH-053: TEST_DATE is a past calendar day — live cash_balance must not be used.
        assertThatThrownBy(() -> dailyBalanceService.getOpeningBalance(TEST_BRANCH_ID, TEST_DATE, "EUR"))
            .isInstanceOf(hu.puzzleir.valuta.exception.ValidationException.class);
        verifyNoInteractions(currencyStockRepository);
    }

    @Test
    @DisplayName("Nyitó egyenleg: minden forrás hiányzik → ZERO")
    void testOpeningBalance_allSourcesMissing_returnsZero() {
        when(dailyBalanceRepository.findClosingBalance(org.mockito.ArgumentMatchers.eq(TEST_COMPANY_ID), eq(TEST_BRANCH_ID), eq("EUR"), any(LocalDate.class)))
            .thenReturn(Optional.empty());
        when(monthlyClosingSummaryRepository.findClosingByBranchAndYearMonth(
                eq(TEST_BRANCH_ID), anyString()))
            .thenReturn(Optional.empty());
        when(cashBalanceRepository.findByBranchIdAndCurrencyCodeAndCompanyId(
                eq(TEST_BRANCH_ID), eq("EUR"), eq(TEST_COMPANY_ID)))
            .thenReturn(Optional.empty());

        BigDecimal result = dailyBalanceService.getOpeningBalance(TEST_BRANCH_ID, TEST_DATE, "EUR");

        assertThat(result).isEqualByComparingTo(BigDecimal.ZERO);
    }

    // ============================================================
    // calculateAllCurrenciesForDay — per-valuta hibaizoláció
    // ============================================================

    @Test
    @DisplayName("calculateAllCurrenciesForDay: egy valuta hibája nem állítja le a többit")
    void testCalculateAllCurrencies_oneCurrencyFails_othersProcessed() {
        // EUR és USD aktív
        hu.puzzleir.valuta.entity.Currency eur = new hu.puzzleir.valuta.entity.Currency();
        eur.setCode("EUR");
        hu.puzzleir.valuta.entity.Currency usd = new hu.puzzleir.valuta.entity.Currency();
        usd.setCode("USD");

        when(currencyRepository.findActiveByCompany(TEST_COMPANY_ID))
            .thenReturn(List.of(eur, usd));

        // EUR: nincs meglévő mérleg
        when(dailyBalanceRepository.findByBranchIdAndBalanceDateAndCurrencyCode(org.mockito.ArgumentMatchers.eq(TEST_COMPANY_ID), org.mockito.ArgumentMatchers.eq(TEST_BRANCH_ID), org.mockito.ArgumentMatchers.eq(TEST_DATE), org.mockito.ArgumentMatchers.eq("EUR")))
            .thenReturn(Optional.empty());

        // USD: kivételt dob (szimulált hiba)
        when(dailyBalanceRepository.findByBranchIdAndBalanceDateAndCurrencyCode(org.mockito.ArgumentMatchers.eq(TEST_COMPANY_ID), org.mockito.ArgumentMatchers.eq(TEST_BRANCH_ID), org.mockito.ArgumentMatchers.eq(TEST_DATE), org.mockito.ArgumentMatchers.eq("USD")))
            .thenThrow(new RuntimeException("Szimulált DB hiba USD-nél"));

        // EUR opening balance: ZERO (nincs adat)
        when(dailyBalanceRepository.findClosingBalance(org.mockito.ArgumentMatchers.eq(TEST_COMPANY_ID), eq(TEST_BRANCH_ID), eq("EUR"), any()))
            .thenReturn(Optional.empty());
        when(monthlyClosingSummaryRepository.findClosingByBranchAndYearMonth(eq(TEST_BRANCH_ID), any()))
            .thenReturn(Optional.empty());
        when(cashBalanceRepository.findByBranchIdAndCurrencyCodeAndCompanyId(eq(TEST_BRANCH_ID), eq("EUR"), eq(TEST_COMPANY_ID)))
            .thenReturn(Optional.empty());

        // EUR tranzakciók (multi-line-helyes: single-line + line; itt mindkettő 0)
        when(transactionRepository.sumDailySingleLineTurnoverByCurrency(
                eq(TEST_BRANCH_ID), eq(TEST_DATE), eq(TransactionType.BUY), eq("EUR")))
            .thenReturn(BigDecimal.ZERO);
        when(transactionRepository.sumDailySingleLineTurnoverByCurrency(
                eq(TEST_BRANCH_ID), eq(TEST_DATE), eq(TransactionType.SELL), eq("EUR")))
            .thenReturn(BigDecimal.ZERO);
        when(transferRepository.sumTransfersInExcludingTh(eq(TEST_BRANCH_ID), eq(TEST_COMPANY_ID), eq(TEST_DATE), eq("EUR")))
            .thenReturn(BigDecimal.ZERO);
        when(transferRepository.sumTransfersOutExcludingTh(eq(TEST_BRANCH_ID), eq(TEST_COMPANY_ID), eq(TEST_DATE), eq("EUR")))
            .thenReturn(BigDecimal.ZERO);

        when(dailyBalanceRepository.save(any(DailyBalance.class)))
            .thenAnswer(inv -> inv.getArgument(0));

        List<DailyBalance> results = dailyBalanceService.calculateAllCurrenciesForDay(TEST_BRANCH_ID, TEST_DATE);

        // Csak EUR sikerült
        assertThat(results).hasSize(1);
        assertThat(results.get(0).getCurrencyCode()).isEqualTo("EUR");

        // Audit log rögzítve a részleges hibáról
        verify(auditLogService).log(
            eq("DAILY_BALANCE_PARTIAL_FAILURE"),
            contains("USD"),
            eq(TEST_BRANCH_ID.toString())
        );
    }

    // ============================================================
    // Alapfunkciók
    // ============================================================

    @Test
    @DisplayName("getDailyBalances: üres nap → üres lista")
    void testGetDailyBalances_empty() {
        when(dailyBalanceRepository.findByBranchIdAndBalanceDate(org.mockito.ArgumentMatchers.eq(TEST_COMPANY_ID), org.mockito.ArgumentMatchers.eq(TEST_BRANCH_ID), org.mockito.ArgumentMatchers.eq(TEST_DATE)))
            .thenReturn(Collections.emptyList());

        List<DailyBalance> result = dailyBalanceService.getDailyBalances(TEST_BRANCH_ID, TEST_DATE);

        assertThat(result).isEmpty();
    }

    @Test
    @DisplayName("getDailyBalances: van adat → visszaadja")
    void testGetDailyBalances_withData() {
        DailyBalance db = new DailyBalance();
        db.setBranchId(TEST_BRANCH_ID);
        db.setBalanceDate(TEST_DATE);
        db.setCurrencyCode("EUR");

        when(dailyBalanceRepository.findByBranchIdAndBalanceDate(org.mockito.ArgumentMatchers.eq(TEST_COMPANY_ID), org.mockito.ArgumentMatchers.eq(TEST_BRANCH_ID), org.mockito.ArgumentMatchers.eq(TEST_DATE)))
            .thenReturn(List.of(db));

        List<DailyBalance> result = dailyBalanceService.getDailyBalances(TEST_BRANCH_ID, TEST_DATE);

        assertThat(result).hasSize(1);
        assertThat(result.get(0).getCurrencyCode()).isEqualTo("EUR");
    }

    @Test
    @DisplayName("getMonthlyBalances: havi adatok lekérdezése")
    void testGetMonthlyBalances() {
        when(dailyBalanceRepository.findByBranchAndMonth(org.mockito.ArgumentMatchers.eq(TEST_COMPANY_ID), eq(TEST_BRANCH_ID), eq(2026), eq(3)))
            .thenReturn(Collections.emptyList());

        List<DailyBalance> result = dailyBalanceService.getMonthlyBalances(TEST_BRANCH_ID, 2026, 3);

        assertThat(result).isNotNull();
        verify(dailyBalanceRepository).findByBranchAndMonth(org.mockito.ArgumentMatchers.eq(TEST_COMPANY_ID), eq(TEST_BRANCH_ID), eq(2026), eq(3));
    }

    @Test
    @DisplayName("closeDailyBalance: sikeres lezárás, nincs kivétel")
    void testCloseDailyBalance() {
        DailyBalance balance = new DailyBalance();
        balance.setBranchId(TEST_BRANCH_ID);
        balance.setBalanceDate(TEST_DATE);
        balance.setCurrencyCode("EUR");
        balance.setIsClosed(false);

        when(dailyBalanceRepository.findByBranchIdAndBalanceDateAndCurrencyCode(org.mockito.ArgumentMatchers.eq(TEST_COMPANY_ID), org.mockito.ArgumentMatchers.eq(TEST_BRANCH_ID), org.mockito.ArgumentMatchers.eq(TEST_DATE), org.mockito.ArgumentMatchers.eq("EUR")))
            .thenReturn(Optional.of(balance));

        assertThatNoException().isThrownBy(() ->
            dailyBalanceService.closeDailyBalance(TEST_BRANCH_ID, TEST_DATE, "EUR")
        );
    }

    @Test
    @DisplayName("Codex #903: napi zárás-egyenleg a multi-line tétel-sorokat is beleszámolja (single-line + line)")
    void testCalculateDailyBalance_multiLineTurnoverIncludedInClosing() {
        // EUR vétel: 100 egy-soros + 50 multi-line tétel-sorból = 150 purchases; eladás 0; nyitó 0.
        when(dailyBalanceRepository.findByBranchIdAndBalanceDateAndCurrencyCode(org.mockito.ArgumentMatchers.eq(TEST_COMPANY_ID), org.mockito.ArgumentMatchers.eq(TEST_BRANCH_ID), org.mockito.ArgumentMatchers.eq(TEST_DATE), org.mockito.ArgumentMatchers.eq("EUR")))
            .thenReturn(Optional.empty());
        when(dailyBalanceRepository.findClosingBalance(org.mockito.ArgumentMatchers.eq(TEST_COMPANY_ID), eq(TEST_BRANCH_ID), eq("EUR"), any())).thenReturn(Optional.empty());
        when(monthlyClosingSummaryRepository.findClosingByBranchAndYearMonth(eq(TEST_BRANCH_ID), any())).thenReturn(Optional.empty());
        when(cashBalanceRepository.findByBranchIdAndCurrencyCodeAndCompanyId(eq(TEST_BRANCH_ID), eq("EUR"), eq(TEST_COMPANY_ID))).thenReturn(Optional.empty());
        when(transactionRepository.sumDailySingleLineTurnoverByCurrency(eq(TEST_BRANCH_ID), eq(TEST_DATE), eq(TransactionType.BUY), eq("EUR")))
            .thenReturn(new BigDecimal("100"));
        when(transactionLineRepository.sumDailyLineTurnoverByCurrency(eq(TEST_BRANCH_ID), eq(TEST_DATE), eq(TransactionType.BUY), eq("EUR")))
            .thenReturn(new BigDecimal("50"));
        when(transactionRepository.sumDailySingleLineTurnoverByCurrency(eq(TEST_BRANCH_ID), eq(TEST_DATE), eq(TransactionType.SELL), eq("EUR")))
            .thenReturn(BigDecimal.ZERO);
        when(transactionLineRepository.sumDailyLineTurnoverByCurrency(eq(TEST_BRANCH_ID), eq(TEST_DATE), eq(TransactionType.SELL), eq("EUR")))
            .thenReturn(BigDecimal.ZERO);
        when(transferRepository.sumTransfersInExcludingTh(eq(TEST_BRANCH_ID), eq(TEST_COMPANY_ID), eq(TEST_DATE), eq("EUR"))).thenReturn(BigDecimal.ZERO);
        when(transferRepository.sumTransfersOutExcludingTh(eq(TEST_BRANCH_ID), eq(TEST_COMPANY_ID), eq(TEST_DATE), eq("EUR"))).thenReturn(BigDecimal.ZERO);
        when(dailyBalanceRepository.save(any(DailyBalance.class))).thenAnswer(inv -> inv.getArgument(0));

        DailyBalance result = dailyBalanceService.calculateDailyBalance(TEST_BRANCH_ID, TEST_DATE, "EUR");

        assertThat(result.getPurchases()).as("purchases = single-line 100 + line 50").isEqualByComparingTo(new BigDecimal("150"));
        assertThat(result.getClosingBalance()).as("closing = 0 + 150 - 0").isEqualByComparingTo(new BigDecimal("150"));
    }

    // ============================================================
    // FK-046: SZÁMZÁR (recordClosingAdjustments) + Többlet/Hiány (TH)
    // ============================================================

    private Branch cashierBranch() {
        Branch b = new Branch();
        b.setId(TEST_BRANCH_ID);
        b.setIsVault(false);
        Company c = new Company();
        c.setId(TEST_COMPANY_ID);
        b.setCompany(c);
        return b;
    }

    private DailyBalance balanceRow(String currency) {
        DailyBalance db = DailyBalance.builder()
            .branchId(TEST_BRANCH_ID).balanceDate(TEST_DATE).currencyCode(currency)
            .isClosed(false).build();
        return db;
    }

    @Test
    @DisplayName("FK-046 FR-1/2: a SZÁMZÁR a záráskori snapshotból egy valutára kitöltődik")
    void recordActualStock_invokedOnDailyClosing_singleCurrency() {
        when(branchRepository.findById(TEST_BRANCH_ID)).thenReturn(Optional.of(cashierBranch()));
        when(denominationBalanceRepository.sumActualStockByCurrency(
                TEST_BRANCH_ID, TEST_DATE, DenominationCategory.EVENING))
            .thenReturn(List.<Object[]>of(new Object[]{"EUR", new BigDecimal("1000")}));
        DailyBalance eur = balanceRow("EUR");
        when(dailyBalanceRepository.findByBranchIdAndBalanceDate(org.mockito.ArgumentMatchers.eq(TEST_COMPANY_ID), org.mockito.ArgumentMatchers.eq(TEST_BRANCH_ID), org.mockito.ArgumentMatchers.eq(TEST_DATE)))
            .thenReturn(List.of(eur));
        when(transferRepository.sumSurplusFromTh(any(), any(), any(), any())).thenReturn(BigDecimal.ZERO);
        when(transferRepository.sumShortageToTh(any(), any(), any(), any())).thenReturn(BigDecimal.ZERO);
        when(dailyBalanceRepository.save(any(DailyBalance.class))).thenAnswer(inv -> inv.getArgument(0));

        dailyBalanceService.recordClosingAdjustments(TEST_BRANCH_ID, TEST_DATE);

        assertThat(eur.getActualStock()).isEqualByComparingTo("1000");
    }

    @Test
    @DisplayName("FK-046 FR-2: több valutára helyesen rögzít a SZÁMZÁR")
    void recordActualStock_invokedOnDailyClosing_multipleCurrencies() {
        when(branchRepository.findById(TEST_BRANCH_ID)).thenReturn(Optional.of(cashierBranch()));
        when(denominationBalanceRepository.sumActualStockByCurrency(
                TEST_BRANCH_ID, TEST_DATE, DenominationCategory.EVENING))
            .thenReturn(List.<Object[]>of(
                new Object[]{"EUR", new BigDecimal("1000")},
                new Object[]{"USD", new BigDecimal("500")}));
        DailyBalance eur = balanceRow("EUR");
        DailyBalance usd = balanceRow("USD");
        when(dailyBalanceRepository.findByBranchIdAndBalanceDate(org.mockito.ArgumentMatchers.eq(TEST_COMPANY_ID), org.mockito.ArgumentMatchers.eq(TEST_BRANCH_ID), org.mockito.ArgumentMatchers.eq(TEST_DATE)))
            .thenReturn(List.of(eur, usd));
        when(transferRepository.sumSurplusFromTh(any(), any(), any(), any())).thenReturn(BigDecimal.ZERO);
        when(transferRepository.sumShortageToTh(any(), any(), any(), any())).thenReturn(BigDecimal.ZERO);
        when(dailyBalanceRepository.save(any(DailyBalance.class))).thenAnswer(inv -> inv.getArgument(0));

        dailyBalanceService.recordClosingAdjustments(TEST_BRANCH_ID, TEST_DATE);

        assertThat(eur.getActualStock()).isEqualByComparingTo("1000");
        assertThat(usd.getActualStock()).isEqualByComparingTo("500");
    }

    @Test
    @DisplayName("FK-046 FR-7: ha egy valutára nincs snapshot, a SZÁMZÁR mező üres marad (nem 0)")
    void recordActualStock_missingSnapshot_leavesFieldEmpty() {
        when(branchRepository.findById(TEST_BRANCH_ID)).thenReturn(Optional.of(cashierBranch()));
        // EUR-ra van snapshot, USD-re nincs
        when(denominationBalanceRepository.sumActualStockByCurrency(
                TEST_BRANCH_ID, TEST_DATE, DenominationCategory.EVENING))
            .thenReturn(List.<Object[]>of(new Object[]{"EUR", new BigDecimal("1000")}));
        DailyBalance eur = balanceRow("EUR");
        DailyBalance usd = balanceRow("USD");
        when(dailyBalanceRepository.findByBranchIdAndBalanceDate(org.mockito.ArgumentMatchers.eq(TEST_COMPANY_ID), org.mockito.ArgumentMatchers.eq(TEST_BRANCH_ID), org.mockito.ArgumentMatchers.eq(TEST_DATE)))
            .thenReturn(List.of(eur, usd));
        when(transferRepository.sumSurplusFromTh(any(), any(), any(), any())).thenReturn(BigDecimal.ZERO);
        when(transferRepository.sumShortageToTh(any(), any(), any(), any())).thenReturn(BigDecimal.ZERO);
        when(dailyBalanceRepository.save(any(DailyBalance.class))).thenAnswer(inv -> inv.getArgument(0));

        dailyBalanceService.recordClosingAdjustments(TEST_BRANCH_ID, TEST_DATE);

        assertThat(eur.getActualStock()).isEqualByComparingTo("1000");
        assertThat(usd.getActualStock()).as("nincs snapshot → üres, nem 0").isNull();
    }

    @Test
    @DisplayName("FK-046 FR-9: értéktári irodára a SZÁMZÁR/TH rögzítés NEM fut le")
    void recordActualStock_vaultBranch_notInvoked() {
        Branch vault = new Branch();
        vault.setId(TEST_BRANCH_ID);
        vault.setIsVault(true);
        when(branchRepository.findById(TEST_BRANCH_ID)).thenReturn(Optional.of(vault));

        dailyBalanceService.recordClosingAdjustments(TEST_BRANCH_ID, TEST_DATE);

        verify(dailyBalanceRepository, never()).findByBranchIdAndBalanceDate(org.mockito.ArgumentMatchers.eq(TEST_COMPANY_ID), any(), any());
        verify(denominationBalanceRepository, never()).sumActualStockByCurrency(any(), any(), any());
    }

    @Test
    @DisplayName("FK-046 FR-4: a TH-tól átvett tétel a Többlet (surplus) mezőbe kerül")
    void surplus_calculatedFromThTransfer_incoming() {
        when(branchRepository.findById(TEST_BRANCH_ID)).thenReturn(Optional.of(cashierBranch()));
        when(denominationBalanceRepository.sumActualStockByCurrency(any(), any(), any()))
            .thenReturn(Collections.emptyList());
        DailyBalance eur = balanceRow("EUR");
        when(dailyBalanceRepository.findByBranchIdAndBalanceDate(org.mockito.ArgumentMatchers.eq(TEST_COMPANY_ID), org.mockito.ArgumentMatchers.eq(TEST_BRANCH_ID), org.mockito.ArgumentMatchers.eq(TEST_DATE)))
            .thenReturn(List.of(eur));
        when(transferRepository.sumSurplusFromTh(TEST_BRANCH_ID, TEST_COMPANY_ID, TEST_DATE, "EUR")).thenReturn(new BigDecimal("200"));
        when(transferRepository.sumShortageToTh(TEST_BRANCH_ID, TEST_COMPANY_ID, TEST_DATE, "EUR")).thenReturn(BigDecimal.ZERO);
        when(dailyBalanceRepository.save(any(DailyBalance.class))).thenAnswer(inv -> inv.getArgument(0));

        dailyBalanceService.recordClosingAdjustments(TEST_BRANCH_ID, TEST_DATE);

        assertThat(eur.getSurplus()).isEqualByComparingTo("200");
        assertThat(eur.getShortage()).isEqualByComparingTo("0");
    }

    @Test
    @DisplayName("FK-046 FR-4: a TH-nak átadott tétel a Hiány (shortage) mezőbe kerül")
    void shortage_calculatedFromThTransfer_outgoing() {
        when(branchRepository.findById(TEST_BRANCH_ID)).thenReturn(Optional.of(cashierBranch()));
        when(denominationBalanceRepository.sumActualStockByCurrency(any(), any(), any()))
            .thenReturn(Collections.emptyList());
        DailyBalance eur = balanceRow("EUR");
        when(dailyBalanceRepository.findByBranchIdAndBalanceDate(org.mockito.ArgumentMatchers.eq(TEST_COMPANY_ID), org.mockito.ArgumentMatchers.eq(TEST_BRANCH_ID), org.mockito.ArgumentMatchers.eq(TEST_DATE)))
            .thenReturn(List.of(eur));
        when(transferRepository.sumSurplusFromTh(TEST_BRANCH_ID, TEST_COMPANY_ID, TEST_DATE, "EUR")).thenReturn(BigDecimal.ZERO);
        when(transferRepository.sumShortageToTh(TEST_BRANCH_ID, TEST_COMPANY_ID, TEST_DATE, "EUR")).thenReturn(new BigDecimal("300"));
        when(dailyBalanceRepository.save(any(DailyBalance.class))).thenAnswer(inv -> inv.getArgument(0));

        dailyBalanceService.recordClosingAdjustments(TEST_BRANCH_ID, TEST_DATE);

        assertThat(eur.getShortage()).isEqualByComparingTo("300");
        assertThat(eur.getSurplus()).isEqualByComparingTo("0");
    }

    @Test
    @DisplayName("FK-046 NFR-5: ismételt zárás-futás felülírja a Többlet/Hiány-t, nem duplázza (idempotens)")
    void thTransfer_idempotent_rerunDoesNotDuplicate() {
        when(branchRepository.findById(TEST_BRANCH_ID)).thenReturn(Optional.of(cashierBranch()));
        when(denominationBalanceRepository.sumActualStockByCurrency(any(), any(), any()))
            .thenReturn(Collections.emptyList());
        DailyBalance eur = balanceRow("EUR");
        eur.setSurplus(new BigDecimal("200")); // korábbi futás értéke
        when(dailyBalanceRepository.findByBranchIdAndBalanceDate(org.mockito.ArgumentMatchers.eq(TEST_COMPANY_ID), org.mockito.ArgumentMatchers.eq(TEST_BRANCH_ID), org.mockito.ArgumentMatchers.eq(TEST_DATE)))
            .thenReturn(List.of(eur));
        when(transferRepository.sumSurplusFromTh(TEST_BRANCH_ID, TEST_COMPANY_ID, TEST_DATE, "EUR")).thenReturn(new BigDecimal("200"));
        when(transferRepository.sumShortageToTh(TEST_BRANCH_ID, TEST_COMPANY_ID, TEST_DATE, "EUR")).thenReturn(BigDecimal.ZERO);
        when(dailyBalanceRepository.save(any(DailyBalance.class))).thenAnswer(inv -> inv.getArgument(0));

        dailyBalanceService.recordClosingAdjustments(TEST_BRANCH_ID, TEST_DATE);

        // felülírás, NEM 400 (200+200)
        assertThat(eur.getSurplus()).as("idempotens: felülír, nem additív").isEqualByComparingTo("200");
    }

    @Test
    @DisplayName("FK-046 FR-5: a számított záró (calculatedClosing) a Többlet/Hiány tételeket IS tartalmazza")
    void closingBalance_withSurplusShortage_matchesActualStock() {
        when(branchRepository.findById(TEST_BRANCH_ID)).thenReturn(Optional.of(cashierBranch()));
        // FR-5 lényege (GLM R3 #1): a calculateMnbValidation() a surplus-t IS beleszámítja a
        // calculatedClosing-ba. Nyitó 0, vétel 100000, TH-tól TÖBBLET 5000 → calculatedClosing =
        // (0+100000+5000) − 0 = 105000. Ha a metódus NEM számítaná be a surplus-t, 100000 lenne (a teszt bukna).
        when(denominationBalanceRepository.sumActualStockByCurrency(
                TEST_BRANCH_ID, TEST_DATE, DenominationCategory.EVENING))
            .thenReturn(List.<Object[]>of(new Object[]{"HUF", new BigDecimal("105000")}));
        DailyBalance huf = balanceRow("HUF");
        huf.setOpeningBalance(BigDecimal.ZERO);
        huf.setPurchases(new BigDecimal("100000"));
        huf.setSales(BigDecimal.ZERO);
        huf.setClosingBalance(new BigDecimal("105000")); // a teljes (TH-t is tartalmazó) tényleges záró
        when(dailyBalanceRepository.findByBranchIdAndBalanceDate(org.mockito.ArgumentMatchers.eq(TEST_COMPANY_ID), org.mockito.ArgumentMatchers.eq(TEST_BRANCH_ID), org.mockito.ArgumentMatchers.eq(TEST_DATE)))
            .thenReturn(List.of(huf));
        when(transferRepository.sumSurplusFromTh(TEST_BRANCH_ID, TEST_COMPANY_ID, TEST_DATE, "HUF")).thenReturn(new BigDecimal("5000"));
        when(transferRepository.sumShortageToTh(TEST_BRANCH_ID, TEST_COMPANY_ID, TEST_DATE, "HUF")).thenReturn(BigDecimal.ZERO);
        when(dailyBalanceRepository.save(any(DailyBalance.class))).thenAnswer(inv -> inv.getArgument(0));

        dailyBalanceService.recordClosingAdjustments(TEST_BRANCH_ID, TEST_DATE);

        // a surplus beépült: calculatedClosing = 100000 + 5000 = 105000 (BIZONYÍTÉK, hogy a TH beleszámít)
        assertThat(huf.getSurplus()).isEqualByComparingTo("5000");
        assertThat(huf.getCalculatedClosing()).as("calculatedClosing tartalmazza a TH-többletet").isEqualByComparingTo("105000");
        // a számított záró == SZÁMZÁR (105000) → validáció OK, difference 0
        assertThat(huf.getValidationStatus()).as("calculatedClosing == closingBalance → OK").isEqualTo("OK");
        assertThat(huf.getDifference()).as("closingBalance − SZÁMZÁR = 0").isEqualByComparingTo("0");
    }

    @Test
    @DisplayName("FK-046 FR-6: a függőben lévő (nem COMPLETED) TH-tétel nem számít bele a Többlet/Hiány-ba")
    void thTransfer_pendingStatus_excludedFromCalculation() {
        // A query 'COMPLETED'-szűrése miatt egy PENDING tétel nem szerepel az összegben → a repo 0-t ad.
        // Ezt service-szinten azzal igazoljuk, hogy a (COMPLETED-only) repo-összeg 0, így surplus/shortage 0.
        when(branchRepository.findById(TEST_BRANCH_ID)).thenReturn(Optional.of(cashierBranch()));
        when(denominationBalanceRepository.sumActualStockByCurrency(any(), any(), any()))
            .thenReturn(Collections.emptyList());
        DailyBalance eur = balanceRow("EUR");
        when(dailyBalanceRepository.findByBranchIdAndBalanceDate(org.mockito.ArgumentMatchers.eq(TEST_COMPANY_ID), org.mockito.ArgumentMatchers.eq(TEST_BRANCH_ID), org.mockito.ArgumentMatchers.eq(TEST_DATE)))
            .thenReturn(List.of(eur));
        // a COMPLETED-only query 0-t ad, mert a tétel PENDING (a JPQL status='COMPLETED' kizárja)
        when(transferRepository.sumSurplusFromTh(TEST_BRANCH_ID, TEST_COMPANY_ID, TEST_DATE, "EUR")).thenReturn(BigDecimal.ZERO);
        when(transferRepository.sumShortageToTh(TEST_BRANCH_ID, TEST_COMPANY_ID, TEST_DATE, "EUR")).thenReturn(BigDecimal.ZERO);
        when(dailyBalanceRepository.save(any(DailyBalance.class))).thenAnswer(inv -> inv.getArgument(0));

        dailyBalanceService.recordClosingAdjustments(TEST_BRANCH_ID, TEST_DATE);

        assertThat(eur.getSurplus()).isEqualByComparingTo("0");
        assertThat(eur.getShortage()).isEqualByComparingTo("0");
    }

    @Test
    @DisplayName("FK-046 GLM #2 (NFR-3): nem-HUF (EUR) Többlet/Hiány NEM kerül 5 Ft-os kerekítésre")
    void surplus_nonHuf_notRoundedToFive() {
        when(branchRepository.findById(TEST_BRANCH_ID)).thenReturn(Optional.of(cashierBranch()));
        when(denominationBalanceRepository.sumActualStockByCurrency(any(), any(), any()))
            .thenReturn(Collections.emptyList());
        DailyBalance eur = balanceRow("EUR");
        when(dailyBalanceRepository.findByBranchIdAndBalanceDate(org.mockito.ArgumentMatchers.eq(TEST_COMPANY_ID), org.mockito.ArgumentMatchers.eq(TEST_BRANCH_ID), org.mockito.ArgumentMatchers.eq(TEST_DATE)))
            .thenReturn(List.of(eur));
        // EUR többlet 123.47 — HUF-kerekítés 123-ra/125-re rontaná; itt változatlanul kell maradnia
        when(transferRepository.sumSurplusFromTh(TEST_BRANCH_ID, TEST_COMPANY_ID, TEST_DATE, "EUR")).thenReturn(new BigDecimal("123.47"));
        when(transferRepository.sumShortageToTh(TEST_BRANCH_ID, TEST_COMPANY_ID, TEST_DATE, "EUR")).thenReturn(BigDecimal.ZERO);
        when(dailyBalanceRepository.save(any(DailyBalance.class))).thenAnswer(inv -> inv.getArgument(0));

        dailyBalanceService.recordClosingAdjustments(TEST_BRANCH_ID, TEST_DATE);

        assertThat(eur.getSurplus()).as("EUR nem kerekül 5 Ft-ra").isEqualByComparingTo("123.47");
    }

    @Test
    @DisplayName("FK-046 GLM #3 (FR-1): csak snapshot-tal rendelkező valutára is rögzül a SZÁMZÁR (új mérleg-sor)")
    void recordActualStock_snapshotOnlyCurrency_createsRow() {
        when(branchRepository.findById(TEST_BRANCH_ID)).thenReturn(Optional.of(cashierBranch()));
        // CHF-re van snapshot, de NINCS aznapi mérleg-sor (nem volt mozgás)
        when(denominationBalanceRepository.sumActualStockByCurrency(
                TEST_BRANCH_ID, TEST_DATE, DenominationCategory.EVENING))
            .thenReturn(List.<Object[]>of(new Object[]{"CHF", new BigDecimal("777")}));
        when(dailyBalanceRepository.findByBranchIdAndBalanceDate(org.mockito.ArgumentMatchers.eq(TEST_COMPANY_ID), org.mockito.ArgumentMatchers.eq(TEST_BRANCH_ID), org.mockito.ArgumentMatchers.eq(TEST_DATE)))
            .thenReturn(Collections.emptyList()); // nincs előzetes sor
        when(transferRepository.sumSurplusFromTh(any(), any(), any(), any())).thenReturn(BigDecimal.ZERO);
        when(transferRepository.sumShortageToTh(any(), any(), any(), any())).thenReturn(BigDecimal.ZERO);
        java.util.List<DailyBalance> saved = new java.util.ArrayList<>();
        when(dailyBalanceRepository.save(any(DailyBalance.class))).thenAnswer(inv -> {
            saved.add(inv.getArgument(0));
            return inv.getArgument(0);
        });

        dailyBalanceService.recordClosingAdjustments(TEST_BRANCH_ID, TEST_DATE);

        // a CHF-re létrejött egy mérleg-sor a SZÁMZÁR-ral
        assertThat(saved).anySatisfy(b -> {
            assertThat(b.getCurrencyCode()).isEqualTo("CHF");
            assertThat(b.getActualStock()).isEqualByComparingTo("777");
        });
    }

    // ============================================================
    // FK Batch3-followup: closeDailyBalance + recordActualStock
    // mutation-coverage (túlélő VoidMethodCall/Negate/Boundary ölése)
    // ============================================================

    @Test
    @DisplayName("closeDailyBalance — sikeres lezárás: isClosed=true, closedAt/By beállítva, mentés + audit")
    void closeDailyBalance_success() {
        DailyBalance balance = DailyBalance.builder()
                .branchId(TEST_BRANCH_ID).balanceDate(TEST_DATE).currencyCode("EUR").isClosed(false).build();
        when(dailyBalanceRepository.findByBranchIdAndBalanceDateAndCurrencyCode(org.mockito.ArgumentMatchers.eq(TEST_COMPANY_ID), org.mockito.ArgumentMatchers.eq(TEST_BRANCH_ID), org.mockito.ArgumentMatchers.eq(TEST_DATE), org.mockito.ArgumentMatchers.eq("EUR")))
                .thenReturn(Optional.of(balance));

        dailyBalanceService.closeDailyBalance(TEST_BRANCH_ID, TEST_DATE, "EUR");

        assertThat(balance.getIsClosed()).isTrue();
        assertThat(balance.getClosedAt()).isNotNull();
        assertThat(balance.getClosedBy()).isNotNull();
        verify(dailyBalanceRepository).save(balance);
        verify(auditLogService).log(eq("DAILY_BALANCE_CLOSED"), anyString(), eq(TEST_BRANCH_ID.toString()));
    }

    @Test
    @DisplayName("closeDailyBalance — nincs mérleg → ValidationException, NEM ment/auditál")
    void closeDailyBalance_notFound_throws() {
        when(dailyBalanceRepository.findByBranchIdAndBalanceDateAndCurrencyCode(org.mockito.ArgumentMatchers.eq(TEST_COMPANY_ID), org.mockito.ArgumentMatchers.eq(TEST_BRANCH_ID), org.mockito.ArgumentMatchers.eq(TEST_DATE), org.mockito.ArgumentMatchers.eq("EUR")))
                .thenReturn(Optional.empty());

        assertThatThrownBy(() -> dailyBalanceService.closeDailyBalance(TEST_BRANCH_ID, TEST_DATE, "EUR"))
                .isInstanceOf(hu.puzzleir.valuta.exception.ValidationException.class)
                .hasMessageContaining("Nincs napi mérleg");
        verify(dailyBalanceRepository, never()).save(any());
        verify(auditLogService, never()).log(anyString(), anyString(), anyString());
    }

    @Test
    @DisplayName("closeDailyBalance — már lezárt → ValidationException (dupla zárás tiltva)")
    void closeDailyBalance_alreadyClosed_throws() {
        DailyBalance balance = DailyBalance.builder()
                .branchId(TEST_BRANCH_ID).balanceDate(TEST_DATE).currencyCode("EUR").isClosed(true).build();
        when(dailyBalanceRepository.findByBranchIdAndBalanceDateAndCurrencyCode(org.mockito.ArgumentMatchers.eq(TEST_COMPANY_ID), org.mockito.ArgumentMatchers.eq(TEST_BRANCH_ID), org.mockito.ArgumentMatchers.eq(TEST_DATE), org.mockito.ArgumentMatchers.eq("EUR")))
                .thenReturn(Optional.of(balance));

        assertThatThrownBy(() -> dailyBalanceService.closeDailyBalance(TEST_BRANCH_ID, TEST_DATE, "EUR"))
                .isInstanceOf(hu.puzzleir.valuta.exception.ValidationException.class)
                .hasMessageContaining("már lezárva");
        verify(dailyBalanceRepository, never()).save(any());
    }

    @Test
    @DisplayName("recordActualStock — leltár rögzítése + note beállítás, difference számítás")
    void recordActualStock_withNote() {
        DailyBalance balance = DailyBalance.builder()
                .branchId(TEST_BRANCH_ID).balanceDate(TEST_DATE).currencyCode("EUR")
                .closingBalance(new BigDecimal("1000")).build();
        when(dailyBalanceRepository.findByBranchIdAndBalanceDateAndCurrencyCode(org.mockito.ArgumentMatchers.eq(TEST_COMPANY_ID), org.mockito.ArgumentMatchers.eq(TEST_BRANCH_ID), org.mockito.ArgumentMatchers.eq(TEST_DATE), org.mockito.ArgumentMatchers.eq("EUR")))
                .thenReturn(Optional.of(balance));

        dailyBalanceService.recordActualStock(TEST_BRANCH_ID, TEST_DATE, "EUR", new BigDecimal("950"), "leltár eltérés");

        assertThat(balance.getActualStock()).isEqualByComparingTo("950");
        assertThat(balance.getDifferenceNote()).isEqualTo("leltár eltérés");
        verify(dailyBalanceRepository).save(balance);
    }

    @Test
    @DisplayName("recordActualStock — üres/blank note NEM íródik felül a mezőn")
    void recordActualStock_blankNote_notSet() {
        DailyBalance balance = DailyBalance.builder()
                .branchId(TEST_BRANCH_ID).balanceDate(TEST_DATE).currencyCode("EUR")
                .closingBalance(new BigDecimal("1000")).build();
        when(dailyBalanceRepository.findByBranchIdAndBalanceDateAndCurrencyCode(org.mockito.ArgumentMatchers.eq(TEST_COMPANY_ID), org.mockito.ArgumentMatchers.eq(TEST_BRANCH_ID), org.mockito.ArgumentMatchers.eq(TEST_DATE), org.mockito.ArgumentMatchers.eq("EUR")))
                .thenReturn(Optional.of(balance));

        dailyBalanceService.recordActualStock(TEST_BRANCH_ID, TEST_DATE, "EUR", new BigDecimal("980"), "   ");

        assertThat(balance.getActualStock()).isEqualByComparingTo("980");
        assertThat(balance.getDifferenceNote()).isNull(); // blank → nem állítja be
        verify(dailyBalanceRepository).save(balance);
    }

    @Test
    @DisplayName("recordActualStock — nincs mérleg → ValidationException")
    void recordActualStock_notFound_throws() {
        when(dailyBalanceRepository.findByBranchIdAndBalanceDateAndCurrencyCode(org.mockito.ArgumentMatchers.eq(TEST_COMPANY_ID), org.mockito.ArgumentMatchers.eq(TEST_BRANCH_ID), org.mockito.ArgumentMatchers.eq(TEST_DATE), org.mockito.ArgumentMatchers.eq("USD")))
                .thenReturn(Optional.empty());

        assertThatThrownBy(() -> dailyBalanceService.recordActualStock(
                TEST_BRANCH_ID, TEST_DATE, "USD", BigDecimal.TEN, "x"))
                .isInstanceOf(hu.puzzleir.valuta.exception.ValidationException.class);
        verify(dailyBalanceRepository, never()).save(any());
    }

    // ============================================================
    // FK-052: értéktári BANK+/BANK− napi igazítás
    // ============================================================

    private Branch vaultBranch() {
        Branch branch = cashierBranch();
        branch.setIsVault(true);
        return branch;
    }

    @Test
    @DisplayName("FK-052: pénztári branch-re a banki igazítás NO-OP")
    void recordVaultBankAdjustments_nonVaultBranch_noOp() {
        when(branchRepository.findById(TEST_BRANCH_ID)).thenReturn(Optional.of(cashierBranch()));

        dailyBalanceService.recordVaultBankAdjustments(TEST_BRANCH_ID, TEST_DATE);

        verify(transferRepository, never()).sumBankInByDay(any(), any(), any());
        verify(transferRepository, never()).sumBankOutByDay(any(), any(), any());
        verify(dailyBalanceRepository, never()).save(any());
    }

    @Test
    @DisplayName("FK-052: ismeretlen branch-re a banki igazítás NO-OP, nem dob")
    void recordVaultBankAdjustments_unknownBranch_noOp() {
        when(branchRepository.findById(TEST_BRANCH_ID)).thenReturn(Optional.empty());

        assertThatNoException().isThrownBy(() ->
                dailyBalanceService.recordVaultBankAdjustments(TEST_BRANCH_ID, TEST_DATE));

        verifyNoInteractions(transferRepository);
        verify(dailyBalanceRepository, never()).save(any());
    }

    @Test
    @DisplayName("FK-052: vault meglévő EUR sora BANK+/BANK− értéket kap, MNB-validációval és siker-audittal")
    void recordVaultBankAdjustments_existingBalance_persistsAggregatesAndValidation() {
        when(branchRepository.findById(TEST_BRANCH_ID)).thenReturn(Optional.of(vaultBranch()));
        DailyBalance eur = balanceRow("EUR");
        when(dailyBalanceRepository.findByBranchIdAndBalanceDate(TEST_COMPANY_ID, TEST_BRANCH_ID, TEST_DATE))
                .thenReturn(List.of(eur));
        when(transferRepository.sumBankInByDay(TEST_BRANCH_ID, TEST_COMPANY_ID, TEST_DATE))
                .thenReturn(List.<Object[]>of(new Object[]{null, "EUR", new BigDecimal("1500")}));
        when(transferRepository.sumBankOutByDay(TEST_BRANCH_ID, TEST_COMPANY_ID, TEST_DATE))
                .thenReturn(List.<Object[]>of(new Object[]{null, "EUR", new BigDecimal("200")}));

        dailyBalanceService.recordVaultBankAdjustments(TEST_BRANCH_ID, TEST_DATE);

        assertThat(eur.getBankIn()).isEqualByComparingTo("1500");
        assertThat(eur.getBankOut()).isEqualByComparingTo("200");
        assertThat(eur.getCalculatedClosing()).isEqualByComparingTo("1300");
        verify(dailyBalanceRepository).save(eur);
        verify(auditLogService).logForCompany(
                eq("DAILY_BALANCE_BANK_ADJUSTMENT"),
                argThat(message -> message.contains("\"KAT\":\"TX\"")
                        && message.contains("\"currencies\":1")),
                eq(TEST_BRANCH_ID.toString()),
                eq(TEST_COMPANY_ID));
        verify(auditLogService, never()).log(anyString(), anyString(), any(String.class));
    }

    @Test
    @DisplayName("FK-052: ismételt futás felülírja a banki összeget, nem duplázza")
    void recordVaultBankAdjustments_rerunOverwritesIdempotently() {
        when(branchRepository.findById(TEST_BRANCH_ID)).thenReturn(Optional.of(vaultBranch()));
        DailyBalance eur = balanceRow("EUR");
        when(dailyBalanceRepository.findByBranchIdAndBalanceDate(TEST_COMPANY_ID, TEST_BRANCH_ID, TEST_DATE))
                .thenReturn(List.of(eur));
        when(transferRepository.sumBankInByDay(TEST_BRANCH_ID, TEST_COMPANY_ID, TEST_DATE))
                .thenReturn(
                        List.<Object[]>of(new Object[]{null, "EUR", new BigDecimal("1500")}),
                        List.<Object[]>of(new Object[]{null, "EUR", new BigDecimal("500")}));
        when(transferRepository.sumBankOutByDay(TEST_BRANCH_ID, TEST_COMPANY_ID, TEST_DATE))
                .thenReturn(Collections.emptyList());

        dailyBalanceService.recordVaultBankAdjustments(TEST_BRANCH_ID, TEST_DATE);
        dailyBalanceService.recordVaultBankAdjustments(TEST_BRANCH_ID, TEST_DATE);

        assertThat(eur.getBankIn()).as("felülírás, nem 1500+500").isEqualByComparingTo("500");
        verify(dailyBalanceRepository, times(2)).save(eur);
    }

    @Test
    @DisplayName("FK-052: csak banki aggregátumban létező valutára új, nullabázisú mérleg-sor készül")
    void recordVaultBankAdjustments_aggregateOnlyCurrency_createsZeroBasedRow() {
        when(branchRepository.findById(TEST_BRANCH_ID)).thenReturn(Optional.of(vaultBranch()));
        when(dailyBalanceRepository.findByBranchIdAndBalanceDate(TEST_COMPANY_ID, TEST_BRANCH_ID, TEST_DATE))
                .thenReturn(Collections.emptyList());
        when(transferRepository.sumBankInByDay(TEST_BRANCH_ID, TEST_COMPANY_ID, TEST_DATE))
                .thenReturn(List.<Object[]>of(new Object[]{"CHF", "EUR", new BigDecimal("777")}));
        when(transferRepository.sumBankOutByDay(TEST_BRANCH_ID, TEST_COMPANY_ID, TEST_DATE))
                .thenReturn(Collections.emptyList());
        ArgumentCaptor<DailyBalance> saved = ArgumentCaptor.forClass(DailyBalance.class);

        dailyBalanceService.recordVaultBankAdjustments(TEST_BRANCH_ID, TEST_DATE);

        verify(dailyBalanceRepository).save(saved.capture());
        DailyBalance chf = saved.getValue();
        assertThat(chf.getCurrencyCode()).isEqualTo("CHF");
        assertThat(chf.getOpeningBalance()).isEqualByComparingTo("0");
        assertThat(chf.getPurchases()).isEqualByComparingTo("0");
        assertThat(chf.getSales()).isEqualByComparingTo("0");
        assertThat(chf.getTransfersIn()).isEqualByComparingTo("0");
        assertThat(chf.getTransfersOut()).isEqualByComparingTo("0");
        assertThat(chf.getClosingBalance()).isEqualByComparingTo("0");
        assertThat(chf.getBankIn()).isEqualByComparingTo("777");
        assertThat(chf.getBankOut()).isEqualByComparingTo("0");
    }

    @Test
    @DisplayName("FK-052: banki tétel nélküli meglévő vault-sor bank mezői nullára íródnak")
    void recordVaultBankAdjustments_existingBalanceWithoutTransfers_overwritesWithZero() {
        when(branchRepository.findById(TEST_BRANCH_ID)).thenReturn(Optional.of(vaultBranch()));
        DailyBalance eur = balanceRow("EUR");
        eur.setBankIn(new BigDecimal("99"));
        eur.setBankOut(new BigDecimal("88"));
        when(dailyBalanceRepository.findByBranchIdAndBalanceDate(TEST_COMPANY_ID, TEST_BRANCH_ID, TEST_DATE))
                .thenReturn(List.of(eur));
        when(transferRepository.sumBankInByDay(TEST_BRANCH_ID, TEST_COMPANY_ID, TEST_DATE))
                .thenReturn(Collections.emptyList());
        when(transferRepository.sumBankOutByDay(TEST_BRANCH_ID, TEST_COMPANY_ID, TEST_DATE))
                .thenReturn(Collections.emptyList());

        dailyBalanceService.recordVaultBankAdjustments(TEST_BRANCH_ID, TEST_DATE);

        assertThat(eur.getBankIn()).isEqualByComparingTo("0");
        assertThat(eur.getBankOut()).isEqualByComparingTo("0");
    }

    @Test
    @DisplayName("FK-052 NFR-3: HUF banki összeg 5 Ft-ra kerekül, EUR változatlan marad")
    void recordVaultBankAdjustments_roundsOnlyHuf() {
        when(branchRepository.findById(TEST_BRANCH_ID)).thenReturn(Optional.of(vaultBranch()));
        DailyBalance huf = balanceRow("HUF");
        DailyBalance eur = balanceRow("EUR");
        when(dailyBalanceRepository.findByBranchIdAndBalanceDate(TEST_COMPANY_ID, TEST_BRANCH_ID, TEST_DATE))
                .thenReturn(List.of(huf, eur));
        when(transferRepository.sumBankInByDay(TEST_BRANCH_ID, TEST_COMPANY_ID, TEST_DATE))
                .thenReturn(List.<Object[]>of(
                        new Object[]{null, "HUF", new BigDecimal("1002")},
                        new Object[]{null, "EUR", new BigDecimal("1002")}));
        when(transferRepository.sumBankOutByDay(TEST_BRANCH_ID, TEST_COMPANY_ID, TEST_DATE))
                .thenReturn(Collections.emptyList());

        dailyBalanceService.recordVaultBankAdjustments(TEST_BRANCH_ID, TEST_DATE);

        assertThat(huf.getBankIn()).isEqualByComparingTo("1000");
        assertThat(eur.getBankIn()).isEqualByComparingTo("1002");
    }

    @Test
    @DisplayName("FK-052: lezárt mérleg-sort a banki igazítás nem módosít és nem ment")
    void recordVaultBankAdjustments_closedBalance_isUntouched() {
        when(branchRepository.findById(TEST_BRANCH_ID)).thenReturn(Optional.of(vaultBranch()));
        DailyBalance eur = balanceRow("EUR");
        eur.setIsClosed(true);
        eur.setBankIn(new BigDecimal("10"));
        when(dailyBalanceRepository.findByBranchIdAndBalanceDate(TEST_COMPANY_ID, TEST_BRANCH_ID, TEST_DATE))
                .thenReturn(List.of(eur));
        when(transferRepository.sumBankInByDay(TEST_BRANCH_ID, TEST_COMPANY_ID, TEST_DATE))
                .thenReturn(List.<Object[]>of(new Object[]{null, "EUR", new BigDecimal("1500")}));
        when(transferRepository.sumBankOutByDay(TEST_BRANCH_ID, TEST_COMPANY_ID, TEST_DATE))
                .thenReturn(Collections.emptyList());

        dailyBalanceService.recordVaultBankAdjustments(TEST_BRANCH_ID, TEST_DATE);

        assertThat(eur.getBankIn()).isEqualByComparingTo("10");
        verify(dailyBalanceRepository, never()).save(any());
    }

    @Test
    @DisplayName("FK-052: line-valutakód elsőbbséget kap, a header-fallback külön valutába olvad")
    void recordVaultBankAdjustments_mergesLineAndHeaderAggregateKeys() {
        when(branchRepository.findById(TEST_BRANCH_ID)).thenReturn(Optional.of(vaultBranch()));
        DailyBalance eur = balanceRow("EUR");
        DailyBalance usd = balanceRow("USD");
        when(dailyBalanceRepository.findByBranchIdAndBalanceDate(TEST_COMPANY_ID, TEST_BRANCH_ID, TEST_DATE))
                .thenReturn(List.of(eur, usd));
        when(transferRepository.sumBankInByDay(TEST_BRANCH_ID, TEST_COMPANY_ID, TEST_DATE))
                .thenReturn(List.<Object[]>of(
                        new Object[]{"USD", "EUR", new BigDecimal("50")},
                        new Object[]{null, "EUR", new BigDecimal("100")}));
        when(transferRepository.sumBankOutByDay(TEST_BRANCH_ID, TEST_COMPANY_ID, TEST_DATE))
                .thenReturn(Collections.emptyList());

        dailyBalanceService.recordVaultBankAdjustments(TEST_BRANCH_ID, TEST_DATE);

        assertThat(eur.getBankIn()).isEqualByComparingTo("100");
        assertThat(usd.getBankIn()).isEqualByComparingTo("50");
    }

    @Test
    @DisplayName("FK-052: aggregációs hiba hiba-audit után változatlanul továbbdobódik")
    void recordVaultBankAdjustments_repositoryFailure_auditsAndRethrows() {
        when(branchRepository.findById(TEST_BRANCH_ID)).thenReturn(Optional.of(vaultBranch()));
        RuntimeException failure = new RuntimeException("bank aggregate failed");
        when(transferRepository.sumBankInByDay(TEST_BRANCH_ID, TEST_COMPANY_ID, TEST_DATE))
                .thenThrow(failure);

        assertThatThrownBy(() -> dailyBalanceService.recordVaultBankAdjustments(TEST_BRANCH_ID, TEST_DATE))
                .isSameAs(failure);
        verify(auditLogService).logInNewTransactionForCompany(
                eq("DAILY_BALANCE_BANK_ADJUSTMENT_FAILED"),
                argThat(message -> message.contains("\"KAT\":\"TX\"")
                        && message.contains("RuntimeException")),
                eq(TEST_BRANCH_ID.toString()),
                eq(TEST_COMPANY_ID));
        verify(auditLogService, never()).log(anyString(), anyString(), any(String.class));
        verify(dailyBalanceRepository, never()).save(any());
    }
}
