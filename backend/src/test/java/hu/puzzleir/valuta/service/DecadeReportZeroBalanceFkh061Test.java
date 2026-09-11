package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.DailyBalance;
import hu.puzzleir.valuta.entity.DecadeReport;
import hu.puzzleir.valuta.entity.DecadeReportLine;
import hu.puzzleir.valuta.entity.MnbExchangeRateCache;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.DailyBalanceRepository;
import hu.puzzleir.valuta.repository.DecadeReportRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.when;

/**
 * FKH-061 (Defect D part 1) — a zero-stock currency must not require an MNB rate.
 *
 * <p>Production evidence: the decade currency set is built from the daily-balance rows, which
 * include currencies MNB does not quote (BAM, RSD — both 0.00 opening AND 0.00 closing).
 * {@code getUnitRate} threw a {@link ValidationException} for those, which failed the whole decade
 * report; because {@code generateDecadeReport} joined the day-closing transaction, that failure
 * marked the transaction rollback-only and the day closing died with HTTP 500.</p>
 *
 * <p>RED on BASE 1588b5b2: {@code zeroStockCurrencyNeedsNoMnbRate} fails with
 * "Hiányzó MNB árfolyam a dekádjelentés generálásához: BAM". The second case pins that a NON-zero
 * stock without a rate still throws (invariant #5 — an MNB rate is mandatory where it affects
 * money), so the fix cannot degrade into silently valuing real stock at zero.</p>
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class DecadeReportZeroBalanceFkh061Test {

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
    /**
     * FKH-063: DecadeReportService gained a second rate source. Left unstubbed here, so
     * {@code findSettlementRateAsOf} returns an empty Optional and the fail-closed throw of
     * {@code nonZeroStockStillRequiresMnbRate} still asserts the "no rate from ANY source"
     * behaviour this test was written for.
     */
    @Mock
    private MnbSettlementRateService mnbSettlementRateService;

    private final UUID BRANCH_ID = UUID.randomUUID();
    private final UUID COMPANY_ID = UUID.randomUUID();

    private static final LocalDate PERIOD_START = LocalDate.of(2026, 9, 1);
    private static final LocalDate PERIOD_END = LocalDate.of(2026, 9, 10);
    /** Global decade 25 = September, third-of-month index 1 => 2026-09-01..2026-09-10. */
    private static final int DECADE = 25;

    private Branch makeBranch() {
        Company company = Company.builder().id(COMPANY_ID).build();
        return Branch.builder().id(BRANCH_ID).company(company).build();
    }

    private DailyBalance balance(LocalDate date, String currency, String opening, String closing) {
        return DailyBalance.builder()
                .balanceDate(date)
                .currencyCode(currency)
                .openingBalance(new BigDecimal(opening))
                .closingBalance(new BigDecimal(closing))
                .build();
    }

    private MnbExchangeRateCache rate(String currency, String ratePerUnit) {
        return MnbExchangeRateCache.builder()
                .currencyCode(currency)
                .officialRate(new BigDecimal(ratePerUnit))
                .unit(1)
                .build();
    }

    private void stubCommon(List<DailyBalance> opening, List<DailyBalance> closing) {
        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(makeBranch()));
        when(dailyBalanceRepository.findClosedDates(eq(COMPANY_ID), eq(BRANCH_ID), eq(PERIOD_START), eq(PERIOD_END)))
                .thenReturn(List.of(PERIOD_END));
        when(decadeReportRepository.findByBranchIdAndYearAndDecade(BRANCH_ID, 2026, DECADE))
                .thenReturn(Optional.empty());
        when(transactionRepository.sumHufAmountByBranchAndTypeAndPeriod(any(), anyString(), any(), any()))
                .thenReturn(BigDecimal.ZERO);
        when(transactionRepository.sumFeeByBranchAndPeriod(any(), any(), any())).thenReturn(BigDecimal.ZERO);
        when(transactionRepository.countByBranchAndPeriod(any(), any(), any())).thenReturn(0L);

        when(dailyBalanceRepository.findByBranchIdAndBalanceDate(eq(COMPANY_ID), eq(BRANCH_ID), eq(PERIOD_START)))
                .thenReturn(opening);
        when(dailyBalanceRepository.findByBranchIdAndBalanceDate(eq(COMPANY_ID), eq(BRANCH_ID), eq(PERIOD_END)))
                .thenReturn(closing);

        when(decadeReportRepository.save(any(DecadeReport.class)))
                .thenAnswer(inv -> inv.getArgument(0));
    }

    @Test
    @DisplayName("FKH-061: zero-stock currency without an MNB rate is valued 0 HUF with a null rate")
    void zeroStockCurrencyNeedsNoMnbRate() {
        // BAM: no MNB rate anywhere, zero stock on both period ends (production shape).
        // EUR: real stock with a real rate — proves the normal path still values money.
        stubCommon(
                List.of(balance(PERIOD_START, "BAM", "0.00", "0.00"),
                        balance(PERIOD_START, "EUR", "1000.00", "1000.00")),
                List.of(balance(PERIOD_END, "BAM", "0.00", "0.00"),
                        balance(PERIOD_END, "EUR", "1200.00", "1200.00")));

        // Only EUR is quoted; every BAM lookup (incl. the 7-day walk-back) returns nothing.
        when(mnbExchangeRateService.getRatesForDate(any()))
                .thenReturn(Map.of("EUR", rate("EUR", "400.00")));

        ArgumentCaptor<DecadeReport> saved = ArgumentCaptor.forClass(DecadeReport.class);

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

            // RED on BASE: throws ValidationException "Hiányzó MNB árfolyam ...: BAM".
            service.generateDecadeReport(BRANCH_ID, 2026, DECADE);
        }

        org.mockito.Mockito.verify(decadeReportRepository).save(saved.capture());
        List<DecadeReportLine> lines = saved.getValue().getLines();

        DecadeReportLine bam = lines.stream()
                .filter(l -> "BAM".equals(l.getCurrencyCode()))
                .findFirst()
                .orElseThrow(() -> new AssertionError("BAM line missing"));

        // No rate is claimed for a currency we could not price, and the value is honestly zero.
        assertThat(bam.getOpeningMnbRate()).isNull();
        assertThat(bam.getClosingMnbRate()).isNull();
        assertThat(bam.getOpeningValueHuf()).isEqualByComparingTo("0.00");
        assertThat(bam.getClosingValueHuf()).isEqualByComparingTo("0.00");
        assertThat(bam.getProfitHuf()).isEqualByComparingTo("0.00");

        // The money-bearing currency is still valued from the real MNB rate.
        DecadeReportLine eur = lines.stream()
                .filter(l -> "EUR".equals(l.getCurrencyCode()))
                .findFirst()
                .orElseThrow(() -> new AssertionError("EUR line missing"));
        assertThat(eur.getOpeningValueHuf()).isEqualByComparingTo("400000.00");
        assertThat(eur.getClosingValueHuf()).isEqualByComparingTo("480000.00");
        assertThat(eur.getProfitHuf()).isEqualByComparingTo("80000.00");
    }

    @Test
    @DisplayName("FKH-061: NON-zero stock without an MNB rate still fails hard (invariant #5)")
    void nonZeroStockStillRequiresMnbRate() {
        stubCommon(
                List.of(balance(PERIOD_START, "EUR", "2634.00", "2634.00")),
                List.of(balance(PERIOD_END, "EUR", "2634.00", "2634.00")));

        // No rate for EUR on any date, and the walk-back finds nothing either.
        when(mnbExchangeRateService.getRatesForDate(any())).thenReturn(Map.of());

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

            assertThatThrownBy(() -> service.generateDecadeReport(BRANCH_ID, 2026, DECADE))
                    .isInstanceOf(ValidationException.class)
                    // FKH-063: the message now names BOTH exhausted sources (MNB cache + walk-back
                    // AND the FK-028 settlement rate). The asserted behaviour is unchanged:
                    // non-zero stock without any usable rate still fails closed.
                    .hasMessageContaining("Hiányzó értékelési árfolyam")
                    .hasMessageContaining("EUR");
        }
    }
}
