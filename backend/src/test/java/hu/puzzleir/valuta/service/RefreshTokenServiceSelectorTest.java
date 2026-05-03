package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.RefreshToken;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.repository.RefreshTokenRepository;
import jakarta.servlet.http.HttpServletRequest;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.mockito.Mockito;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.test.util.ReflectionTestUtils;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Audit P0.3 (2026-05-03) regressziovedelem.
 *
 * <p>Bizonyitja, hogy a `RefreshTokenService`:</p>
 * <ul>
 *   <li>(1) `issue()` selector-os tokenformat (`selector.verifier`), DB-ben selector + BCrypt(verifier);</li>
 *   <li>(2) `findActiveBySelectorAndVerifier()` O(1) DB lookup + 1 BCrypt verify;</li>
 *   <li>(3) `findActiveBySelectorAndVerifier()` rossz verifier-rel empty;</li>
 *   <li>(4) `findActiveBySelectorAndVerifier()` revoked token-nel empty;</li>
 *   <li>(5) hianyzo separator (legacy cookie) -> empty (NEM esik vissza N-BCrypt-re);</li>
 *   <li>(6) `findActiveForWorker` legacy fallback workerId-vel scope-olva mukodik.</li>
 * </ul>
 */
class RefreshTokenServiceSelectorTest {

    private RefreshTokenRepository repository;
    private RefreshTokenService service;
    private final BCryptPasswordEncoder encoder = new BCryptPasswordEncoder(10);

    @BeforeEach
    void setUp() {
        repository = Mockito.mock(RefreshTokenRepository.class);
        service = new RefreshTokenService(repository);
        ReflectionTestUtils.setField(service, "expirationDays", 7);
    }

    private Worker buildWorker(Long workerId) {
        Company company = Company.builder().id(UUID.randomUUID()).build();
        Branch branch = Branch.builder().id(UUID.randomUUID()).company(company).build();
        Worker worker = Worker.builder()
                .id(workerId)
                .code("P001")
                .company(company)
                .branch(branch)
                .build();
        return worker;
    }

    @Test
    @DisplayName("(1) issue() ket-reszes cookie-t (selector.verifier) ad ki, DB-ben selector + BCrypt(verifier)")
    void issue_producesSelectorVerifierCookie() {
        Worker worker = buildWorker(42L);
        HttpServletRequest req = new MockHttpServletRequest();
        when(repository.save(any(RefreshToken.class))).thenAnswer(inv -> inv.getArgument(0));

        RefreshTokenService.IssuedToken issued = service.issue(worker, req);

        assertThat(issued.rawUuid()).contains(".").as("cookie format `selector.verifier`");
        String[] parts = issued.rawUuid().split("\\.");
        assertThat(parts).hasSize(2);
        assertThat(parts[0]).hasSizeGreaterThanOrEqualTo(20).as("selector ~24 char URL-safe Base64");
        assertThat(parts[1]).hasSizeGreaterThanOrEqualTo(40).as("verifier ~43 char URL-safe Base64");

        ArgumentCaptor<RefreshToken> captor = ArgumentCaptor.forClass(RefreshToken.class);
        verify(repository).save(captor.capture());
        RefreshToken saved = captor.getValue();
        assertThat(saved.getSelector()).isEqualTo(parts[0]);
        // tokenHash a VERIFIER BCrypt-hashe (NEM a selector + verifier-e)
        assertThat(encoder.matches(parts[1], saved.getTokenHash())).isTrue();
        assertThat(encoder.matches(issued.rawUuid(), saved.getTokenHash()))
                .as("a cookie egesz string-re NEM matchel — verifier-only hash")
                .isFalse();
    }

    @Test
    @DisplayName("(2) findActiveBySelectorAndVerifier O(1) selector lookup + 1 BCrypt verify")
    void findActiveBySelectorAndVerifier_succeedsWithCorrectVerifier() {
        String selector = "test-selector-12345678";
        String verifier = "test-verifier-abcdefghijklmnopqrstuv";
        String cookie = selector + "." + verifier;
        RefreshToken active = RefreshToken.builder()
                .selector(selector)
                .tokenHash(encoder.encode(verifier))
                .workerId(42L)
                .companyId(UUID.randomUUID())
                .issuedAt(Instant.now().minusSeconds(60))
                .expiresAt(Instant.now().plusSeconds(86400))
                .build();
        when(repository.findBySelector(selector)).thenReturn(Optional.of(active));

        Optional<RefreshToken> result = service.findActiveBySelectorAndVerifier(cookie);

        assertThat(result).isPresent();
        assertThat(result.get().getWorkerId()).isEqualTo(42L);
        verify(repository, times(1)).findBySelector(selector);
        // KRITIKUS: NEM hivta meg a `findAll()` vagy `findByWorkerIdAndRevokedAtIsNull()` metodusokat
        verify(repository, never()).findAll();
        verify(repository, never()).findByWorkerIdAndRevokedAtIsNull(any());
    }

    @Test
    @DisplayName("(3) findActiveBySelectorAndVerifier — rossz verifier => empty")
    void findActiveBySelectorAndVerifier_wrongVerifier_returnsEmpty() {
        String selector = "test-selector-12345678";
        String correctVerifier = "correct-verifier-xyz";
        String cookie = selector + "." + "wrong-verifier-zzz";
        RefreshToken active = RefreshToken.builder()
                .selector(selector)
                .tokenHash(encoder.encode(correctVerifier))
                .workerId(42L)
                .issuedAt(Instant.now()).expiresAt(Instant.now().plusSeconds(3600))
                .build();
        when(repository.findBySelector(selector)).thenReturn(Optional.of(active));

        assertThat(service.findActiveBySelectorAndVerifier(cookie)).isEmpty();
    }

    @Test
    @DisplayName("(4) findActiveBySelectorAndVerifier — revoked token => empty")
    void findActiveBySelectorAndVerifier_revokedToken_returnsEmpty() {
        String selector = "test-selector-12345678";
        String verifier = "verifier-abc";
        RefreshToken revoked = RefreshToken.builder()
                .selector(selector)
                .tokenHash(encoder.encode(verifier))
                .workerId(42L)
                .issuedAt(Instant.now().minusSeconds(120))
                .expiresAt(Instant.now().plusSeconds(3600))
                .revokedAt(Instant.now().minusSeconds(30))
                .build();
        when(repository.findBySelector(selector)).thenReturn(Optional.of(revoked));

        assertThat(service.findActiveBySelectorAndVerifier(selector + "." + verifier)).isEmpty();
    }

    @Test
    @DisplayName("(5) hianyzo separator (legacy raw-UUID cookie) -> empty + NEM hivja a repository-t")
    void findActiveBySelectorAndVerifier_legacyCookie_returnsEmptyAndDoesNotCallRepo() {
        // Pre-V176 nyers UUID cookie format — pont, mert nincs benne.
        String legacyCookie = UUID.randomUUID().toString();

        Optional<RefreshToken> result = service.findActiveBySelectorAndVerifier(legacyCookie);

        assertThat(result).isEmpty();
        verify(repository, never()).findBySelector(any());
        verify(repository, never()).findAll();
    }

    @Test
    @DisplayName("(6) findActiveForWorker — uj selector cookie esete: workerId scope-olas")
    void findActiveForWorker_newCookie_scopedByWorkerId() {
        String selector = "test-selector-12345678";
        String verifier = "verifier-abc";
        String cookie = selector + "." + verifier;
        RefreshToken active = RefreshToken.builder()
                .selector(selector)
                .tokenHash(encoder.encode(verifier))
                .workerId(42L)
                .issuedAt(Instant.now()).expiresAt(Instant.now().plusSeconds(3600))
                .build();
        when(repository.findBySelector(selector)).thenReturn(Optional.of(active));

        // Helyes workerId
        assertThat(service.findActiveForWorker(42L, cookie)).isPresent();
        // Mas workerId — cross-tenant tiltas
        assertThat(service.findActiveForWorker(99L, cookie)).isEmpty();
    }

    @Test
    @DisplayName("(7) findActiveForWorker — legacy cookie esete: workerId-scope-os N×BCrypt fallback")
    void findActiveForWorker_legacyCookie_workerScopedFallback() {
        Long workerId = 42L;
        String legacyRawCookie = "legacy-no-dot-uuid";  // NEM tartalmaz dot-ot
        RefreshToken legacy = RefreshToken.builder()
                .selector(null)  // pre-V176 token
                .tokenHash(encoder.encode(legacyRawCookie))
                .workerId(workerId)
                .issuedAt(Instant.now()).expiresAt(Instant.now().plusSeconds(3600))
                .build();
        when(repository.findByWorkerIdAndRevokedAtIsNull(workerId))
                .thenReturn(List.of(legacy));

        Optional<RefreshToken> result = service.findActiveForWorker(workerId, legacyRawCookie);

        assertThat(result).isPresent();
        verify(repository, times(1)).findByWorkerIdAndRevokedAtIsNull(workerId);
        // KRITIKUS: NEM hivja a `findAll()`-t — workerId scope = max ~3 token, nem skala-issue.
        verify(repository, never()).findAll();
    }
}
