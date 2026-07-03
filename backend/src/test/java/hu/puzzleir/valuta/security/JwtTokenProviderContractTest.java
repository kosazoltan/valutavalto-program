package hu.puzzleir.valuta.security;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.entity.WorkerRole;
import org.junit.jupiter.api.Test;
import org.springframework.core.env.Environment;
import org.springframework.test.util.ReflectionTestUtils;

import java.nio.charset.StandardCharsets;
import java.time.LocalDateTime;
import java.util.Base64;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class JwtTokenProviderContractTest {

    private static final String SECRET_32 = "0123456789abcdef0123456789abcdef";
    private static final String SECRET_64 = SECRET_32 + SECRET_32;

    @Test
    void generatedTokenRoundTripsAllPublicClaims() {
        UUID companyId = UUID.fromString("11111111-1111-1111-1111-111111111111");
        UUID branchId = UUID.fromString("22222222-2222-2222-2222-222222222222");
        Worker worker = worker(companyId, branchId);
        JwtTokenProvider provider = provider(SECRET_32, 60_000L);

        String token = provider.generateToken(worker, "CASHIER", List.of("VIDEO_EXPORT"));

        assertThat(provider.validateToken(token)).isTrue();
        assertThat(provider.getWorkerCodeFromToken(token)).isEqualTo("W001");
        assertThat(provider.getWorkerIdFromToken(token)).isEqualTo(42L);
        assertThat(provider.getCompanyIdFromToken(token)).isEqualTo(companyId);
        assertThat(provider.getBranchIdFromToken(token)).isEqualTo(branchId);
        assertThat(provider.getRoleFromToken(token)).isEqualTo("ADMIN");
        assertThat(provider.getActiveRoleFromToken(token)).isEqualTo("CASHIER");
        assertThat(provider.getPermissionsFromToken(token)).containsExactly("VIDEO_EXPORT");
        assertThatCode(() -> UUID.fromString(provider.getTokenIdFromToken(token))).doesNotThrowAnyException();
        assertThat(provider.getExpirationDateTimeFromToken(token)).isAfter(LocalDateTime.now().minusSeconds(1));
    }

    @Test
    void absentActiveRoleAndPermissionsReadAsNullAndEmptyList() {
        JwtTokenProvider provider = provider(SECRET_32, 60_000L);

        String token = provider.generateToken(worker(UUID.randomUUID(), UUID.randomUUID()), null, List.of());

        assertThat(provider.getActiveRoleFromToken(token)).isNull();
        assertThat(provider.getPermissionsFromToken(token)).isEmpty();
    }

    @Test
    void expiredTokenFailsClosed() {
        JwtTokenProvider provider = provider(SECRET_32, -1_000L);

        String token = provider.generateToken(worker(UUID.randomUUID(), UUID.randomUUID()));

        assertThat(provider.validateToken(token)).isFalse();
    }

    @Test
    void tamperedSignatureFailsClosed() {
        JwtTokenProvider provider = provider(SECRET_32, 60_000L);
        String token = provider.generateToken(worker(UUID.randomUUID(), UUID.randomUUID()));

        assertThat(provider.validateToken(tamperSignature(token))).isFalse();
    }

    @Test
    void malformedTokensFailClosed() {
        JwtTokenProvider provider = provider(SECRET_32, 60_000L);

        assertThat(provider.validateToken("not.a.jwt")).isFalse();
        assertThat(provider.validateToken("")).isFalse();
        assertThat(provider.validateToken("a.b")).isFalse();
        assertThat(provider.validateToken(null)).isFalse();
    }

    @Test
    void signingAlgorithmMatchesJjwtSecretLengthSelection() {
        assertThat(jwtHeader(provider(SECRET_32, 60_000L).generateToken(worker(UUID.randomUUID(), UUID.randomUUID()))))
                .contains("\"alg\":\"HS256\"");
        assertThat(jwtHeader(provider(SECRET_64, 60_000L).generateToken(worker(UUID.randomUUID(), UUID.randomUUID()))))
                .contains("\"alg\":\"HS512\"");
    }

    @Test
    void payloadWireFormatKeepsUuidClaimsAsStringsAndWorkerIdAsNumber() {
        UUID companyId = UUID.fromString("33333333-3333-3333-3333-333333333333");
        UUID branchId = UUID.fromString("44444444-4444-4444-4444-444444444444");
        JwtTokenProvider provider = provider(SECRET_32, 60_000L);

        String payload = jwtPayload(provider.generateToken(worker(companyId, branchId)));

        assertThat(payload).contains("\"companyId\":\"" + companyId + "\"");
        assertThat(payload).contains("\"branchId\":\"" + branchId + "\"");
        assertThat(payload).contains("\"workerId\":42");
    }

    private static JwtTokenProvider provider(String secret, long expiration) {
        Environment environment = mock(Environment.class);
        when(environment.getActiveProfiles()).thenReturn(new String[0]);
        JwtTokenProvider provider = new JwtTokenProvider(environment);
        ReflectionTestUtils.setField(provider, "secretKey", secret);
        ReflectionTestUtils.setField(provider, "expiration", expiration);
        provider.validateSecret();
        return provider;
    }

    private static Worker worker(UUID companyId, UUID branchId) {
        Company company = new Company();
        company.setId(companyId);
        company.setCode("EBC");
        company.setName("Exclusive Best Change");

        Branch branch = new Branch();
        branch.setId(branchId);
        branch.setCode("B001");
        branch.setCompany(company);
        branch.setName("Teszt fiók");

        Worker worker = new Worker();
        worker.setId(42L);
        worker.setCode("W001");
        worker.setName("Teszt Elek");
        worker.setRole(WorkerRole.ADMIN);
        worker.setCompany(company);
        worker.setBranch(branch);
        worker.setActive(true);
        return worker;
    }

    private static String jwtHeader(String token) {
        return decodePart(token, 0);
    }

    private static String jwtPayload(String token) {
        return decodePart(token, 1);
    }

    private static String decodePart(String token, int partIndex) {
        return new String(Base64.getUrlDecoder().decode(token.split("\\.")[partIndex]), StandardCharsets.UTF_8);
    }

    private static String tamperSignature(String token) {
        String[] parts = token.split("\\.");
        char replacement = parts[2].charAt(0) == 'a' ? 'b' : 'a';
        parts[2] = replacement + parts[2].substring(1);
        return String.join(".", parts);
    }
}
