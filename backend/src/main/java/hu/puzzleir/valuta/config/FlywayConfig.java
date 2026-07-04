package hu.puzzleir.valuta.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.flyway.autoconfigure.FlywayMigrationStrategy;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.env.Environment;

/**
 * Fail-closed Flyway strategia (audit TOP15 #4).
 * repair() CSAK explicit spring.flyway.repair-on-migrate=true eseten fut
 * (production: egyszeri FLYWAY_REPAIR_ON_MIGRATE=true env override).
 */
@Configuration
public class FlywayConfig {

    private static final String REPAIR_ON_MIGRATE_PROPERTY = "spring.flyway.repair-on-migrate";

    private static final Logger log = LoggerFactory.getLogger(FlywayConfig.class);

    @Bean
    public FlywayMigrationStrategy flywayMigrationStrategy(Environment env) {
        boolean repairEnabled = isRepairEnabled(env);
        return flyway -> {
            if (repairEnabled) {
                log.warn("EMERGENCY Flyway repair enabled "
                    + "(" + REPAIR_ON_MIGRATE_PROPERTY + "=true) — flyway_schema_history "
                    + "atirasa kovetkezik. Deploy utan kapcsold vissza false-ra!");
                flyway.repair();
            }
            flyway.migrate();
        };
    }

    private boolean isRepairEnabled(Environment env) {
        String repairFlag = env.getProperty(REPAIR_ON_MIGRATE_PROPERTY, "").trim();
        if ("true".equalsIgnoreCase(repairFlag)) {
            return true;
        }
        if (!repairFlag.isEmpty() && !"false".equalsIgnoreCase(repairFlag)) {
            log.warn("Invalid {} value '{}'; Flyway repair disabled (fail-closed).",
                REPAIR_ON_MIGRATE_PROPERTY, repairFlag);
        }
        return false;
    }
}
