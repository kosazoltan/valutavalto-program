package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.service.darius.DariusFixingRequestService;
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
@ContextConfiguration(classes = DariusFixingRequestControllerSecurityTest.TestConfig.class)
class DariusFixingRequestControllerSecurityTest {

    private static final LocalDate DATE = LocalDate.of(2026, 7, 11);
    private static final UUID ID = UUID.fromString("30000000-0000-0000-0000-000000000003");

    @Autowired
    private DariusFixingRequestController controller;

    @Test
    @WithMockUser(roles = "FOERTEKTAR")
    void foertektarCanUseEveryFixingRequestEndpoint() {
        assertAuthorized(() -> controller.bankBranches(false));
        assertAuthorized(() -> controller.createBankBranch(null));
        assertAuthorized(() -> controller.deactivateBankBranch(ID));
        assertAuthorized(() -> controller.list(DATE));
        assertAuthorized(() -> controller.create(null));
        assertAuthorized(() -> controller.updateLines(ID, null));
        assertAuthorized(() -> controller.approve(ID));
        assertAuthorized(() -> controller.cancel(ID));
    }

    @Test
    @WithMockUser(roles = "ADMIN")
    void adminCanCreateButCannotApproveFixingRequests() {
        assertAuthorized(() -> controller.create(null));
        assertAuthorized(() -> controller.createBankBranch(null));

        assertThrows(AccessDeniedException.class, () -> controller.approve(ID));
    }

    @Test
    @WithMockUser(authorities = "DARIUS_REPORT_RUN")
    void dariusReportRunAuthorityRemainsCompatibleButCannotMaintainBankBranches() {
        assertAuthorized(() -> controller.list(DATE));
        assertAuthorized(() -> controller.create(null));
        assertAuthorized(() -> controller.approve(ID));

        assertThrows(AccessDeniedException.class, () -> controller.createBankBranch(null));
        assertThrows(AccessDeniedException.class, () -> controller.deactivateBankBranch(ID));
    }

    @Test
    @WithMockUser(roles = "BELSO_ELLENOR")
    void belsoEllenorCanListButCannotMutateFixingRequests() {
        assertAuthorized(() -> controller.list(DATE));

        assertThrows(AccessDeniedException.class, () -> controller.create(null));
        assertThrows(AccessDeniedException.class, () -> controller.cancel(ID));
    }

    @Test
    @WithMockUser(roles = "PENZTAR")
    void penztarCannotAccessFixingRequests() {
        assertThrows(AccessDeniedException.class, () -> controller.list(DATE));
        assertThrows(AccessDeniedException.class, () -> controller.create(null));
        assertThrows(AccessDeniedException.class, () -> controller.approve(ID));
    }

    @Test
    @WithMockUser(roles = "UGYVEZETO")
    void ugyvezetoCannotAccessFixingRequests() {
        assertThrows(AccessDeniedException.class, () -> controller.list(DATE));
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
        DariusFixingRequestService dariusFixingRequestService() {
            return mock(DariusFixingRequestService.class);
        }

        @Bean
        DariusFixingRequestController dariusFixingRequestController(DariusFixingRequestService service) {
            return new DariusFixingRequestController(service);
        }
    }
}
