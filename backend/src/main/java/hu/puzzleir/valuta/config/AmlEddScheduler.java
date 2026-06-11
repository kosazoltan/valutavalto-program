package hu.puzzleir.valuta.config;

import hu.puzzleir.valuta.service.AmlEddService;
import hu.puzzleir.valuta.service.AmlEddService.AmlEddScanResult;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/**
 * V.2.7 EDD-követés ütemezője (V309) — az előző nap triggereit értékeli ki.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class AmlEddScheduler {

    private final AmlEddService amlEddService;

    /**
     * Minden nap 07:45-kor (a 08:30-as napzárás-alert előtt) jelöli az EDD-ablakokat.
     * Flag-gated (AML_EDD_TRACKING_ENFORCEMENT, default false) + extend-only → biztonságos.
     */
    @Scheduled(cron = "0 45 7 * * *", zone = "Europe/Budapest")
    public void scanEddTriggers() {
        try {
            AmlEddScanResult result = amlEddService.scanYesterday();
            if (!result.enabled()) {
                return;
            }
            if (result.marked() + result.extended() > 0) {
                log.warn("EDD napi scan: day={}, új={}, hosszabbított={}, változatlan={}",
                        result.day(), result.marked(), result.extended(), result.unchanged());
            } else {
                log.info("EDD napi scan: day={}, nincs új trigger", result.day());
            }
        } catch (Exception e) {
            log.error("EDD napi scan hiba: {}", e.getMessage(), e);
        }
    }
}
