package hu.puzzleir.valuta.security;

import com.nimbusds.jose.JOSEException;
import com.nimbusds.jose.JWSAlgorithm;
import com.nimbusds.jose.JWSHeader;
import com.nimbusds.jose.crypto.MACSigner;
import com.nimbusds.jose.crypto.MACVerifier;
import com.nimbusds.jwt.JWTClaimsSet;
import com.nimbusds.jwt.SignedJWT;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Worker;
import jakarta.annotation.PostConstruct;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.env.Environment;
import org.springframework.stereotype.Component;

import java.nio.charset.StandardCharsets;
import java.text.ParseException;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.Collections;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
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
    
    @Value("${jwt.secret}")
    private String secretKey;
    
    @Value("${jwt.expiration:86400000}") // 24 óra
    private long expiration;

    @PostConstruct
    public void validateSecret() {
        boolean isProduction = java.util.Arrays.asList(environment.getActiveProfiles()).contains("production");
        if (isProduction && (secretKey == null
                || secretKey.startsWith("CHANGE-ME")
                || secretKey.startsWith("valutavalto-dev-secret")
                || secretKey.startsWith("valuta-secret-key-change"))) {
            throw new IllegalStateException("FATAL: JWT_SECRET env var NINCS konfigurálva! Production-ban KÖTELEZŐ random 256-bit kulcsot használni.");
        }
        // Kulcs hossz ellenőrzés minden profilban
        if (secretKey != null && secretKey.getBytes(StandardCharsets.UTF_8).length < 32) {
            throw new IllegalStateException("FATAL: JWT_SECRET túl rövid! Minimum 32 byte (256 bit) szükséges. Jelenlegi: " + secretKey.getBytes(StandardCharsets.UTF_8).length + " byte.");
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
        return generateToken(worker, worker != null ? worker.getBranch() : null, activeRole, permissions);
    }

    public String generateToken(Worker worker, Branch sessionBranch, String activeRole, java.util.List<String> permissions) {
        return generateToken(worker, sessionBranch, activeRole, permissions, null);
    }

    /**
     * FK-076 (B1 + appMode-szures): JWT generalas a canonical szerepkor-listaval.
     *
     * @param grantedRoles az appMode-ra mar leszurt canonical szerepkorok
     *                     ({@link hu.puzzleir.valuta.util.AppModeRoleConstants#grantedRolesForAppMode});
     *                     null/ures eseten a claim kimarad (backward compat)
     */
    public String generateToken(Worker worker, Branch sessionBranch, String activeRole,
                                java.util.List<String> permissions, java.util.List<String> grantedRoles) {
        Branch effectiveBranch = sessionBranch != null ? sessionBranch : worker.getBranch();
        Map<String, Object> claims = new HashMap<>();
        claims.put("workerId", worker.getId());
        claims.put("workerCode", worker.getCode());
        claims.put("workerName", worker.getName());
        claims.put("role", worker.getRole().name());
        claims.put("branchId", effectiveBranch.getId());
        claims.put("branchCode", effectiveBranch.getCode());
        
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
        // FK-076: canonical szerepkorok (appMode-ra szurve) -> ROLE_* authority a filterben.
        if (grantedRoles != null && !grantedRoles.isEmpty()) {
            claims.put("grantedRoles", grantedRoles);
        }
        
        // Token ID (session tracking)
        String tokenId = UUID.randomUUID().toString();
        claims.put("tokenId", tokenId);
        
        return createToken(claims, worker.getCode());
    }
    
    /**
     * Token létrehozás nimbus-jose-jwt-vel.
     */
    private String createToken(Map<String, Object> claims, String subject) {
        Instant now = Instant.now();
        byte[] secretBytes = secretKey.getBytes(StandardCharsets.UTF_8);

        JWTClaimsSet.Builder builder = new JWTClaimsSet.Builder()
                .subject(subject)
                .issueTime(Date.from(now))
                .expirationTime(Date.from(now.plusMillis(expiration)));

        claims.forEach((key, value) ->
                builder.claim(key, value instanceof UUID uuid ? uuid.toString() : value));

        try {
            SignedJWT jwt = new SignedJWT(
                    new JWSHeader.Builder(resolveAlgorithm(secretBytes)).build(),
                    builder.build());
            jwt.sign(new MACSigner(secretBytes));
            return jwt.serialize();
        } catch (JOSEException e) {
            throw new JwtTokenException("JWT aláírás sikertelen", e);
        }
    }

    /** jjwt Keys.hmacShaKeyFor + signWith(key) algoritmus-választásának replikája (D3). */
    private JWSAlgorithm resolveAlgorithm(byte[] secretBytes) {
        if (secretBytes.length >= 64) {
            return JWSAlgorithm.HS512;
        }
        if (secretBytes.length >= 48) {
            return JWSAlgorithm.HS384;
        }
        return JWSAlgorithm.HS256;
    }
    
    /**
     * Token validálás
     */
    public boolean validateToken(String token) {
        try {
            getClaimsSet(token);
            return true;
        } catch (JwtTokenException e) {
            log.warn("JWT validálás sikertelen: {}", e.getMessage());
            return false;
        } catch (Exception e) {
            log.warn("JWT validálás váratlan hibával: {}", e.getMessage());
            return false;
        }
    }
    
    /**
     * Worker kód kinyerése token-ből
     */
    public String getWorkerCodeFromToken(String token) {
        return getClaimsSet(token).getSubject();
    }
    
    /**
     * Worker ID kinyerése
     */
    public Long getWorkerIdFromToken(String token) {
        JWTClaimsSet claimsSet = getClaimsSet(token);
        Object workerId = claimsSet.getClaim("workerId");
        if (workerId instanceof Number number) {
            return number.longValue();
        }
        try {
            return claimsSet.getLongClaim("workerId");
        } catch (ParseException e) {
            throw new JwtTokenException("JWT workerId claim hibás", e);
        }
    }
    
    /**
     * Company ID kinyerése (MULTI-TENANT!)
     */
    public UUID getCompanyIdFromToken(String token) {
        try {
            Object companyId = getClaimsSet(token).getClaim("companyId");
            String companyIdStr = companyId != null ? companyId.toString() : null;
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
            Object branchId = getClaimsSet(token).getClaim("branchId");
            String branchIdStr = branchId != null ? branchId.toString() : null;
            return branchIdStr != null ? UUID.fromString(branchIdStr) : null;
        } catch (IllegalArgumentException e) {
            return null;
        }
    }
    
    /**
     * Role kinyerése
     */
    public String getRoleFromToken(String token) {
        return getStringClaim(token, "role");
    }
    
    /**
     * Token ID kinyerése
     */
    public String getTokenIdFromToken(String token) {
        return getStringClaim(token, "tokenId");
    }
    
    /**
     * Claims parse + aláírás-ellenőrzés + explicit lejárat-check.
     */
    private JWTClaimsSet getClaimsSet(String token) {
        if (token == null || token.isBlank()) {
            throw new JwtTokenException("JWT token üres");
        }
        try {
            SignedJWT jwt = SignedJWT.parse(token);
            if (!jwt.verify(new MACVerifier(secretKey.getBytes(StandardCharsets.UTF_8)))) {
                throw new JwtTokenException("JWT aláírás érvénytelen");
            }
            JWTClaimsSet claimsSet = jwt.getJWTClaimsSet();
            Date expirationTime = claimsSet.getExpirationTime();
            if (expirationTime == null || !expirationTime.toInstant().isAfter(Instant.now())) {
                throw new JwtTokenException("JWT token lejárt");
            }
            return claimsSet;
        } catch (JwtTokenException e) {
            throw e;
        } catch (ParseException | JOSEException e) {
            throw new JwtTokenException("JWT token hibás formátumú: " + e.getMessage(), e);
        } catch (Exception e) {
            throw new JwtTokenException("JWT token feldolgozása sikertelen: " + e.getMessage(), e);
        }
    }

    private String getStringClaim(String token, String claimName) {
        try {
            return getClaimsSet(token).getStringClaim(claimName);
        } catch (ParseException e) {
            throw new JwtTokenException("JWT " + claimName + " claim hibás", e);
        }
    }
    
    /**
     * Token lejárati idő ellenőrzés.
     *
     * <p>F12 fix (2026-05-07): java.time.Instant alapú összehasonlítás.
     * A JWTClaimsSet továbbra is `Date`-et ad vissza, de azt azonnal
     * `Instant`-ra konvertáljuk az időaritmetikához.</p>
     */
    public boolean isTokenExpired(String token) {
        Instant expirationInstant = getClaimsSet(token).getExpirationTime().toInstant();
        return expirationInstant.isBefore(Instant.now());
    }

    public LocalDateTime getExpirationDateTimeFromToken(String token) {
        Instant expirationInstant = getClaimsSet(token).getExpirationTime().toInstant();
        return LocalDateTime.ofInstant(expirationInstant, ZoneId.systemDefault());
    }

    public LocalDateTime getConfiguredExpirationDateTimeFromNow() {
        return LocalDateTime.ofInstant(Instant.now().plusMillis(expiration), ZoneId.systemDefault());
    }

    /**
     * Operatív szerepkör kinyerése token-ből (V57)
     */
    public String getActiveRoleFromToken(String token) {
        return getStringClaim(token, "activeRole");
    }

    /**
     * Permission lista kinyerése token-ből (V57)
     */
    public java.util.List<String> getPermissionsFromToken(String token) {
        try {
            List<String> permissions = getClaimsSet(token).getStringListClaim("permissions");
            return permissions != null ? permissions : Collections.emptyList();
        } catch (ParseException e) {
            return Collections.emptyList();
        }
    }

    /**
     * FK-076: az appMode-ra szurt canonical szerepkor-lista a tokenbol.
     * Regi (claim nelkuli) tokeneknel ures lista — a filter ilyenkor a korabbi
     * {@code role} + {@code activeRole} authority-parra esik vissza.
     */
    public java.util.List<String> getGrantedRolesFromToken(String token) {
        try {
            List<String> grantedRoles = getClaimsSet(token).getStringListClaim("grantedRoles");
            return grantedRoles != null ? grantedRoles : Collections.emptyList();
        } catch (ParseException e) {
            return Collections.emptyList();
        }
    }
}

