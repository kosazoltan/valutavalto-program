package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.compliance.ComplianceTransactionRowDto;
import hu.puzzleir.valuta.dto.compliance.ComplianceTransactionSearchCriteria;
import hu.puzzleir.valuta.service.ComplianceTransactionExportService;
import hu.puzzleir.valuta.service.ComplianceTransactionSearchService;
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
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.reset;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * FS-11 S1: controller metódus-security tesztek a cégszintű compliance tranzakció-keresőhöz.
 */
@ExtendWith(SpringExtension.class)
@ContextConfiguration(classes = ComplianceTransactionControllerSecurityTest.TestConfig.class)
class ComplianceTransactionControllerSecurityTest {

    @org.springframework.beans.factory.annotation.Autowired
    private ComplianceTransactionSearchService searchService;

    @org.springframework.beans.factory.annotation.Autowired
    private ComplianceTransactionExportService exportService;

    @org.springframework.beans.factory.annotation.Autowired
    private ComplianceTransactionController controller;

    @BeforeEach
    void setUp() {
        reset(searchService, exportService);
        when(searchService.search(any(), any(Pageable.class))).thenReturn(Page.empty());
        when(searchService.searchForExport(any())).thenReturn(List.of());
        when(exportService.toCsv(any())).thenReturn(new byte[] {1});
        when(exportService.toXlsx(any())).thenReturn(new byte[] {2});
    }

    @Configuration
    @EnableMethodSecurity
    static class TestConfig {
        @Bean
        ComplianceTransactionSearchService complianceTransactionSearchService() {
            return mock(ComplianceTransactionSearchService.class);
        }

        @Bean
        ComplianceTransactionExportService complianceTransactionExportService() {
            return mock(ComplianceTransactionExportService.class);
        }

        @Bean
        ComplianceTransactionController complianceTransactionController(
                ComplianceTransactionSearchService searchService,
                ComplianceTransactionExportService exportService) {
            return new ComplianceTransactionController(searchService, exportService);
        }
    }

    @Test
    @DisplayName("FS-11 S1 AuthZ: COMPLIANCE kereshet")
    @WithMockUser(roles = "COMPLIANCE")
    void complianceCanSearch() {
        controller.search(new ComplianceTransactionSearchCriteria(), 0, 50);
        verify(searchService).search(any(), any(Pageable.class));
    }

    @Test
    @DisplayName("FS-11 S1 AuthZ: ADMIN kereshet")
    @WithMockUser(roles = "ADMIN")
    void adminCanSearch() {
        controller.search(new ComplianceTransactionSearchCriteria(), 0, 50);
        verify(searchService).search(any(), any(Pageable.class));
    }

    @Test
    @DisplayName("FS-11 S1 AuthZ: COMPLIANCE_OFFICER CSV exportot indíthat")
    @WithMockUser(roles = "COMPLIANCE_OFFICER")
    void complianceOfficerCanExportCsv() {
        controller.exportCsv(new ComplianceTransactionSearchCriteria());
        verify(searchService).searchForExport(any());
        verify(exportService).toCsv(any());
    }

    @Test
    @DisplayName("FS-11 S1 AuthZ: MANAGER XLSX exportot indíthat")
    @WithMockUser(roles = "MANAGER")
    void managerCanExportXlsx() {
        controller.exportXlsx(new ComplianceTransactionSearchCriteria());
        verify(searchService).searchForExport(any());
        verify(exportService).toXlsx(any());
    }

    @Test
    @DisplayName("FS-11 S1 AuthZ: CASHIER mindhárom compliance endpointon tiltott")
    @WithMockUser(roles = "CASHIER")
    void cashierIsForbiddenEverywhere() {
        assertThrows(AccessDeniedException.class, () -> controller.search(new ComplianceTransactionSearchCriteria(), 0, 50));
        assertThrows(AccessDeniedException.class, () -> controller.exportCsv(new ComplianceTransactionSearchCriteria()));
        assertThrows(AccessDeniedException.class, () -> controller.exportXlsx(new ComplianceTransactionSearchCriteria()));
        verify(searchService, never()).search(any(), any(Pageable.class));
        verify(searchService, never()).searchForExport(any());
        verify(exportService, never()).toCsv(any());
        verify(exportService, never()).toXlsx(any());
    }

    @Test
    @DisplayName("FS-11 S1 AuthZ: SUPERVISOR nem láthat cégszintű compliance keresőt")
    @WithMockUser(roles = "SUPERVISOR")
    void supervisorIsForbiddenForCompanyWideSearch() {
        assertThrows(AccessDeniedException.class, () -> controller.search(new ComplianceTransactionSearchCriteria(), 0, 50));
        verify(searchService, never()).search(any(), any(Pageable.class));
    }
}
