package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.service.TransferReconciliationService;
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
@ContextConfiguration(classes = TransferReconciliationControllerSecurityTest.TestConfig.class)
class TransferReconciliationControllerSecurityTest {

    private static final LocalDate FROM = LocalDate.of(2026, 9, 1);
    private static final LocalDate TO = LocalDate.of(2026, 9, 8);

    @Autowired
    private TransferReconciliationService transferReconciliationService;

    @Autowired
    private TransferReconciliationController controller;

    @BeforeEach
    void setup() {
        reset(transferReconciliationService);
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
        TransferReconciliationService transferReconciliationService() {
            return mock(TransferReconciliationService.class);
        }

        @Bean
        TransferReconciliationController transferReconciliationController(TransferReconciliationService svc) {
            return new TransferReconciliationController(svc);
        }
    }

    @Test
    @WithMockUser(roles = {"FOERTEKTAR"})
    @DisplayName("FOERTEKTAR → run allowed")
    void allowed_foertektar() {
        assertAuthorized(() -> controller.run(FROM, TO));
    }

    @Test
    @WithMockUser(roles = {"BELSO_ELLENOR"})
    @DisplayName("BELSO_ELLENOR → run allowed")
    void allowed_belsoEllenor() {
        assertAuthorized(() -> controller.run(FROM, TO));
    }

    @Test
    @WithMockUser(roles = {"ADMIN"})
    @DisplayName("ADMIN → run allowed")
    void allowed_admin() {
        assertAuthorized(() -> controller.run(FROM, TO));
    }

    @Test
    @WithMockUser(roles = {"IRODAVEZETO"})
    @DisplayName("IRODAVEZETO → 403")
    void denied_irodavezeto() {
        assertThrows(AccessDeniedException.class, () -> controller.run(FROM, TO));
    }

    @Test
    @WithMockUser(roles = {"TERULETI_VEZETO"})
    @DisplayName("TERULETI_VEZETO → 403")
    void denied_teruletiVezeto() {
        assertThrows(AccessDeniedException.class, () -> controller.run(FROM, TO));
    }

    @Test
    @WithMockUser(roles = {"UGYVEZETO"})
    @DisplayName("UGYVEZETO → 403")
    void denied_ugyvezeto() {
        assertThrows(AccessDeniedException.class, () -> controller.run(FROM, TO));
    }
}
