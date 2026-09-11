package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.decade.DecadeReportDto;
import hu.puzzleir.valuta.dto.decade.DecadeReportLineDto;
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
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

/**
 * FKH-063 — a currency MNB does not quote (BAM/BRL/EUA/ILS/MXN/NZD/RSD/THB) must be valued
 * from the company's hand-entered FK-028 settlement rate, with the rate provenance persisted.
 *
 * <p>RED on BASE b2c27b6d: {@code DecadeReportService} has no settlement-rate collaborator and
 * {@code DecadeReportLine} has no provenance fields set, so the manual-rate cases fail with the
 * FKH-061 "Hiányzó MNB árfolyam" throw (missing manual source) or with a null source (missing
 * provenance) — business reasons, not wiring errors. The {@code @Mock MnbSettlementRateService}
 * exists from WU-1 (Mockito tolerates an unused mock); the
 * {@code mnbQuotedCurrencyStillUsesMnbCacheAndWalkBack} pin becomes behaviour-meaningful only
 * from WU-4, when the collaborator is actually injected.</p>
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class DecadeReportManualRateFkh063Test {

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
    @Mock
    private MnbSettlementRateService mnbSettlementRateService;

    private final UUID BRANCH_ID = UUID.randomUUID();
    private final UUID COMPANY_ID = UUID.randomUUID();

    private static final LocalDate PERIOD_START = LocalDate.of(2026, 9, 1);
    private static final LocalDate PERIOD_END = LocalDate.of(2026, 9, 10);
    /** Global decade 25 = September, first-of-month index => 2026-09-01..2026-09-10. */
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

    private DecadeReportLine lineOf(List<DecadeReportLine> lines, String currency) {
        return lines.stream()
                .filter(l -> currency.equals(l.getCurrencyCode()))
                .findFirst()
                .orElseThrow(() -> new AssertionError(currency + " line missing"));
    }

    @Test
    @DisplayName("FKH-063: non-zero BAM stock is valued from the manual settlement rate with MANUAL_SETTLEMENT provenance")
    void manualRateValuesNonZeroStockAndRecordsProvenance() {
        stubCommon(
                List.of(balance(PERIOD_START, "BAM", "1000.0000", "1000.0000")),
                List.of(balance(PERIOD_END, "BAM", "1500.0000", "1500.0000")));
        // MNB does not quote BAM: empty map for the boundary dates and every walk-back date.
        when(mnbExchangeRateService.getRatesForDate(any())).thenReturn(Map.of());
        when(mnbSettlementRateService.findSettlementRateAsOf(COMPANY_ID, "BAM", PERIOD_START))
                .thenReturn(Optional.of(new BigDecimal("185.5000")));
        when(mnbSettlementRateService.findSettlementRateAsOf(COMPANY_ID, "BAM", PERIOD_END))
                .thenReturn(Optional.of(new BigDecimal("185.5000")));

        DecadeReportDto dto;
        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            // RED on BASE: throws ValidationException "Hiányzó MNB árfolyam ...: BAM".
            dto = service.generateDecadeReport(BRANCH_ID, 2026, DECADE);
        }

        ArgumentCaptor<DecadeReport> saved = ArgumentCaptor.forClass(DecadeReport.class);
        verify(decadeReportRepository).save(saved.capture());
        DecadeReportLine bam = lineOf(saved.getValue().getLines(), "BAM");

        assertThat(bam.getOpeningMnbRate()).isEqualByComparingTo("185.5000");
        assertThat(bam.getClosingMnbRate()).isEqualByComparingTo("185.5000");
        assertThat(bam.getOpeningValueHuf()).isEqualByComparingTo("185500.00");
        assertThat(bam.getClosingValueHuf()).isEqualByComparingTo("278250.00");
        assertThat(bam.getProfitHuf()).isEqualByComparingTo("92750.00");
        assertThat(saved.getValue().getDecadeProfitHuf()).isEqualByComparingTo("92750.00");
        // Provenance is persisted on the line (RED on BASE: fields are null).
        assertThat(bam.getOpeningRateSource()).isEqualTo("MANUAL_SETTLEMENT");
        assertThat(bam.getClosingRateSource()).isEqualTo("MANUAL_SETTLEMENT");
        // ...and surfaced on the DTO.
        DecadeReportLineDto bamDto = dto.getLines().stream()
                .filter(l -> "BAM".equals(l.getCurrencyCode()))
                .findFirst()
                .orElseThrow(() -> new AssertionError("BAM DTO line missing"));
        assertThat(bamDto.getOpeningRateSource()).isEqualTo("MANUAL_SETTLEMENT");
        assertThat(bamDto.getClosingRateSource()).isEqualTo("MANUAL_SETTLEMENT");
    }

    @Test
    @DisplayName("FKH-063: non-zero stock with neither MNB nor manual rate fails closed, naming both sources")
    void missingBothSourcesFailsClosed() {
        stubCommon(
                List.of(balance(PERIOD_START, "BAM", "1000.0000", "1000.0000")),
                List.of(balance(PERIOD_END, "BAM", "1500.0000", "1500.0000")));
        when(mnbExchangeRateService.getRatesForDate(any())).thenReturn(Map.of());
        when(mnbSettlementRateService.findSettlementRateAsOf(eq(COMPANY_ID), eq("BAM"), any()))
                .thenReturn(Optional.empty());

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

            // RED on BASE: the message names only the MNB source, not the exhausted manual one.
            assertThatThrownBy(() -> service.generateDecadeReport(BRANCH_ID, 2026, DECADE))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("BAM")
                    .hasMessageContaining("MNB elszámolási");
        }

        // No silent zero valuation: nothing at all was saved.
        verify(decadeReportRepository, never()).save(any());
    }

    @Test
    @DisplayName("FKH-063 pin: an MNB-quoted currency still resolves from the MNB cache/walk-back, never the manual rate")
    void mnbQuotedCurrencyStillUsesMnbCacheAndWalkBack() {
        stubCommon(
                List.of(balance(PERIOD_START, "EUR", "1000.00", "1000.00")),
                List.of(balance(PERIOD_END, "EUR", "1200.00", "1200.00")));
        // Opening: EUR absent on periodStart, present 3 days back (walk-back hit).
        // Closing: EUR present directly on periodEnd (map hit).
        when(mnbExchangeRateService.getRatesForDate(any())).thenReturn(Map.of());
        when(mnbExchangeRateService.getRatesForDate(PERIOD_START.minusDays(3)))
                .thenReturn(Map.of("EUR", rate("EUR", "400.00")));
        when(mnbExchangeRateService.getRatesForDate(PERIOD_END))
                .thenReturn(Map.of("EUR", rate("EUR", "400.00")));
        // A different manual value exists — it must never be consulted for an MNB-quoted currency.
        when(mnbSettlementRateService.findSettlementRateAsOf(eq(COMPANY_ID), eq("EUR"), any()))
                .thenReturn(Optional.of(new BigDecimal("999.0000")));

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            service.generateDecadeReport(BRANCH_ID, 2026, DECADE);
        }

        ArgumentCaptor<DecadeReport> saved = ArgumentCaptor.forClass(DecadeReport.class);
        verify(decadeReportRepository).save(saved.capture());
        DecadeReportLine eur = lineOf(saved.getValue().getLines(), "EUR");

        assertThat(eur.getOpeningMnbRate()).isEqualByComparingTo("400.00");
        assertThat(eur.getClosingMnbRate()).isEqualByComparingTo("400.00");
        assertThat(eur.getOpeningValueHuf()).isEqualByComparingTo("400000.00");
        assertThat(eur.getClosingValueHuf()).isEqualByComparingTo("480000.00");
        // RED on BASE: source fields are null (provenance not recorded yet).
        assertThat(eur.getOpeningRateSource()).isEqualTo("MNB");
        assertThat(eur.getClosingRateSource()).isEqualTo("MNB");
        verifyNoInteractions(mnbSettlementRateService);
    }

    @Test
    @DisplayName("FKH-063 pin: zero stock needs no rate, no provenance and no manual lookup (FKH-061 kept)")
    void zeroStockNeedsNoRateAndNoProvenance() {
        stubCommon(
                List.of(balance(PERIOD_START, "BAM", "0.0000", "0.0000")),
                List.of(balance(PERIOD_END, "BAM", "0.0000", "0.0000")));
        when(mnbExchangeRateService.getRatesForDate(any())).thenReturn(Map.of());
        when(mnbSettlementRateService.findSettlementRateAsOf(eq(COMPANY_ID), eq("BAM"), any()))
                .thenReturn(Optional.empty());

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            service.generateDecadeReport(BRANCH_ID, 2026, DECADE);
        }

        ArgumentCaptor<DecadeReport> saved = ArgumentCaptor.forClass(DecadeReport.class);
        verify(decadeReportRepository).save(saved.capture());
        DecadeReportLine bam = lineOf(saved.getValue().getLines(), "BAM");

        assertThat(bam.getOpeningMnbRate()).isNull();
        assertThat(bam.getClosingMnbRate()).isNull();
        assertThat(bam.getOpeningRateSource()).isNull();
        assertThat(bam.getClosingRateSource()).isNull();
        assertThat(bam.getOpeningValueHuf()).isEqualByComparingTo("0.00");
        assertThat(bam.getClosingValueHuf()).isEqualByComparingTo("0.00");
        verify(mnbSettlementRateService, never()).findSettlementRateAsOf(any(), anyString(), any());
    }

    @Test
    @DisplayName("FKH-063: when the MNB map quotes the currency, MNB wins over an existing manual snapshot")
    void mnbTakesPrecedenceOverManual() {
        stubCommon(
                List.of(balance(PERIOD_START, "BAM", "1000.0000", "1000.0000")),
                List.of(balance(PERIOD_END, "BAM", "1500.0000", "1500.0000")));
        // Hypothetical: MNB quotes BAM on both boundary dates.
        when(mnbExchangeRateService.getRatesForDate(PERIOD_START))
                .thenReturn(Map.of("BAM", rate("BAM", "190.00")));
        when(mnbExchangeRateService.getRatesForDate(PERIOD_END))
                .thenReturn(Map.of("BAM", rate("BAM", "190.00")));
        when(mnbSettlementRateService.findSettlementRateAsOf(eq(COMPANY_ID), eq("BAM"), any()))
                .thenReturn(Optional.of(new BigDecimal("185.5000")));

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            service.generateDecadeReport(BRANCH_ID, 2026, DECADE);
        }

        ArgumentCaptor<DecadeReport> saved = ArgumentCaptor.forClass(DecadeReport.class);
        verify(decadeReportRepository).save(saved.capture());
        DecadeReportLine bam = lineOf(saved.getValue().getLines(), "BAM");

        // RED on BASE: source fields are null; from WU-4 the MNB map hit short-circuits the manual lookup.
        assertThat(bam.getOpeningMnbRate()).isEqualByComparingTo("190.00");
        assertThat(bam.getClosingMnbRate()).isEqualByComparingTo("190.00");
        assertThat(bam.getOpeningRateSource()).isEqualTo("MNB");
        assertThat(bam.getClosingRateSource()).isEqualTo("MNB");
        verify(mnbSettlementRateService, never()).findSettlementRateAsOf(any(), anyString(), any());
    }
}
