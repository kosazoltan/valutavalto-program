package hu.puzzleir.valuta.config;

import org.springframework.boot.flyway.autoconfigure.FlywayMigrationStrategy;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Flyway konfiguráció production környezethez.
 * Repair-t futtat migrate előtt, hogy a sikertelen migrációkat kezelje.
 */
@Configuration
public class FlywayConfig {

    @Bean
    public FlywayMigrationStrategy flywayMigrationStrategy() {
        return flyway -> {
            // Repair first to fix any failed migrations or checksum mismatches
            flyway.repair();
            // Then run migrations
            flyway.migrate();
        };
    }
}
