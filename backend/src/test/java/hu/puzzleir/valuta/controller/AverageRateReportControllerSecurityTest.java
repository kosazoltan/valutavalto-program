package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.service.AuditEventService;
import hu.puzzleir.valuta.service.AverageRateReportExcelService;
import hu.puzzleir.valuta.service.AverageRateReportService;
import jakarta.persistence.EntityManagerFactory;
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
 * FK-049: az Átlag árfolyam riport két végpontjának (pivot / export) jogosultsági
 * körét védi method-security szinten. A régi négy fantom szerepkör-név ({@code TREASURY_MANAGER},
 * {@code MAIN_TREASURY}, {@code REGIONAL_MANAGER}, {@code CASHIER_SUPERVISOR}) eltávolítva; a
 * ténylegesen élő kanonikus szerepkörök ({@code FOERTEKTAR}, {@code UGYVEZETO}, {@code BELSO_ELLENOR})
 * bekerültek, a legacy {@code MANAGER} / {@code SUPERVISOR} / {@code ADMIN} hozzáférés változatlan.
 *
 * <p>A könnyű method-security mintát követi (mint CashBalanceControllerSecurityWebMvcTest): a
 * {@code @PreAuthorize} a controller-metódus hívásakor érvényesül — deny → AccessDeniedException,
 * allow → a hívás lefut. Nincs teljes web/JPA context (a service mockolt).</p>
 */
@ExtendWith(SpringExtension.class)
@ContextConfiguration(classes = AverageRateReportControllerSecurityTest.TestConfig.class)
class AverageRateReportControllerSecurityTest {

    private static final LocalDate FROM = LocalDate.of(2026, 1, 1);
    private static final LocalDate TO = LocalDate.of(2026, 1, 31);

    @Autowired
    private AverageRateReportService averageRateReportService;

    @Autowired
    private AverageRateReportController controller;

    @BeforeEach
    void setup() {
        reset(averageRateReportService);
    }

    /**
     * Igazolja, hogy a {@code @PreAuthorize} ÁTENGEDTE a hívást: NEM dob AccessDeniedException-t.
     * A biztonsági rétegen túli üzleti hiba (pl. ValidationException "Nincs bejelentkezett
     * felhasználó" a SecurityUtils company-context hiánya miatt) ELFOGADHATÓ — az már bizonyítja,
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
        AverageRateReportService averageRateReportService() {
            return mock(AverageRateReportService.class);
        }

        // A valódi AverageRateReportService @PersistenceContext EntityManager mezős; a mock proxy
        // örökli, ezért a Spring PersistenceAnnotationBeanPostProcessor EntityManagerFactory-t keres.
        // Mock EMF: a persistence-injektálás sikerül, valódi JPA/DB nélkül (method-security izoláció).
        @Bean
        EntityManagerFactory entityManagerFactory() {
            return mock(EntityManagerFactory.class);
        }

        @Bean
        AverageRateReportExcelService averageRateReportExcelService() {
            return mock(AverageRateReportExcelService.class);
        }

        @Bean
        AuditEventService auditEventService() {
            return mock(AuditEventService.class);
        }

        @Bean
        AverageRateReportController averageRateReportController(
                AverageRateReportService svc,
                AverageRateReportExcelService excel,
                AuditEventService audit) {
            return new AverageRateReportController(svc, excel, audit);
        }
    }

    // ----- ALLOW: kanonikus szerepkörök (FR-1..3) -----

    @Test
    @WithMockUser(roles = {"UGYVEZETO"})
    @DisplayName("FR-2: UGYVEZETO kanonikus → pivot engedélyezett")
    void pivot_allowed_ugyvezeto() {
        assertAuthorized(() -> controller.generatePivot(FROM, TO, null));
    }

    @Test
    @WithMockUser(roles = {"BELSO_ELLENOR"})
    @DisplayName("FR-3: BELSO_ELLENOR kanonikus → export engedélyezett")
    void export_allowed_belsoEllenor() {
        assertAuthorized(() -> controller.export(FROM, TO));
    }

    @Test
    @WithMockUser(roles = {"FOERTEKTAR"})
    @DisplayName("FR-3: FOERTEKTAR → export engedélyezett")
    void export_allowed_foertektar() {
        assertAuthorized(() -> controller.export(FROM, TO));
    }

    // ----- ALLOW: legacy szerepkörök (FR-4 regresszió-védelem) -----

    @Test
    @WithMockUser(roles = {"SUPERVISOR"})
    @DisplayName("FR-4: legacy SUPERVISOR → pivot engedélyezett (regresszió)")
    void pivot_allowed_legacySupervisor() {
        assertAuthorized(() -> controller.generatePivot(FROM, TO, null));
    }

    // ----- DENY: nem jogosult szerepkörök -----

    @Test
    @WithMockUser(roles = {"IRODAVEZETO"})
    @DisplayName("FR-5: IRODAVEZETO → pivot elutasítva")
    void pivot_denied_irodavezeto() {
        assertThrows(AccessDeniedException.class, () -> controller.generatePivot(FROM, TO, null));
    }

    @Test
    @WithMockUser(roles = {"CASHIER"})
    @DisplayName("CASHIER → export elutasítva")
    void export_denied_cashier() {
        assertThrows(AccessDeniedException.class, () -> controller.export(FROM, TO));
    }
}
