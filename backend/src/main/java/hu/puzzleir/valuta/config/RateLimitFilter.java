package hu.puzzleir.valuta.config;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.annotation.Order;
import org.springframework.http.HttpStatus;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicLong;

/**
 * Rate limiting szűrő a kritikus végpontokhoz.
 *
 * Védi a login endpointot brute force támadás ellen,
 * és a tranzakciós endpointokat túlzott terhelés ellen.
 * Per-IP alapú limitálás — minden pénztár/kliens külön számlálót kap.
 *
 * Cleanup: 5 percenként törli a lejárt bejegyzéseket (memory leak megelőzés).
 */
@Component
@Order(0)
@Slf4j
public class RateLimitFilter extends OncePerRequestFilter {

    /** Login: max kérés / ablak */
    @Value("${rate-limit.login.max-requests:10}")
    private int loginMaxRequests;

    /** Login: időablak ms-ban (alapértelmezett: 60 sec) */
    @Value("${rate-limit.login.window-ms:60000}")
    private long loginWindowMs;

    /** Tranzakciók: max kérés / ablak */
    @Value("${rate-limit.transaction.max-requests:30}")
    private int transactionMaxRequests;

    /** Tranzakciók: időablak ms-ban (alapértelmezett: 60 sec) */
    @Value("${rate-limit.transaction.window-ms:60000}")
    private long transactionWindowMs;

    /** Cleanup: bejegyzések ennyi ms után törölhetők (alapértelmezett: 10 perc) */
    private static final long CLEANUP_THRESHOLD_MS = 600_000L;

    private final Map<String, RateLimitEntry> loginLimits = new ConcurrentHashMap<>();
    private final Map<String, RateLimitEntry> transactionLimits = new ConcurrentHashMap<>();

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {
        String path = request.getRequestURI();
        String method = request.getMethod();

        // Csak POST kérésekre limitálunk (GET-ek nem módosítanak)
        if (!"POST".equalsIgnoreCase(method)) {
            filterChain.doFilter(request, response);
            return;
        }

        String clientIp = resolveClientIp(request);

        // Login endpoint — szigorúbb limit
        if (path.startsWith("/api/v1/auth/login")) {
            if (isRateLimited(clientIp, loginLimits, loginMaxRequests, loginWindowMs)) {
                log.warn("Rate limit elérve: login — IP: {}", clientIp);
                response.setStatus(HttpStatus.TOO_MANY_REQUESTS.value());
                response.setContentType("application/json");
                response.getWriter().write(
                        "{\"error\":\"Túl sok bejelentkezési kísérlet. Kérjük próbálja újra később.\"}");
                return;
            }
        }

        // Tranzakciós endpointok
        if (path.startsWith("/api/v1/transactions/buy")
                || path.startsWith("/api/v1/transactions/sell")
                || path.startsWith("/api/v1/transactions/conversion")
                || path.startsWith("/api/v1/transactions/reversal")
                || path.startsWith("/api/v1/pos-terminal/process-transaction")) {
            if (isRateLimited(clientIp, transactionLimits, transactionMaxRequests, transactionWindowMs)) {
                log.warn("Rate limit elérve: tranzakció — IP: {}", clientIp);
                response.setStatus(HttpStatus.TOO_MANY_REQUESTS.value());
                response.setContentType("application/json");
                response.getWriter().write(
                        "{\"error\":\"Túl sok tranzakciós kérés. Kérjük próbálja újra később.\"}");
                return;
            }
        }

        filterChain.doFilter(request, response);
    }

    private boolean isRateLimited(String key, Map<String, RateLimitEntry> limits,
                                  int maxRequests, long windowMs) {
        long now = System.currentTimeMillis();
        RateLimitEntry entry = limits.compute(key, (k, existing) -> {
            if (existing == null || now - existing.windowStart.get() > windowMs) {
                return new RateLimitEntry(now);
            }
            return existing;
        });
        return entry.counter.incrementAndGet() > maxRequests;
    }

    /**
     * Lejárt bejegyzések törlése — 5 percenként fut.
     * Megelőzi a ConcurrentHashMap korlátlan növekedését (memory leak).
     */
    @Scheduled(fixedDelay = 300_000L) // 5 perc
    public void cleanupExpiredEntries() {
        long now = System.currentTimeMillis();
        int loginRemoved = removeExpired(loginLimits, now);
        int txRemoved = removeExpired(transactionLimits, now);
        if (loginRemoved > 0 || txRemoved > 0) {
            log.debug("Rate limit cleanup: {} login + {} tranzakció bejegyzés törölve. " +
                    "Aktív: {} login, {} tranzakció",
                    loginRemoved, txRemoved, loginLimits.size(), transactionLimits.size());
        }
    }

    private int removeExpired(Map<String, RateLimitEntry> limits, long now) {
        int[] removed = {0};
        limits.entrySet().removeIf(entry -> {
            boolean expired = now - entry.getValue().windowStart.get() > CLEANUP_THRESHOLD_MS;
            if (expired) removed[0]++;
            return expired;
        });
        return removed[0];
    }

    private String resolveClientIp(HttpServletRequest request) {
        String xff = request.getHeader("X-Forwarded-For");
        if (xff != null && !xff.isBlank()) {
            return xff.split(",")[0].trim();
        }
        String realIp = request.getHeader("X-Real-IP");
        if (realIp != null && !realIp.isBlank()) {
            return realIp;
        }
        return request.getRemoteAddr();
    }

    private static class RateLimitEntry {
        final AtomicLong windowStart;
        final AtomicInteger counter;

        RateLimitEntry(long startTime) {
            this.windowStart = new AtomicLong(startTime);
            this.counter = new AtomicInteger(0);
        }
    }
}
