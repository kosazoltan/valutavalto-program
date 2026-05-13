package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.service.TotpService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

/**
 * MFA (TOTP) REST API — Sprint 3 (P2-A).
 *
 * <p>Két flow:
 * <ol>
 *   <li><b>Self-enrollment</b> (a bejelentkezett worker saját MFA-ját aktiválja):
 *       POST /enroll/start → QR + secret, POST /enroll/complete → backup codes</li>
 *   <li><b>Admin disable</b> (egy worker MFA-ját letiltja, pl. eltört telefon):
 *       POST /admin/{workerId}/disable</li>
 * </ol></p>
 */
@RestController
@RequestMapping("/api/v1/mfa")
@RequiredArgsConstructor
public class MfaController {

    private final TotpService totpService;

    // ==========================================================================
    // Self-enrollment (a bejelentkezett worker saját MFA-ja)
    // ==========================================================================

    @PostMapping("/enroll/start")
    public TotpService.EnrollmentResponse startEnrollment() {
        Long workerId = SecurityUtils.getCurrentWorkerId();
        return totpService.startEnrollment(workerId);
    }

    @PostMapping("/enroll/complete")
    public TotpService.EnrollmentCompleteResponse completeEnrollment(
            @Valid @RequestBody VerifyRequest req) {
        Long workerId = SecurityUtils.getCurrentWorkerId();
        return totpService.completeEnrollment(workerId, req.getCode());
    }

    @GetMapping("/status")
    public MfaStatusResponse status() {
        Long workerId = SecurityUtils.getCurrentWorkerId();
        return MfaStatusResponse.builder()
                .enabled(totpService.isMfaRequired(workerId))
                .build();
    }

    // ==========================================================================
    // Admin endpoint-ok
    // ==========================================================================

    @PostMapping("/admin/{workerId}/disable")
    @PreAuthorize("hasAnyRole('ADMIN','MANAGER','MAIN_TREASURY')")
    public DisableResponse adminDisable(@PathVariable Long workerId) {
        totpService.disable(workerId);
        return DisableResponse.builder()
                .workerId(workerId)
                .message("MFA letiltva. A worker újra-enrollment-tel aktiválhatja.")
                .build();
    }

    // ==========================================================================
    // Request / Response DTOs
    // ==========================================================================

    @Data @NoArgsConstructor @AllArgsConstructor
    public static class VerifyRequest {
        @NotNull
        @Min(value = 0, message = "TOTP kód 6 számjegyű kell legyen")
        @Max(value = 999999, message = "TOTP kód 6 számjegyű kell legyen")
        private Integer code;
    }

    @Data
    @lombok.Builder
    @AllArgsConstructor
    public static class MfaStatusResponse {
        private Boolean enabled;
    }

    @Data
    @lombok.Builder
    @AllArgsConstructor
    public static class DisableResponse {
        private Long workerId;
        private String message;
    }
}
