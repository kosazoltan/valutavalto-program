package hu.puzzleir.valuta.dto.auth;

import hu.puzzleir.valuta.dto.worker.WorkerDto;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Login response DTO - JWT token + worker adatok.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class LoginResponseDto {
    private String token;
    @Builder.Default
    private String tokenType = "Bearer";
    private WorkerDto worker;

    // Frontend compatibility: expiresAt as ISO string
    private String expiresAt;

    // Legacy: expiresIn in milliseconds (for backward compatibility)
    private Long expiresIn;
}
