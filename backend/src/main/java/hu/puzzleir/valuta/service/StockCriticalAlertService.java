package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.CashBalance;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.repository.CashBalanceRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.ZoneId;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * E-B8 (#279) 3. rész: kritikus készlet-küszöb figyelés + sürgősségi kivét javaslat.
 *
 * <p>Ha egy értéktári/pénztári {@code cash_balance.current_balance} a beállított
 * {@code min_balance} küszöb alá (vagy alá-egyenlő) esik, a cég supervisor+ dolgozói
 * URGENT értesítést kapnak sürgősségi banki rendelés (EMERGENCY bank order) javaslattal.</p>
 *
 * <p>Idempotencia: cégenként + naponta legfeljebb egy alert megy ki (audit-referencia
 * {@code companyId:date}), így az ismételt scheduler-futás nem spamel — a
 * {@link DailyClosingMissedAlertService} mintájára.</p>
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class StockCriticalAlertService {

    static final String AUDIT_ACTION = "STOCK_CRITICAL_ALERT";
    static final String NOTIFICATION_TYPE = "STOCK_CRITICAL";

    /** A scheduler is Europe/Budapest zónával fut — az idempotencia-dátumnak ugyanabban
     *  a zónában kell képződnie, különben UTC JVM-en éjfél körül napot tévesztene. */
    static final ZoneId BUSINESS_ZONE = ZoneId.of("Europe/Budapest");

    private final CashBalanceRepository cashBalanceRepository;
    private final WorkerRepository workerRepository;
    private final NotificationService notificationService;
    private final AuditLogService auditLogService;

    @Transactional(rollbackFor = Exception.class)
    public StockCriticalAlertResult checkNow() {
        return checkDate(LocalDate.now(BUSINESS_ZONE));
    }

    @Transactional(rollbackFor = Exception.class)
    public StockCriticalAlertResult checkDate(LocalDate targetDate) {
        if (targetDate == null) {
            throw new IllegalArgumentException("targetDate nem lehet null");
        }

        List<CashBalance> critical = cashBalanceRepository.findAllLowBalances();
        if (critical.isEmpty()) {
            log.info("Kritikus készlet ellenőrzés: nincs küszöb alatti egyenleg, date={}", targetDate);
            return new StockCriticalAlertResult(targetDate, 0, 0, 0, 0);
        }

        int companiesAlerted = 0;
        int notificationsSent = 0;
        int skippedAlreadyAudited = 0;

        Map<UUID, List<CashBalance>> byCompany = critical.stream()
                .collect(Collectors.groupingBy(cb -> cb.getCompany().getId()));

        for (Map.Entry<UUID, List<CashBalance>> entry : byCompany.entrySet()) {
            UUID companyId = entry.getKey();
            List<CashBalance> companyCritical = entry.getValue().stream()
                    .sorted(Comparator
                            .comparing((CashBalance cb) -> cb.getBranch().getCode(),
                                    Comparator.nullsLast(String::compareToIgnoreCase))
                            .thenComparing(cb -> cb.getCurrency().getCode(),
                                    Comparator.nullsLast(String::compareToIgnoreCase)))
                    .toList();

            String auditReference = companyId + ":" + targetDate;
            if (auditLogService.existsByActionAndReferenceForCompany(AUDIT_ACTION, auditReference, companyId)) {
                skippedAlreadyAudited++;
                continue;
            }

            companiesAlerted++;
            String title = "Kritikus értéktári készlet — sürgősségi banki kivét javasolt";
            String message = buildMessage(companyCritical);
            List<Worker> recipients = workerRepository.findSupervisorsAndAbove(companyId);
            for (Worker worker : recipients) {
                notificationService.sendToWorker(worker.getId(), title, message, NOTIFICATION_TYPE);
                notificationsSent++;
            }

            auditLogService.logForCompany(AUDIT_ACTION, message, auditReference, companyId);
            log.warn("Kritikus készlet alert: company={}, date={}, balances={}, recipients={}",
                    companyId, targetDate, companyCritical.size(), recipients.size());
        }

        return new StockCriticalAlertResult(
                targetDate,
                critical.size(),
                companiesAlerted,
                notificationsSent,
                skippedAlreadyAudited);
    }

    private String buildMessage(List<CashBalance> critical) {
        String items = critical.stream()
                .limit(20)
                .map(cb -> safeCode(cb.getBranch().getCode()) + " " + safeCode(cb.getCurrency().getCode())
                        + " (egyenleg: " + cb.getCurrentBalance().toPlainString()
                        + ", küszöb: " + cb.getMinBalance().toPlainString() + ")")
                .collect(Collectors.joining("; "));
        if (critical.size() > 20) {
            items += "; további érintett egyenlegek: " + (critical.size() - 20);
        }
        return "Kritikus küszöb alatti készlet " + critical.size()
                + " egyenlegnél. Érintettek: " + items
                + ". Javasolt sürgősségi (EMERGENCY) banki rendelés indítása a Banki rendelések menüpontban.";
    }

    /** Sourcery review: a comparator null-safe, az üzenet-építés is legyen az. */
    private static String safeCode(String code) {
        return code != null ? code : "?";
    }

    public record StockCriticalAlertResult(
            LocalDate targetDate,
            int criticalBalances,
            int companiesAlerted,
            int notificationsSent,
            int skippedAlreadyAudited) {
    }
}
