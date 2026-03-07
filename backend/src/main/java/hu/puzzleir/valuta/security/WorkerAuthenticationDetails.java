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
    
    /**
     * Operatív szerepkör kódja (V57 — pl. CASHIER, VAULT_KEEPER, DIRECTOR).
     * Null ha nincs operatív role beállítva (backward compat).
     */
    private String activeRole;

    /**
     * Backward compatible constructor (4 args)
     */
    public WorkerAuthenticationDetails(Long workerId, UUID companyId, UUID branchId, String role) {
        this(workerId, companyId, branchId, role, null);
    }
}
