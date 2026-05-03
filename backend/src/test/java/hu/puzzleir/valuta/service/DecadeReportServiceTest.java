package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.DailyBalance;
import hu.puzzleir.valuta.entity.DecadeReport;
import hu.puzzleir.valuta.entity.MnbExchangeRateCache;
import hu.puzzleir.valuta.entity.PaymentMethod;
import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.entity.TransactionType;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.DailyBalanceRepository;
import hu.puzzleir.valuta.repository.DecadeReportRepository;
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
 * DecadeReportService unit tesztek.
 *
 * 4 bug regressziós teszt:
 *   1. BUY kezelési díj bevételként jelenik meg a forint kontrollban
 *   2. MNB árfolyam fallback nem dob kivételt (előző nap árfolyamát használja)
 *   3. printControlFlag = true ha a forint kontroll egyezik
 *   4. ValidationException ha a dekád utolsó napja nincs lezárva
 */
@ExtendWith(MockitoExtension.class)
class DecadeReportServiceTest {

    @InjectMocks
    private DecadeReportService service;

    @Mock
    private DecadeReportRepository decadeReportRepository;

    @Mock
    private TransactionRepository transactionRepository;

    @Mock
    private BranchRepository branchRepository;

    @Mock
    private DailyBalanceRepository dailyBalanceRepository;

    @Mock
    private MnbExchangeRateService mnbExchangeRateService;

    private final UUID BRANCH_ID = UUID.randomUUID();
    private final UUID COMPANY_ID = UUID.randomUUID();

    // =========================================================================
    // Segédmetódusok
    // =========================================================================

    private Branch makeBranch() {
        Company company = Company.builder().id(COMPANY_ID).build();
        return Branch.builder().id(BRANCH_ID).company(company).build();
    }

    private Transaction makeBuyTx(BigDecimal hufAmount, BigDecimal handlingFee) {
        return Transaction.builder()
                .transactionType(TransactionType.BUY)
                .hufAmount(hufAmount)
                .handlingFee(handlingFee)
                .paymentMethod(PaymentMethod.CASH)
                .build();
    }

    private Transaction makeSellTx(BigDecimal hufAmount, BigDecimal handlingFee) {
        return Transaction.builder()
                .transactionType(TransactionType.SELL)
                .hufAmount(hufAmount)
                .handlingFee(handlingFee)
                .paymentMethod(PaymentMethod.CASH)
                .build();
    }

    private DailyBalance makeHufBalance(LocalDate date, BigDecimal opening, BigDecimal closing) {
        return DailyBalance.builder()
                .balanceDate(date)
                .currencyCode("HUF")
                .openingBalance(opening)
                .closingBalance(closing)
                .build();
    }

    private MnbExchangeRateCache makeMnbRate(String currency, String ratePerUnit) {
        return MnbExchangeRateCache.builder()
                .currencyCode(currency)
                .officialRate(new BigDecimal(ratePerUnit))
                .unit(1)
                .build();
    }

    /**
     * Stub-olja az összes szükséges repository metódust a generateDecadeReport() futtatásához.
     * Dekád 1 (január 1–10) az alapértelmezett időszak.
     *
     * A forint kontroll számok az alábbiak:
     *   nyitó HUF: openingHuf
     *   záró HUF: closingHuf (expected = openingHuf + totalIncome - totalExpense)
     *   tranzakciók: txList
     */
    private void stubGenerateDecadeReport(
            BigDecimal openingHuf, BigDecimal closingHuf, List<Transaction> txList) {

        LocalDate periodStart = LocalDate.of(2026, 1, 1);
        LocalDate periodEnd   = LocalDate.of(2026, 1, 10);

        // Branch + Security
        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(makeBranch()));

        // Napzárás teljességi ellenőrzés — utolsó nap lezárva
        when(dailyBalanceRepository.findClosedDates(eq(BRANCH_ID), eq(periodStart), eq(periodEnd)))
                .thenReturn(List.of(periodEnd));

        // Meglévő dekád: nincs
        when(decadeReportRepository.findByBranchIdAndYearAndDecade(BRANCH_ID, 2026, 1))
                .thenReturn(Optional.empty());

        // Összesítő lekérdezések
        when(transactionRepository.sumHufAmountByBranchAndTypeAndPeriod(any(), eq("BUY"), any(), any()))
                .thenReturn(BigDecimal.ZERO);
        when(transactionRepository.sumHufAmountByBranchAndTypeAndPeriod(any(), eq("SELL"), any(), any()))
                .thenReturn(BigDecimal.ZERO);
        when(transactionRepository.sumFeeByBranchAndPeriod(any(), any(), any()))
                .thenReturn(BigDecimal.ZERO);
        when(transactionRepository.countByBranchAndPeriod(any(), any(), any()))
                .thenReturn(0L);

        // MNB árfolyamok (üres → calculateDecadeProfit befejezi early)
        when(dailyBalanceRepository.findByBranchIdAndBalanceDate(BRANCH_ID, periodStart))
                .thenReturn(List.of(makeHufBalance(periodStart, openingHuf, openingHuf)));
        when(dailyBalanceRepository.findByBranchIdAndBalanceDate(BRANCH_ID, periodEnd))
                .thenReturn(List.of(makeHufBalance(periodEnd, closingHuf, closingHuf)));

        // Forint kontroll tranzakciók
        when(transactionRepository.findFinanciallyEffectiveByBranchAndDateRange(eq(BRANCH_ID), eq(periodStart), eq(periodEnd)))
                .thenReturn(txList);

        // Mentés → visszaad egyet
        when(decadeReportRepository.save(any(DecadeReport.class)))
                .thenAnswer(inv -> inv.getArgument(0));
    }

    // =========================================================================
    // Bug 1: BUY kezelési díj bevételként jelenik meg a forint kontrollban
    // =========================================================================

    @Test
    @DisplayName("Bug1: BUY kezelési díja bevételként kerül a forint kontrollba")
    void testBuyHandlingFeeAddedToIncome() {
        // Arrange
        // nyitó: 100 000, záró: 95 000
        // BUY: hufAmount=10 000 (kiadás), handlingFee=500 (bevétel)
        // SELL: hufAmount=5 500 (bevétel), handlingFee=0 (már benne)
        //
        // Helyes számítás: 100 000 + (500 + 5 500) - 10 000 = 96 000
        // Ha a fee hiányzik: 100 000 + 5 500 - 10 000 = 95 500 ≠ 96 000
        // Záró = 96 000 → valid = true ha fee hozzáadódik

        BigDecimal openingHuf = new BigDecimal("100000");
        BigDecimal closingHuf = new BigDecimal("96000"); // = 100K + 6K income - 10K expense

        List<Transaction> txs = List.of(
                makeBuyTx(new BigDecimal("10000"), new BigDecimal("500")),
                makeSellTx(new BigDecimal("5500"), BigDecimal.ZERO)
        );

        stubGenerateDecadeReport(openingHuf, closingHuf, txs);

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

            // Act
            var dto = service.generateDecadeReport(BRANCH_ID, 2026, 1);

            // Assert
            // totalIncome = SELL(5500) + BUY_fee(500) = 6000
            assertThat(dto.getForintTotalIncome()).isEqualByComparingTo(new BigDecimal("6000"));
            // totalExpense = BUY(10000)
            assertThat(dto.getForintTotalExpense()).isEqualByComparingTo(new BigDecimal("10000"));
            // diff = 0 → valid
            assertThat(dto.getForintControlValid()).isTrue();
            assertThat(dto.getForintControlDiff()).isEqualByComparingTo(BigDecimal.ZERO);
        }
    }

    @Test
    @DisplayName("Bug1: SELL kezelési díja NEM adódik hozzá kétszer (már benne van hufAmount-ban)")
    void testSellHandlingFeeNotDoubleAdded() {
        // SELL esetén a handlingFee már BENNE van a hufAmount-ban,
        // tehát a totalIncome csak a hufAmount-ot kapja, a fee-t nem.
        BigDecimal openingHuf = new BigDecimal("50000");
        // SELL hufAmount=20000 (fee benne), BUY hufAmount=5000, BUY fee=200
        // Helyes záró: 50000 + (20000 + 200) - 5000 = 65200
        BigDecimal closingHuf = new BigDecimal("65200");

        List<Transaction> txs = List.of(
                makeSellTx(new BigDecimal("20000"), new BigDecimal("1000")), // fee benne van
                makeBuyTx(new BigDecimal("5000"), new BigDecimal("200"))
        );

        stubGenerateDecadeReport(openingHuf, closingHuf, txs);

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

            var dto = service.generateDecadeReport(BRANCH_ID, 2026, 1);

            // SELL contributes only hufAmount=20000 to income (not 20000+1000)
            // BUY contributes fee=200 to income, hufAmount=5000 to expense
            assertThat(dto.getForintTotalIncome()).isEqualByComparingTo(new BigDecimal("20200"));
            assertThat(dto.getForintControlValid()).isTrue();
        }
    }

    // =========================================================================
    // Bug 2: MNB árfolyam fallback — nem dob kivételt, előző nap árfolyamát veszi
    // =========================================================================

    @Test
    @DisplayName("Bug2: MNB fallback — ha adott napra nincs EUR árfolyam, előző nap árfolyamát használja")
    void testMnbRateFallbackUsedWhenDateMissing() {
        LocalDate periodStart = LocalDate.of(2026, 1, 1);
        LocalDate periodEnd   = LocalDate.of(2026, 1, 10);

        Branch branch = makeBranch();
        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));

        when(dailyBalanceRepository.findClosedDates(eq(BRANCH_ID), any(), any()))
                .thenReturn(List.of(periodEnd));

        when(decadeReportRepository.findByBranchIdAndYearAndDecade(BRANCH_ID, 2026, 1))
                .thenReturn(Optional.empty());

        when(transactionRepository.sumHufAmountByBranchAndTypeAndPeriod(any(), any(), any(), any()))
                .thenReturn(BigDecimal.ZERO);
        when(transactionRepository.sumFeeByBranchAndPeriod(any(), any(), any()))
                .thenReturn(BigDecimal.ZERO);
        when(transactionRepository.countByBranchAndPeriod(any(), any(), any()))
                .thenReturn(0L);

        // Forint kontroll: egyszerű setup
        when(transactionRepository.findFinanciallyEffectiveByBranchAndDateRange(any(), any(), any()))
                .thenReturn(Collections.emptyList());

        // Napi mérlegek: EUR pozíció létezik
        DailyBalance eurBalance = DailyBalance.builder()
                .balanceDate(periodStart)
                .currencyCode("EUR")
                .openingBalance(new BigDecimal("1000"))
                .closingBalance(new BigDecimal("1000"))
                .build();
        DailyBalance hufBalOpen = makeHufBalance(periodStart, BigDecimal.ZERO, BigDecimal.ZERO);
        DailyBalance hufBalClose = makeHufBalance(periodEnd, BigDecimal.ZERO, BigDecimal.ZERO);

        when(dailyBalanceRepository.findByBranchIdAndBalanceDate(BRANCH_ID, periodStart))
                .thenReturn(List.of(hufBalOpen, eurBalance));
        when(dailyBalanceRepository.findByBranchIdAndBalanceDate(BRANCH_ID, periodEnd))
                .thenReturn(List.of(hufBalClose, eurBalance));

        // getRatesForDate(periodStart/periodEnd) üres map-et ad vissza (pl. hétvége)
        when(mnbExchangeRateService.getRatesForDate(periodStart)).thenReturn(Collections.emptyMap());
        when(mnbExchangeRateService.getRatesForDate(periodEnd)).thenReturn(Collections.emptyMap());

        // Fallback: -1 nap sem talál, -2 nap EUR árfolyamot ad
        MnbExchangeRateCache eurRate = makeMnbRate("EUR", "395.50");
        when(mnbExchangeRateService.getRatesForDate(periodStart.minusDays(1))).thenReturn(Collections.emptyMap());
        when(mnbExchangeRateService.getRatesForDate(periodStart.minusDays(2)))
                .thenReturn(Map.of("EUR", eurRate));
        when(mnbExchangeRateService.getRatesForDate(periodEnd.minusDays(1))).thenReturn(Collections.emptyMap());
        when(mnbExchangeRateService.getRatesForDate(periodEnd.minusDays(2)))
                .thenReturn(Map.of("EUR", eurRate));

        when(decadeReportRepository.save(any(DecadeReport.class)))
                .thenAnswer(inv -> inv.getArgument(0));

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

            // Act — nem dob ValidationException-t
            var dto = service.generateDecadeReport(BRANCH_ID, 2026, 1);

            // Assert: az EUR árfolyam fallback-ból lett felhasználva
            assertThat(dto.getLines()).isNotEmpty();
            assertThat(dto.getLines().get(0).getCurrencyCode()).isEqualTo("EUR");
            assertThat(dto.getLines().get(0).getOpeningMnbRate())
                    .isEqualByComparingTo(new BigDecimal("395.50"));
        }
    }

    // =========================================================================
    // Bug 3: printControlFlag = true ha forint kontroll egyezik
    // =========================================================================

    @Test
    @DisplayName("Bug3: printControlFlag = true ha a forint kontroll egyezik")
    void testPrintControlFlagSetToTrueWhenForintControlValid() {
        // nyitó = záró, nincs tranzakció → diff = 0 → valid
        BigDecimal balance = new BigDecimal("200000");
        stubGenerateDecadeReport(balance, balance, Collections.emptyList());

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

            var dto = service.generateDecadeReport(BRANCH_ID, 2026, 1);

            assertThat(dto.getForintControlValid()).isTrue();
            assertThat(dto.getPrintControlFlag()).isTrue();
        }
    }

    @Test
    @DisplayName("Bug3: printControlFlag = false ha a forint kontroll eltér")
    void testPrintControlFlagSetToFalseWhenForintControlInvalid() {
        // nyitó = 100 000, záró = 99 000 (eltérés: -1000) → valid = false
        BigDecimal opening = new BigDecimal("100000");
        BigDecimal closing = new BigDecimal("99000");
        stubGenerateDecadeReport(opening, closing, Collections.emptyList());

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

            var dto = service.generateDecadeReport(BRANCH_ID, 2026, 1);

            assertThat(dto.getForintControlValid()).isFalse();
            assertThat(dto.getPrintControlFlag()).isFalse();
        }
    }

    // =========================================================================
    // Bug 4: ValidationException ha a dekád utolsó napja nincs lezárva
    // =========================================================================

    @Test
    @DisplayName("Bug4: ValidationException ha a dekád utolsó napja (jan 10) nincs lezárva")
    void testThrowsWhenLastDayOfDecadeNotClosed() {
        LocalDate periodStart = LocalDate.of(2026, 1, 1);
        LocalDate periodEnd   = LocalDate.of(2026, 1, 10);

        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(makeBranch()));

        // findClosedDates: csak jan 1–9 zárva, jan 10 hiányzik
        when(dailyBalanceRepository.findClosedDates(eq(BRANCH_ID), eq(periodStart), eq(periodEnd)))
                .thenReturn(List.of(
                        LocalDate.of(2026, 1, 1),
                        LocalDate.of(2026, 1, 2),
                        LocalDate.of(2026, 1, 9)
                        // jan 10 szándékosan hiányzik
                ));

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

            assertThatThrownBy(() -> service.generateDecadeReport(BRANCH_ID, 2026, 1))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("2026-01-10")
                    .hasMessageContaining("nincs lezárva");
        }
    }

    @Test
    @DisplayName("Bug4: Nincs kivétel ha az összes szükséges napzárás megvan")
    void testNoExceptionWhenLastDayIsClosed() {
        BigDecimal balance = new BigDecimal("50000");
        stubGenerateDecadeReport(balance, balance, Collections.emptyList());

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

            // Nem dob ValidationException-t
            assertThatCode(() -> service.generateDecadeReport(BRANCH_ID, 2026, 1))
                    .doesNotThrowAnyException();
        }
    }
}
