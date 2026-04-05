package hu.puzzleir.valuta.config;

import hu.puzzleir.valuta.service.AmlService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/**
 * Napi AML bejelentési határidő ellenőrzés.
 *
 * 2017. évi LIII. tv. 33.§ — 2 munkanapon belüli bejelentési kötelezettség.
 * Naponta 8:00-kor fut, DRAFT státuszú bejelentéseket OVERDUE-ra állítja
 * ha a 2 munkanap határidő lejárt.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class AmlDeadlineScheduler {

    private final AmlService amlService;

    /**
     * Naponta 8:00-kor fut (munkaidő eleje).
     */
    @Scheduled(cron = "0 0 8 * * MON-FRI", zone = "Europe/Budapest")
    public void checkOverdueReports() {
        log.info("AML határidő ellenőrzés indítása...");
        try {
            int count = amlService.checkAndMarkOverdueReports();
            if (count > 0) {
                log.warn("AML OVERDUE: {} bejelentés határideje lejárt — supervisor értesítés szükséges!", count);
            } else {
                log.info("AML határidő ellenőrzés: nincs lejárt bejelentés.");
            }
        } catch (Exception e) {
            log.error("AML határidő ellenőrzés hiba: {}", e.getMessage(), e);
        }
    }
}
