package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.aml.AmlCheckResult;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.service.AmlApprovalService;
import hu.puzzleir.valuta.service.AmlService;
import hu.puzzleir.valuta.service.SupervisorPinService;
import jakarta.servlet.http.HttpServletRequest;
import org.junit.jupiter.api.Test;
import org.mockito.MockedStatic;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.*;

class AmlApprovalControllerTest {

    private final AmlApprovalService amlApprovalService = mock(AmlApprovalService.class);
    private final SupervisorPinService supervisorPinService = mock(SupervisorPinService.class);
    private final WorkerRepository workerRepository = mock(WorkerRepository.class);
    private final AmlService amlService = mock(AmlService.class);
    private final HttpServletRequest request = mock(HttpServletRequest.class);
    private final AmlApprovalController controller =
            new AmlApprovalController(amlApprovalService, supervisorPinService, workerRepository, amlService);

    private static final Long CASHIER_ID = 10L;
    private static final Long APPROVER_ID = 20L;
    private static final UUID COMPANY_ID = UUID.randomUUID();

    @Test
    void verifyApproverSucceedsForValidSeniorApproverWithCorrectPin() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentWorkerId).thenReturn(CASHIER_ID);
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(amlApprovalService.isValidSeniorApprover(APPROVER_ID)).thenReturn(true);
            when(supervisorPinService.verifyPin(eq(APPROVER_ID), eq("1234"), any(), any())).thenReturn(true);
            Worker approver = Worker.builder().name("Teszt Supervisor").build();
            when(workerRepository.findByIdAndCompanyId(APPROVER_ID, COMPANY_ID)).thenReturn(Optional.of(approver));

            ResponseEntity<Map<String, Object>> resp = controller.verifyApprover(
                    Map.of("approverWorkerId", 20, "pin", "1234", "approvalSessionId", "sess-1",
                            "customerName", "Teszt Ügyfél"), request);

            assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.OK);
            assertThat(resp.getBody()).containsEntry("ok", true)
                    .containsEntry("approverWorkerId", APPROVER_ID)
                    .containsEntry("approverName", "Teszt Supervisor");
            // Codex P1: PIN OK → SINGLE-USE grant kiállítása a sessionhöz ÉS a jóváhagyott ügyfélhez kötve.
            verify(amlApprovalService).issueApprovalGrant(eq(APPROVER_ID), eq("sess-1"), eq("Teszt Ügyfél"));
            verify(workerRepository).findByIdAndCompanyId(APPROVER_ID, COMPANY_ID);
            verify(workerRepository, never()).findById(APPROVER_ID);
        }
    }

    // verifyApprover: hiányzó customerName → 400 (Codex P1: a customer-scoping kötelező, nincs NULL-wildcard).
    @Test
    void verifyApprover_rejectsMissingCustomerName() {
        try (var mocked = mockStatic(SecurityUtils.class)) {
            mocked.when(SecurityUtils::getCurrentWorkerId).thenReturn(10L);

            // customerName hiányzik → elutasít MIELŐTT grantot állítana ki (nem lehet wildcard grant).
            ResponseEntity<Map<String, Object>> resp = controller.verifyApprover(
                    Map.of("approverWorkerId", 20, "pin", "1234", "approvalSessionId", "sess-1"),
                    request);

            assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
            verify(amlApprovalService, never()).issueApprovalGrant(any(), any(), any());
        }
    }

    @Test
    void verifyApproverRejectsSelfApprovalFourEyes() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentWorkerId).thenReturn(CASHIER_ID);

            // approver == a bejelentkezett pénztáros → 4-szem-elv sért
            ResponseEntity<Map<String, Object>> resp = controller.verifyApprover(
                    Map.of("approverWorkerId", 10, "pin", "1234", "approvalSessionId", "sess-1",
                            "customerName", "Teszt Ügyfél"), request);

            assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
            assertThat(resp.getBody()).containsEntry("ok", false);
            verify(supervisorPinService, never()).verifyPin(any(), any(), any(), any());
        }
    }

    @Test
    void verifyApproverRejectsNonSeniorApprover() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentWorkerId).thenReturn(CASHIER_ID);
            when(amlApprovalService.isValidSeniorApprover(APPROVER_ID)).thenReturn(false);

            ResponseEntity<Map<String, Object>> resp = controller.verifyApprover(
                    Map.of("approverWorkerId", 20, "pin", "1234", "approvalSessionId", "sess-1",
                            "customerName", "Teszt Ügyfél"), request);

            assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
            assertThat(resp.getBody()).containsEntry("ok", false);
            verify(supervisorPinService, never()).verifyPin(any(), any(), any(), any());
        }
    }

    @Test
    void verifyApproverRejectsWrongPin() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentWorkerId).thenReturn(CASHIER_ID);
            when(amlApprovalService.isValidSeniorApprover(APPROVER_ID)).thenReturn(true);
            when(supervisorPinService.verifyPin(eq(APPROVER_ID), eq("0000"), any(), any())).thenReturn(false);

            ResponseEntity<Map<String, Object>> resp = controller.verifyApprover(
                    Map.of("approverWorkerId", 20, "pin", "0000", "approvalSessionId", "sess-1",
                            "customerName", "Teszt Ügyfél"), request);

            assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED);
            assertThat(resp.getBody()).containsEntry("ok", false);
        }
    }

    @Test
    void verifyApproverRejectsMissingFields() {
        ResponseEntity<Map<String, Object>> resp = controller.verifyApprover(
                Map.of("approverWorkerId", 20), request);

        assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        assertThat(resp.getBody()).containsEntry("ok", false);
    }

    @Test
    void checkRequiredReturnsTrueWhenBasicGateNeedsApproval() {
        AmlService.AmlBasicCheckResult basic = mock(AmlService.AmlBasicCheckResult.class);
        when(basic.isRequiresApproval()).thenReturn(true);
        when(basic.getApprovalReason()).thenReturn("Éves göngyölési limit elérve");
        when(amlService.checkTransaction(any(), any(), any(), any(), any(), any())).thenReturn(basic);

        ResponseEntity<Map<String, Object>> resp = controller.checkApprovalRequired(
                Map.of("amountHuf", 4_000_000, "customerId", "C-1"));

        assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(resp.getBody()).containsEntry("requiresApproval", true)
                .containsEntry("reason", "Éves göngyölési limit elérve");
        // Basic kapu kivaltott → a threshold kaput mar nem kell hivni.
        verify(amlService, never()).checkAllThresholds(any(), any(), any());
    }

    @Test
    void checkRequiredReturnsFalseWhenNeitherGateTriggers() {
        AmlService.AmlBasicCheckResult basic = mock(AmlService.AmlBasicCheckResult.class);
        when(basic.isRequiresApproval()).thenReturn(false);
        when(amlService.checkTransaction(any(), any(), any(), any(), any(), any())).thenReturn(basic);
        AmlCheckResult threshold = mock(AmlCheckResult.class);
        when(threshold.isRequiresManagerApproval()).thenReturn(false);
        when(amlService.checkAllThresholds(any(), any(), any())).thenReturn(threshold);

        ResponseEntity<Map<String, Object>> resp = controller.checkApprovalRequired(
                Map.of("amountHuf", 50_000, "customerId", "C-1"));

        assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(resp.getBody()).containsEntry("requiresApproval", false);
    }

    @Test
    void checkRequiredRejectsMissingAmount() {
        ResponseEntity<Map<String, Object>> resp = controller.checkApprovalRequired(Map.of("customerId", "C-1"));
        assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
    }
}
