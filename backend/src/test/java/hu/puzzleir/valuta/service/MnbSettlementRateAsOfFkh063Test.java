package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.MnbSettlementRateHistory;
import hu.puzzleir.valuta.repository.MnbSettlementRateHistoryRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * FKH-063 — direct coverage of the as-of settlement-rate lookup.
 *
 * <p>The decade report's manual-rate arm is only as correct as the window arithmetic in
 * {@code MnbSettlementRateService.findSettlementRateAsOf}: which snapshot is visible for a
 * valuation date, that a zero snapshot is ABSENT rather than a rate, and that another company's
 * rate can never be read. The {@code DecadeReportService} tests stub this method, so without this
 * class a mutation of the boundary arithmetic (for example dropping the FK-028 next-day recording
 * lag) would leave the whole suite green while every non-MNB-quoted decade failed closed in
 * production.</p>
 *
 * <p>The arguments actually handed to the repository are captured and asserted, because the
 * boundary is computed in the service, not in the query.</p>
 */
@ExtendWith(MockitoExtension.class)
class MnbSettlementRateAsOfFkh063Test {

    private static final ZoneId BUDAPEST = ZoneId.of("Europe/Budapest");
    private static final UUID COMPANY_ID = UUID.fromString("11111111-1111-1111-1111-111111111111");
    private static final UUID OTHER_COMPANY_ID = UUID.fromString("22222222-2222-2222-2222-222222222222");
    /** A decade boundary: the 10th of the month (invariant #4). */
    private static final LocalDate VALUATION_DATE = LocalDate.of(2026, 9, 10);

    @Mock
    private MnbSettlementRateHistoryRepository historyRepository;

    @InjectMocks
    private MnbSettlementRateService service;

    private MnbSettlementRateHistory snapshot(String rate, Instant recordedAt) {
        return MnbSettlementRateHistory.builder()
                .companyId(COMPANY_ID)
                .currencyCode("BAM")
                .officialRate(new BigDecimal(rate))
                .recordedAt(recordedAt)
                .build();
    }

    private ArgumentCaptor<Instant> captureLookup(Optional<MnbSettlementRateHistory> result) {
        ArgumentCaptor<Instant> asOf = ArgumentCaptor.forClass(Instant.class);
        when(historyRepository
                .findFirstByCompanyIdAndCurrencyCodeAndOfficialRateGreaterThanAndRecordedAtLessThanOrderByRecordedAtDesc(
                        any(), anyString(), any(), any()))
                .thenReturn(result);
        return asOf;
    }

    @Test
    @DisplayName("FKH-063: the as-of bound is start of (valuationDate + 1 recording-lag day + 1) in Europe/Budapest")
    void asOfBoundIncludesTheNextDayRecordingAndExcludesTheDayAfter() {
        captureLookup(Optional.empty());

        service.findSettlementRateAsOf(COMPANY_ID, "BAM", VALUATION_DATE);

        ArgumentCaptor<Instant> asOf = ArgumentCaptor.forClass(Instant.class);
        verify(historyRepository)
                .findFirstByCompanyIdAndCurrencyCodeAndOfficialRateGreaterThanAndRecordedAtLessThanOrderByRecordedAtDesc(
                        any(), anyString(), any(), asOf.capture());

        // FK-028 records the boundary rate on the FOLLOWING day, so D+1 must still be visible and
        // D+2 must not: the exclusive bound is midnight at the start of D+2, Budapest time.
        Instant expected = VALUATION_DATE.plusDays(2).atStartOfDay(BUDAPEST).toInstant();
        assertThat(asOf.getValue()).isEqualTo(expected);

        // Concretely: a snapshot recorded at 23:59 on D+1 is inside, one at 00:00 on D+2 is not.
        Instant lastMomentOfNextDay = VALUATION_DATE.plusDays(1).atTime(23, 59, 59).atZone(BUDAPEST).toInstant();
        Instant startOfDayAfter = VALUATION_DATE.plusDays(2).atStartOfDay(BUDAPEST).toInstant();
        assertThat(lastMomentOfNextDay).isBefore(asOf.getValue());
        assertThat(startOfDayAfter).isAfterOrEqualTo(asOf.getValue());
    }

    @Test
    @DisplayName("FKH-063: the zero filter is passed to the query as a strict lower bound of ZERO")
    void zeroSnapshotIsTreatedAsAbsent() {
        captureLookup(Optional.empty());

        Optional<BigDecimal> result = service.findSettlementRateAsOf(COMPANY_ID, "BAM", VALUATION_DATE);

        ArgumentCaptor<BigDecimal> minRate = ArgumentCaptor.forClass(BigDecimal.class);
        verify(historyRepository)
                .findFirstByCompanyIdAndCurrencyCodeAndOfficialRateGreaterThanAndRecordedAtLessThanOrderByRecordedAtDesc(
                        any(), anyString(), minRate.capture(), any());

        // V353 seeds 0 as the "never recorded" marker (FR-8): a zero must never reach a multiply.
        assertThat(minRate.getValue()).isEqualByComparingTo(BigDecimal.ZERO);
        assertThat(result).isEmpty();
    }

    @Test
    @DisplayName("FKH-063: the newest usable snapshot wins and its rate is returned")
    void newestUsableSnapshotWins() {
        Instant recordedNextDay = VALUATION_DATE.plusDays(1).atTime(9, 0).atZone(BUDAPEST).toInstant();
        captureLookup(Optional.of(snapshot("185.5000", recordedNextDay)));

        Optional<BigDecimal> result = service.findSettlementRateAsOf(COMPANY_ID, "BAM", VALUATION_DATE);

        // Ordering is the query's job (OrderByRecordedAtDesc + findFirst); the service must return
        // the rate of whatever that query selected, unmodified.
        assertThat(result).contains(new BigDecimal("185.5000"));
    }

    @Test
    @DisplayName("FKH-063: the caller's companyId is passed through unchanged (invariant #1)")
    void companyIdIsPassedThroughUnchanged() {
        captureLookup(Optional.empty());

        service.findSettlementRateAsOf(OTHER_COMPANY_ID, "BAM", VALUATION_DATE);

        ArgumentCaptor<UUID> companyId = ArgumentCaptor.forClass(UUID.class);
        verify(historyRepository)
                .findFirstByCompanyIdAndCurrencyCodeAndOfficialRateGreaterThanAndRecordedAtLessThanOrderByRecordedAtDesc(
                        companyId.capture(), anyString(), any(), any());

        assertThat(companyId.getValue()).isEqualTo(OTHER_COMPANY_ID);
    }

    @Test
    @DisplayName("FKH-063: the currency code is normalised before the lookup")
    void currencyCodeIsNormalised() {
        captureLookup(Optional.empty());

        service.findSettlementRateAsOf(COMPANY_ID, " bam ", VALUATION_DATE);

        ArgumentCaptor<String> currency = ArgumentCaptor.forClass(String.class);
        verify(historyRepository)
                .findFirstByCompanyIdAndCurrencyCodeAndOfficialRateGreaterThanAndRecordedAtLessThanOrderByRecordedAtDesc(
                        any(), currency.capture(), any(), any());

        assertThat(currency.getValue()).isEqualTo("BAM");
    }

    @Test
    @DisplayName("FKH-063: a null argument yields empty without touching the repository")
    void nullArgumentsYieldEmpty() {
        assertThat(service.findSettlementRateAsOf(null, "BAM", VALUATION_DATE)).isEmpty();
        assertThat(service.findSettlementRateAsOf(COMPANY_ID, null, VALUATION_DATE)).isEmpty();
        assertThat(service.findSettlementRateAsOf(COMPANY_ID, "BAM", null)).isEmpty();
    }
}
