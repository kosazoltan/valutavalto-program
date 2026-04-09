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
import java.net.InetAddress;
import java.util.Collections;
import java.util.List;
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

    /** POS fizetés: max kérés / ablak */
    @Value("${rate-limit.payment.max-requests:120}")
    private int paymentMaxRequests;

    /** POS fizetés: időablak ms-ban (alapértelmezett: 60 sec) */
    @Value("${rate-limit.payment.window-ms:60000}")
    private long paymentWindowMs;

    /** Trusted proxy CIDR ranges — only these sources may set X-Forwarded-For */
    @Value("${rate-limit.trusted-proxies:127.0.0.1/32,::1/128,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16}")
    private List<String> trustedProxyCidrs;

    private volatile List<CidrRange> parsedTrustedProxies;

    /** Cleanup: bejegyzések ennyi ms után törölhetők (alapértelmezett: 10 perc) */
    private static final long CLEANUP_THRESHOLD_MS = 600_000L;

    private final Map<String, RateLimitEntry> loginLimits = new ConcurrentHashMap<>();
    private final Map<String, RateLimitEntry> transactionLimits = new ConcurrentHashMap<>();
    private final Map<String, RateLimitEntry> paymentLimits = new ConcurrentHashMap<>();

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

        // POS fizetés endpoint — magasabb limit (kártyás fizetésekhez)
        if (path.startsWith("/api/v1/pos-terminal/process-transaction")) {
            if (isRateLimited(clientIp, paymentLimits, paymentMaxRequests, paymentWindowMs)) {
                log.warn("Rate limit elérve: fizetés — IP: {}", clientIp);
                response.setStatus(HttpStatus.TOO_MANY_REQUESTS.value());
                response.setContentType("application/json");
                response.getWriter().write(
                        "{\"error\":\"Túl sok fizetési kérés. Kérjük próbálja újra később.\"}");
                return;
            }
        }

        // Tranzakciós endpointok
        if (path.startsWith("/api/v1/transactions/buy")
                || path.startsWith("/api/v1/transactions/sell")
                || path.startsWith("/api/v1/transactions/conversion")
                || path.startsWith("/api/v1/transactions/reversal")) {
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
        int paymentRemoved = removeExpired(paymentLimits, now);
        if (loginRemoved > 0 || txRemoved > 0 || paymentRemoved > 0) {
            log.debug("Rate limit cleanup: {} login + {} tranzakció + {} fizetés bejegyzés törölve. " +
                            "Aktív: {} login, {} tranzakció, {} fizetés",
                    loginRemoved, txRemoved, paymentRemoved,
                    loginLimits.size(), transactionLimits.size(), paymentLimits.size());
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

    private List<CidrRange> getTrustedProxies() {
        if (parsedTrustedProxies == null) {
            if (trustedProxyCidrs == null || trustedProxyCidrs.isEmpty()) {
                parsedTrustedProxies = Collections.emptyList();
            } else {
                parsedTrustedProxies = trustedProxyCidrs.stream()
                        .map(String::trim)
                        .filter(s -> !s.isEmpty())
                        .map(CidrRange::parse)
                        .filter(java.util.Objects::nonNull)
                        .toList();
            }
        }
        return parsedTrustedProxies;
    }

    private boolean isTrustedProxy(String remoteAddr) {
        try {
            InetAddress addr = InetAddress.getByName(remoteAddr);
            for (CidrRange cidr : getTrustedProxies()) {
                if (cidr.contains(addr)) {
                    return true;
                }
            }
        } catch (Exception e) {
            log.debug("Cannot resolve remote address for trusted proxy check: {}", remoteAddr);
        }
        return false;
    }

    private String resolveClientIp(HttpServletRequest request) {
        String remoteAddr = request.getRemoteAddr();
        if (isTrustedProxy(remoteAddr)) {
            String xff = request.getHeader("X-Forwarded-For");
            if (xff != null && !xff.isBlank()) {
                return xff.split(",")[0].trim();
            }
            String realIp = request.getHeader("X-Real-IP");
            if (realIp != null && !realIp.isBlank()) {
                return realIp;
            }
        }
        return remoteAddr;
    }

    private static class CidrRange {
        private final byte[] network;
        private final int prefixLength;

        CidrRange(byte[] network, int prefixLength) {
            this.network = network;
            this.prefixLength = prefixLength;
        }

        static CidrRange parse(String cidr) {
            try {
                String[] parts = cidr.split("/");
                InetAddress addr = InetAddress.getByName(parts[0]);
                int prefix = parts.length > 1 ? Integer.parseInt(parts[1]) : (addr.getAddress().length * 8);
                return new CidrRange(addr.getAddress(), prefix);
            } catch (Exception e) {
                return null;
            }
        }

        boolean contains(InetAddress address) {
            byte[] addrBytes = address.getAddress();
            if (addrBytes.length != network.length) {
                return false;
            }
            int fullBytes = prefixLength / 8;
            for (int i = 0; i < fullBytes && i < addrBytes.length; i++) {
                if (addrBytes[i] != network[i]) return false;
            }
            int remainingBits = prefixLength % 8;
            if (remainingBits > 0 && fullBytes < addrBytes.length) {
                int mask = (0xFF << (8 - remainingBits)) & 0xFF;
                if ((addrBytes[fullBytes] & mask) != (network[fullBytes] & mask)) return false;
            }
            return true;
        }
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
