package hu.puzzleir.valuta.config;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.MnbReport;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.service.MnbReportService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.dao.DataIntegrityViolationException;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * MnbDailyReportScheduler.generateDailyDrafts — branch-enként izolált hibakezelés tesztje
 * (generált / kihagyott-létező / hibás), VV-ELVI 9.3.
 */
@ExtendWith(MockitoExtension.class)
class MnbDailyReportSchedulerTest {

    @Mock
    private BranchRepository branchRepository;

    @Mock
    private MnbReportService mnbReportService;

    @InjectMocks
    private MnbDailyReportScheduler scheduler;

    private static Branch branch(UUID id) {
        return Branch.builder().id(id).build();
    }

    @Test
    @DisplayName("Vegyes kimenet: 1 generált, 1 kihagyott (létező), 1 hibás — egy hiba nem állítja le a többit")
    void mixedOutcomesIsolated() {
        UUID ok = UUID.randomUUID();
        UUID exists = UUID.randomUUID();
        UUID fails = UUID.randomUUID();
        LocalDate date = LocalDate.of(2026, 5, 20);

        when(branchRepository.findByIsActiveTrue())
                .thenReturn(List.of(branch(ok), branch(exists), branch(fails)));
        // ok-branch: sikeres generálás (DRAFT visszaadva)
        when(mnbReportService.generateDailyReport(eq(ok), any()))
                .thenReturn(MnbReport.builder().build());
        when(mnbReportService.generateDailyReport(eq(exists), any()))
                .thenThrow(new ValidationException("Már létezik MNB napi riport erre a dátumra: " + date));
        when(mnbReportService.generateDailyReport(eq(fails), any()))
                .thenThrow(new RuntimeException("DB timeout"));

        var result = scheduler.generateDailyDrafts(date);

        assertThat(result.generated()).isEqualTo(1);
        assertThat(result.skipped()).isEqualTo(1);
        assertThat(result.failed()).isEqualTo(1);
        verify(mnbReportService, times(3)).generateDailyReport(any(), eq(date));
    }

    @Test
    @DisplayName("Konkurens insert: DataIntegrityViolationException is kihagyásnak számít (nem hiba)")
    void concurrentInsertCountsAsSkipped() {
        UUID ok = UUID.randomUUID();
        UUID race = UUID.randomUUID();
        LocalDate date = LocalDate.of(2026, 5, 20);

        when(branchRepository.findByIsActiveTrue()).thenReturn(List.of(branch(ok), branch(race)));
        when(mnbReportService.generateDailyReport(eq(ok), any()))
                .thenReturn(MnbReport.builder().build());
        when(mnbReportService.generateDailyReport(eq(race), any()))
                .thenThrow(new DataIntegrityViolationException(
                        "duplicate key value violates unique constraint \"uq_mnb_report_branch_type_date\""));

        var result = scheduler.generateDailyDrafts(date);

        assertThat(result.generated()).isEqualTo(1);
        assertThat(result.skipped()).isEqualTo(1);
        assertThat(result.failed()).isZero();
    }

    @Test
    @DisplayName("Nincs aktív iroda → minden számláló 0, nincs service-hívás")
    void noActiveBranches() {
        when(branchRepository.findByIsActiveTrue()).thenReturn(List.of());

        var result = scheduler.generateDailyDrafts(LocalDate.of(2026, 5, 20));

        assertThat(result.generated()).isZero();
        assertThat(result.skipped()).isZero();
        assertThat(result.failed()).isZero();
        verify(mnbReportService, times(0)).generateDailyReport(any(), any());
    }
}
