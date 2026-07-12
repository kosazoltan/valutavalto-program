package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.compliance.ComplianceSearchTemplateDto;
import hu.puzzleir.valuta.dto.compliance.ComplianceTransactionSearchCriteria;
import hu.puzzleir.valuta.dto.compliance.CreateComplianceSearchTemplateDto;
import hu.puzzleir.valuta.service.ComplianceSearchTemplateService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.ContextConfiguration;
import org.springframework.test.context.junit.jupiter.SpringExtension;

import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.reset;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * FS-11 S2a: controller metódus-security tesztek a compliance szűrő-sablonokhoz.
 */
@ExtendWith(SpringExtension.class)
@ContextConfiguration(classes = ComplianceSearchTemplateControllerSecurityTest.TestConfig.class)
class ComplianceSearchTemplateControllerSecurityTest {

    private static final UUID TEMPLATE_ID = UUID.fromString("22222222-2222-2222-2222-222222222222");

    @org.springframework.beans.factory.annotation.Autowired
    private ComplianceSearchTemplateService service;

    @org.springframework.beans.factory.annotation.Autowired
    private ComplianceSearchTemplateController controller;

    @BeforeEach
    void setUp() {
        reset(service);
        when(service.create(any())).thenReturn(templateDto());
        when(service.listForCurrentCompany()).thenReturn(List.of(templateDto()));
    }

    @Configuration
    @EnableMethodSecurity
    static class TestConfig {
        @Bean
        ComplianceSearchTemplateService complianceSearchTemplateService() {
            return mock(ComplianceSearchTemplateService.class);
        }

        @Bean
        ComplianceSearchTemplateController complianceSearchTemplateController(ComplianceSearchTemplateService service) {
            return new ComplianceSearchTemplateController(service);
        }
    }

    @Test
    @DisplayName("FS-11 S2a AuthZ: COMPLIANCE sablont menthet, listázhat és törölhet")
    @WithMockUser(roles = "COMPLIANCE")
    void complianceCanCreateListDelete() {
        CreateComplianceSearchTemplateDto request = CreateComplianceSearchTemplateDto.builder()
                .name("Sablon")
                .criteria(new ComplianceTransactionSearchCriteria())
                .build();

        controller.create(request);
        controller.list();
        controller.delete(TEMPLATE_ID);

        verify(service).create(request);
        verify(service).listForCurrentCompany();
        verify(service).delete(TEMPLATE_ID);
    }

    @Test
    @DisplayName("FS-11 S2a AuthZ: ADMIN sablont listázhat")
    @WithMockUser(roles = "ADMIN")
    void adminCanList() {
        controller.list();

        verify(service).listForCurrentCompany();
    }

    @Test
    @DisplayName("FS-11 S2a AuthZ: CASHIER mindhárom sablon endpointon tiltott")
    @WithMockUser(roles = "CASHIER")
    void cashierIsForbiddenEverywhere() {
        CreateComplianceSearchTemplateDto request = CreateComplianceSearchTemplateDto.builder()
                .name("Sablon")
                .criteria(new ComplianceTransactionSearchCriteria())
                .build();

        assertThrows(AccessDeniedException.class, () -> controller.create(request));
        assertThrows(AccessDeniedException.class, () -> controller.list());
        assertThrows(AccessDeniedException.class, () -> controller.delete(TEMPLATE_ID));

        verify(service, never()).create(any());
        verify(service, never()).listForCurrentCompany();
        verify(service, never()).delete(any());
    }

    @Test
    @DisplayName("FS11-MENU-ROLE: canonical BELSO_ELLENOR sablont menthet, listázhat és törölhet")
    @WithMockUser(roles = "BELSO_ELLENOR")
    void belsoEllenorCanCreateListDelete() {
        CreateComplianceSearchTemplateDto request = CreateComplianceSearchTemplateDto.builder()
                .name("Sablon")
                .criteria(new ComplianceTransactionSearchCriteria())
                .build();

        controller.create(request);
        controller.list();
        controller.delete(TEMPLATE_ID);

        verify(service).create(request);
        verify(service).listForCurrentCompany();
        verify(service).delete(TEMPLATE_ID);
    }

    @Test
    @DisplayName("FS11-MENU-ROLE: canonical BIZTONSAGI_VEZETO listázhat")
    @WithMockUser(roles = "BIZTONSAGI_VEZETO")
    void biztonsagiVezetoCanList() {
        controller.list();

        verify(service).listForCurrentCompany();
    }

    @Test
    @DisplayName("FS11-MENU-ROLE: canonical UGYVEZETO listázhat")
    @WithMockUser(roles = "UGYVEZETO")
    void ugyvezetoCanList() {
        controller.list();

        verify(service).listForCurrentCompany();
    }

    @Test
    @DisplayName("FS11-MENU-ROLE: PENZTAR tiltott marad")
    @WithMockUser(roles = "PENZTAR")
    void penztarIsForbidden() {
        assertThrows(AccessDeniedException.class, () -> controller.list());
        verify(service, never()).listForCurrentCompany();
    }

    private static ComplianceSearchTemplateDto templateDto() {
        return ComplianceSearchTemplateDto.builder()
                .id(TEMPLATE_ID)
                .name("Sablon")
                .criteria(new ComplianceTransactionSearchCriteria())
                .createdByWorkerCode("W-001")
                .build();
    }
}
