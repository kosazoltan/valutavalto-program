package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.RefreshToken;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.repository.RefreshTokenRepository;
import hu.puzzleir.valuta.util.ClientIpResolver;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.time.Duration;
import java.time.Instant;
import java.util.Base64;
import java.util.Optional;
import java.util.UUID;

/**
 * Refresh token kezeles (vezerlokonyv par.12.3).
 * Funkiok: issue, rotate, revoke, cleanup.
 * Token rotation: minden refresh-kor a regi lezarul, uj jon helyette.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class RefreshTokenService {

    private static final int BCRYPT_ROUNDS = 10;

    /** Audit P0.3 (2026-05-03): selector hossza byte-okban (URL-safe Base64 -> 24 char). */
    private static final int SELECTOR_BYTES = 18;
    /** Verifier hossza byte-okban (URL-safe Base64 -> ~43 char). */
    private static final int VERIFIER_BYTES = 32;
    private static final SecureRandom RNG = new SecureRandom();
    private static final String COOKIE_SEPARATOR = ".";

    @Value("${refresh-token.expiration-days:7}")
    private int expirationDays;

    private final RefreshTokenRepository repository;
    /** Audit P1.4 SSOT: trusted-proxy-aware kliens IP feloldas. */
    private final ClientIpResolver clientIpResolver;
    private final BCryptPasswordEncoder passwordEncoder = new BCryptPasswordEncoder(BCRYPT_ROUNDS);

    /**
     * Uj refresh token kibocsatas (Audit P0.3 selector pattern).
     *
     * <p>A `IssuedToken.rawCookie()` formatuma `selector.verifier`, BCrypt CSAK
     * a verifier-en (NEM a teljes string-en). DB-ben: `selector` indexed UNIQUE +
     * `token_hash` BCrypt(verifier).</p>
     */
    @Transactional
    public IssuedToken issue(Worker worker, HttpServletRequest request) {
        return issue(worker, request, null);
    }

    /**
     * Uj refresh token kibocsatasa egy veglegesitett aktiv role-lal.
     *
     * <p>Login/role-select/google-login vegleges session flow-kban ezt az overloadot
     * hasznald, hogy a silent refresh ne essen vissza masik role-ra. A role nelkuli
     * overload csak legacy vagy role-nelkuli sessionokhoz marad.</p>
     */
    @Transactional
    public IssuedToken issue(Worker worker, HttpServletRequest request, String activeRole) {
        return issue(worker, request, activeRole, null);
    }

    /**
     * FK-076: kibocsatas a kliens appMode-javal egyutt. A silent refresh ebbol szuri ujra a
     * JWT {@code grantedRoles} claim-et, hogy a rotacio ne kerulje meg az appMode-izolaciot.
     */
    @Transactional
    public IssuedToken issue(Worker worker, HttpServletRequest request, String activeRole, String appMode) {
        String selector = randomUrlSafe(SELECTOR_BYTES);
        String verifier = randomUrlSafe(VERIFIER_BYTES);
        String rawCookie = selector + COOKIE_SEPARATOR + verifier;
        String verifierHash = passwordEncoder.encode(verifier);
        Instant now = Instant.now();
        Instant expires = now.plus(Duration.ofDays(expirationDays));

        RefreshToken rt = RefreshToken.builder()
            .selector(selector)
            .tokenHash(verifierHash)
            .workerId(worker.getId())
            .companyId(worker.getCompany().getId())
            .activeRole(normalizeActiveRole(activeRole))
            .appMode(normalizeAppMode(appMode))
            .issuedAt(now)
            .expiresAt(expires)
            .userAgent(truncate(request.getHeader("User-Agent"), 512))
            .ipAddress(truncate(clientIpResolver.resolveClientIp(request), 45))
            .build();
        repository.save(rt);
        log.debug("Refresh token issued worker={} selector={} expires={}",
                worker.getId(), maskSelector(selector), expires);
        return new IssuedToken(rawCookie, verifierHash, expires);
    }

    /**
     * Audit P0.3 (2026-05-03): O(1) lookup selector alapjan, EGYETLEN BCrypt verify
     * a verifier-en. Ezzel a `findAll().stream().filter(BCrypt.matches)` O(N) hibat valtja le.
     *
     * @param rawCookie cookie-bol kapott `selector.verifier` string
     * @return aktiv (nem revoked, nem expired) token, ha a verifier matchel; egyebkent empty
     */
    @Transactional(readOnly = true)
    public Optional<RefreshToken> findActiveBySelectorAndVerifier(String rawCookie) {
        if (rawCookie == null) return Optional.empty();
        int dot = rawCookie.indexOf(COOKIE_SEPARATOR);
        if (dot <= 0 || dot == rawCookie.length() - 1) return Optional.empty();
        String selector = rawCookie.substring(0, dot);
        String verifier = rawCookie.substring(dot + 1);

        return repository.findBySelector(selector)
            .filter(RefreshToken::isActive)
            .filter(rt -> passwordEncoder.matches(verifier, rt.getTokenHash()));
    }

    /**
     * Legacy lookup workerId + raw cookie alapjan. Backward compat a logout-flow-hoz,
     * ahol a JWT-bol mar tudjuk a workerId-t.
     *
     * <p>Audit P0.3 (2026-05-03): a refresh-cookie endpoint helyett `findActiveBySelectorAndVerifier`
     * hasznalando, mert ott a workerId nem ismert es a `findAll()` osszes BCrypt-elese
     * O(N) DoS-kockazat volt.</p>
     */
    @Transactional(readOnly = true)
    public Optional<RefreshToken> findActiveForWorker(Long workerId, String rawCookie) {
        // Uj cookie format `selector.verifier` -> workerId scope-ban is selector lookup
        if (rawCookie != null && rawCookie.contains(COOKIE_SEPARATOR)) {
            return findActiveBySelectorAndVerifier(rawCookie)
                .filter(rt -> workerId.equals(rt.getWorkerId()));
        }
        // Legacy fallback: regi (V176 elotti) tokenek — workerId scope-on belul N×BCrypt.
        // Ez a workerId-vel scope-olt halmaz tipikusan kicsi (1-3 token), nem skala-issue.
        return repository.findByWorkerIdAndRevokedAtIsNull(workerId).stream()
            .filter(RefreshToken::isActive)
            .filter(rt -> passwordEncoder.matches(rawCookie, rt.getTokenHash()))
            .findFirst();
    }

    /** Token rotation: regi revoke + uj issue. */
    @Transactional
    public IssuedToken rotate(RefreshToken oldToken, Worker worker, HttpServletRequest request) {
        return rotate(oldToken, worker, request, oldToken.getActiveRole());
    }

    /**
     * Token rotation explicit aktiv role-lal. Refresh-cookie flow-ban ezt hasznald,
     * miutan a controller ujraellenorizte, hogy a tarolt role meg a workerhez tartozik.
     */
    @Transactional
    public IssuedToken rotate(RefreshToken oldToken, Worker worker, HttpServletRequest request, String activeRole) {
        // FK-076: a rotacio megorzi a kibocsato appMode-ot, kulonben a kovetkezo token
        // szuretlen grantedRoles listat kapna es kilyukasztana az appMode-izolaciot.
        IssuedToken newIssued = issue(worker, request, activeRole, oldToken.getAppMode());
        oldToken.setRevokedAt(Instant.now());
        oldToken.setReplacedBy(newIssued.hash());
        repository.save(oldToken);
        log.debug("Refresh token rotated worker={} oldId={}", worker.getId(), oldToken.getId());
        return newIssued;
    }

    @Transactional
    public void revoke(RefreshToken token) {
        token.setRevokedAt(Instant.now());
        repository.save(token);
    }

    @Transactional
    public void revokeAllForWorker(Long workerId) {
        int n = repository.revokeAllForWorker(workerId, Instant.now());
        log.info("Revoked {} refresh tokens worker={}", n, workerId);
    }

    /** Napi cleanup 4:00-kor. */
    @Scheduled(cron = "0 0 4 * * *", zone = "Europe/Budapest")
    @Transactional
    public void cleanupExpired() {
        int deleted = repository.deleteExpired(Instant.now().minus(Duration.ofDays(30)));
        if (deleted > 0) log.info("Cleaned up {} expired refresh tokens", deleted);
    }

    /**
     * Audit P1.4: a `clientIp` private metodus eltavolitva, helyette a kozos
     * {@link ClientIpResolver} util-ot hasznaljuk. Korabban itt naivan vakon biztunk
     * a kliens X-Forwarded-For header-eben — security gap (audit log spoofing).
     */

    private static String truncate(String s, int max) {
        if (s == null) return null;
        return s.length() > max ? s.substring(0, max) : s;
    }

    public static String normalizeActiveRole(String activeRole) {
        if (activeRole == null || activeRole.isBlank()) {
            return null;
        }
        return activeRole.trim();
    }

    /** FK-076: appMode normalizalas (trim + lowercase); blank -> null (nincs szures). */
    public static String normalizeAppMode(String appMode) {
        if (appMode == null || appMode.isBlank()) {
            return null;
        }
        return appMode.trim().toLowerCase(java.util.Locale.ROOT);
    }

    /** Audit P0.3: URL-safe Base64 random a SecureRandom-bol (no padding). */
    private static String randomUrlSafe(int byteLen) {
        byte[] buf = new byte[byteLen];
        RNG.nextBytes(buf);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(buf);
    }

    /** Defenziv: log-ban ne menjen ki teljes selector. */
    private static String maskSelector(String selector) {
        if (selector == null || selector.length() < 8) return "***";
        return selector.substring(0, 4) + "..." + selector.substring(selector.length() - 4);
    }

    /**
     * Refresh token kibocsatasanak eredmenye.
     *
     * @param rawUuid a HttpOnly cookie-ba kerulo string (Audit P0.3 ota: `selector.verifier`,
     *                korabban: nyers UUID — a record nev nem valtozott a backward compat-hoz).
     * @param hash    a verifier BCrypt-hashe (DB-ben tarolt `token_hash`).
     */
    public record IssuedToken(String rawUuid, String hash, Instant expiresAt) {}
}
