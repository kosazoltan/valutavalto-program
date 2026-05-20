package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.entity.ApprovalLevel;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.service.DiscountApprovalService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.ResponseEntity;

import java.math.BigDecimal;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.when;

/**
 * Sprint 50-step S9 (v2.5.73) — DiscountApprovalController unit teszt.
 *
 * <p>A korábban dead-code DiscountApprovalService REST-exponálásának verifikálása.</p>
 */
@ExtendWith(MockitoExtension.class)
class DiscountApprovalControllerTest {

    @Mock
    private DiscountApprovalService discountApprovalService;

    @InjectMocks
    private DiscountApprovalController controller;

    @Test
    @DisplayName("required-level: 3% MANAGER worker → SUPERVISOR required, canApprove=true")
    void requiredLevel_managerCanApproveSupervisorLevel() {
        when(discountApprovalService.getRequiredLevel(new BigDecimal("3.0")))
                .thenReturn(ApprovalLevel.SUPERVISOR);
        when(discountApprovalService.mapRoleToLevel("MANAGER")).thenReturn(ApprovalLevel.MANAGER);

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getActiveOperationalRole).thenReturn("MANAGER");

            ResponseEntity<Map<String, Object>> resp = controller.requiredLevel(new BigDecimal("3.0"));

            assertThat(resp.getStatusCode().value()).isEqualTo(200);
            Map<String, Object> body = resp.getBody();
            assertThat(body).isNotNull();
            assertThat(body.get("requiredLevel")).isEqualTo("SUPERVISOR");
            assertThat(body.get("workerLevel")).isEqualTo("MANAGER");
            assertThat(body.get("canApprove")).isEqualTo(true);
        }
    }

    @Test
    @DisplayName("required-level: 7% CASHIER worker → MANAGER required, canApprove=false")
    void requiredLevel_cashierCannotApproveManagerLevel() {
        when(discountApprovalService.getRequiredLevel(new BigDecimal("7.0")))
                .thenReturn(ApprovalLevel.MANAGER);
        when(discountApprovalService.mapRoleToLevel("CASHIER")).thenReturn(ApprovalLevel.CASHIER);

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getActiveOperationalRole).thenReturn("CASHIER");

            ResponseEntity<Map<String, Object>> resp = controller.requiredLevel(new BigDecimal("7.0"));

            Map<String, Object> body = resp.getBody();
            assertThat(body).isNotNull();
            assertThat(body.get("canApprove")).isEqualTo(false);
        }
    }

    @Test
    @DisplayName("validate: engedélyezett kedvezmény → approved=true")
    void validate_allowed_returnsApproved() {
        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getActiveOperationalRole).thenReturn("MANAGER");
            when(discountApprovalService.mapRoleToLevel("MANAGER")).thenReturn(ApprovalLevel.MANAGER);
            // validateApprovalLevel nem dob → engedélyezett

            ResponseEntity<Map<String, Object>> resp = controller.validate(new BigDecimal("7.0"));

            assertThat(resp.getStatusCode().value()).isEqualTo(200);
            assertThat(resp.getBody()).isNotNull();
            assertThat(resp.getBody().get("approved")).isEqualTo(true);
        }
    }

    @Test
    @DisplayName("validate: nem engedélyezett → ValidationException propagál (GlobalExceptionHandler 400)")
    void validate_notAllowed_throws() {
        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getActiveOperationalRole).thenReturn("CASHIER");
            org.mockito.Mockito.doThrow(new ValidationException("SUPERVISOR szintű jóváhagyást igényel"))
                    .when(discountApprovalService).validateApprovalLevel(new BigDecimal("3.0"), "CASHIER");

            assertThatThrownBy(() -> controller.validate(new BigDecimal("3.0")))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("SUPERVISOR");
        }
    }
}
