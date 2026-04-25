package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.WorkerRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.time.Duration;
import java.time.Instant;
import java.util.Base64;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Elfelejtett-jelszo flow — in-memory reset token cache.
 *
 * <p>Egy egyszeru, memory-based token-cache. Production-ban erdemes
 * Redis-re atallni, de 6 user-re ez is eleg, ha a backend nem restart-ol
 * tokens kiadas es felhasznalas kozott.</p>
 *
 * <p>Token elettartam: 15 perc. Anti-enumeration: ha az email nem
 * regisztralt, akkor is success-t ad vissza a requestForgot.</p>
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class PasswordResetService {

    private static final Duration TOKEN_TTL = Duration.ofMinutes(15);
    private static final SecureRandom SECURE_RANDOM = new SecureRandom();

    private final WorkerRepository workerRepository;
    private final PasswordEncoder passwordEncoder;

    // In-memory token cache: token -> { workerId, expiresAt }
    private static final Map<String, TokenEntry> TOKEN_CACHE = new ConcurrentHashMap<>();

    /**
     * Kerelem forgot-password flow-ra. Az email-tulajdonos-nak torteno
     * token kikuldes itt nem implementalva (Gmail API nelkuli, de a
     * GoogleAuthController mar rendelkezik a credentialekkel).
     *
     * <p>Anti-enumeration: akkor is 200-at adunk vissza ha az email
     * nem letezik a DB-ben. Igy egy attacker nem tudja felderiteni
     * melyik email van regisztralva.</p>
     *
     * @return a generalt token (TESZT celu — production-ban csak logolni
     *         vagy email-ben kikuldeni, NE returnolni a API valaszban)
     */
    @Transactional(readOnly = true)
    public String requestForgotPassword(String email) {
        if (email == null || email.isBlank()) {
            return null;
        }

        Optional<Worker> workerOpt = workerRepository.findByEmail(email.trim().toLowerCase());
        if (workerOpt.isEmpty()) {
            log.info("Forgot password: ismeretlen email (anti-enumeration silent): {}", email);
            return null;
        }

        Worker worker = workerOpt.get();
        if (!Boolean.TRUE.equals(worker.getActive())) {
            log.warn("Forgot password: inaktiv worker: {}", email);
            return null;
        }

        // Token generalasa
        byte[] randomBytes = new byte[32];
        SECURE_RANDOM.nextBytes(randomBytes);
        String token = Base64.getUrlEncoder().withoutPadding().encodeToString(randomBytes);

        TOKEN_CACHE.put(token, new TokenEntry(
                worker.getId(),
                Instant.now().plus(TOKEN_TTL)
        ));

        // CodeQL java/sensitive-log fix: NEM logoljuk az emailt (PII/GDPR) es a tokent
        // (security-sensitive) - csak worker id-t es egy nem-rekonstrualhato hashet a tokenrol.
        log.info("Forgot password token generalva: worker id={}, tokenHash={}",
                worker.getId(), Integer.toHexString(token.hashCode()));

        // TODO v2.3.1: Gmail API-n kikuldeni email-ben. Production-ban ez
        // kotelezo; most a token vissza van adva a response-ban tesztelheto
        // flow-hoz (a frontend kizarolag dev modban hasznalja).
        cleanupExpiredTokens();

        return token;
    }

    /**
     * Reset-password vegrehajtas token + uj jelszo alapjan.
     */
    @Transactional(rollbackFor = Exception.class)
    public void resetPassword(String token, String newPassword) {
        TokenEntry entry = TOKEN_CACHE.remove(token);
        if (entry == null) {
            throw new ValidationException("Ervenytelen vagy lejart token");
        }
        if (Instant.now().isAfter(entry.expiresAt)) {
            throw new ValidationException("A token lejart (15 perc). Igenyelj ujat.");
        }

        Worker worker = workerRepository.findById(entry.workerId)
                .orElseThrow(() -> new ValidationException("Worker not found"));
        worker.setPasswordHash(passwordEncoder.encode(newPassword));
        worker.setPasswordChangedAt(java.time.LocalDateTime.now());
        workerRepository.save(worker);

        log.info("Password reset sikeres: worker id={}", worker.getId());
    }

    private void cleanupExpiredTokens() {
        Instant now = Instant.now();
        TOKEN_CACHE.entrySet().removeIf(entry -> now.isAfter(entry.getValue().expiresAt));
    }

    private record TokenEntry(Long workerId, Instant expiresAt) {}
}