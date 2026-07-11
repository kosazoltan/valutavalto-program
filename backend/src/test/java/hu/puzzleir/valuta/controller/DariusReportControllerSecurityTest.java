package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.service.DariusReportService;
import hu.puzzleir.valuta.service.darius.DariusImportFileService;
import jakarta.persistence.EntityManagerFactory;
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

@ExtendWith(SpringExtension.class)
@ContextConfiguration(classes = DariusReportControllerSecurityTest.TestConfig.class)
class DariusReportControllerSecurityTest {

    private static final LocalDate DATE = LocalDate.of(2026, 7, 11);
    private static final UUID REPORT_ID = UUID.fromString("10000000-0000-0000-0000-000000000001");

    @Autowired
    private DariusReportController controller;

    @Test
    @WithMockUser(roles = "FOERTEKTAR")
    void foertektarCanUseReportEndpointsExceptOperations() {
        assertAuthorized(() -> controller.generate(DATE));
        assertAuthorized(() -> controller.approve(REPORT_ID));
        assertAuthorized(() -> controller.getByDate(DATE));
        assertAuthorized(() -> controller.importReadiness());
        assertAuthorized(() -> controller.submit(REPORT_ID));

        assertThrows(AccessDeniedException.class, () -> controller.acknowledge(REPORT_ID, "ACK-1"));
        assertThrows(AccessDeniedException.class, () -> controller.retryFailed());
    }

    @Test
    @WithMockUser(authorities = "DARIUS_REPORT_RUN")
    void dariusReportRunAuthorityRemainsCompatible() {
        assertAuthorized(() -> controller.generate(DATE));
        assertAuthorized(() -> controller.acknowledge(REPORT_ID, "ACK-1"));
        assertAuthorized(() -> controller.getMonthly(2026, 7));
    }

    @Test
    @WithMockUser(roles = "ADMIN")
    void adminCanUseReportEndpointsExceptApproval() {
        assertAuthorized(() -> controller.generate(DATE));
        assertAuthorized(() -> controller.retryFailed());
        assertAuthorized(() -> controller.getById(REPORT_ID));

        assertThrows(AccessDeniedException.class, () -> controller.approve(REPORT_ID));
    }

    @Test
    @WithMockUser(authorities = "SYSTEM_ADMIN")
    void systemAdminAuthorityRemainsCompatibleExceptApproval() {
        assertAuthorized(() -> controller.generate(DATE));
        assertThrows(AccessDeniedException.class, () -> controller.approve(REPORT_ID));
    }

    @Test
    @WithMockUser(roles = "BELSO_ELLENOR")
    void belsoEllenorCanReadButCannotRunOrSubmitReports() {
        assertAuthorized(() -> controller.getByDate(DATE));
        assertAuthorized(() -> controller.getByDateRange(DATE, DATE));

        assertThrows(AccessDeniedException.class, () -> controller.generate(DATE));
        assertThrows(AccessDeniedException.class, () -> controller.submit(REPORT_ID));
    }

    @Test
    @WithMockUser(roles = "PENZTAR")
    void penztarCannotAccessReports() {
        assertThrows(AccessDeniedException.class, () -> controller.generate(DATE));
        assertThrows(AccessDeniedException.class, () -> controller.getByDate(DATE));
    }

    @Test
    @WithMockUser(roles = "CASHIER")
    void cashierCannotAccessReports() {
        assertThrows(AccessDeniedException.class, () -> controller.generate(DATE));
        assertThrows(AccessDeniedException.class, () -> controller.getByDate(DATE));
    }

    @Test
    @WithMockUser(roles = "ERTEKTAR")
    void ertektarCannotAccessReports() {
        assertThrows(AccessDeniedException.class, () -> controller.generate(DATE));
        assertThrows(AccessDeniedException.class, () -> controller.getByDate(DATE));
    }

    @Test
    @WithMockUser(roles = {"CASHIER", "FOERTEKTAR"})
    void canonicalRoleAllowsMixedLegacyUser() {
        assertAuthorized(() -> controller.generate(DATE));
    }

    private static void assertAuthorized(Callable<?> call) {
        try {
            call.call();
        } catch (AccessDeniedException denied) {
            throw new AssertionError("A @PreAuthorize tévesen elutasította a jogosult authority-t", denied);
        } catch (Exception businessError) {
            // A metódustörzs elkezdett futni, tehát a method-security engedélyezte a hívást.
        }
    }

    @Configuration
    @EnableMethodSecurity
    static class TestConfig {

        @Bean
        DariusReportService dariusReportService() {
            return mock(DariusReportService.class);
        }

        @Bean
        DariusImportFileService dariusImportFileService() {
            return mock(DariusImportFileService.class);
        }

        @Bean
        EntityManagerFactory entityManagerFactory() {
            return mock(EntityManagerFactory.class);
        }

        @Bean
        DariusReportController dariusReportController(
                DariusReportService reportService,
                DariusImportFileService importFileService) {
            return new DariusReportController(reportService, importFileService);
        }
    }
}
