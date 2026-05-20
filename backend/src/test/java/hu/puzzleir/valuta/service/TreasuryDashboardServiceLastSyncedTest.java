package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.DailyReport;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.time.LocalDateTime;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * TreasuryDashboardService lastSyncedAt pure-helper tesztek (VV-ELVI frissesség).
 * reportTimestamp = submittedAt ?? createdAt; maxTimestamp = a későbbi, null-kihagyással.
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
    @DisplayName("maxTimestamp: a későbbi időbélyeget adja vissza")
    void maxReturnsLater() {
        LocalDateTime early = LocalDateTime.of(2026, 5, 20, 9, 0);
        LocalDateTime late = LocalDateTime.of(2026, 5, 20, 18, 0);

        assertThat(TreasuryDashboardService.maxTimestamp(early, late)).isEqualTo(late);
        assertThat(TreasuryDashboardService.maxTimestamp(late, early)).isEqualTo(late);
    }

    @Test
    @DisplayName("maxTimestamp: null-okat kihagyja; mindkettő null → null")
    void maxHandlesNull() {
        LocalDateTime t = LocalDateTime.of(2026, 5, 20, 12, 0);

        assertThat(TreasuryDashboardService.maxTimestamp(null, t)).isEqualTo(t);
        assertThat(TreasuryDashboardService.maxTimestamp(t, null)).isEqualTo(t);
        assertThat(TreasuryDashboardService.maxTimestamp(null, null)).isNull();
    }

    @Test
    @DisplayName("maxTimestamp asszociatív akkumuláció: riportok időbélyegeinek maximuma reportTimestamp-pel")
    void maxAccumulationOverReports() {
        DailyReport r1 = report(LocalDateTime.of(2026, 5, 20, 9, 0), LocalDateTime.of(2026, 5, 20, 7, 0));
        DailyReport r2 = report(null, LocalDateTime.of(2026, 5, 20, 18, 0)); // createdAt fallback, legkésőbbi
        DailyReport r3 = report(LocalDateTime.of(2026, 5, 20, 12, 0), LocalDateTime.of(2026, 5, 20, 6, 0));

        LocalDateTime acc = null;
        for (DailyReport r : new DailyReport[]{r1, r2, r3}) {
            acc = TreasuryDashboardService.maxTimestamp(acc, TreasuryDashboardService.reportTimestamp(r));
        }
        assertThat(acc).isEqualTo(LocalDateTime.of(2026, 5, 20, 18, 0));
    }
}
