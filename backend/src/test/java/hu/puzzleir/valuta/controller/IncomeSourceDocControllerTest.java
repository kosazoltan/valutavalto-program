package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.document.IncomeProofEmailRequest;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.service.AmlService;
import hu.puzzleir.valuta.service.AuditLogService;
import hu.puzzleir.valuta.service.IncomeSourceDocService;
import hu.puzzleir.valuta.service.SystemParameterService;
import hu.puzzleir.valuta.service.ValueBandService;
import org.junit.jupiter.api.Test;
import org.mockito.MockedStatic;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class IncomeSourceDocControllerTest {

    private static final UUID COMPANY_ID = UUID.fromString("22222222-2222-2222-2222-222222222222");

    private final IncomeSourceDocService incomeSourceDocService = mock(IncomeSourceDocService.class);
    private final SystemParameterService systemParameterService = mock(SystemParameterService.class);
    private final AuditLogService auditLogService = mock(AuditLogService.class);
    private final IncomeSourceDocController controller =
            new IncomeSourceDocController(incomeSourceDocService, systemParameterService, auditLogService);

    @Test
    void required_delegatesToServiceAndReturnsResult() {
        BigDecimal amount = new BigDecimal("12000000");
        when(incomeSourceDocService.isRequired("C1", amount, "EUR")).thenReturn(true);
        when(incomeSourceDocService.thresholdHuf()).thenReturn(new BigDecimal("10000000"));

        ResponseEntity<Map<String, Object>> resp =
                controller.required(amount, "C1", "EUR");

        assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(resp.getBody()).containsEntry("required", true)
                .containsEntry("thresholdHuf", new BigDecimal("10000000"));
        verify(incomeSourceDocService).isRequired("C1", amount, "EUR");
    }

    @Test
    void email_delegatesAndReturnsSentCount() {
        IncomeProofEmailRequest req = IncomeProofEmailRequest.builder()
                .imageBase64("base64data").mimeType("image/jpeg")
                .transactionRef("TX-1").build();
        when(incomeSourceDocService.sendIncomeProofDocument(req)).thenReturn(2);

        ResponseEntity<Map<String, Object>> resp = controller.email(req);

        assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(resp.getBody()).containsEntry("sentTo", 2);
        verify(incomeSourceDocService).sendIncomeProofDocument(req);
    }

    @Test
    void email_validationException_propagatesAsException() {
        IncomeProofEmailRequest req = IncomeProofEmailRequest.builder()
                .imageBase64("base64data").mimeType("text/html").build();
        when(incomeSourceDocService.sendIncomeProofDocument(req))
                .thenThrow(new ValidationException("Hiba"));

        assertThatThrownBy(() -> controller.email(req))
                .isInstanceOf(ValidationException.class)
                .hasMessage("Hiba");
    }

    @Test
    void putRecipients_invalidEmail_throwsValidation() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

            Map<String, Object> body = Map.of("recipients", List.of("valid@valuta.local", "not-an-email"));

            assertThatThrownBy(() -> controller.putRecipients(body))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("Érvénytelen címzett email");
        }
    }

    @Test
    void putRecipients_validList_upsertsWithSecurityContextCompanyId() {
        UUID foreignCompanyId = UUID.fromString("33333333-3333-3333-3333-333333333333");
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

            // body contains a foreign companyId field — must be IGNORED
            Map<String, Object> body = Map.of(
                    "recipients", List.of("a@x.local", "b@x.local"),
                    "companyId", foreignCompanyId.toString());

            ResponseEntity<Map<String, Object>> resp = controller.putRecipients(body);

            assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.OK);
            assertThat(resp.getBody()).containsEntry("count", 2);
            // key derived from SecurityContext companyId, NOT from body
            verify(systemParameterService).upsertCompanyValue(
                    eq(IncomeSourceDocService.RECIPIENTS_PARAM_KEY), eq(COMPANY_ID),
                    eq("a@x.local,b@x.local"), eq("COMPLIANCE"), anyString());
            // audit fires with count (never addresses)
            verify(auditLogService).log(eq("INCOME_PROOF_DOC_RECIPIENTS_UPDATED"),
                    eq("cég=" + COMPANY_ID + ", címzettek=2"), eq((String) null));
        }
    }

    @Test
    void getRecipients_returnsCompanyScopedList() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(systemParameterService.getCompanyValue(
                    eq(IncomeSourceDocService.RECIPIENTS_PARAM_KEY), eq(COMPANY_ID), anyString()))
                    .thenReturn("compliance@valuta.local, audit@valuta.local");

            ResponseEntity<Map<String, Object>> resp = controller.getRecipients();

            assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.OK);
            @SuppressWarnings("unchecked")
            List<String> list = (List<String>) resp.getBody().get("recipients");
            assertThat(list).containsExactly("compliance@valuta.local", "audit@valuta.local");
            verify(systemParameterService).getCompanyValue(
                    eq(IncomeSourceDocService.RECIPIENTS_PARAM_KEY), eq(COMPANY_ID), anyString());
        }
    }
}
