package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.service.WorkerRoleService;
import hu.puzzleir.valuta.service.WorkerService;
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

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.reset;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * RBAC-audit (2026-06-05): a {@code GET /api/v1/workers} (getAllWorkers) eddig NEM volt
 * {@code @PreAuthorize}-olt → bármely belépett user (pl. pénztáros) lekérhette a TELJES céges
 * dolgozó-listát (név + telefon + email + OTP/login-metaadat). Caller-audit: az endpointot
 * kizárólag az admin WorkerPage hívja, ezért {@code ADMIN/MANAGER/UGYVEZETO/IRODAVEZETO/
 * IRODAI_DOLGOZO}-ra szűkítettük (a /workers/active picker SZÁNDÉKOSAN szélesebb marad).
 *
 * <p>A @PreAuthorize interceptor a metódus-test ELŐTT dob a tiltott szerepköröknél; az
 * engedélyezetteknél a body lefut (a mockolt service üres listát ad).</p>
 */
@ExtendWith(SpringExtension.class)
@ContextConfiguration(classes = WorkerControllerListSecurityWebMvcTest.TestConfig.class)
class WorkerControllerListSecurityWebMvcTest {

    @Autowired
    private WorkerService workerService;

    @Autowired
    private WorkerController workerController;

    @BeforeEach
    void setup() {
        reset(workerService);
        when(workerService.findAllByCompany()).thenReturn(List.of());
    }

    @Configuration
    @EnableMethodSecurity
    static class TestConfig {
        @Bean
        WorkerService workerService() {
            return mock(WorkerService.class);
        }

        @Bean
        WorkerRepository workerRepository() {
            return mock(WorkerRepository.class);
        }

        @Bean
        WorkerRoleService workerRoleService() {
            return mock(WorkerRoleService.class);
        }

        @Bean
        WorkerController workerController(WorkerService s, WorkerRepository r, WorkerRoleService rs) {
            return new WorkerController(s, r, rs);
        }
    }

    @Test
    @DisplayName("AuthZ: CASHIER TILTOTT a teljes dolgozó-lista lekérésére")
    @WithMockUser(roles = "CASHIER")
    void getAllWorkers_forbiddenForCashier() {
        assertThrows(AccessDeniedException.class, () -> workerController.getAllWorkers());
        verify(workerService, never()).findAllByCompany();
    }

    @Test
    @DisplayName("AuthZ: PENZTAR TILTOTT a teljes dolgozó-lista lekérésére")
    @WithMockUser(roles = "PENZTAR")
    void getAllWorkers_forbiddenForPenztar() {
        assertThrows(AccessDeniedException.class, () -> workerController.getAllWorkers());
        verify(workerService, never()).findAllByCompany();
    }

    @Test
    @DisplayName("AuthZ: UGYVEZETO ENGEDÉLYEZETT (a body lefut)")
    @WithMockUser(roles = "UGYVEZETO")
    void getAllWorkers_allowedForUgyvezeto() {
        workerController.getAllWorkers();
        verify(workerService).findAllByCompany();
    }

    @Test
    @DisplayName("AuthZ: IRODAI_DOLGOZO ENGEDÉLYEZETT (a menü-szerepkörökkel egyezően)")
    @WithMockUser(roles = "IRODAI_DOLGOZO")
    void getAllWorkers_allowedForIrodaiDolgozo() {
        workerController.getAllWorkers();
        verify(workerService).findAllByCompany();
    }

    @Test
    @DisplayName("AuthZ: ADMIN ENGEDÉLYEZETT")
    @WithMockUser(roles = "ADMIN")
    void getAllWorkers_allowedForAdmin() {
        workerController.getAllWorkers();
        verify(workerService).findAllByCompany();
    }
}
