package hu.puzzleir.valuta.config;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Locale;

@Component
@Order(Ordered.HIGHEST_PRECEDENCE)
public class ProductionCorsFilter extends OncePerRequestFilter {

    private static final List<String> DEFAULT_ALLOWED_METHODS = List.of("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS");
    private static final List<String> DEFAULT_ALLOWED_HEADERS = List.of(
            "Authorization",
            "Content-Type",
            "X-Requested-With",
            "Accept",
            "Origin",
            "Access-Control-Request-Method",
            "Access-Control-Request-Headers",
            "Idempotency-Key",
            "X-Idempotency-Key"
    );

    private final List<String> allowedOrigins;
    private final List<String> allowedOriginPatterns;

    public ProductionCorsFilter(
            @Value("${cors.allowed-origins:http://localhost:3000,http://localhost:5173,https://excvaluta.com}")
            String corsAllowedOrigins
    ) {
        List<String> configuredOrigins = Arrays.stream(corsAllowedOrigins.split(","))
                .map(String::trim)
                .filter(s -> !s.isEmpty())
                .toList();

        this.allowedOrigins = new ArrayList<>();
        this.allowedOriginPatterns = new ArrayList<>();

        for (String origin : configuredOrigins) {
            if (origin.contains("*")) {
                allowedOriginPatterns.add(origin);
            } else if (!allowedOrigins.contains(origin)) {
                allowedOrigins.add(origin);
            }
        }

        // SSOT refaktor (2026-04-24): excvaluta.com a ProductionUrls konstansosztalybol
        for (String mandatoryOrigin : List.of(
                "http://localhost:3000",
                "http://localhost:5173",
                ProductionUrls.BASE_URL
        )) {
            if (!allowedOrigins.contains(mandatoryOrigin)) {
                allowedOrigins.add(mandatoryOrigin);
            }
        }
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {
        String origin = request.getHeader(HttpHeaders.ORIGIN);

        if (origin == null || !isAllowedOrigin(origin)) {
            filterChain.doFilter(request, response);
            return;
        }

        response.setHeader(HttpHeaders.ACCESS_CONTROL_ALLOW_ORIGIN, origin);
        response.setHeader(HttpHeaders.VARY, HttpHeaders.ORIGIN);
        response.setHeader(HttpHeaders.ACCESS_CONTROL_ALLOW_CREDENTIALS, "true");
        response.setHeader(HttpHeaders.ACCESS_CONTROL_ALLOW_METHODS, String.join(", ", DEFAULT_ALLOWED_METHODS));

        // Always use fixed whitelist — never reflect request headers
        response.setHeader(HttpHeaders.ACCESS_CONTROL_ALLOW_HEADERS, String.join(", ", DEFAULT_ALLOWED_HEADERS));
        response.setHeader(HttpHeaders.ACCESS_CONTROL_MAX_AGE, "3600");

        if (HttpMethod.OPTIONS.matches(request.getMethod())) {
            response.setStatus(HttpServletResponse.SC_OK);
            return;
        }

        filterChain.doFilter(request, response);
    }

    private boolean isAllowedOrigin(String origin) {
        if (allowedOrigins.contains(origin)) {
            return true;
        }

        return allowedOriginPatterns.stream().anyMatch(pattern -> matchesPattern(origin, pattern));
    }

    /**
     * PP-04: Biztonságos minta-illesztés. A korábbi startsWith/endsWith logika kijátszható volt
     * (pl. `http://localhost:*` minta + üres utótag → bármilyen `http://localhost:...` átment).
     * Most: a literál szegmenseket regex-re escape-eljük, a `*` wildcardot pedig egy szűk,
     * host/port-barát karakterosztályra (`[a-z0-9.\-]*`) cseréljük, ami NEM enged `/`, `:`, `@`
     * karaktert — így nem injektálható path/userinfo/port-trükk (pl. localhost.evil.com kizárva).
     * A teljes mintát lehorgonyozzuk (^...$).
     */
    boolean matchesPattern(String origin, String pattern) {
        String normalizedPattern = pattern.toLowerCase(Locale.ROOT);
        String normalizedOrigin = origin.toLowerCase(Locale.ROOT);

        if (!normalizedPattern.contains("*")) {
            return normalizedOrigin.equals(normalizedPattern);
        }

        String[] parts = normalizedPattern.split("\\*", -1);
        StringBuilder regex = new StringBuilder("^");
        for (int i = 0; i < parts.length; i++) {
            if (!parts[i].isEmpty()) {
                regex.append(java.util.regex.Pattern.quote(parts[i]));
            }
            if (i < parts.length - 1) {
                regex.append("[a-z0-9.\\-]*"); // wildcard: host/port-barát, nincs / : @
            }
        }
        regex.append("$");
        return normalizedOrigin.matches(regex.toString());
    }
}