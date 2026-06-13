package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.worker.WorkerDto;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.service.WorkerRoleService;
import hu.puzzleir.valuta.service.WorkerService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.ContextConfiguration;
import org.springframework.test.context.junit.jupiter.SpringExtension;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

/**
 * FK-026 (Codex #1124 P1) AuthZ-regresszió: a Dolgozói Törzs read-only listát a kanonikus olvasó
 * szerepköröknek (FOERTEKTAR, BELSO_ELLENOR, UGYVEZETO) is el kell érniük — a sima /workers GET
 * SUPERVISOR/MANAGER/ADMIN-ra korlátoz, ami 403-at adott volna 2 olvasó szerepkörnél. A dedikált
 * {@code GET /api/v1/workers/directory} method-szintű @PreAuthorize-gate-jét verifikáljuk:
 * a tiltott CASHIER/PENZTAR AccessDenied-et kap, az olvasó szerepkörök átengedve (lista visszaadva).
 */
@ExtendWith(SpringExtension.class)
@ContextConfiguration(classes = WorkerDirectorySecurityWebMvcTest.TestConfig.class)
class WorkerDirectorySecurityWebMvcTest {

    @Autowired
    private WorkerController workerController;

    @Autowired
    private WorkerService workerService;

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

    private void stubList() {
        when(workerService.findAllByCompany())
                .thenReturn(List.of(WorkerDto.builder().id(1L).workerCode("BR020-01")
                        .fullName("Kiss Anna").region("SZEGED").active(true)
                        .roleCodes(List.of("ertektar")).build()));
    }

    @Test
    @DisplayName("AuthZ: CASHIER TILTOTT a directory-ra (AccessDenied a gate-en)")
    @WithMockUser(roles = "CASHIER")
    void directory_forbiddenForCashier() {
        assertThrows(AccessDeniedException.class, () -> workerController.getWorkerDirectory());
    }

    @Test
    @DisplayName("AuthZ: PENZTAR TILTOTT a directory-ra")
    @WithMockUser(roles = "PENZTAR")
    void directory_forbiddenForPenztar() {
        assertThrows(AccessDeniedException.class, () -> workerController.getWorkerDirectory());
    }

    @Test
    @DisplayName("AuthZ: FOERTEKTAR ÁTENGEDVE — visszaadja a listát (a P1 lényege)")
    @WithMockUser(roles = "FOERTEKTAR")
    void directory_allowedForFoertektar() {
        stubList();
        ResponseEntity<List<WorkerDto>> resp = workerController.getWorkerDirectory();
        assertThat(resp.getStatusCode().is2xxSuccessful()).isTrue();
        assertThat(resp.getBody()).hasSize(1);
    }

    @Test
    @DisplayName("AuthZ: BELSO_ELLENOR ÁTENGEDVE (a P1 lényege — eddig 403 lett volna)")
    @WithMockUser(roles = "BELSO_ELLENOR")
    void directory_allowedForBelsoEllenor() {
        stubList();
        ResponseEntity<List<WorkerDto>> resp = workerController.getWorkerDirectory();
        assertThat(resp.getStatusCode().is2xxSuccessful()).isTrue();
        assertThat(resp.getBody()).hasSize(1);
    }

    @Test
    @DisplayName("AuthZ: UGYVEZETO ÁTENGEDVE")
    @WithMockUser(roles = "UGYVEZETO")
    void directory_allowedForUgyvezeto() {
        stubList();
        ResponseEntity<List<WorkerDto>> resp = workerController.getWorkerDirectory();
        assertThat(resp.getStatusCode().is2xxSuccessful()).isTrue();
        assertThat(resp.getBody()).hasSize(1);
    }
}
