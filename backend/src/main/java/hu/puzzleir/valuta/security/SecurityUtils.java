package hu.puzzleir.valuta.security;

import hu.puzzleir.valuta.exception.ValidationException;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;

import java.util.UUID;

/**
 * Security utility - current user context helper.
 */
public class SecurityUtils {
    
    /**
     * Null guard helper — dob ValidationException ha nincs bejelentkezett felhasználó.
     */
    private static <T> T requireAuth(T value) {
        if (value == null) {
            throw new ValidationException("Nincs bejelentkezett felhasználó!");
        }
        return value;
    }
    
    /**
     * Aktuális bejelentkezett worker ID
     */
    public static Long getCurrentWorkerId() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth != null && auth.getDetails() instanceof WorkerAuthenticationDetails) {
            return requireAuth(((WorkerAuthenticationDetails) auth.getDetails()).getWorkerId());
        }
        throw new ValidationException("Nincs bejelentkezett felhasználó!");
    }
    
    /**
     * Aktuális company ID (MULTI-TENANT!)
     */
    public static UUID getCurrentCompanyId() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth != null && auth.getDetails() instanceof WorkerAuthenticationDetails) {
            return requireAuth(((WorkerAuthenticationDetails) auth.getDetails()).getCompanyId());
        }
        throw new ValidationException("Nincs bejelentkezett felhasználó!");
    }
    
    /**
     * Aktuális branch ID
     */
    public static UUID getCurrentBranchId() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth != null && auth.getDetails() instanceof WorkerAuthenticationDetails) {
            return requireAuth(((WorkerAuthenticationDetails) auth.getDetails()).getBranchId());
        }
        throw new ValidationException("Nincs bejelentkezett felhasználó!");
    }
    
    /**
     * Aktuális worker kód
     */
    public static String getCurrentWorkerCode() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth != null) {
            return requireAuth((String) auth.getPrincipal());
        }
        throw new ValidationException("Nincs bejelentkezett felhasználó!");
    }
    
    /**
     * Aktuális role
     */
    public static String getCurrentRole() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth != null && auth.getDetails() instanceof WorkerAuthenticationDetails) {
            return requireAuth(((WorkerAuthenticationDetails) auth.getDetails()).getRole());
        }
        throw new ValidationException("Nincs bejelentkezett felhasználó!");
    }
    
    /**
     * Van-e legalább SUPERVISOR jog?
     */
    public static boolean isSupervisorOrAbove() {
        String role = getCurrentRole();
        return role != null && (
            role.equals("SUPERVISOR") || 
            role.equals("MANAGER") || 
            role.equals("ADMIN")
        );
    }
    
    /**
     * ADMIN jog ellenőrzés
     */
    public static boolean isAdmin() {
        return "ADMIN".equals(getCurrentRole());
    }

    /**
     * Van-e legalább MANAGER jog?
     */
    public static boolean isManagerOrAbove() {
        String role = getCurrentRole();
        return role != null && (
            role.equals("MANAGER") ||
            role.equals("ADMIN")
        );
    }

    /**
     * Aktuális operatív szerepkör (V57 — pl. CASHIER, VAULT_KEEPER, DIRECTOR)
     * 
     * @return operatív role kód, vagy null ha nincs beállítva
     */
    public static String getActiveOperationalRole() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth != null && auth.getDetails() instanceof WorkerAuthenticationDetails) {
            return ((WorkerAuthenticationDetails) auth.getDetails()).getActiveRole();
        }
        return null;
    }

    /**
     * v2.5.1-D B6: branch ID null-fallback (NEM dob ValidationException).
     * Territoriális szűrés helper-ekhez használt, ahol pre-auth context-ben
     * (pl. scheduler, async task) is lefuthat a kód.
     */
    public static UUID getCurrentBranchIdOrNull() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth != null && auth.getDetails() instanceof WorkerAuthenticationDetails) {
            return ((WorkerAuthenticationDetails) auth.getDetails()).getBranchId();
        }
        return null;
    }

    /**
     * Audit P0.7 (2026-05-03): company ID null-fallback (NEM dob ValidationException).
     *
     * <p>Olyan szolgaltatashoz hasznald, ahol a SecurityContext nelkuli (startup,
     * async, scheduler) hivasok is legitimak. Pl. `CashBalanceService.initializeBranchBalances`
     * Spring `ApplicationReadyEvent` alatt SecurityContext nelkul fut, viszont user-
     * context-ben futtatva multi-tenant cross-company tiltas kell.</p>
     *
     * <p>Anti-pattern-t valt fel: korabban a hivok `try { getCurrentCompanyId() }
     * catch (IllegalStateException) {...}` mintat hasznaltak, de a `getCurrentCompanyId()`
     * `ValidationException`-t dob, igy a catch SOHA nem fogott.</p>
     */
    public static UUID getCurrentCompanyIdOrNull() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth != null && auth.getDetails() instanceof WorkerAuthenticationDetails) {
            return ((WorkerAuthenticationDetails) auth.getDetails()).getCompanyId();
        }
        return null;
    }
}
