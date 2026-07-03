package hu.puzzleir.valuta.security;

import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.junit.jupiter.api.Test;
import org.springframework.core.env.Environment;
import org.springframework.test.util.ReflectionTestUtils;

import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.Date;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class JwtLegacyTokenCompatTest {

    private static final String SECRET_32 = "0123456789abcdef0123456789abcdef";
    private static final String SECRET_64 = SECRET_32 + SECRET_32;

    @Test
    void validatesAndReadsLegacyJjwtHs256Token() {
        JwtTokenProvider provider = provider(SECRET_32);
        UUID companyId = UUID.fromString("55555555-5555-5555-5555-555555555555");
        UUID branchId = UUID.fromString("66666666-6666-6666-6666-666666666666");

        String legacy = legacyToken(SECRET_32, companyId, branchId);

        assertThat(provider.validateToken(legacy)).isTrue();
        assertThat(provider.getWorkerCodeFromToken(legacy)).isEqualTo("W001");
        assertThat(provider.getWorkerIdFromToken(legacy)).isEqualTo(42L);
        assertThat(provider.getCompanyIdFromToken(legacy)).isEqualTo(companyId);
        assertThat(provider.getBranchIdFromToken(legacy)).isEqualTo(branchId);
        assertThat(provider.getRoleFromToken(legacy)).isEqualTo("ADMIN");
        assertThat(provider.getActiveRoleFromToken(legacy)).isEqualTo("CASHIER");
        assertThat(provider.getPermissionsFromToken(legacy)).containsExactly("VIDEO_EXPORT");
        assertThat(provider.getTokenIdFromToken(legacy)).isEqualTo("legacy-token-id");
    }

    @Test
    void validatesLegacyJjwtHs512TokenFromLongSecret() {
        JwtTokenProvider provider = provider(SECRET_64);
        UUID companyId = UUID.fromString("77777777-7777-7777-7777-777777777777");
        UUID branchId = UUID.fromString("88888888-8888-8888-8888-888888888888");

        String legacy = legacyToken(SECRET_64, companyId, branchId);

        assertThat(jwtHeader(legacy)).contains("\"alg\":\"HS512\"");
        assertThat(provider.validateToken(legacy)).isTrue();
        assertThat(provider.getCompanyIdFromToken(legacy)).isEqualTo(companyId);
        assertThat(provider.getBranchIdFromToken(legacy)).isEqualTo(branchId);
    }

    private static JwtTokenProvider provider(String secret) {
        Environment environment = mock(Environment.class);
        when(environment.getActiveProfiles()).thenReturn(new String[0]);
        JwtTokenProvider provider = new JwtTokenProvider(environment);
        ReflectionTestUtils.setField(provider, "secretKey", secret);
        ReflectionTestUtils.setField(provider, "expiration", 60_000L);
        provider.validateSecret();
        return provider;
    }

    private static String legacyToken(String secret, UUID companyId, UUID branchId) {
        Map<String, Object> claims = new LinkedHashMap<>();
        claims.put("workerId", 42L);
        claims.put("workerCode", "W001");
        claims.put("workerName", "Teszt Elek");
        claims.put("role", "ADMIN");
        claims.put("branchId", branchId);
        claims.put("branchCode", "B001");
        claims.put("companyId", companyId);
        claims.put("companyCode", "EBC");
        claims.put("activeRole", "CASHIER");
        claims.put("permissions", List.of("VIDEO_EXPORT"));
        claims.put("tokenId", "legacy-token-id");

        return Jwts.builder()
                .claims(claims)
                .subject("W001")
                .issuedAt(new Date())
                .expiration(new Date(System.currentTimeMillis() + 60_000L))
                .signWith(Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8)))
                .compact();
    }

    private static String jwtHeader(String token) {
        return new String(Base64.getUrlDecoder().decode(token.split("\\.")[0]), StandardCharsets.UTF_8);
    }
}
