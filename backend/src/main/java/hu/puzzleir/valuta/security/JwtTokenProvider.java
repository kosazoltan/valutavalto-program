package hu.puzzleir.valuta.security;

import hu.puzzleir.valuta.entity.Worker;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
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
public class JwtTokenProvider {
    
    @Value("${jwt.secret:valuta-secret-key-change-in-production-must-be-at-least-256-bits-long}")
    private String secretKey;
    
    @Value("${jwt.expiration:86400000}") // 24 óra
    private long expiration;
    
    /**
     * JWT generálás Worker-hez (MULTI-TENANT!)
     */
    public String generateToken(Worker worker) {
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
                .setClaims(claims)
                .setSubject(subject)
                .setIssuedAt(now)
                .setExpiration(expiryDate)
                .signWith(key, SignatureAlgorithm.HS256)
                .compact();
    }
    
    /**
     * Token validálás
     */
    public boolean validateToken(String token) {
        try {
            SecretKey key = Keys.hmacShaKeyFor(secretKey.getBytes());
            Jwts.parserBuilder()
                .setSigningKey(key)
                .build()
                .parseClaimsJws(token);
            return true;
        } catch (Exception e) {
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
        String companyIdStr = getClaims(token).get("companyId", String.class);
        return companyIdStr != null ? UUID.fromString(companyIdStr) : null;
    }
    
    /**
     * Branch ID kinyerése
     */
    public UUID getBranchIdFromToken(String token) {
        String branchIdStr = getClaims(token).get("branchId", String.class);
        return branchIdStr != null ? UUID.fromString(branchIdStr) : null;
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
        return Jwts.parserBuilder()
                .setSigningKey(key)
                .build()
                .parseClaimsJws(token)
                .getBody();
    }
    
    /**
     * Token lejárati idő ellenőrzés
     */
    public boolean isTokenExpired(String token) {
        Date expiration = getClaims(token).getExpiration();
        return expiration.before(new Date());
    }
}
