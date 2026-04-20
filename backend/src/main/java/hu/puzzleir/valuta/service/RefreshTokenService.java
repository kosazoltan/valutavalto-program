package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.RefreshToken;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.repository.RefreshTokenRepository;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.Instant;
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

    @Value("${refresh-token.expiration-days:7}")
    private int expirationDays;

    private final RefreshTokenRepository repository;
    private final BCryptPasswordEncoder passwordEncoder = new BCryptPasswordEncoder(BCRYPT_ROUNDS);

    /** Uj refresh token kibocsatas. A rawUuid csak a HttpOnly cookie-ba kerul. */
    @Transactional
    public IssuedToken issue(Worker worker, HttpServletRequest request) {
        String rawUuid = UUID.randomUUID().toString();
        String hash = passwordEncoder.encode(rawUuid);
        Instant now = Instant.now();
        Instant expires = now.plus(Duration.ofDays(expirationDays));

        RefreshToken rt = RefreshToken.builder()
            .tokenHash(hash)
            .workerId(worker.getId())
            .companyId(worker.getCompany().getId())
            .issuedAt(now)
            .expiresAt(expires)
            .userAgent(truncate(request.getHeader("User-Agent"), 512))
            .ipAddress(truncate(clientIp(request), 45))
            .build();
        repository.save(rt);
        log.debug("Refresh token issued worker={} expires={}", worker.getId(), expires);
        return new IssuedToken(rawUuid, hash, expires);
    }

    /** rawUuid alapjan keres az adott worker aktiv refresh tokenei kozott. */
    @Transactional(readOnly = true)
    public Optional<RefreshToken> findActiveForWorker(Long workerId, String rawUuid) {
        return repository.findByWorkerIdAndRevokedAtIsNull(workerId).stream()
            .filter(RefreshToken::isActive)
            .filter(rt -> passwordEncoder.matches(rawUuid, rt.getTokenHash()))
            .findFirst();
    }

    /** Token rotation: regi revoke + uj issue. */
    @Transactional
    public IssuedToken rotate(RefreshToken oldToken, Worker worker, HttpServletRequest request) {
        IssuedToken newIssued = issue(worker, request);
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

    private static String clientIp(HttpServletRequest request) {
        String xff = request.getHeader("X-Forwarded-For");
        if (xff != null && !xff.isBlank()) return xff.split(",")[0].trim();
        return request.getRemoteAddr();
    }

    private static String truncate(String s, int max) {
        if (s == null) return null;
        return s.length() > max ? s.substring(0, max) : s;
    }

    public record IssuedToken(String rawUuid, String hash, Instant expiresAt) {}
}
