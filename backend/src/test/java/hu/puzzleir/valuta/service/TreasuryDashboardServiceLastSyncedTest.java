package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.DailyReport;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * TreasuryDashboardService lastSyncedAt pure-helper tesztek (VV-ELVI frissesség).
 * reportTimestamp = submittedAt ?? createdAt; latestReportTimestamp = max (null-kihagyással).
 */
class TreasuryDashboardServiceLastSyncedTest {

    private static DailyReport report(LocalDateTime submittedAt, LocalDateTime createdAt) {
        return DailyReport.builder().submittedAt(submittedAt).createdAt(createdAt).build();
    }

    @Test
    @DisplayName("reportTimestamp: submittedAt-ot ad ha van, különben createdAt-ot")
    void reportTimestampPrefersSubmitted() {
        LocalDateTime submitted = LocalDateTime.of(2026, 5, 20, 17, 0);
        LocalDateTime created = LocalDateTime.of(2026, 5, 20, 8, 0);

        assertThat(TreasuryDashboardService.reportTimestamp(report(submitted, created))).isEqualTo(submitted);
        assertThat(TreasuryDashboardService.reportTimestamp(report(null, created))).isEqualTo(created);
        assertThat(TreasuryDashboardService.reportTimestamp(null)).isNull();
    }

    @Test
    @DisplayName("latestReportTimestamp: a riportok közül a legkésőbbi (submittedAt/createdAt) időbélyeg")
    void latestAcrossReports() {
        DailyReport r1 = report(LocalDateTime.of(2026, 5, 20, 9, 0), LocalDateTime.of(2026, 5, 20, 7, 0));
        DailyReport r2 = report(null, LocalDateTime.of(2026, 5, 20, 18, 0)); // createdAt fallback, legkésőbbi
        DailyReport r3 = report(LocalDateTime.of(2026, 5, 20, 12, 0), LocalDateTime.of(2026, 5, 20, 6, 0));

        assertThat(TreasuryDashboardService.latestReportTimestamp(List.of(r1, r2, r3)))
                .isEqualTo(LocalDateTime.of(2026, 5, 20, 18, 0));
    }

    @Test
    @DisplayName("latestReportTimestamp: üres/null/csupa-null → null")
    void latestEmptyOrNull() {
        assertThat(TreasuryDashboardService.latestReportTimestamp(List.of())).isNull();
        assertThat(TreasuryDashboardService.latestReportTimestamp(null)).isNull();
        assertThat(TreasuryDashboardService.latestReportTimestamp(
                Arrays.asList(report(null, null), report(null, null)))).isNull();
    }
}
