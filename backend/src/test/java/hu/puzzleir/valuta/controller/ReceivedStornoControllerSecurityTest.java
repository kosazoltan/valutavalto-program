package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.service.central.ReceivedStornoService;
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

@ExtendWith(SpringExtension.class)
@ContextConfiguration(classes = ReceivedStornoControllerSecurityTest.TestConfig.class)
class ReceivedStornoControllerSecurityTest {

    private static final LocalDate FROM = LocalDate.of(2026, 9, 10);
    private static final LocalDate TO = LocalDate.of(2026, 9, 12);

    @Autowired
    private ReceivedStornoService receivedStornoService;
    @Autowired
    private ReceivedStornoController controller;

    @BeforeEach
    void setup() {
        reset(receivedStornoService);
    }

    private static void assertAuthorized(Callable<?> call) {
        try {
            call.call();
        } catch (AccessDeniedException denied) {
            throw new AssertionError("PreAuthorize wrongly denied an allowed role", denied);
        } catch (Exception ignored) {
        }
    }

    @Configuration
    @EnableMethodSecurity
    static class TestConfig {
        @Bean
        ReceivedStornoService receivedStornoService() {
            return mock(ReceivedStornoService.class);
        }

        @Bean
        ReceivedStornoController receivedStornoController(ReceivedStornoService svc) {
            return new ReceivedStornoController(svc);
        }
    }

    @Test
    @WithMockUser(roles = {"FOERTEKTAR"})
    @DisplayName("FOERTEKTAR -> storno allowed")
    void allowed_foertektar() {
        assertAuthorized(() -> controller.storno(FROM, TO, null, null));
    }

    @Test
    @WithMockUser(roles = {"BELSO_ELLENOR"})
    @DisplayName("BELSO_ELLENOR -> storno allowed")
    void allowed_belsoEllenor() {
        assertAuthorized(() -> controller.storno(FROM, TO, null, null));
    }

    @Test
    @WithMockUser(roles = {"ADMIN"})
    @DisplayName("ADMIN -> storno allowed")
    void allowed_admin() {
        assertAuthorized(() -> controller.storno(FROM, TO, null, null));
    }

    @Test
    @WithMockUser(roles = {"IRODAVEZETO"})
    @DisplayName("IRODAVEZETO -> 403")
    void denied_irodavezeto() {
        assertThrows(AccessDeniedException.class, () -> controller.storno(FROM, TO, null, null));
    }

    @Test
    @WithMockUser(roles = {"PENZTAROS"})
    @DisplayName("PENZTAROS -> 403 (not TransactionController's cashier set)")
    void denied_penztaros() {
        assertThrows(AccessDeniedException.class, () -> controller.storno(FROM, TO, null, null));
    }
}
