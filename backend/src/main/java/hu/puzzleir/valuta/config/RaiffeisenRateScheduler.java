package hu.puzzleir.valuta.config;

import hu.puzzleir.valuta.service.RaiffeisenRateService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.LocalDate;
import java.time.ZoneId;

/**
 * Raiffeisen devizaközép árfolyam ütemezett letöltés.
 *
 * Munkanapokon (hétfő-péntek) reggel 8:00-kor (Europe/Budapest)
 * letölti a Raiffeisen Bank devizaközép árfolyamait és cache-eli.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class RaiffeisenRateScheduler {

    private final RaiffeisenRateService raiffeisenRateService;

    /**
     * Napi Raiffeisen árfolyam scraping — munkanapokon 8:00 (Budapest).
     * Cron: sec min hour day month weekday
     * MON-FRI = 1-5
     */
    @Scheduled(cron = "0 0 8 * * MON-FRI", zone = "Europe/Budapest")
    public void scheduledRaiffeisenRateFetch() {
        LocalDate today = LocalDate.now(ZoneId.of("Europe/Budapest"));

        log.info("Ütemezett Raiffeisen árfolyam letöltés indítása: {} ({})", today, today.getDayOfWeek());

        try {
            int count = raiffeisenRateService.fetchAndCacheRates();
            log.info("Ütemezett Raiffeisen árfolyam letöltés kész: {} valuta cache-elve", count);
        } catch (Exception e) {
            log.error("Ütemezett Raiffeisen árfolyam letöltés HIBA: {}", e.getMessage(), e);
        }
    }
}
