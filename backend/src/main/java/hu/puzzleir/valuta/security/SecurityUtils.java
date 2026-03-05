package hu.puzzleir.valuta.security;

import com.puzzleir.backend.exception.ValidationException;
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
