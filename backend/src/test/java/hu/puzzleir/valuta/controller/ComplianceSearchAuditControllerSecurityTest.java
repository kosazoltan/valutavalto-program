package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.compliance.ComplianceSearchAuditDto;
import hu.puzzleir.valuta.dto.compliance.ComplianceTransactionSearchCriteria;
import hu.puzzleir.valuta.dto.compliance.CreateComplianceSearchAuditDto;
import hu.puzzleir.valuta.service.ComplianceSearchAuditPdfService;
import hu.puzzleir.valuta.service.ComplianceSearchAuditService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpHeaders;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.ContextConfiguration;
import org.springframework.test.context.junit.jupiter.SpringExtension;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.reset;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * FS-11 S2b: controller metódus-security tesztek a compliance keresés-audithoz.
 */
@ExtendWith(SpringExtension.class)
@ContextConfiguration(classes = ComplianceSearchAuditControllerSecurityTest.TestConfig.class)
class ComplianceSearchAuditControllerSecurityTest {

    private static final UUID AUDIT_ID = UUID.fromString("33333333-3333-3333-3333-333333333333");

    @org.springframework.beans.factory.annotation.Autowired
    private ComplianceSearchAuditService auditService;

    @org.springframework.beans.factory.annotation.Autowired
    private ComplianceSearchAuditPdfService pdfService;

    @org.springframework.beans.factory.annotation.Autowired
    private ComplianceSearchAuditController controller;

    @BeforeEach
    void setUp() {
        reset(auditService, pdfService);
        when(auditService.create(any())).thenReturn(auditDto());
        when(auditService.listForCurrentCompany()).thenReturn(List.of(auditDto()));
        when(auditService.loadForPdf(AUDIT_ID)).thenReturn(pdfData());
        when(pdfService.renderPdf(any())).thenReturn("%PDF-".getBytes());
    }

    @Configuration
    @EnableMethodSecurity
    static class TestConfig {
        @Bean
        ComplianceSearchAuditService complianceSearchAuditService() {
            return mock(ComplianceSearchAuditService.class);
        }

        @Bean
        ComplianceSearchAuditPdfService complianceSearchAuditPdfService() {
            return mock(ComplianceSearchAuditPdfService.class);
        }

        @Bean
        ComplianceSearchAuditController complianceSearchAuditController(
                ComplianceSearchAuditService auditService,
                ComplianceSearchAuditPdfService pdfService) {
            return new ComplianceSearchAuditController(auditService, pdfService);
        }
    }

    @Test
    @DisplayName("FS-11 S2b AuthZ: COMPLIANCE auditot menthet, listázhat és PDF-et tölthet")
    @WithMockUser(roles = "COMPLIANCE")
    void complianceCanCreateListPdf() {
        CreateComplianceSearchAuditDto request = CreateComplianceSearchAuditDto.builder()
                .title("Audit")
                .criteria(new ComplianceTransactionSearchCriteria())
                .build();

        controller.create(request);
        controller.list();
        ResponseEntity<byte[]> pdf = controller.pdf(AUDIT_ID);

        verify(auditService).create(request);
        verify(auditService).listForCurrentCompany();
        verify(auditService).loadForPdf(AUDIT_ID);
        verify(pdfService).renderPdf(any());
        assertThat(pdf.getHeaders().getFirst(HttpHeaders.CONTENT_DISPOSITION))
                .contains("compliance_kereses_audit_" + AUDIT_ID + ".pdf");
        assertThat(pdf.getBody()).isEqualTo("%PDF-".getBytes());
    }

    @Test
    @DisplayName("FS-11 S2b AuthZ: ADMIN audit-listát olvashat")
    @WithMockUser(roles = "ADMIN")
    void adminCanList() {
        controller.list();

        verify(auditService).listForCurrentCompany();
    }

    @Test
    @DisplayName("FS-11 S2b AuthZ: CASHIER mindhárom audit endpointon tiltott")
    @WithMockUser(roles = "CASHIER")
    void cashierIsForbiddenEverywhere() {
        CreateComplianceSearchAuditDto request = CreateComplianceSearchAuditDto.builder()
                .title("Audit")
                .criteria(new ComplianceTransactionSearchCriteria())
                .build();

        assertThrows(AccessDeniedException.class, () -> controller.create(request));
        assertThrows(AccessDeniedException.class, () -> controller.list());
        assertThrows(AccessDeniedException.class, () -> controller.pdf(AUDIT_ID));

        verify(auditService, never()).create(any());
        verify(auditService, never()).listForCurrentCompany();
        verify(auditService, never()).loadForPdf(any());
        verify(pdfService, never()).renderPdf(any());
    }

    @Test
    @DisplayName("FS11-MENU-ROLE: canonical BELSO_ELLENOR auditot menthet, listázhat és PDF-et tölthet")
    @WithMockUser(roles = "BELSO_ELLENOR")
    void belsoEllenorCanCreateListPdf() {
        CreateComplianceSearchAuditDto request = CreateComplianceSearchAuditDto.builder()
                .title("Audit")
                .criteria(new ComplianceTransactionSearchCriteria())
                .build();

        controller.create(request);
        controller.list();
        ResponseEntity<byte[]> pdf = controller.pdf(AUDIT_ID);

        verify(auditService).create(request);
        verify(auditService).listForCurrentCompany();
        verify(auditService).loadForPdf(AUDIT_ID);
        verify(pdfService).renderPdf(any());
        assertThat(pdf.getHeaders().getFirst(HttpHeaders.CONTENT_DISPOSITION))
                .contains("compliance_kereses_audit_" + AUDIT_ID + ".pdf");
        assertThat(pdf.getBody()).isEqualTo("%PDF-".getBytes());
    }

    @Test
    @DisplayName("FS11-MENU-ROLE: canonical BIZTONSAGI_VEZETO listázhat")
    @WithMockUser(roles = "BIZTONSAGI_VEZETO")
    void biztonsagiVezetoCanList() {
        controller.list();

        verify(auditService).listForCurrentCompany();
    }

    @Test
    @DisplayName("FS11-MENU-ROLE: canonical UGYVEZETO listázhat")
    @WithMockUser(roles = "UGYVEZETO")
    void ugyvezetoCanList() {
        controller.list();

        verify(auditService).listForCurrentCompany();
    }

    @Test
    @DisplayName("FS11-MENU-ROLE: PENZTAR tiltott marad")
    @WithMockUser(roles = "PENZTAR")
    void penztarIsForbidden() {
        assertThrows(AccessDeniedException.class, () -> controller.list());
        verify(auditService, never()).listForCurrentCompany();
    }

    private static ComplianceSearchAuditDto auditDto() {
        return ComplianceSearchAuditDto.builder()
                .id(AUDIT_ID)
                .title("Audit")
                .criteria(new ComplianceTransactionSearchCriteria())
                .resultCount(0)
                .createdByWorkerCode("W-001")
                .build();
    }

    private static ComplianceSearchAuditService.ComplianceSearchAuditPdfData pdfData() {
        return new ComplianceSearchAuditService.ComplianceSearchAuditPdfData(
                "Audit", null, "W-001", LocalDateTime.of(2026, 7, 8, 14, 30), 0, List.of());
    }
}
