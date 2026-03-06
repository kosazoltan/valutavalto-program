package hu.puzzleir.valuta.service;

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
 * DailyBalanceService UNIT tesztek — Mockito.
 *
 * calculateDailyBalance() metódus tesztelése:
 * - Nyitó + vétel + átvétel - eladás - átadás = záró
 * - Első nap (nincs előző nap) → havi zárásból olvas
 * - Negatív záró készlet → WARNING de nem hiba
 * - Több valutanem párhuzamosan
 * - NULL-safety
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
    private MonthlyClosingRepository monthlyClosingRepository;

    @Mock
    private CurrencyRepository currencyRepository;

    private static final UUID TEST_COMPANY_ID = UUID.randomUUID();
    private static final UUID TEST_BRANCH_ID = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        // SecurityContext beállítása
        hu.puzzleir.valuta.security.WorkerAuthenticationDetails details =
            new hu.puzzleir.valuta.security.WorkerAuthenticationDetails(
                1L, TEST_COMPANY_ID, TEST_BRANCH_ID, "CASHIER");
        TestingAuthenticationToken auth = new TestingAuthenticationToken("test", "pass", "ROLE_CASHIER");
        auth.setDetails(details);
        SecurityContextHolder.getContext().setAuthentication(auth);
    }

    // ============ ALAPVETŐ SZÁMÍTÁS ============

    @Test
    @DisplayName("calculateDailyBalance: nyitó + vétel + átvétel - eladás - átadás = záró")
    void testCalculateDailyBalance_basicFormula() {
        // GIVEN
        LocalDate today = LocalDate.of(2024, 12, 15);
        String currencyCode = "EUR";
        
        // Mock: Előző nap záró készlete
        DailyBalance previousDay = createMockDailyBalance(
            today.minusDays(1), currencyCode, 
            BigDecimal.ZERO, // nyitó
            new BigDecimal("1000") // záró = nyitó + mozgások
        );
        when(dailyBalanceRepository.findByBranchIdAndDateAndCurrencyCodeAndCompanyId(
            eq(TEST_BRANCH_ID), eq(today.minusDays(1)), eq(currencyCode), eq(TEST_COMPANY_ID)
        )).thenReturn(Optional.of(previousDay));
        
        // Mock: Mai tranzakciók
        when(transactionRepository.sumDailyPurchases(TEST_BRANCH_ID, today, currencyCode, TEST_COMPANY_ID))
            .thenReturn(new BigDecimal("500")); // vétel
        when(transactionRepository.sumDailySales(TEST_BRANCH_ID, today, currencyCode, TEST_COMPANY_ID))
            .thenReturn(new BigDecimal("300")); // eladás
        
        // WHEN
        DailyBalance result = dailyBalanceService.calculateDailyBalance(TEST_BRANCH_ID, today, currencyCode);
        
        // THEN
        // Nyitó = előző nap záró
        assertThat(result.getOpeningBalance()).isEqualByComparingTo(new BigDecimal("1000"));
        
        // Mozgások
        assertThat(result.getPurchases()).isEqualByComparingTo(new BigDecimal("500"));
        assertThat(result.getSales()).isEqualByComparingTo(new BigDecimal("300"));
        assertThat(result.getTransfersIn()).isEqualByComparingTo(BigDecimal.ZERO);
        assertThat(result.getTransfersOut()).isEqualByComparingTo(BigDecimal.ZERO);
        
        // Záró = 1000 + 500 - 300 = 1200
        assertThat(result.getClosingBalance()).isEqualByComparingTo(new BigDecimal("1200"));
        
        verify(dailyBalanceRepository, times(1)).save(any(DailyBalance.class));
    }

    // ============ ELSŐ NAP (nincs előző nap) ============

    @Test
    @DisplayName("calculateDailyBalance: első nap — előző hó végi záró a havi zárásból")
    void testCalculateDailyBalance_firstDay() {
        // GIVEN
        LocalDate firstDayOfMonth = LocalDate.of(2024, 12, 1);
        String currencyCode = "USD";
        
        // Mock: NINCS előző nap (nov 30 nem létezik a napi mérlegben)
        when(dailyBalanceRepository.findByBranchIdAndDateAndCurrencyCodeAndCompanyId(
            eq(TEST_BRANCH_ID), eq(LocalDate.of(2024, 11, 30)), eq(currencyCode), eq(TEST_COMPANY_ID)
        )).thenReturn(Optional.empty());
        
        // Mock: De VAN előző havi zárás (nov 30)
        MonthlyClosing monthlyClosing = new MonthlyClosing();
        monthlyClosing.setClosingBalance(new BigDecimal("5000"));
        when(monthlyClosingRepository.findByBranchIdAndClosingDateAndCurrencyCodeAndCompanyId(
            eq(TEST_BRANCH_ID), eq(LocalDate.of(2024, 11, 30)), eq(currencyCode), eq(TEST_COMPANY_ID)
        )).thenReturn(Optional.of(monthlyClosing));
        
        // Mock: Mai tranzakciók
        when(transactionRepository.sumDailyPurchases(TEST_BRANCH_ID, firstDayOfMonth, currencyCode, TEST_COMPANY_ID))
            .thenReturn(new BigDecimal("200"));
        when(transactionRepository.sumDailySales(TEST_BRANCH_ID, firstDayOfMonth, currencyCode, TEST_COMPANY_ID))
            .thenReturn(new BigDecimal("100"));
        
        // WHEN
        DailyBalance result = dailyBalanceService.calculateDailyBalance(TEST_BRANCH_ID, firstDayOfMonth, currencyCode);
        
        // THEN
        // Nyitó = előző hó végi záró
        assertThat(result.getOpeningBalance()).isEqualByComparingTo(new BigDecimal("5000"));
        
        // Záró = 5000 + 200 - 100 = 5100
        assertThat(result.getClosingBalance()).isEqualByComparingTo(new BigDecimal("5100"));
    }

    // ============ TELJESEN ELSŐ NAP (nincs havi zárás sem) ============

    @Test
    @DisplayName("calculateDailyBalance: teljesen első nap (nincs előzmény) → nyitó = 0")
    void testCalculateDailyBalance_veryFirstDay() {
        // GIVEN
        LocalDate veryFirstDay = LocalDate.of(2024, 1, 1);
        String currencyCode = "GBP";
        
        // Mock: NINCS előző nap
        when(dailyBalanceRepository.findByBranchIdAndDateAndCurrencyCodeAndCompanyId(
            any(), any(), eq(currencyCode), eq(TEST_COMPANY_ID)
        )).thenReturn(Optional.empty());
        
        // Mock: NINCS havi zárás sem
        when(monthlyClosingRepository.findByBranchIdAndClosingDateAndCurrencyCodeAndCompanyId(
            any(), any(), eq(currencyCode), eq(TEST_COMPANY_ID)
        )).thenReturn(Optional.empty());
        
        // Mock: Mai tranzakciók
        when(transactionRepository.sumDailyPurchases(TEST_BRANCH_ID, veryFirstDay, currencyCode, TEST_COMPANY_ID))
            .thenReturn(new BigDecimal("1000"));
        when(transactionRepository.sumDailySales(TEST_BRANCH_ID, veryFirstDay, currencyCode, TEST_COMPANY_ID))
            .thenReturn(BigDecimal.ZERO);
        
        // WHEN
        DailyBalance result = dailyBalanceService.calculateDailyBalance(TEST_BRANCH_ID, veryFirstDay, currencyCode);
        
        // THEN
        // Nyitó = 0 (nincs előzmény)
        assertThat(result.getOpeningBalance()).isEqualByComparingTo(BigDecimal.ZERO);
        
        // Záró = 0 + 1000 = 1000
        assertThat(result.getClosingBalance()).isEqualByComparingTo(new BigDecimal("1000"));
    }

    // ============ NEGATÍV ZÁRÓ KÉSZLET ============

    @Test
    @DisplayName("calculateDailyBalance: negatív záró készlet → WARNING de nem hiba")
    void testCalculateDailyBalance_negativeClosing() {
        // GIVEN
        LocalDate today = LocalDate.of(2024, 12, 20);
        String currencyCode = "CHF";
        
        // Mock: Előző nap
        DailyBalance previousDay = createMockDailyBalance(
            today.minusDays(1), currencyCode, 
            BigDecimal.ZERO, 
            new BigDecimal("100") // csak 100 CHF maradt
        );
        when(dailyBalanceRepository.findByBranchIdAndDateAndCurrencyCodeAndCompanyId(
            eq(TEST_BRANCH_ID), eq(today.minusDays(1)), eq(currencyCode), eq(TEST_COMPANY_ID)
        )).thenReturn(Optional.of(previousDay));
        
        // Mock: Mai eladás TÖBB mint a készlet (300 eladás, de csak 100 volt)
        when(transactionRepository.sumDailyPurchases(TEST_BRANCH_ID, today, currencyCode, TEST_COMPANY_ID))
            .thenReturn(BigDecimal.ZERO);
        when(transactionRepository.sumDailySales(TEST_BRANCH_ID, today, currencyCode, TEST_COMPANY_ID))
            .thenReturn(new BigDecimal("300")); // !!! negatív lesz
        
        // WHEN
        DailyBalance result = dailyBalanceService.calculateDailyBalance(TEST_BRANCH_ID, today, currencyCode);
        
        // THEN
        // Záró = 100 + 0 - 300 = -200 (NEGATÍV!)
        assertThat(result.getClosingBalance()).isEqualByComparingTo(new BigDecimal("-200"));
        
        // WARNING log-ot kell írni (ezt mockolni nem tudjuk, de a mentés megtörténik)
        verify(dailyBalanceRepository, times(1)).save(argThat(db -> 
            db.getClosingBalance().compareTo(BigDecimal.ZERO) < 0
        ));
        
        // NEM dob ValidationException-t (csak WARNING)
        assertThatCode(() -> dailyBalanceService.calculateDailyBalance(TEST_BRANCH_ID, today, currencyCode))
            .doesNotThrowAnyException();
    }

    // ============ TÖBB VALUTANEM PÁRHUZAMOSAN ============

    @Test
    @DisplayName("calculateAllCurrenciesForDay: több valuta párhuzamosan")
    void testCalculateAllCurrenciesForDay_multiCurrency() {
        // GIVEN
        LocalDate today = LocalDate.of(2024, 12, 25);
        
        // Mock: 3 aktív valuta
        List<Currency> currencies = Arrays.asList(
            createMockCurrency("EUR"),
            createMockCurrency("USD"),
            createMockCurrency("GBP")
        );
        when(currencyRepository.findActiveByCompany(TEST_COMPANY_ID))
            .thenReturn(currencies);
        
        // Mock: minden valutának van előző napi zárója
        for (Currency currency : currencies) {
            DailyBalance previousDay = createMockDailyBalance(
                today.minusDays(1), 
                currency.getCode(), 
                BigDecimal.ZERO, 
                new BigDecimal("500")
            );
            when(dailyBalanceRepository.findByBranchIdAndDateAndCurrencyCodeAndCompanyId(
                eq(TEST_BRANCH_ID), eq(today.minusDays(1)), eq(currency.getCode()), eq(TEST_COMPANY_ID)
            )).thenReturn(Optional.of(previousDay));
            
            // Mock: minden valutának van forgalma
            when(transactionRepository.sumDailyPurchases(TEST_BRANCH_ID, today, currency.getCode(), TEST_COMPANY_ID))
                .thenReturn(new BigDecimal("100"));
            when(transactionRepository.sumDailySales(TEST_BRANCH_ID, today, currency.getCode(), TEST_COMPANY_ID))
                .thenReturn(new BigDecimal("50"));
        }
        
        // WHEN
        dailyBalanceService.calculateAllCurrenciesForDay(TEST_BRANCH_ID, today);
        
        // THEN
        // 3 valuta × 1 mentés = 3 mentés
        verify(dailyBalanceRepository, times(3)).save(any(DailyBalance.class));
    }

    // ============ NULL-SAFETY ============

    @Test
    @DisplayName("calculateDailyBalance: NULL visszatérés védelem — előző nap záró NULL → 0")
    void testCalculateDailyBalance_nullSafety() {
        // GIVEN
        LocalDate today = LocalDate.of(2024, 12, 31);
        String currencyCode = "JPY";
        
        // Mock: Előző nap létezik, de closingBalance NULL (adatbázis hiba)
        DailyBalance previousDay = createMockDailyBalance(
            today.minusDays(1), currencyCode, 
            BigDecimal.ZERO, 
            null // NULL!
        );
        when(dailyBalanceRepository.findByBranchIdAndDateAndCurrencyCodeAndCompanyId(
            eq(TEST_BRANCH_ID), eq(today.minusDays(1)), eq(currencyCode), eq(TEST_COMPANY_ID)
        )).thenReturn(Optional.of(previousDay));
        
        // Mock: Mai forgalom
        when(transactionRepository.sumDailyPurchases(TEST_BRANCH_ID, today, currencyCode, TEST_COMPANY_ID))
            .thenReturn(new BigDecimal("200"));
        when(transactionRepository.sumDailySales(TEST_BRANCH_ID, today, currencyCode, TEST_COMPANY_ID))
            .thenReturn(BigDecimal.ZERO);
        
        // WHEN
        DailyBalance result = dailyBalanceService.calculateDailyBalance(TEST_BRANCH_ID, today, currencyCode);
        
        // THEN
        // Nyitó = 0 (NULL → 0 konverzió)
        assertThat(result.getOpeningBalance()).isEqualByComparingTo(BigDecimal.ZERO);
        
        // Záró = 0 + 200 = 200
        assertThat(result.getClosingBalance()).isEqualByComparingTo(new BigDecimal("200"));
        
        // NEM NPE
        assertThatCode(() -> dailyBalanceService.calculateDailyBalance(TEST_BRANCH_ID, today, currencyCode))
            .doesNotThrowAnyException();
    }

    @Test
    @DisplayName("calculateDailyBalance: záró készlet SOSEM lehet NULL — default BigDecimal.ZERO")
    void testCalculateDailyBalance_closingNeverNull() {
        // GIVEN
        LocalDate today = LocalDate.of(2025, 1, 1);
        String currencyCode = "CZK";
        
        // Mock: Nincs előzmény
        when(dailyBalanceRepository.findByBranchIdAndDateAndCurrencyCodeAndCompanyId(
            any(), any(), eq(currencyCode), eq(TEST_COMPANY_ID)
        )).thenReturn(Optional.empty());
        
        // Mock: NINCS forgalom (minden NULL)
        when(transactionRepository.sumDailyPurchases(TEST_BRANCH_ID, today, currencyCode, TEST_COMPANY_ID))
            .thenReturn(null); // NULL!
        when(transactionRepository.sumDailySales(TEST_BRANCH_ID, today, currencyCode, TEST_COMPANY_ID))
            .thenReturn(null); // NULL!
        
        // WHEN
        DailyBalance result = dailyBalanceService.calculateDailyBalance(TEST_BRANCH_ID, today, currencyCode);
        
        // THEN
        // Minden mező BigDecimal.ZERO (NEM NULL)
        assertThat(result.getOpeningBalance()).isNotNull().isEqualByComparingTo(BigDecimal.ZERO);
        assertThat(result.getPurchases()).isNotNull().isEqualByComparingTo(BigDecimal.ZERO);
        assertThat(result.getSales()).isNotNull().isEqualByComparingTo(BigDecimal.ZERO);
        assertThat(result.getClosingBalance()).isNotNull().isEqualByComparingTo(BigDecimal.ZERO);
    }

    // ============ HELPER METÓDUSOK ============

    private DailyBalance createMockDailyBalance(LocalDate date, String currencyCode, 
                                                 BigDecimal opening, BigDecimal closing) {
        DailyBalance db = new DailyBalance();
        db.setId(UUID.randomUUID());
        
        Company company = new Company();
        company.setId(TEST_COMPANY_ID);
        db.setCompany(company);
        
        Branch branch = new Branch();
        branch.setId(TEST_BRANCH_ID);
        db.setBranch(branch);
        
        db.setDate(date);
        db.setCurrencyCode(currencyCode);
        db.setOpeningBalance(opening);
        db.setClosingBalance(closing);
        db.setPurchases(BigDecimal.ZERO);
        db.setSales(BigDecimal.ZERO);
        db.setTransfersIn(BigDecimal.ZERO);
        db.setTransfersOut(BigDecimal.ZERO);
        
        return db;
    }

    private Currency createMockCurrency(String code) {
        Currency currency = new Currency();
        currency.setId(UUID.randomUUID());
        currency.setCode(code);
        currency.setName(code + " Currency");
        currency.setActive(true);
        
        Company company = new Company();
        company.setId(TEST_COMPANY_ID);
        currency.setCompany(company);
        
        return currency;
    }
}
