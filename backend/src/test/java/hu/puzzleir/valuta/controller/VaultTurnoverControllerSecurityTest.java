package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.service.VaultTurnoverService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.ContextConfiguration;
import org.springframework.test.context.junit.jupiter.SpringExtension;

import java.time.LocalDate;
import java.util.UUID;
import java.util.concurrent.Callable;

import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.reset;

/**
 * FKH-066 RBAC: the vault arm (ERTEKTAR) gains access to daily turnover, while roles that have no
 * business reading another unit's turnover stay out. The territory restriction itself is enforced
 * in the service (see VaultTurnoverServiceTest) - this fixes the ROLE boundary.
 */
@ExtendWith(SpringExtension.class)
@ContextConfiguration(classes = VaultTurnoverControllerSecurityTest.TestConfig.class)
class VaultTurnoverControllerSecurityTest {

    private static final UUID BRANCH = UUID.fromString("20000000-0000-0000-0000-00000000000a");
    private static final LocalDate DATE = LocalDate.of(2026, 9, 10);

    @Autowired
    private VaultTurnoverService vaultTurnoverService;

    @Autowired
    private VaultTurnoverController controller;

    @BeforeEach
    void setup() {
        reset(vaultTurnoverService);
    }

    private static void assertAuthorized(Callable<?> call) {
        try {
            call.call();
        } catch (AccessDeniedException denied) {
            throw new AssertionError("PreAuthorize wrongly denied an allowed role", denied);
        } catch (Exception ignored) {
            // security passed; business/context errors are out of scope
        }
    }

    @Configuration
    @EnableMethodSecurity
    static class TestConfig {
        @Bean
        VaultTurnoverService vaultTurnoverService() {
            return mock(VaultTurnoverService.class);
        }

        @Bean
        VaultTurnoverController vaultTurnoverController(VaultTurnoverService svc) {
            return new VaultTurnoverController(svc);
        }
    }

    @Test
    @WithMockUser(roles = {"ERTEKTAR"})
    @DisplayName("ERTEKTAR -> allowed (this is the point of FKH-066)")
    void allowed_ertektar() {
        assertAuthorized(() -> controller.vaultDaily(BRANCH, DATE));
    }

    @Test
    @WithMockUser(roles = {"FOERTEKTAR"})
    @DisplayName("FOERTEKTAR -> allowed")
    void allowed_foertektar() {
        assertAuthorized(() -> controller.vaultDaily(BRANCH, DATE));
    }

    @Test
    @WithMockUser(roles = {"UGYVEZETO"})
    @DisplayName("UGYVEZETO -> allowed")
    void allowed_ugyvezeto() {
        assertAuthorized(() -> controller.vaultDaily(BRANCH, DATE));
    }

    @Test
    @WithMockUser(roles = {"CASHIER"})
    @DisplayName("CASHIER -> 403 (a cashier has no cross-branch turnover view)")
    void denied_cashier() {
        assertThrows(AccessDeniedException.class, () -> controller.vaultDaily(BRANCH, DATE));
    }

    @Test
    @WithMockUser(roles = {"IRODAVEZETO"})
    @DisplayName("IRODAVEZETO -> 403")
    void denied_irodavezeto() {
        assertThrows(AccessDeniedException.class, () -> controller.vaultDaily(BRANCH, DATE));
    }

    @Test
    @WithMockUser(roles = {"TERULETI_VEZETO"})
    @DisplayName("TERULETI_VEZETO -> 403")
    void denied_teruletiVezeto() {
        assertThrows(AccessDeniedException.class, () -> controller.vaultDaily(BRANCH, DATE));
    }
}
