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

        for (String mandatoryOrigin : List.of(
                "http://localhost:3000",
                "http://localhost:5173",
                "https://excvaluta.com"
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

    private boolean matchesPattern(String origin, String pattern) {
        String normalizedPattern = pattern.toLowerCase(Locale.ROOT);
        String normalizedOrigin = origin.toLowerCase(Locale.ROOT);

        if (!normalizedPattern.contains("*")) {
            return normalizedOrigin.equals(normalizedPattern);
        }

        String[] parts = normalizedPattern.split("\\*", -1);
        int index = 0;
        for (String part : parts) {
            if (part.isEmpty()) {
                continue;
            }
            int found = normalizedOrigin.indexOf(part, index);
            if (found < 0) {
                return false;
            }
            index = found + part.length();
        }

        return normalizedOrigin.startsWith(parts[0]) && normalizedOrigin.endsWith(parts[parts.length - 1]);
    }
}