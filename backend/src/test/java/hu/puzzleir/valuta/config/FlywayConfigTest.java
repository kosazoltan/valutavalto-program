package hu.puzzleir.valuta.config;

import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.InOrder;
import org.springframework.boot.flyway.autoconfigure.FlywayMigrationStrategy;
import org.springframework.mock.env.MockEnvironment;

import static org.mockito.Mockito.*;

/**
 * Audit TOP15 #4: a repair() nem futhat a production fail-closed guard
 * (spring.flyway.repair-on-migrate=false) ellenere.
 */
class FlywayConfigTest {

    private final FlywayConfig config = new FlywayConfig();

    @Test
    @DisplayName("default (property hianyzik): repair NEM fut, migrate igen")
    void repairSkippedByDefault() {
        Flyway flyway = mock(Flyway.class);
        FlywayMigrationStrategy s = config.flywayMigrationStrategy(new MockEnvironment());
        s.migrate(flyway);
        verify(flyway, never()).repair();
        verify(flyway, times(1)).migrate();
    }

    @Test
    @DisplayName("repair-on-migrate=false: repair NEM fut, migrate igen")
    void repairSkippedWhenExplicitlyDisabled() {
        Flyway flyway = mock(Flyway.class);
        MockEnvironment env = new MockEnvironment()
            .withProperty("spring.flyway.repair-on-migrate", "false");
        config.flywayMigrationStrategy(env).migrate(flyway);
        verify(flyway, never()).repair();
        verify(flyway, times(1)).migrate();
    }

    @Test
    @DisplayName("repair-on-migrate=banana: repair NEM fut, migrate igen, nincs startup kivetel")
    void repairSkippedWhenPropertyIsGarbage() {
        Flyway flyway = mock(Flyway.class);
        MockEnvironment env = new MockEnvironment()
            .withProperty("spring.flyway.repair-on-migrate", "banana");
        config.flywayMigrationStrategy(env).migrate(flyway);
        verify(flyway, never()).repair();
        verify(flyway, times(1)).migrate();
    }

    @Test
    @DisplayName("repair-on-migrate ures string: repair NEM fut, migrate igen")
    void repairSkippedWhenPropertyIsEmpty() {
        Flyway flyway = mock(Flyway.class);
        MockEnvironment env = new MockEnvironment()
            .withProperty("spring.flyway.repair-on-migrate", "");
        config.flywayMigrationStrategy(env).migrate(flyway);
        verify(flyway, never()).repair();
        verify(flyway, times(1)).migrate();
    }

    @Test
    @DisplayName("repair-on-migrate=true: repair fut, MAJD migrate (sorrend)")
    void repairRunsBeforeMigrateWhenEnabled() {
        Flyway flyway = mock(Flyway.class);
        MockEnvironment env = new MockEnvironment()
            .withProperty("spring.flyway.repair-on-migrate", "true");
        config.flywayMigrationStrategy(env).migrate(flyway);
        InOrder inOrder = inOrder(flyway);
        inOrder.verify(flyway).repair();
        inOrder.verify(flyway).migrate();
    }

    @Test
    @DisplayName("repair-on-migrate=TRUE: repair fut, MAJD migrate (sorrend)")
    void repairRunsBeforeMigrateWhenEnabledWithUppercaseValue() {
        Flyway flyway = mock(Flyway.class);
        MockEnvironment env = new MockEnvironment()
            .withProperty("spring.flyway.repair-on-migrate", "TRUE");
        config.flywayMigrationStrategy(env).migrate(flyway);
        InOrder inOrder = inOrder(flyway);
        inOrder.verify(flyway).repair();
        inOrder.verify(flyway).migrate();
    }
}
