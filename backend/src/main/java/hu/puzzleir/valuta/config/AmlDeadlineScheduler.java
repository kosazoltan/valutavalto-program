package hu.puzzleir.valuta.config;

import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.service.AmlService;
import hu.puzzleir.valuta.service.NotificationService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.util.List;

/**
 * Napi AML bejelentesi hatarido ellenorzes.
 *
 * 2017. evi LIII. tv. 33.§ - 2 munkanapon beluli bejelentesi kotelezettseg.
 * Naponta 8:00-kor fut, DRAFT statuszu bejelenteseket OVERDUE-ra allitja
 * ha a 2 munkanap hatarido lejart.
 *
 * H6 gap fix: OVERDUE eseten supervisor + manager ertesites automatikus.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class AmlDeadlineScheduler {

    private final AmlService amlService;
    private final NotificationService notificationService;
    private final WorkerRepository workerRepository;

    /**
     * Naponta 8:00-kor fut (munkaido eleje).
     */
    @Scheduled(cron = "0 0 8 * * MON-FRI", zone = "Europe/Budapest")
    public void checkOverdueReports() {
        log.info("AML hatarido ellenorzes inditasa...");
        try {
            int count = amlService.checkAndMarkOverdueReports();
            if (count > 0) {
                log.warn("AML OVERDUE: {} bejelentes hatarideje lejart!", count);
                notifySupervisors(count);
            } else {
                log.info("AML hatarido ellenorzes: nincs lejart bejelentes.");
            }
        } catch (Exception e) {
            log.error("AML hatarido ellenorzes hiba: {}", e.getMessage(), e);
        }
    }

    /**
     * Supervisor es manager szintu dolgozok ertesitese OVERDUE bejelentesekrol.
     * A Pmt. 33.§ szerint a felugyeleti biztosnak (supervisor) tudomast kell szereznie.
     */
    private void notifySupervisors(int overdueCount) {
        String title = "AML FIGYELMEZTETÉS — " + overdueCount + " lejárt bejelentés";
        String message = String.format(
                "Figyelem! %d AML bejelentés határideje lejárt (Pmt. 33.§ — 2 munkanap). " +
                "Kérjük, azonnal intézkedjen a bejelentések benyújtásáról a hatóság felé. " +
                "Részletek: Adminisztráció → AML Bejelentések → Lejárt szűrő.",
                overdueCount);

        // Osszes cegtol — a scheduler system szinten fut, nincs SecurityContext
        // Nezzuk meg az osszes SUPERVISOR es MANAGER dolgozot
        try {
            List<Worker> supervisorsAndAbove = workerRepository.findAllSupervisorsAndAbove();

            int notified = 0;
            for (Worker w : supervisorsAndAbove) {
                notificationService.sendToWorker(w.getId(), title, message, "AML_OVERDUE");
                notified++;
            }
            log.info("AML OVERDUE ertesites elkuldve {} supervisor/manager-nek", notified);
        } catch (Exception e) {
            log.error("AML OVERDUE supervisor ertesites hiba: {}", e.getMessage(), e);
        }
    }
}
