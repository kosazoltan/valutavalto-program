package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.ClosingControl;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.entity.WorkerRole;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.ClosingControlRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class DailyClosingMissedAlertServiceTest {

    @Mock private BranchRepository branchRepository;
    @Mock private ClosingControlRepository closingControlRepository;
    @Mock private WorkerRepository workerRepository;
    @Mock private NotificationService notificationService;
    @Mock private AuditLogService auditLogService;

    @InjectMocks
    private DailyClosingMissedAlertService service;

    private static final LocalDate TARGET_DATE = LocalDate.of(2026, 6, 8);

    @Test
    @DisplayName("Hiányzó ClosingControl esetén company supervisorok értesítést kapnak")
    void alertsSupervisorsWhenClosingControlMissing() {
        Company company = company();
        Branch branch = branch(company, "001", false, false);
        Worker supervisor = worker(company, 10L, WorkerRole.SUPERVISOR);

        when(branchRepository.findActiveClosingMonitoredBranches()).thenReturn(List.of(branch));
        when(closingControlRepository.findByCompanyIdAndBranchIdAndControlDate(company.getId(), branch.getId(), TARGET_DATE))
                .thenReturn(Optional.empty());
        when(auditLogService.existsByActionAndReferenceForCompany(
                DailyClosingMissedAlertService.AUDIT_ACTION,
                company.getId() + ":" + TARGET_DATE,
                company.getId())).thenReturn(false);
        when(workerRepository.findSupervisorsAndAbove(company.getId())).thenReturn(List.of(supervisor));

        DailyClosingMissedAlertService.DailyClosingMissedAlertResult result = service.checkDate(TARGET_DATE);

        assertThat(result.missedBranches()).isEqualTo(1);
        assertThat(result.companiesAlerted()).isEqualTo(1);
        assertThat(result.notificationsSent()).isEqualTo(1);
        verify(notificationService).sendToWorker(
                eq(10L),
                eq("P0 napzárás-kimaradás - " + TARGET_DATE),
                any(String.class),
                eq(DailyClosingMissedAlertService.NOTIFICATION_TYPE));
        verify(auditLogService).logForCompany(
                eq(DailyClosingMissedAlertService.AUDIT_ACTION),
                any(String.class),
                eq(company.getId() + ":" + TARGET_DATE),
                eq(company.getId()));
    }

    @Test
    @DisplayName("Kész napi zárásnál nincs alert")
    void doesNotAlertWhenDailyClosingDone() {
        Company company = company();
        Branch branch = branch(company, "001", false, false);
        ClosingControl control = ClosingControl.builder()
                .companyId(company.getId())
                .branchId(branch.getId())
                .controlDate(TARGET_DATE)
                .dailyClosingDone(true)
                .build();

        when(branchRepository.findActiveClosingMonitoredBranches()).thenReturn(List.of(branch));
        when(closingControlRepository.findByCompanyIdAndBranchIdAndControlDate(company.getId(), branch.getId(), TARGET_DATE))
                .thenReturn(Optional.of(control));

        DailyClosingMissedAlertService.DailyClosingMissedAlertResult result = service.checkDate(TARGET_DATE);

        assertThat(result.missedBranches()).isZero();
        verify(notificationService, never()).sendToWorker(any(), any(), any(), any());
        verify(auditLogService, never()).logForCompany(any(), any(), any(), any());
    }

    @Test
    @DisplayName("Vasárnap zárva tartó iroda nem számít hiányzónak")
    void skipsBranchClosedOnSunday() {
        Company company = company();
        LocalDate sunday = LocalDate.of(2026, 6, 7);
        Branch branch = branch(company, "001", false, true);

        when(branchRepository.findActiveClosingMonitoredBranches()).thenReturn(List.of(branch));

        DailyClosingMissedAlertService.DailyClosingMissedAlertResult result = service.checkDate(sunday);

        assertThat(result.missedBranches()).isZero();
        verify(closingControlRepository, never()).findByCompanyIdAndBranchIdAndControlDate(any(), any(), any());
        verify(notificationService, never()).sendToWorker(any(), any(), any(), any());
    }

    @Test
    @DisplayName("Már auditált napi alert nem küld új értesítést")
    void skipsAlreadyAuditedAlert() {
        Company company = company();
        Branch branch = branch(company, "001", false, false);

        when(branchRepository.findActiveClosingMonitoredBranches()).thenReturn(List.of(branch));
        when(closingControlRepository.findByCompanyIdAndBranchIdAndControlDate(company.getId(), branch.getId(), TARGET_DATE))
                .thenReturn(Optional.empty());
        when(auditLogService.existsByActionAndReferenceForCompany(
                DailyClosingMissedAlertService.AUDIT_ACTION,
                company.getId() + ":" + TARGET_DATE,
                company.getId())).thenReturn(true);

        DailyClosingMissedAlertService.DailyClosingMissedAlertResult result = service.checkDate(TARGET_DATE);

        assertThat(result.missedBranches()).isEqualTo(1);
        assertThat(result.companiesAlerted()).isZero();
        assertThat(result.skippedAlreadyAudited()).isEqualTo(1);
        verify(workerRepository, never()).findSupervisorsAndAbove(any());
        verify(notificationService, never()).sendToWorker(any(), any(), any(), any());
    }

    private Company company() {
        return Company.builder()
                .id(UUID.randomUUID())
                .code("BEST")
                .name("Exclusive Best Change Zrt.")
                .build();
    }

    private Branch branch(Company company, String code, boolean closedSaturday, boolean closedSunday) {
        return Branch.builder()
                .id(UUID.randomUUID())
                .company(company)
                .code(code)
                .name("Teszt iroda " + code)
                .openingDate(LocalDate.of(2020, 1, 1))
                .closedSaturday(closedSaturday)
                .closedSunday(closedSunday)
                .isActive(true)
                .build();
    }

    private Worker worker(Company company, Long id, WorkerRole role) {
        return Worker.builder()
                .id(id)
                .company(company)
                .code("W" + id)
                .name("Supervisor " + id)
                .role(role)
                .active(true)
                .build();
    }
}
