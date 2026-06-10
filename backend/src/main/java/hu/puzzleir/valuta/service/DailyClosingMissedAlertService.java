package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.ClosingControl;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.ClosingControlRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * P0 Product Ready kontroll: elozo napi napzaras-kimaradas detektalas es supervisor alert.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class DailyClosingMissedAlertService {

    static final String AUDIT_ACTION = "DAILY_CLOSING_MISSED_ALERT";
    static final String NOTIFICATION_TYPE = "DAILY_CLOSING_MISSED";

    private final BranchRepository branchRepository;
    private final ClosingControlRepository closingControlRepository;
    private final WorkerRepository workerRepository;
    private final NotificationService notificationService;
    private final AuditLogService auditLogService;

    @Transactional(rollbackFor = Exception.class)
    public DailyClosingMissedAlertResult checkYesterday() {
        return checkDate(LocalDate.now().minusDays(1));
    }

    @Transactional(rollbackFor = Exception.class)
    public DailyClosingMissedAlertResult checkDate(LocalDate targetDate) {
        if (targetDate == null) {
            throw new IllegalArgumentException("targetDate nem lehet null");
        }

        List<MissedBranchClosing> missed = findMissedClosings(targetDate);
        if (missed.isEmpty()) {
            log.info("Napzaras-kimaradas ellenorzes: nincs hiany, date={}", targetDate);
            return new DailyClosingMissedAlertResult(targetDate, 0, 0, 0, 0);
        }

        int companiesWithMissing = 0;
        int notificationsSent = 0;
        int skippedAlreadyAudited = 0;

        Map<UUID, List<MissedBranchClosing>> byCompany = missed.stream()
                .collect(Collectors.groupingBy(MissedBranchClosing::companyId));

        for (Map.Entry<UUID, List<MissedBranchClosing>> entry : byCompany.entrySet()) {
            UUID companyId = entry.getKey();
            List<MissedBranchClosing> companyMissed = entry.getValue().stream()
                    .sorted(Comparator.comparing(MissedBranchClosing::branchCode, Comparator.nullsLast(String::compareToIgnoreCase)))
                    .toList();

            String auditReference = companyId + ":" + targetDate;
            if (auditLogService.existsByActionAndReferenceForCompany(AUDIT_ACTION, auditReference, companyId)) {
                skippedAlreadyAudited++;
                continue;
            }

            companiesWithMissing++;
            String title = "P0 napzárás-kimaradás - " + targetDate;
            String message = buildMessage(targetDate, companyMissed);
            List<Worker> recipients = workerRepository.findSupervisorsAndAbove(companyId);
            for (Worker worker : recipients) {
                notificationService.sendToWorker(worker.getId(), title, message, NOTIFICATION_TYPE);
                notificationsSent++;
            }

            auditLogService.logForCompany(
                    AUDIT_ACTION,
                    message,
                    auditReference,
                    companyId);
            log.warn("Napzaras-kimaradas alert: company={}, date={}, branches={}, recipients={}",
                    companyId, targetDate, companyMissed.size(), recipients.size());
        }

        return new DailyClosingMissedAlertResult(
                targetDate,
                missed.size(),
                companiesWithMissing,
                notificationsSent,
                skippedAlreadyAudited);
    }

    @Transactional(readOnly = true)
    public List<MissedBranchClosing> findMissedClosings(LocalDate targetDate) {
        if (targetDate == null) {
            throw new IllegalArgumentException("targetDate nem lehet null");
        }

        List<MissedBranchClosing> missed = new ArrayList<>();
        for (Branch branch : branchRepository.findActiveClosingMonitoredBranches()) {
            if (!isOpenOn(branch, targetDate)) {
                continue;
            }
            ClosingControl control = closingControlRepository
                    .findByCompanyIdAndBranchIdAndControlDate(branch.getCompany().getId(), branch.getId(), targetDate)
                    .orElse(null);
            if (control == null || !Boolean.TRUE.equals(control.getDailyClosingDone())) {
                missed.add(new MissedBranchClosing(
                        branch.getCompany().getId(),
                        branch.getId(),
                        branch.getCode(),
                        branch.getName(),
                        control == null ? "MISSING_CONTROL" : "DAILY_CLOSING_NOT_DONE"));
            }
        }
        return missed;
    }

    private boolean isOpenOn(Branch branch, LocalDate targetDate) {
        if (branch.getOpeningDate() != null && branch.getOpeningDate().isAfter(targetDate)) {
            return false;
        }
        DayOfWeek day = targetDate.getDayOfWeek();
        if (day == DayOfWeek.SATURDAY && Boolean.TRUE.equals(branch.getClosedSaturday())) {
            return false;
        }
        return day != DayOfWeek.SUNDAY || !Boolean.TRUE.equals(branch.getClosedSunday());
    }

    private String buildMessage(LocalDate targetDate, List<MissedBranchClosing> missed) {
        String branches = missed.stream()
                .limit(20)
                .map(item -> item.branchCode() + " - " + item.branchName() + " (" + item.reason() + ")")
                .collect(Collectors.joining("; "));
        if (missed.size() > 20) {
            branches += "; tovabbi hianyzo irodak: " + (missed.size() - 20);
        }
        return "A " + targetDate + " napi zaras hianyzik " + missed.size()
                + " aktiv irodaban. Erintett irodak: " + branches
                + ". Product Ready P0: azonnali DPO/uzemeltetesi ellenorzes szukseges.";
    }

    public record DailyClosingMissedAlertResult(
            LocalDate targetDate,
            int missedBranches,
            int companiesAlerted,
            int notificationsSent,
            int skippedAlreadyAudited) {
    }

    public record MissedBranchClosing(
            UUID companyId,
            UUID branchId,
            String branchCode,
            String branchName,
            String reason) {
    }
}
