package hu.puzzleir.valuta.entity;

/**
 * Worker szerepkörök az autentikációhoz és jogosultságkezeléshez.
 * 
 * Legacy mapping:
 * - CASHIER: Normál pénztáros (_alapjog)
 * - SUPERVISOR: Főnök (_fonokrend)
 * - MANAGER: Vezető (további jogosultságok)
 * - ADMIN: Rendszergazda (teljes hozzáférés)
 */
public enum WorkerRole {
    CASHIER("Pénztáros"),
    SUPERVISOR("Főnök"),
    MANAGER("Vezető"),
    ADMIN("Rendszergazda");
    
    private final String displayName;
    
    WorkerRole(String displayName) {
        this.displayName = displayName;
    }
    
    public String getDisplayName() {
        return displayName;
    }
}
