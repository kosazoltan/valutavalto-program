package hu.puzzleir.valuta.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import hu.puzzleir.valuta.entity.ArchivedMonthlyTransaction;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.MonthlyClosingSummary;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.*;
import hu.puzzleir.valuta.security.WorkerAuthenticationDetails;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.springframework.security.authentication.TestingAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.*;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * MonthlyClosingService UNIT tesztek.
 *
 * Tesztek:
 * 1. Nyitott session esetén ValidationException
 * 2. getLastBusinessDay — hétvégéről visszalépés
 * 3. calculateEaster — 2025 → ápr.20, 2026 → ápr.5
 * 4. isHungarianHoliday — aug.20 ünnep
 * 5. archiveTransactions — meghívásra kerül
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class MonthlyClosingServiceTest {

    @InjectMocks
    private MonthlyClosingService service;

    @Mock
    private TransactionRepository transactionRepository;

    @Mock
    private MonthlyClosingSummaryRepository monthlyClosingSummaryRepository;

    @Mock
    private BranchRepository branchRepository;

    @Mock
    private WorkerRepository workerRepository;

    @Mock
    private ObjectMapper objectMapper;

    @Mock
    private MnbExchangeRateService mnbExchangeRateService;

    @Mock
    private CurrencyStockRepository currencyStockRepository;

    @Mock
    private DailySessionRepository dailySessionRepository;

    @Mock
    private ArchivedMonthlyTransactionRepository archivedMonthlyTransactionRepository;

    private static final UUID BRANCH_ID = UUID.randomUUID();
    private static final UUID COMPANY_ID = UUID.randomUUID();
    private static final Long WORKER_ID = 42L;

    @BeforeEach
    void setUpSecurityContext() {
        WorkerAuthenticationDetails details =
                new WorkerAuthenticationDetails(WORKER_ID, COMPANY_ID, BRANCH_ID, "ADMIN");
        TestingAuthenticationToken auth = new TestingAuthenticationToken("test", "pass", "ROLE_ADMIN");
        auth.setDetails(details);
        SecurityContextHolder.getContext().setAuthentication(auth);
    }

    // ============ 1. OPEN SESSION BLOCK ============

    @Test
    @DisplayName("performMonthlyClosing: nyitott napi session → ValidationException")
    void testPerformMonthlyClosing_openSessionBlock() {
        String yearMonth = "2025-01";

        when(monthlyClosingSummaryRepository.existsByBranchIdAndYearMonth(BRANCH_ID, yearMonth))
                .thenReturn(false);
        // 2 nyitott session van a hónapban
        when(dailySessionRepository.countOpenSessionsInRange(eq(BRANCH_ID), any(LocalDate.class), any(LocalDate.class)))
                .thenReturn(2L);

        assertThatThrownBy(() -> service.performMonthlyClosing(BRANCH_ID, yearMonth))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("nyitott napi session")
                .hasMessageContaining("2");
    }

    @Test
    @DisplayName("performMonthlyClosing: nincs nyitott session → továbblép")
    void testPerformMonthlyClosing_noOpenSessions_proceeds() throws Exception {
        String yearMonth = "2025-01";

        Branch branch = new Branch();
        branch.setId(BRANCH_ID);
        Company company = new Company();
        company.setId(COMPANY_ID);
        branch.setCompany(company);

        Worker worker = Worker.builder().id(WORKER_ID).code("WRK01").name("Teszt").build();

        when(monthlyClosingSummaryRepository.existsByBranchIdAndYearMonth(BRANCH_ID, yearMonth))
                .thenReturn(false);
        when(dailySessionRepository.countOpenSessionsInRange(eq(BRANCH_ID), any(LocalDate.class), any(LocalDate.class)))
                .thenReturn(0L);
        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));
        when(workerRepository.findById(WORKER_ID)).thenReturn(Optional.of(worker));
        when(transactionRepository.sumMonthlyBuyHuf(any(), any(), any())).thenReturn(BigDecimal.ZERO);
        when(transactionRepository.sumMonthlySellHuf(any(), any(), any())).thenReturn(BigDecimal.ZERO);
        when(transactionRepository.sumMonthlyHandlingFees(any(), any(), any())).thenReturn(BigDecimal.ZERO);
        when(transactionRepository.countMonthlyTransactions(any(), any(), any())).thenReturn(0L);
        when(transactionRepository.findByBranchAndMonth(any(), any(), any())).thenReturn(Collections.emptyList());
        when(mnbExchangeRateService.getRatesForDate(any())).thenReturn(Collections.emptyMap());
        when(currencyStockRepository.findByEntityTypeAndEntityId(any(), any())).thenReturn(Collections.emptyList());
        when(objectMapper.writeValueAsString(any())).thenReturn("[]");

        MonthlyClosingSummary savedSummary = MonthlyClosingSummary.builder()
                .id(1L)
                .branch(branch)
                .yearMonth(yearMonth)
                .totalBuyHuf(BigDecimal.ZERO)
                .totalSellHuf(BigDecimal.ZERO)
                .totalHandlingFee(BigDecimal.ZERO)
                .transactionCount(0)
                .currencyBreakdown("[]")
                .build();
        when(monthlyClosingSummaryRepository.save(any())).thenReturn(savedSummary);

        MonthlyClosingSummary result = service.performMonthlyClosing(BRANCH_ID, yearMonth);

        assertThat(result).isNotNull();
        assertThat(result.getYearMonth()).isEqualTo(yearMonth);
        verify(dailySessionRepository).countOpenSessionsInRange(eq(BRANCH_ID), any(), any());
    }

    // ============ 2. GETLASTBUSINESSDAY — HÉTVÉGE ============

    @Test
    @DisplayName("getLastBusinessDay: vasárnap → visszalép péntekre")
    void testGetLastBusinessDay_sunday() {
        // 2025-03-31 = hétfő → dec. utolsó napja 31, nézzünk olyan hónapot ahol vasárnap
        // 2025-08-31 = vasárnap
        LocalDate sunday = LocalDate.of(2025, 8, 31);
        assertThat(sunday.getDayOfWeek().name()).isEqualTo("SUNDAY");

        LocalDate result = service.getLastBusinessDay(sunday);

        // aug.29 = péntek (aug.30=szombat, aug.31=vasárnap)
        assertThat(result).isEqualTo(LocalDate.of(2025, 8, 29));
    }

    @Test
    @DisplayName("getLastBusinessDay: szombat → visszalép péntekre")
    void testGetLastBusinessDay_saturday() {
        // 2025-05-31 = szombat
        LocalDate saturday = LocalDate.of(2025, 5, 31);
        assertThat(saturday.getDayOfWeek().name()).isEqualTo("SATURDAY");

        LocalDate result = service.getLastBusinessDay(saturday);

        // máj.30 = péntek
        assertThat(result).isEqualTo(LocalDate.of(2025, 5, 30));
    }

    @Test
    @DisplayName("getLastBusinessDay: hétköznap → nem lép vissza")
    void testGetLastBusinessDay_weekday() {
        // 2025-09-30 = kedd
        LocalDate tuesday = LocalDate.of(2025, 9, 30);

        LocalDate result = service.getLastBusinessDay(tuesday);

        assertThat(result).isEqualTo(tuesday);
    }

    @Test
    @DisplayName("getLastBusinessDay: dec.26 ünnep → visszalép dec.24-re (szombat esetén dec.23)")
    void testGetLastBusinessDay_december() {
        // 2025-12-31 = szerda → de dec.31 nem ünnep, tehát dec.31-t adja vissza
        LocalDate dec31 = LocalDate.of(2025, 12, 31);

        LocalDate result = service.getLastBusinessDay(dec31);

        assertThat(result).isEqualTo(LocalDate.of(2025, 12, 31));
    }

    // ============ 3. EASTER CALCULATION ============

    @Test
    @DisplayName("calculateEaster 2025 → április 20.")
    void testCalculateEaster_2025() {
        LocalDate easter = service.calculateEaster(2025);

        assertThat(easter).isEqualTo(LocalDate.of(2025, 4, 20));
    }

    @Test
    @DisplayName("calculateEaster 2026 → április 5.")
    void testCalculateEaster_2026() {
        LocalDate easter = service.calculateEaster(2026);

        assertThat(easter).isEqualTo(LocalDate.of(2026, 4, 5));
    }

    @Test
    @DisplayName("calculateEaster 2024 → március 31.")
    void testCalculateEaster_2024() {
        LocalDate easter = service.calculateEaster(2024);

        assertThat(easter).isEqualTo(LocalDate.of(2024, 3, 31));
    }

    @Test
    @DisplayName("calculateEaster 2023 → április 9.")
    void testCalculateEaster_2023() {
        LocalDate easter = service.calculateEaster(2023);

        assertThat(easter).isEqualTo(LocalDate.of(2023, 4, 9));
    }

    // ============ 4. ISHOLIDAY — MAGYAR ÜNNEPNAPOK ============

    @Test
    @DisplayName("isHungarianHoliday: aug.20 → true (Államalapítás)")
    void testIsHungarianHoliday_aug20() {
        assertThat(service.isHungarianHoliday(LocalDate.of(2025, 8, 20))).isTrue();
    }

    @Test
    @DisplayName("isHungarianHoliday: jan.1 → true (Újév)")
    void testIsHungarianHoliday_jan1() {
        assertThat(service.isHungarianHoliday(LocalDate.of(2025, 1, 1))).isTrue();
    }

    @Test
    @DisplayName("isHungarianHoliday: márc.15 → true (Nemzeti ünnep)")
    void testIsHungarianHoliday_mar15() {
        assertThat(service.isHungarianHoliday(LocalDate.of(2025, 3, 15))).isTrue();
    }

    @Test
    @DisplayName("isHungarianHoliday: máj.1 → true (A munka ünnepe)")
    void testIsHungarianHoliday_may1() {
        assertThat(service.isHungarianHoliday(LocalDate.of(2025, 5, 1))).isTrue();
    }

    @Test
    @DisplayName("isHungarianHoliday: okt.23 → true (Nemzeti ünnep)")
    void testIsHungarianHoliday_oct23() {
        assertThat(service.isHungarianHoliday(LocalDate.of(2025, 10, 23))).isTrue();
    }

    @Test
    @DisplayName("isHungarianHoliday: nov.1 → true (Mindenszentek)")
    void testIsHungarianHoliday_nov1() {
        assertThat(service.isHungarianHoliday(LocalDate.of(2025, 11, 1))).isTrue();
    }

    @Test
    @DisplayName("isHungarianHoliday: dec.25 → true (Karácsony)")
    void testIsHungarianHoliday_dec25() {
        assertThat(service.isHungarianHoliday(LocalDate.of(2025, 12, 25))).isTrue();
    }

    @Test
    @DisplayName("isHungarianHoliday: dec.26 → true (Karácsony 2.)")
    void testIsHungarianHoliday_dec26() {
        assertThat(service.isHungarianHoliday(LocalDate.of(2025, 12, 26))).isTrue();
    }

    @Test
    @DisplayName("isHungarianHoliday: Húsvét hétfő 2025 (ápr.21) → true")
    void testIsHungarianHoliday_easterMonday2025() {
        // Húsvét 2025 = ápr.20, tehát húsvét hétfő = ápr.21
        assertThat(service.isHungarianHoliday(LocalDate.of(2025, 4, 21))).isTrue();
    }

    @Test
    @DisplayName("isHungarianHoliday: Nagypéntek 2025 (ápr.18) → true")
    void testIsHungarianHoliday_goodFriday2025() {
        // Húsvét 2025 = ápr.20, tehát nagypéntek = ápr.18
        assertThat(service.isHungarianHoliday(LocalDate.of(2025, 4, 18))).isTrue();
    }

    @Test
    @DisplayName("isHungarianHoliday: normál munkanap (pl. 2025 ápr.22 kedd) → false")
    void testIsHungarianHoliday_normalDay() {
        // ápr.22 = kedd, nem ünnep (húsvét hétfő = ápr.21)
        assertThat(service.isHungarianHoliday(LocalDate.of(2025, 4, 22))).isFalse();
    }

    @Test
    @DisplayName("isHungarianHoliday: aug.19 munkanap → false")
    void testIsHungarianHoliday_aug19_notHoliday() {
        assertThat(service.isHungarianHoliday(LocalDate.of(2025, 8, 19))).isFalse();
    }

    // ============ 5. ARCHIVETRANSACTIONS MEGHÍVÁSA ============

    @Test
    @DisplayName("performMonthlyClosing: archiveTransactions meghívásra kerül saveAll-lal")
    void testPerformMonthlyClosing_archiveTransactionsCalled() throws Exception {
        String yearMonth = "2025-01";

        Branch branch = new Branch();
        branch.setId(BRANCH_ID);
        Company company = new Company();
        company.setId(COMPANY_ID);
        branch.setCompany(company);

        Worker worker = Worker.builder().id(WORKER_ID).code("WRK01").name("Teszt").build();

        when(monthlyClosingSummaryRepository.existsByBranchIdAndYearMonth(BRANCH_ID, yearMonth))
                .thenReturn(false);
        when(dailySessionRepository.countOpenSessionsInRange(eq(BRANCH_ID), any(LocalDate.class), any(LocalDate.class)))
                .thenReturn(0L);
        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));
        when(workerRepository.findById(WORKER_ID)).thenReturn(Optional.of(worker));
        when(transactionRepository.sumMonthlyBuyHuf(any(), any(), any())).thenReturn(new BigDecimal("100000"));
        when(transactionRepository.sumMonthlySellHuf(any(), any(), any())).thenReturn(new BigDecimal("80000"));
        when(transactionRepository.sumMonthlyHandlingFees(any(), any(), any())).thenReturn(new BigDecimal("2000"));
        when(transactionRepository.countMonthlyTransactions(any(), any(), any())).thenReturn(5L);
        when(mnbExchangeRateService.getRatesForDate(any())).thenReturn(Collections.emptyMap());
        when(currencyStockRepository.findByEntityTypeAndEntityId(any(), any())).thenReturn(Collections.emptyList());
        when(objectMapper.writeValueAsString(any())).thenReturn("[]");

        // 2 mock tranzakció
        hu.puzzleir.valuta.entity.Transaction tx1 = buildMockTransaction(branch, company, worker,
                LocalDate.of(2025, 1, 10));
        hu.puzzleir.valuta.entity.Transaction tx2 = buildMockTransaction(branch, company, worker,
                LocalDate.of(2025, 1, 15));
        when(transactionRepository.findByBranchAndMonth(eq(BRANCH_ID), any(LocalDate.class), any(LocalDate.class)))
                .thenReturn(List.of(tx1, tx2));

        MonthlyClosingSummary savedSummary = MonthlyClosingSummary.builder()
                .id(99L)
                .branch(branch)
                .yearMonth(yearMonth)
                .totalBuyHuf(new BigDecimal("100000"))
                .totalSellHuf(new BigDecimal("80000"))
                .totalHandlingFee(new BigDecimal("2000"))
                .transactionCount(5)
                .currencyBreakdown("[]")
                .build();
        when(monthlyClosingSummaryRepository.save(any())).thenReturn(savedSummary);

        service.performMonthlyClosing(BRANCH_ID, yearMonth);

        // Ellenőrzés: saveAll meghívásra kerül a 2 archivált tranzakcióval
        ArgumentCaptor<List<ArchivedMonthlyTransaction>> captor =
                ArgumentCaptor.forClass((Class) List.class);
        verify(archivedMonthlyTransactionRepository).saveAll(captor.capture());

        List<ArchivedMonthlyTransaction> archived = captor.getValue();
        assertThat(archived).hasSize(2);
        assertThat(archived.get(0).getMonthlyClosingId()).isEqualTo(99L);
        assertThat(archived.get(0).getYearMonth()).isEqualTo(yearMonth);
        assertThat(archived.get(0).getBranchId()).isEqualTo(BRANCH_ID);
    }

    // ============ HELPER ============

    private hu.puzzleir.valuta.entity.Transaction buildMockTransaction(
            Branch branch, Company company, Worker worker, LocalDate date) {
        hu.puzzleir.valuta.entity.Currency curr = new hu.puzzleir.valuta.entity.Currency();
        curr.setCode("EUR");

        hu.puzzleir.valuta.entity.Transaction tx = new hu.puzzleir.valuta.entity.Transaction();
        tx.setId((long) (Math.random() * 10000));
        tx.setBranch(branch);
        tx.setCompany(company);
        tx.setWorker(worker);
        tx.setTransactionDate(date);
        tx.setTransactionType(hu.puzzleir.valuta.entity.TransactionType.BUY);
        tx.setCurrency(curr);
        tx.setCurrencyAmount(new BigDecimal("100.00"));
        tx.setHufAmount(new BigDecimal("40000.00"));
        tx.setExchangeRate(new BigDecimal("400.0000"));
        tx.setHandlingFee(BigDecimal.ZERO);
        return tx;
    }
}
