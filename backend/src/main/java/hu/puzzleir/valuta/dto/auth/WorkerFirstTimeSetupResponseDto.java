package hu.puzzleir.valuta.dto.auth;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Worker first-time setup sikeres valasz — a setup wizard ebbol nyeri
 * ki a bejelentkezett dolgozo identity-jet, amit az Electron config
 * store elment es a Login oldal pre-fill-ezeshez hasznal.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class WorkerFirstTimeSetupResponseDto {
    private boolean success;
    private String message;
    private Long workerId;
    private String companyCode;
    private String companyName;
    private String workerCode;
    private String workerName;
    private String workerRole;
    private String branchCode;
    private String branchName;
    /**
     * JWT token auto-login celjara, hogy a wizard befejezese utan
     * a kliens mar bejelentkezve indulhasson.
     */
    private String token;
    private Long expiresAt;
}