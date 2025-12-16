package hu.puzzleir.valuta.security;

import lombok.AllArgsConstructor;
import lombok.Data;

import java.util.UUID;

/**
 * Worker authentication details - JWT token-ből származó adatok.
 * 
 * SecurityContext.getAuthentication().getDetails() casting után elérhető.
 */
@Data
@AllArgsConstructor
public class WorkerAuthenticationDetails {
    private Long workerId;
    private UUID companyId;  // MULTI-TENANT
    private UUID branchId;
    private String role;
}
