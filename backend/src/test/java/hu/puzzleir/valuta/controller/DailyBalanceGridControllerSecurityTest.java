package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.service.DailyBalanceGridService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.authentication.AuthenticationCredentialsNotFoundException;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.ContextConfiguration;
import org.springframework.test.context.junit.jupiter.SpringExtension;

import java.time.LocalDate;
import java.util.concurrent.Callable;

import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.reset;

/**
 * FK-047: a Napi ellenőrző lista grid végpont jogosultsági körének method-security tesztje.
 * RBAC (§3): FOERTEKTAR / UGYVEZETO / BELSO_ELLENOR kanonikus + legacy MANAGER / SUPERVISOR /
 * ADMIN olvashat; a pénztáros (CASHIER) és az operatív értéktáros (ERTEKTAR) NEM.
 *
 * <p>A könnyű method-security mintát követi (AverageRateReportControllerSecurityTest): deny →
 * AccessDeniedException; allow → a metódustörzs elkezdett futni (üzleti hiba elfogadható).</p>
 */
@ExtendWith(SpringExtension.class)
@ContextConfiguration(classes = DailyBalanceGridControllerSecurityTest.TestConfig.class)
class DailyBalanceGridControllerSecurityTest {

    private static final LocalDate DATE = LocalDate.of(2026, 7, 1);

    @Autowired
    private DailyBalanceGridService service;

    @Autowired
    private DailyBalanceGridController controller;

    @BeforeEach
    void setup() {
        reset(service);
    }

    private static void assertAuthorized(Callable<?> call) {
        try {
            call.call();
        } catch (AccessDeniedException denied) {
            throw new AssertionError("A @PreAuthorize tévesen elutasította a jogosult szerepkört", denied);
        } catch (Exception businessError) {
            // OK: a security átengedett; az üzleti/context-hiba itt irreleváns.
        }
    }

    @Configuration
    @EnableMethodSecurity
    static class TestConfig {
        @Bean
        DailyBalanceGridService dailyBalanceGridService() {
            return mock(DailyBalanceGridService.class);
        }

        @Bean
        DailyBalanceGridController dailyBalanceGridController(DailyBalanceGridService svc) {
            return new DailyBalanceGridController(svc);
        }
    }

    // ----- ALLOW: kanonikus szerepkörök -----

    @Test
    @WithMockUser(roles = {"FOERTEKTAR"})
    @DisplayName("FOERTEKTAR kanonikus → grid olvasás engedélyezett")
    void grid_allowed_foertektar() {
        assertAuthorized(() -> controller.getGrid(DATE, null, null));
    }

    @Test
    @WithMockUser(roles = {"UGYVEZETO"})
    @DisplayName("UGYVEZETO kanonikus → grid olvasás engedélyezett")
    void grid_allowed_ugyvezeto() {
        assertAuthorized(() -> controller.getGrid(DATE, null, null));
    }

    @Test
    @WithMockUser(roles = {"BELSO_ELLENOR"})
    @DisplayName("BELSO_ELLENOR kanonikus → grid olvasás engedélyezett")
    void grid_allowed_belso_ellenor() {
        assertAuthorized(() -> controller.getGrid(DATE, null, null));
    }

    // ----- ALLOW: legacy szerepkörök (regresszió-védelem) -----

    @Test
    @WithMockUser(roles = {"MANAGER"})
    @DisplayName("legacy MANAGER → engedélyezett")
    void grid_allowed_manager() {
        assertAuthorized(() -> controller.getGrid(DATE, null, null));
    }

    @Test
    @WithMockUser(roles = {"SUPERVISOR"})
    @DisplayName("legacy SUPERVISOR → engedélyezett")
    void grid_allowed_supervisor() {
        assertAuthorized(() -> controller.getGrid(DATE, null, null));
    }

    @Test
    @WithMockUser(roles = {"ADMIN"})
    @DisplayName("legacy ADMIN → engedélyezett")
    void grid_allowed_admin() {
        assertAuthorized(() -> controller.getGrid(DATE, null, null));
    }

    // ----- DENY -----

    @Test
    @WithMockUser(roles = {"CASHIER"})
    @DisplayName("CASHIER (pénztáros) → tiltott")
    void grid_denied_cashier() {
        assertThrows(AccessDeniedException.class, () -> controller.getGrid(DATE, null, null));
    }

    @Test
    @WithMockUser(roles = {"ERTEKTAR"})
    @DisplayName("ERTEKTAR (operatív értéktáros) → tiltott")
    void grid_denied_ertektar() {
        assertThrows(AccessDeniedException.class, () -> controller.getGrid(DATE, null, null));
    }

    @Test
    @WithMockUser(roles = {"IRODAVEZETO"})
    @DisplayName("IRODAVEZETO → tiltott (a §3 RBAC-mátrixban nem szerepel)")
    void grid_denied_irodavezeto() {
        assertThrows(AccessDeniedException.class, () -> controller.getGrid(DATE, null, null));
    }
}
