package hu.puzzleir.valuta.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableScheduling;

/**
 * Scheduling konfiguráció — @Scheduled annotációk engedélyezése.
 *
 * Legacy IRQ timer (perces polling FTP-ről) helyett
 * Spring @Scheduled cron alapú HTTP polling.
 */
@Configuration
@EnableScheduling
public class SchedulingConfig {
    // Az @EnableScheduling engedélyezi a @Scheduled annotációk feldolgozását.
    // A konkrét ütemezések az ExchangeRatePollingService-ben vannak definiálva.
}
