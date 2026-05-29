package hu.puzzleir.valuta.dto.auth;

import lombok.Builder;
import lombok.Data;

import java.time.Instant;

/**
 * A kiállított worker setup-token válasza (F-001 fix). A {@code token} mező a raw token,
 * ami CSAK itt, a kiállításkor érhető el — az adatbázis csak a SHA-256 hash-t tárolja.
 */
@Data
@Builder
public class WorkerSetupTokenResponseDto {

    private boolean success;
    private String message;
    private String companyCode;
    private String workerCode;
    private String workerName;
    /** A raw setup-token — ezt kell a kollégának eljuttatni (csak egyszer látható). */
    private String token;
    private Instant expiresAt;
}
