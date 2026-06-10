package hu.puzzleir.valuta.config;

import hu.puzzleir.valuta.service.DailyClosingMissedAlertService;
import hu.puzzleir.valuta.service.DailyClosingMissedAlertService.DailyClosingMissedAlertResult;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/**
 * Product Ready P0: napi napzaras-kimaradas alert.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class DailyClosingMissedAlertScheduler {

    private final DailyClosingMissedAlertService dailyClosingMissedAlertService;

    /**
     * Minden nap 08:30-kor ellenorzi az elozo naptari nap nyitva levo aktiv irodait.
     */
    @Scheduled(cron = "0 30 8 * * *", zone = "Europe/Budapest")
    public void checkMissedDailyClosings() {
        try {
            DailyClosingMissedAlertResult result = dailyClosingMissedAlertService.checkYesterday();
            if (result.missedBranches() > 0) {
                log.warn("Napzaras-kimaradas ellenorzes: date={}, missedBranches={}, companiesAlerted={}, notificationsSent={}, skippedAlreadyAudited={}",
                        result.targetDate(), result.missedBranches(), result.companiesAlerted(),
                        result.notificationsSent(), result.skippedAlreadyAudited());
            } else {
                log.info("Napzaras-kimaradas ellenorzes: nincs hiany, date={}", result.targetDate());
            }
        } catch (Exception e) {
            log.error("Napzaras-kimaradas ellenorzes hiba: {}", e.getMessage(), e);
        }
    }
}
