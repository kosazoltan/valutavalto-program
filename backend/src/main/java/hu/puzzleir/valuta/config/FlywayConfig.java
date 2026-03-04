package hu.puzzleir.valuta.config;

import org.springframework.boot.autoconfigure.flyway.FlywayMigrationStrategy;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;

/**
 * Flyway konfiguráció production környezethez.
 * Repair-t futtat migrate előtt, hogy a sikertelen migrációkat kezelje.
 */
@Configuration
@Profile("production")
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
