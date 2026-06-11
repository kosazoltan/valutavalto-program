package hu.puzzleir.valuta.config;

import hu.puzzleir.valuta.service.StockCriticalAlertService;
import hu.puzzleir.valuta.service.StockCriticalAlertService.StockCriticalAlertResult;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/**
 * E-B8 (#279): kritikus készlet-küszöb figyelés ütemezője.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class StockCriticalAlertScheduler {

    private final StockCriticalAlertService stockCriticalAlertService;

    /**
     * Munkaidőben (08:00–20:00) 30 percenként ellenőrzi a küszöb alatti egyenlegeket.
     * Cégenként naponta legfeljebb egy alert megy ki (service-szintű idempotencia).
     */
    @Scheduled(cron = "0 0/30 8-20 * * *", zone = "Europe/Budapest")
    public void checkCriticalStock() {
        try {
            StockCriticalAlertResult result = stockCriticalAlertService.checkNow();
            if (result.criticalBalances() > 0) {
                log.warn("Kritikus készlet ellenőrzés: date={}, criticalBalances={}, companiesAlerted={}, notificationsSent={}, skippedAlreadyAudited={}",
                        result.targetDate(), result.criticalBalances(), result.companiesAlerted(),
                        result.notificationsSent(), result.skippedAlreadyAudited());
            } else {
                log.info("Kritikus készlet ellenőrzés: nincs küszöb alatti egyenleg, date={}", result.targetDate());
            }
        } catch (Exception e) {
            log.error("Kritikus készlet ellenőrzés hiba: {}", e.getMessage(), e);
        }
    }
}
