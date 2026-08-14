package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.service.BranchService;
import hu.puzzleir.valuta.service.CashRegisterDeviceService;
import hu.puzzleir.valuta.service.CashRegisterService;
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

import java.util.concurrent.Callable;

import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.reset;

/**
 * FK-085 FR-3: a GET /api/v1/cash-register/devices végpont jogosultsági körének
 * method-security lefedettsége. A bővítés FOERTEKTAR és UGYVEZETO szerepköröket ad
 * hozzá; a meglévő SUPERVISOR / MANAGER / ADMIN hozzáférés változatlan marad.
 *
 * <p>Az AverageRateReportControllerSecurityTest könnyű method-security mintáját követi:
 * a {@code @PreAuthorize} a controller-metódus hívásakor érvényesül — deny →
 * AccessDeniedException, allow → a hívás lefut. Nincs teljes web/JPA context
 * (a service-ek mockoltak). A három CashRegister service-ben nincs @PersistenceContext
 * mező (grep-verifikálva), ezért mock EntityManagerFactory bean NEM szükséges.</p>
 */
@ExtendWith(SpringExtension.class)
@ContextConfiguration(classes = CashRegisterControllerSecurityTest.TestConfig.class)
class CashRegisterControllerSecurityTest {

    @Autowired
    private CashRegisterDeviceService cashRegisterDeviceService;

    @Autowired
    private CashRegisterController controller;

    @BeforeEach
    void setup() {
        reset(cashRegisterDeviceService);
    }

    /**
     * Igazolja, hogy a {@code @PreAuthorize} ÁTENGEDTE a hívást: NEM dob AccessDeniedException-t.
     * A biztonsági rétegen túli üzleti hiba ELFOGADHATÓ — az már bizonyítja,
     * hogy a jogosultság-ellenőrzés engedélyezett (a metódustörzs elkezdett futni).
     */
    private static void assertAuthorized(Callable<?> call) {
        try {
            call.call();
        } catch (AccessDeniedException denied) {
            throw new AssertionError("A @PreAuthorize tévesen elutasította a jogosult szerepkört", denied);
        } catch (Exception businessError) {
            // OK: a security átengedett; az üzleti/context-hiba a method-security teszt szempontjából irreleváns.
        }
    }

    @Configuration
    @EnableMethodSecurity
    static class TestConfig {
        @Bean
        CashRegisterService cashRegisterService() {
            return mock(CashRegisterService.class);
        }

        @Bean
        CashRegisterDeviceService cashRegisterDeviceService() {
            return mock(CashRegisterDeviceService.class);
        }

        @Bean
        BranchService branchService() {
            return mock(BranchService.class);
        }

        @Bean
        CashRegisterController cashRegisterController(
                CashRegisterService cashRegisterService,
                CashRegisterDeviceService cashRegisterDeviceService,
                BranchService branchService) {
            // Lombok @RequiredArgsConstructor ctor-sorrend = meződeklarációs sorrend
            // (CashRegisterController.java 33-35. sor).
            return new CashRegisterController(cashRegisterService, cashRegisterDeviceService, branchService);
        }
    }

    // ----- ALLOW: új szerepkörök (FK-085 FR-3) -----

    @Test
    @WithMockUser(roles = {"FOERTEKTAR"})
    @DisplayName("FR-3: FOERTEKTAR → devices lista engedélyezett")
    void devices_allowed_foertektar() {
        assertAuthorized(() -> controller.listCashRegisterDevices());
    }

    @Test
    @WithMockUser(roles = {"UGYVEZETO"})
    @DisplayName("FR-3: UGYVEZETO → devices lista engedélyezett")
    void devices_allowed_ugyvezeto() {
        assertAuthorized(() -> controller.listCashRegisterDevices());
    }

    // ----- ALLOW: meglévő szerepkörök (regresszió-védelem) -----

    @Test
    @WithMockUser(roles = {"SUPERVISOR"})
    @DisplayName("FR-3 regresszió: SUPERVISOR → devices lista továbbra is engedélyezett")
    void devices_allowed_supervisor() {
        assertAuthorized(() -> controller.listCashRegisterDevices());
    }

    @Test
    @WithMockUser(roles = {"MANAGER"})
    @DisplayName("FR-3 regresszió: MANAGER → devices lista továbbra is engedélyezett")
    void devices_allowed_manager() {
        assertAuthorized(() -> controller.listCashRegisterDevices());
    }

    @Test
    @WithMockUser(roles = {"ADMIN"})
    @DisplayName("FR-3 regresszió: ADMIN → devices lista továbbra is engedélyezett")
    void devices_allowed_admin() {
        assertAuthorized(() -> controller.listCashRegisterDevices());
    }

    // ----- DENY: nem jogosult szerepkörök -----

    @Test
    @WithMockUser(roles = {"CASHIER"})
    @DisplayName("FR-3: CASHIER → devices lista elutasítva")
    void devices_denied_cashier() {
        assertThrows(AccessDeniedException.class, () -> controller.listCashRegisterDevices());
    }

    @Test
    @WithMockUser(roles = {"IRODAVEZETO"})
    @DisplayName("FR-3: IRODAVEZETO → devices lista elutasítva")
    void devices_denied_irodavezeto() {
        assertThrows(AccessDeniedException.class, () -> controller.listCashRegisterDevices());
    }
}
