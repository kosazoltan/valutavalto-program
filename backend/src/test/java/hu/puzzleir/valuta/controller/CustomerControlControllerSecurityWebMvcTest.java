package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.service.CustomerControlService;
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

import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.reset;
import static org.mockito.Mockito.verify;

/**
 * Audit fix (API-01): a customer-control AML-restrikció WRITE-jai (restrict/remove)
 * csak compliance/manager szerepkörrel (SUPERVISOR/MANAGER/ADMIN) hivhatok — a korabbi
 * class-level `isAuthenticated()` barmely bejelentkezett (pl. penztaros) usernek engedte
 * az AML-tiltolista kezeleset. Ez a teszt a method-security (@PreAuthorize) enforcement-et
 * verifikalja.
 *
 * <p>A @PreAuthorize-t a @EnableMethodSecurity AOP-proxy ervenyesiti a bean kozvetlen
 * hivasakor is (a @WithMockUser allitja be a SecurityContextet) — nincs szukseg HTTP
 * SecurityFilterChain-re vagy MockMvc-ra (ezert nincs CSRF-konfiguracio sem).</p>
 *
 * <p>Megj.: az `addRestriction` a `SecurityUtils.getCurrentWorkerId()`-t hivja, ami
 * @WithMockUser kontextusban nem WorkerAuthenticationDetails — ezert az "engedelyezett"
 * agat a `removeRestriction`-on verifikaljuk (nincs benne SecurityUtils-hivas); a tiltott
 * agnal a method-security interceptor a metodus-test ELOTT dob, igy a SecurityUtils sosem fut.</p>
 */
@ExtendWith(SpringExtension.class)
@ContextConfiguration(classes = CustomerControlControllerSecurityWebMvcTest.TestConfig.class)
class CustomerControlControllerSecurityWebMvcTest {

    @Autowired
    private CustomerControlService customerControlService;

    @Autowired
    private CustomerControlController customerControlController;

    @BeforeEach
    void setup() {
        reset(customerControlService);
    }

    @Configuration
    @EnableMethodSecurity
    static class TestConfig {
        @Bean
        CustomerControlService customerControlService() {
            return mock(CustomerControlService.class);
        }

        @Bean
        CustomerControlController customerControlController(CustomerControlService customerControlService) {
            return new CustomerControlController(customerControlService);
        }
    }

    @Test
    @DisplayName("AuthZ: CASHIER role TILTOTT a korlátozás-eltávolítás (removeRestriction) műveletre")
    @WithMockUser(roles = "CASHIER")
    void removeRestriction_forbiddenForCashier() {
        UUID restrictionId = UUID.randomUUID();
        assertThrows(AccessDeniedException.class,
                () -> customerControlController.removeRestriction(restrictionId));
        verify(customerControlService, never()).removeRestriction(any());
    }

    @Test
    @DisplayName("AuthZ: CASHIER role TILTOTT a korlátozás-hozzáadás (addRestriction) műveletre")
    @WithMockUser(roles = "CASHIER")
    void addRestriction_forbiddenForCashier() {
        assertThrows(AccessDeniedException.class,
                () -> customerControlController.addRestriction(1L, null));
        verify(customerControlService, never()).addRestriction(any(), any(), any());
    }

    @Test
    @DisplayName("AuthZ: SUPERVISOR role ENGEDÉLYEZETT a removeRestriction-re")
    @WithMockUser(roles = "SUPERVISOR")
    void removeRestriction_allowedForSupervisor() {
        UUID restrictionId = UUID.randomUUID();
        customerControlController.removeRestriction(restrictionId);
        verify(customerControlService).removeRestriction(restrictionId);
    }

    @Test
    @DisplayName("AuthZ: MANAGER role ENGEDÉLYEZETT a removeRestriction-re")
    @WithMockUser(roles = "MANAGER")
    void removeRestriction_allowedForManager() {
        UUID restrictionId = UUID.randomUUID();
        customerControlController.removeRestriction(restrictionId);
        verify(customerControlService).removeRestriction(restrictionId);
    }
}
