package hu.puzzleir.valuta.config;

import hu.puzzleir.valuta.service.DataCollectionService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.LocalDate;

/**
 * Adatgyűjtő ütemezés — minden este 22:00-kor.
 *
 * Legacy: A Delphi szerver DLL timer-je (~perces polling) helyett
 * Spring @Scheduled cron alapú adatgyűjtés.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class DataCollectionScheduler {

    private final DataCollectionService dataCollectionService;

    /**
     * Minden este 22:00-kor automatikus napi adatgyűjtés minden aktív irodából.
     */
    @Scheduled(cron = "0 0 22 * * *")
    public void scheduledDailyCollection() {
        log.info("Ütemezett napi adatgyűjtés indítása: {}", LocalDate.now());
        try {
            dataCollectionService.collectAllBranches(LocalDate.now());
            log.info("Ütemezett napi adatgyűjtés befejezve.");
        } catch (Exception e) {
            log.error("Ütemezett napi adatgyűjtés HIBA: {}", e.getMessage(), e);
        }
    }
}
