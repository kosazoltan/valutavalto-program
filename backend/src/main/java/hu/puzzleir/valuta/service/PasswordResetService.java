package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.PasswordResetToken;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.PasswordResetTokenRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.net.URLEncoder;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.nio.charset.StandardCharsets;
import java.security.SecureRandom;
import java.time.Duration;
import java.time.Instant;
import java.util.Base64;
import java.util.Optional;
import java.util.HexFormat;

/**
 * Elfelejtett-jelszo flow — persistent reset token storage.
 *
 * <p>The raw token only travels in email. The database stores a SHA-256 hash,
 * so a backend restart does not break an already issued reset link.</p>
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
    private final PasswordResetTokenRepository resetTokenRepository;
    private final PasswordEncoder passwordEncoder;
    private final EmailNotificationService emailNotificationService;

    /**
     * Frontend base URL a reset link generálásához. Defaultban a production
     * domain ({@link hu.puzzleir.valuta.config.ProductionUrls#BASE_URL}); az
     * application.properties-ben (vagy ENV-bol) felulirhato.
     */
    @Value("${app.frontend.base-url:https://excvaluta.com}")
    private String frontendBaseUrl;

    /**
     * Kerelem forgot-password flow-ra. Production-ban a nyers token csak
     * email-ben megy ki; az adatbazisba a token SHA-256 hash-e kerul.
     * Dev/test kornyezetben a hivo a tokent diagnosztikai celbol visszakaphatja.
     *
     * <p>Anti-enumeration: akkor is 200-at adunk vissza ha az email
     * nem letezik a DB-ben. Igy egy attacker nem tudja felderiteni
     * melyik email van regisztralva.</p>
     *
     * @return a generalt token (TESZT celu — production-ban csak logolni
     *         vagy email-ben kikuldeni, NE returnolni a API valaszban)
     */
    @Transactional(rollbackFor = Exception.class)
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

        Instant now = Instant.now();
        resetTokenRepository.save(PasswordResetToken.builder()
                .workerId(worker.getId())
                .tokenHash(hashToken(token))
                .issuedAt(now)
                .expiresAt(now.plus(TOKEN_TTL))
                .build());

        cleanupExpiredTokens();

        // CodeQL java/sensitive-log fix: NEM logoljuk az emailt (PII/GDPR) es a tokent
        // (security-sensitive) - csak worker id-t es egy nem-rekonstrualhato hashet a tokenrol.
        log.info("Forgot password token generalva: worker id={}, tokenHash={}",
                worker.getId(), Integer.toHexString(token.hashCode()));

        // Audit P1.8 (2026-05-03): production email kikuldes a Spring JavaMailSender-en
        // keresztul. Az EmailNotificationService aszinkron (`@Async`), igy NEM blokkolja
        // a forgot-password endpoint valaszat. Ha az SMTP_PASSWORD nincs configolva,
        // az EmailNotificationService.sendEmail logol egy hibat, de az endpoint sikeres
        // marad (anti-enumeration: a kliens semmilyen visszajelzest nem kap arrol hogy
        // a kuldes sikerult-e vagy sem).
        sendResetEmail(worker, token);

        return token;
    }

    /**
     * Reset link email-ben kikuldese a workernek. Aszinkron — nem blokkolja a hivot.
     *
     * <p>A link formatuma: {@code <frontendBaseUrl>/reset-password?token=<URL-encoded-token>}.</p>
     */
    private void sendResetEmail(Worker worker, String token) {
        String email = worker.getEmail();
        if (email == null || email.isBlank()) {
            log.warn("Forgot password: workernek nincs email cime, email kikuldes kihagyva: id={}",
                    worker.getId());
            return;
        }

        String encodedToken = URLEncoder.encode(token, StandardCharsets.UTF_8);
        String resetUrl = String.format("%s/reset-password?token=%s",
                frontendBaseUrl.replaceAll("/+$", ""),
                encodedToken);

        String subject = "Jelszo visszaallitas";
        String body = String.format(
                "Kedves %s!%n%n"
                        + "Valaki (remenyem szerint Te) jelszo-visszaallitast kert a "
                        + "Valutavalto fiokjahoz.%n%n"
                        + "Az alabbi linkre kattintva 15 percen belul beallithatsz uj jelszot:%n"
                        + "%s%n%n"
                        + "Ha nem Te kerted, hagyd figyelmen kivul ezt az emailt — a fiokod biztonsagban van.%n%n"
                        + "(Ez egy automatikus email, kerunk NE valaszolj ra.)",
                worker.getName() != null ? worker.getName() : "Felhasznalo",
                resetUrl);

        emailNotificationService.sendEmail(email, subject, body);
    }

    /**
     * Reset-password vegrehajtas token + uj jelszo alapjan.
     */
    @Transactional(rollbackFor = Exception.class)
    public void resetPassword(String token, String newPassword) {
        if (token == null || token.isBlank()) {
            throw new ValidationException("Ervenytelen vagy lejart token");
        }
        PasswordResetToken resetToken = resetTokenRepository.findUnusedByTokenHashForUpdate(hashToken(token))
                .orElseThrow(() -> new ValidationException("Ervenytelen vagy lejart token"));
        Instant now = Instant.now();
        if (now.isAfter(resetToken.getExpiresAt())) {
            throw new ValidationException("A token lejart (15 perc). Igenyelj ujat.");
        }
        resetToken.setUsedAt(now);
        resetTokenRepository.save(resetToken);

        Worker worker = workerRepository.findById(resetToken.getWorkerId())
                .orElseThrow(() -> new ValidationException("Dolgozo nem talalhato"));
        worker.setPasswordHash(passwordEncoder.encode(newPassword));
        worker.setPasswordChangedAt(java.time.LocalDateTime.now());
        workerRepository.save(worker);

        log.info("Password reset sikeres: worker id={}", worker.getId());
    }

    private void cleanupExpiredTokens() {
        resetTokenRepository.deleteExpiredOrUsed(Instant.now());
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
