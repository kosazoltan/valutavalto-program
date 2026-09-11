package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.service.central.ReceivedDenominationsService;
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
import java.util.concurrent.Callable;

import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.reset;

/**
 * FK-111 RBAC: the "Keszletek, cimletek" tab inherits the received-data page roles
 * (FOERTEKTAR / BELSO_ELLENOR / ADMIN), not the narrower Darius import-file roles.
 */
@ExtendWith(SpringExtension.class)
@ContextConfiguration(classes = ReceivedDenominationsControllerSecurityTest.TestConfig.class)
class ReceivedDenominationsControllerSecurityTest {

    private static final LocalDate DATE = LocalDate.of(2026, 9, 10);

    @Autowired
    private ReceivedDenominationsService receivedDenominationsService;

    @Autowired
    private ReceivedDenominationsController controller;

    @BeforeEach
    void setup() {
        reset(receivedDenominationsService);
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
        ReceivedDenominationsService receivedDenominationsService() {
            return mock(ReceivedDenominationsService.class);
        }

        @Bean
        ReceivedDenominationsController receivedDenominationsController(ReceivedDenominationsService svc) {
            return new ReceivedDenominationsController(svc);
        }
    }

    @Test
    @WithMockUser(roles = {"FOERTEKTAR"})
    @DisplayName("FOERTEKTAR -> denominations allowed")
    void allowed_foertektar() {
        assertAuthorized(() -> controller.denominations(DATE, null));
    }

    @Test
    @WithMockUser(roles = {"BELSO_ELLENOR"})
    @DisplayName("BELSO_ELLENOR -> denominations allowed")
    void allowed_belsoEllenor() {
        assertAuthorized(() -> controller.denominations(DATE, null));
    }

    @Test
    @WithMockUser(roles = {"ADMIN"})
    @DisplayName("ADMIN -> denominations allowed")
    void allowed_admin() {
        assertAuthorized(() -> controller.denominations(DATE, null));
    }

    @Test
    @WithMockUser(roles = {"IRODAVEZETO"})
    @DisplayName("IRODAVEZETO -> 403")
    void denied_irodavezeto() {
        assertThrows(AccessDeniedException.class, () -> controller.denominations(DATE, null));
    }

    @Test
    @WithMockUser(roles = {"TERULETI_VEZETO"})
    @DisplayName("TERULETI_VEZETO -> 403")
    void denied_teruletiVezeto() {
        assertThrows(AccessDeniedException.class, () -> controller.denominations(DATE, null));
    }

    @Test
    @WithMockUser(roles = {"UGYVEZETO"})
    @DisplayName("UGYVEZETO -> 403")
    void denied_ugyvezeto() {
        assertThrows(AccessDeniedException.class, () -> controller.denominations(DATE, null));
    }
}
