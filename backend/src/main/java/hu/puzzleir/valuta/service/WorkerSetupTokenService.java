package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.WorkerSetupToken;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.WorkerSetupTokenRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.Duration;
import java.time.Instant;
import java.util.Base64;
import java.util.HexFormat;
import java.util.UUID;

/**
 * Worker first-time setup token kiállítása + ellenőrzése (F-001 fix).
 *
 * <p>A null-hash {@code first-time-worker-setup} ág publikus fiókátvétel ellen: az admin
 * egyszer használatos, lejáró tokent állít ki egy konkrét workerhez; a setup csak érvényes
 * (le nem járt, fel nem használt, ehhez a workerhez/céghez tartozó) tokennel megy át.</p>
 *
 * <p>A raw token CSAK a kiállításkor kerül vissza; az adatbázis SHA-256 hash-t tárol
 * ({@link hu.puzzleir.valuta.entity.PasswordResetToken} mintája).</p>
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class WorkerSetupTokenService {

    /** A setup-token érvényességi ablaka: 72 óra (admin kiállít → kolléga felhasználja). */
    public static final Duration TOKEN_TTL = Duration.ofHours(72);

    private static final SecureRandom SECURE_RANDOM = new SecureRandom();

    private final WorkerSetupTokenRepository tokenRepository;

    /** A kiállított token: a raw érték (csak egyszer) + a tényleges lejárat (Sourcery fix). */
    public record IssuedSetupToken(String rawToken, Instant expiresAt) {
    }

    /**
     * Új setup-token kiállítása egy workerhez. A visszaadott raw token CSAK itt érhető el.
     *
     * @param workerId      a céltárs worker
     * @param companyId     a worker cége (scope-ellenőrzéshez)
     * @param createdByWorkerId a kiállító admin worker id-ja (audit, lehet null)
     * @return a raw (URL-safe Base64) token + a tényleges lejárat
     */
    @Transactional
    public IssuedSetupToken issueToken(Long workerId, UUID companyId, Long createdByWorkerId) {
        if (workerId == null || companyId == null) {
            throw new ValidationException("Setup-token kiállításához worker és cég kötelező.");
        }
        byte[] randomBytes = new byte[32];
        SECURE_RANDOM.nextBytes(randomBytes);
        String rawToken = Base64.getUrlEncoder().withoutPadding().encodeToString(randomBytes);

        Instant now = Instant.now();
        WorkerSetupToken token = WorkerSetupToken.builder()
                .tokenHash(hashToken(rawToken))
                .workerId(workerId)
                .companyId(companyId)
                .createdBy(createdByWorkerId)
                .issuedAt(now)
                .expiresAt(now.plus(TOKEN_TTL))
                .build();
        tokenRepository.save(token);

        log.info("Worker setup-token kiállítva: workerId={}, companyId={}, createdBy={}, expiresAt={}",
                workerId, companyId, createdByWorkerId, token.getExpiresAt());
        return new IssuedSetupToken(rawToken, token.getExpiresAt());
    }

    /**
     * Setup-token ellenőrzése és FELHASZNÁLÁSA (egyszer használatos).
     *
     * <p>Sikeres ellenőrzéskor a tokent {@code used_at}-tal lezárja. Bármely hiba esetén
     * {@link ValidationException}-t dob (a hívó null-hash setup-ágát blokkolva).</p>
     *
     * @param rawToken  a kolléga által megadott token
     * @param workerId  az aktuális worker (a tokennek ehhez kell tartoznia)
     * @param companyId az aktuális cég (a tokennek ehhez kell tartoznia)
     */
    @Transactional
    public void validateAndConsume(String rawToken, Long workerId, UUID companyId) {
        if (rawToken == null || rawToken.isBlank()) {
            throw new ValidationException(
                    "Ehhez a beállításhoz egyszeri setup-token szükséges. Kérd az adminisztrátortól.");
        }
        WorkerSetupToken token = tokenRepository.findByTokenHashAndUsedAtIsNull(hashToken(rawToken.trim()))
                .orElseThrow(() -> new ValidationException(
                        "Érvénytelen vagy már felhasznált setup-token."));

        if (token.getExpiresAt().isBefore(Instant.now())) {
            throw new ValidationException("A setup-token lejárt. Kérj újat az adminisztrátortól.");
        }
        // Scope-ellenőrzés: a token PONTOSAN ehhez a workerhez és céghez tartozzon
        // (id-enumeráció / kereszt-worker felhasználás ellen).
        if (!token.getWorkerId().equals(workerId) || !token.getCompanyId().equals(companyId)) {
            log.warn("Setup-token scope-eltérés: token(worker={}, company={}) vs kérés(worker={}, company={})",
                    token.getWorkerId(), token.getCompanyId(), workerId, companyId);
            throw new ValidationException("A setup-token nem ehhez a dolgozóhoz tartozik.");
        }

        // ATOMI felhasználás (Copilot review fix): a feltételes UPDATE garantálja, hogy két
        // párhuzamos kérés közül csak EGY tudja felhasználni a tokent (a másik 0 sort kap).
        int updated = tokenRepository.markUsedIfUnused(token.getId(), Instant.now());
        if (updated != 1) {
            log.warn("Setup-token párhuzamos felhasználási kísérlet: tokenId={}, workerId={}", token.getId(), workerId);
            throw new ValidationException("Érvénytelen vagy már felhasznált setup-token.");
        }
        log.info("Worker setup-token felhasználva: tokenId={}, workerId={}", token.getId(), workerId);
    }

    private static String hashToken(String token) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            return HexFormat.of().formatHex(digest.digest(token.getBytes(StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException ex) {
            throw new IllegalStateException("SHA-256 digest unavailable", ex);
        }
    }
}
