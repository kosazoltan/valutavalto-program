package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.service.central.ReceivedBankTurnoverService;
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
 * FK-114 RBAC: the bank-turnover tab inherits the received-data page roles.
 */
@ExtendWith(SpringExtension.class)
@ContextConfiguration(classes = ReceivedBankTurnoverControllerSecurityTest.TestConfig.class)
class ReceivedBankTurnoverControllerSecurityTest {

    private static final LocalDate FROM = LocalDate.of(2026, 9, 10);
    private static final LocalDate TO = LocalDate.of(2026, 9, 12);

    @Autowired
    private ReceivedBankTurnoverService receivedBankTurnoverService;

    @Autowired
    private ReceivedBankTurnoverController controller;

    @BeforeEach
    void setup() {
        reset(receivedBankTurnoverService);
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
        ReceivedBankTurnoverService receivedBankTurnoverService() {
            return mock(ReceivedBankTurnoverService.class);
        }

        @Bean
        ReceivedBankTurnoverController receivedBankTurnoverController(ReceivedBankTurnoverService svc) {
            return new ReceivedBankTurnoverController(svc);
        }
    }

    @Test
    @WithMockUser(roles = {"FOERTEKTAR"})
    @DisplayName("FOERTEKTAR -> bank-turnover allowed")
    void allowed_foertektar() {
        assertAuthorized(() -> controller.bankTurnover(FROM, TO, null, null));
    }

    @Test
    @WithMockUser(roles = {"BELSO_ELLENOR"})
    @DisplayName("BELSO_ELLENOR -> bank-turnover allowed")
    void allowed_belsoEllenor() {
        assertAuthorized(() -> controller.bankTurnover(FROM, TO, null, null));
    }

    @Test
    @WithMockUser(roles = {"ADMIN"})
    @DisplayName("ADMIN -> bank-turnover allowed")
    void allowed_admin() {
        assertAuthorized(() -> controller.bankTurnover(FROM, TO, null, null));
    }

    @Test
    @WithMockUser(roles = {"IRODAVEZETO"})
    @DisplayName("IRODAVEZETO -> 403")
    void denied_irodavezeto() {
        assertThrows(AccessDeniedException.class, () -> controller.bankTurnover(FROM, TO, null, null));
    }

    @Test
    @WithMockUser(roles = {"PENZTAROS"})
    @DisplayName("PENZTAROS -> 403")
    void denied_penztaros() {
        assertThrows(AccessDeniedException.class, () -> controller.bankTurnover(FROM, TO, null, null));
    }
}
