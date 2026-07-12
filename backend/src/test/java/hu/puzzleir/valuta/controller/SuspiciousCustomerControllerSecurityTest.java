package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.compliance.SuspiciousCustomerDto;
import hu.puzzleir.valuta.service.SuspiciousCustomerExportService;
import hu.puzzleir.valuta.service.SuspiciousCustomerService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.ContextConfiguration;
import org.springframework.test.context.junit.jupiter.SpringExtension;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyBoolean;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.reset;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * FS-12 S1: gyanús ügyfél controller metódus-security tesztek.
 */
@ExtendWith(SpringExtension.class)
@ContextConfiguration(classes = SuspiciousCustomerControllerSecurityTest.TestConfig.class)
class SuspiciousCustomerControllerSecurityTest {

    @org.springframework.beans.factory.annotation.Autowired
    private SuspiciousCustomerService suspiciousCustomerService;

    @org.springframework.beans.factory.annotation.Autowired
    private SuspiciousCustomerExportService exportService;

    @org.springframework.beans.factory.annotation.Autowired
    private SuspiciousCustomerController controller;

    @BeforeEach
    void setUp() {
        reset(suspiciousCustomerService, exportService);
        when(suspiciousCustomerService.search(any(), any(), anyBoolean(), any(), anyBoolean(), any(), anyBoolean(), any(), any(Pageable.class)))
                .thenReturn(Page.empty());
        when(suspiciousCustomerService.listValueBandReachedForExport(any(), any())).thenReturn(List.of());
        when(exportService.toXlsx(any())).thenReturn(new byte[] {1});
    }

    @Configuration
    @EnableMethodSecurity
    static class TestConfig {
        @Bean
        SuspiciousCustomerService suspiciousCustomerService() {
            return mock(SuspiciousCustomerService.class);
        }

        @Bean
        SuspiciousCustomerExportService suspiciousCustomerExportService() {
            return mock(SuspiciousCustomerExportService.class);
        }

        @Bean
        SuspiciousCustomerController suspiciousCustomerController(
                SuspiciousCustomerService suspiciousCustomerService,
                SuspiciousCustomerExportService exportService) {
            return new SuspiciousCustomerController(suspiciousCustomerService, exportService);
        }
    }

    @Test
    @DisplayName("FS-12 S1 AuthZ: COMPLIANCE_OFFICER kereshet")
    @WithMockUser(roles = "COMPLIANCE_OFFICER")
    void complianceOfficerCanSearch() {
        controller.search(null, null, true, null, true, null, true, null, 0, 50);
        verify(suspiciousCustomerService).search(any(), any(), anyBoolean(), any(), anyBoolean(), any(), anyBoolean(), any(), any(Pageable.class));
    }

    @Test
    @DisplayName("FS-12 S1 AuthZ: MANAGER exportálhat XLSX-et")
    @WithMockUser(roles = "MANAGER")
    void managerCanExportXlsx() {
        controller.exportXlsx(null, null);
        verify(suspiciousCustomerService).listValueBandReachedForExport(any(), any());
        verify(exportService).toXlsx(any());
    }

    @Test
    @DisplayName("FS-12 S1 AuthZ: CASHIER nem érheti el a gyanús ügyfél endpointokat")
    @WithMockUser(roles = "CASHIER")
    void cashierIsForbidden() {
        assertThrows(AccessDeniedException.class,
                () -> controller.search(null, null, true, null, true, null, true, null, 0, 50));
        assertThrows(AccessDeniedException.class, () -> controller.exportXlsx(null, null));
        verify(suspiciousCustomerService, never()).search(any(), any(), anyBoolean(), any(), anyBoolean(), any(), anyBoolean(), any(), any(Pageable.class));
        verify(suspiciousCustomerService, never()).listValueBandReachedForExport(any(), any());
        verify(exportService, never()).toXlsx(any());
    }

    @Test
    @DisplayName("FS-12 S1 AuthZ: SUPERVISOR nem láthatja a compliance gyanús ügyfél dashboardot")
    @WithMockUser(roles = "SUPERVISOR")
    void supervisorIsForbidden() {
        assertThrows(AccessDeniedException.class,
                () -> controller.search(null, null, true, null, true, null, true, null, 0, 50));
        verify(suspiciousCustomerService, never()).search(any(), any(), anyBoolean(), any(), anyBoolean(), any(), anyBoolean(), any(), any(Pageable.class));
    }

    @Test
    @DisplayName("FS11-MENU-ROLE: canonical BELSO_ELLENOR kereshet")
    @WithMockUser(roles = "BELSO_ELLENOR")
    void belsoEllenorCanSearch() {
        controller.search(null, null, true, null, true, null, true, null, 0, 50);
        verify(suspiciousCustomerService).search(any(), any(), anyBoolean(), any(), anyBoolean(), any(), anyBoolean(), any(), any(Pageable.class));
    }

    @Test
    @DisplayName("FS11-MENU-ROLE: canonical BIZTONSAGI_VEZETO kereshet")
    @WithMockUser(roles = "BIZTONSAGI_VEZETO")
    void biztonsagiVezetoCanSearch() {
        controller.search(null, null, true, null, true, null, true, null, 0, 50);
        verify(suspiciousCustomerService).search(any(), any(), anyBoolean(), any(), anyBoolean(), any(), anyBoolean(), any(), any(Pageable.class));
    }

    @Test
    @DisplayName("FS11-MENU-ROLE: canonical UGYVEZETO exportálhat XLSX-et")
    @WithMockUser(roles = "UGYVEZETO")
    void ugyvezetoCanExportXlsx() {
        controller.exportXlsx(null, null);
        verify(suspiciousCustomerService).listValueBandReachedForExport(any(), any());
        verify(exportService).toXlsx(any());
    }

    @Test
    @DisplayName("FS11-MENU-ROLE: COMPLIANCE regresszió-őr — a meglévő role továbbra is elérheti")
    @WithMockUser(roles = "COMPLIANCE")
    void complianceStillCanSearch() {
        controller.search(null, null, true, null, true, null, true, null, 0, 50);
        verify(suspiciousCustomerService).search(any(), any(), anyBoolean(), any(), anyBoolean(), any(), anyBoolean(), any(), any(Pageable.class));
    }

    @Test
    @DisplayName("FS11-MENU-ROLE: PENZTAR tiltott marad")
    @WithMockUser(roles = "PENZTAR")
    void penztarIsForbidden() {
        assertThrows(AccessDeniedException.class,
                () -> controller.search(null, null, true, null, true, null, true, null, 0, 50));
        assertThrows(AccessDeniedException.class, () -> controller.exportXlsx(null, null));
        verify(suspiciousCustomerService, never()).search(any(), any(), anyBoolean(), any(), anyBoolean(), any(), anyBoolean(), any(), any(Pageable.class));
        verify(exportService, never()).toXlsx(any());
    }
}
