package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.compliance.ComplianceQuestionDto;
import hu.puzzleir.valuta.dto.compliance.CreateComplianceQuestionDto;
import hu.puzzleir.valuta.dto.compliance.UpdateComplianceQuestionDto;
import hu.puzzleir.valuta.entity.ComplianceQuestionType;
import hu.puzzleir.valuta.service.ComplianceQuestionService;
import hu.puzzleir.valuta.util.IdempotencyGuard;
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
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.reset;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * FS-10 S1 / FS11-MENU-ROLE: controller metódus-security tesztek a compliance-kérdésekhez.
 * A setActive endpoint (private record paraméter) direkt hívással nem tesztelhető innen —
 * a megosztott COMPLIANCE_MANAGE_ROLES konstans (create/update/list-en keresztül) fedi le.
 */
@ExtendWith(SpringExtension.class)
@ContextConfiguration(classes = ComplianceQuestionControllerSecurityTest.TestConfig.class)
class ComplianceQuestionControllerSecurityTest {

    private static final UUID QUESTION_ID = UUID.fromString("44444444-4444-4444-4444-444444444444");

    @org.springframework.beans.factory.annotation.Autowired
    private ComplianceQuestionService service;

    @org.springframework.beans.factory.annotation.Autowired
    private IdempotencyGuard idempotencyGuard;

    @org.springframework.beans.factory.annotation.Autowired
    private ComplianceQuestionController controller;

    @BeforeEach
    void setUp() {
        reset(service, idempotencyGuard);
        when(service.create(any())).thenReturn(questionDto());
        when(service.update(eq(QUESTION_ID), any())).thenReturn(questionDto());
        when(service.listForCurrentCompany()).thenReturn(List.of(questionDto()));
        when(service.getAnswersForQuestion(QUESTION_ID)).thenReturn(List.of());
        when(service.getAnswersForCustomer(42L)).thenReturn(List.of());
    }

    @Configuration
    @EnableMethodSecurity
    static class TestConfig {
        @Bean
        ComplianceQuestionService complianceQuestionService() {
            return mock(ComplianceQuestionService.class);
        }

        @Bean
        IdempotencyGuard idempotencyGuard() {
            return mock(IdempotencyGuard.class);
        }

        @Bean
        ComplianceQuestionController complianceQuestionController(
                ComplianceQuestionService service, IdempotencyGuard idempotencyGuard) {
            return new ComplianceQuestionController(service, idempotencyGuard);
        }
    }

    @Test
    @DisplayName("FS11-MENU-ROLE: canonical BELSO_ELLENOR kérdést hozhat létre és listázhat")
    @WithMockUser(roles = "BELSO_ELLENOR")
    void belsoEllenorCanCreateAndList() {
        controller.create(CreateComplianceQuestionDto.builder()
                .questionText("Ismeri az ügyfelet?")
                .questionType(ComplianceQuestionType.YES_NO)
                .displayOrder(1)
                .build());
        controller.list();
        verify(service).create(any());
        verify(service).listForCurrentCompany();
    }

    @Test
    @DisplayName("FS11-MENU-ROLE: canonical UGYVEZETO módosíthat")
    @WithMockUser(roles = "UGYVEZETO")
    void ugyvezetoCanUpdate() {
        controller.update(QUESTION_ID, UpdateComplianceQuestionDto.builder()
                .questionText("Frissítve").build());
        verify(service).update(eq(QUESTION_ID), any());
    }

    @Test
    @DisplayName("FS11-MENU-ROLE: BIZTONSAGI_VEZETO válasz-nézetet olvashat; SUPERVISOR szintén (view-halmaz)")
    @WithMockUser(roles = "BIZTONSAGI_VEZETO")
    void biztonsagiVezetoCanReadAnswers() {
        controller.getAnswers(QUESTION_ID);
        controller.getAnswersForCustomer(42L);
        verify(service).getAnswersForQuestion(QUESTION_ID);
        verify(service).getAnswersForCustomer(42L);
    }

    @Test
    @DisplayName("FS11-MENU-ROLE: SUPERVISOR válasz-nézetet olvashat (view-halmaz megőrizve)")
    @WithMockUser(roles = "SUPERVISOR")
    void supervisorCanReadAnswers() {
        controller.getAnswers(QUESTION_ID);
        verify(service).getAnswersForQuestion(QUESTION_ID);
    }

    @Test
    @DisplayName("FS11-MENU-ROLE: PENZTAR a manage- és view-endpointokon tiltott")
    @WithMockUser(roles = "PENZTAR")
    void penztarIsForbidden() {
        assertThrows(AccessDeniedException.class, () -> controller.list());
        assertThrows(AccessDeniedException.class, () -> controller.getAnswers(QUESTION_ID));
        verify(service, never()).listForCurrentCompany();
        verify(service, never()).getAnswersForQuestion(any());
    }

    private static ComplianceQuestionDto questionDto() {
        return ComplianceQuestionDto.builder()
                .id(QUESTION_ID)
                .questionText("Ismeri az ügyfelet?")
                .questionType(ComplianceQuestionType.YES_NO)
                .displayOrder(1)
                .active(true)
                .createdByWorkerCode("W-001")
                .build();
    }
}
