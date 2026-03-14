package hu.puzzleir.valuta.security;

import hu.puzzleir.valuta.entity.Worker;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import jakarta.annotation.PostConstruct;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.env.Environment;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

/**
 * JWT Token Provider - generálás és validálás.
 * 
 * MULTI-TENANT: Token tartalmazza a companyId-t!
 */
@Component
@Slf4j
public class JwtTokenProvider {

    private final Environment environment;

    public JwtTokenProvider(Environment environment) {
        this.environment = environment;
    }
    
    @Value("${jwt.secret:valuta-secret-key-change-in-production-must-be-at-least-256-bits-long}")
    private String secretKey;
    
    @Value("${jwt.expiration:86400000}") // 24 óra
    private long expiration;

    @PostConstruct
    public void validateSecret() {
        boolean isProduction = java.util.Arrays.asList(environment.getActiveProfiles()).contains("production");
        if (isProduction && (secretKey == null || secretKey.startsWith("valuta-secret-key-change"))) {
            throw new IllegalStateException("FATAL: JWT_SECRET env var NINCS konfigurálva! Production-ban KÖTELEZŐ random 256-bit kulcsot használni.");
        }
        // Kulcs hossz ellenőrzés minden profilban
        if (secretKey != null && secretKey.getBytes().length < 32) {
            throw new IllegalStateException("FATAL: JWT_SECRET túl rövid! Minimum 32 byte (256 bit) szükséges. Jelenlegi: " + secretKey.getBytes().length + " byte.");
        }
    }
    
    /**
     * JWT generálás Worker-hez (MULTI-TENANT!)
     */
    public String generateToken(Worker worker) {
        return generateToken(worker, null, null);
    }

    /**
     * JWT generálás Worker-hez operatív szerepkörrel.
     * 
     * @param worker        Worker entity
     * @param activeRole    Operatív szerepkör kódja (pl. CASHIER, VAULT_KEEPER) — null ha nincs
     * @param permissions   Az aktív role-hoz tartozó permission kódok — null ha nincs
     */
    public String generateToken(Worker worker, String activeRole, java.util.List<String> permissions) {
        Map<String, Object> claims = new HashMap<>();
        claims.put("workerId", worker.getId());
        claims.put("workerCode", worker.getCode());
        claims.put("workerName", worker.getName());
        claims.put("role", worker.getRole().name());
        claims.put("branchId", worker.getBranch().getId());
        claims.put("branchCode", worker.getBranch().getCode());
        
        // 🔴 MULTI-TENANT: Company ID claim!
        claims.put("companyId", worker.getCompany().getId());
        claims.put("companyCode", worker.getCompany().getCode());
        
        // Operatív szerepkör (V57)
        if (activeRole != null) {
            claims.put("activeRole", activeRole);
        }
        if (permissions != null && !permissions.isEmpty()) {
            claims.put("permissions", permissions);
        }
        
        // Token ID (session tracking)
        String tokenId = UUID.randomUUID().toString();
        claims.put("tokenId", tokenId);
        
        return createToken(claims, worker.getCode());
    }
    
    /**
     * Token létrehozás
     */
    private String createToken(Map<String, Object> claims, String subject) {
        Date now = new Date();
        Date expiryDate = new Date(now.getTime() + expiration);
        
        SecretKey key = Keys.hmacShaKeyFor(secretKey.getBytes());
        
        return Jwts.builder()
                .claims(claims)
                .subject(subject)
                .issuedAt(now)
                .expiration(expiryDate)
                .signWith(key)
                .compact();
    }
    
    /**
     * Token validálás
     */
    public boolean validateToken(String token) {
        try {
            SecretKey key = Keys.hmacShaKeyFor(secretKey.getBytes());
            Jwts.parser()
                .verifyWith(key)
                .build()
                .parseSignedClaims(token);
            return true;
        } catch (io.jsonwebtoken.ExpiredJwtException e) {
            log.warn("JWT token lejárt: {}", e.getMessage());
            return false;
        } catch (io.jsonwebtoken.security.SignatureException e) {
            log.warn("JWT aláírás érvénytelen: {}", e.getMessage());
            return false;
        } catch (io.jsonwebtoken.MalformedJwtException e) {
            log.warn("JWT token hibás formátumú: {}", e.getMessage());
            return false;
        } catch (Exception e) {
            log.warn("JWT validálás sikertelen: {}", e.getMessage());
            return false;
        }
    }
    
    /**
     * Worker kód kinyerése token-ből
     */
    public String getWorkerCodeFromToken(String token) {
        return getClaims(token).getSubject();
    }
    
    /**
     * Worker ID kinyerése
     */
    public Long getWorkerIdFromToken(String token) {
        return getClaims(token).get("workerId", Long.class);
    }
    
    /**
     * Company ID kinyerése (MULTI-TENANT!)
     */
    public UUID getCompanyIdFromToken(String token) {
        try {
            String companyIdStr = getClaims(token).get("companyId", String.class);
            return companyIdStr != null ? UUID.fromString(companyIdStr) : null;
        } catch (IllegalArgumentException e) {
            return null;
        }
    }

    /**
     * Branch ID kinyerése
     */
    public UUID getBranchIdFromToken(String token) {
        try {
            String branchIdStr = getClaims(token).get("branchId", String.class);
            return branchIdStr != null ? UUID.fromString(branchIdStr) : null;
        } catch (IllegalArgumentException e) {
            return null;
        }
    }
    
    /**
     * Role kinyerése
     */
    public String getRoleFromToken(String token) {
        return getClaims(token).get("role", String.class);
    }
    
    /**
     * Token ID kinyerése
     */
    public String getTokenIdFromToken(String token) {
        return getClaims(token).get("tokenId", String.class);
    }
    
    /**
     * Claims parse
     */
    private Claims getClaims(String token) {
        SecretKey key = Keys.hmacShaKeyFor(secretKey.getBytes());
        return Jwts.parser()
                .verifyWith(key)
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }
    
    /**
     * Token lejárati idő ellenőrzés
     */
    public boolean isTokenExpired(String token) {
        Date expiration = getClaims(token).getExpiration();
        return expiration.before(new Date());
    }

    /**
     * Operatív szerepkör kinyerése token-ből (V57)
     */
    public String getActiveRoleFromToken(String token) {
        return getClaims(token).get("activeRole", String.class);
    }

    /**
     * Permission lista kinyerése token-ből (V57)
     */
    @SuppressWarnings("unchecked")
    public java.util.List<String> getPermissionsFromToken(String token) {
        Object perms = getClaims(token).get("permissions");
        if (perms instanceof java.util.List) {
            return (java.util.List<String>) perms;
        }
        return java.util.Collections.emptyList();
    }
}
