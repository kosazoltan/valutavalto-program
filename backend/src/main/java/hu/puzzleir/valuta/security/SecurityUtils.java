package hu.puzzleir.valuta.security;

import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;

import java.util.UUID;

/**
 * Security utility - current user context helper.
 */
public class SecurityUtils {
    
    /**
     * Aktuális bejelentkezett worker ID
     */
    public static Long getCurrentWorkerId() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth != null && auth.getDetails() instanceof WorkerAuthenticationDetails) {
            return ((WorkerAuthenticationDetails) auth.getDetails()).getWorkerId();
        }
        return null;
    }
    
    /**
     * Aktuális company ID (MULTI-TENANT!)
     */
    public static UUID getCurrentCompanyId() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth != null && auth.getDetails() instanceof WorkerAuthenticationDetails) {
            return ((WorkerAuthenticationDetails) auth.getDetails()).getCompanyId();
        }
        return null;
    }
    
    /**
     * Aktuális branch ID
     */
    public static UUID getCurrentBranchId() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth != null && auth.getDetails() instanceof WorkerAuthenticationDetails) {
            return ((WorkerAuthenticationDetails) auth.getDetails()).getBranchId();
        }
        return null;
    }
    
    /**
     * Aktuális worker kód
     */
    public static String getCurrentWorkerCode() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth != null) {
            return (String) auth.getPrincipal();
        }
        return null;
    }
    
    /**
     * Aktuális role
     */
    public static String getCurrentRole() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth != null && auth.getDetails() instanceof WorkerAuthenticationDetails) {
            return ((WorkerAuthenticationDetails) auth.getDetails()).getRole();
        }
        return null;
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
}
