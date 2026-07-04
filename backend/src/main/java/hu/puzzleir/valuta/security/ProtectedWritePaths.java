package hu.puzzleir.valuta.security;

import jakarta.servlet.http.HttpServletRequest;

import java.util.List;
import java.util.Set;

/**
 * Shared protected-write path scope for security filters that guard mutating API requests.
 */
public final class ProtectedWritePaths {

    private static final Set<String> WRITE_METHODS = Set.of("POST", "PUT", "PATCH", "DELETE");

    private static final List<String> EXCLUDED_PREFIXES = List.of(
            "/api/v1/auth/",
            // 2026-05-15: SetupWizard public endpointok (google-identify, setup-status, etc.)
            // — egyszeri belepesi flow, NEM kell idempotency, es a kliens nem tud
            // header-t kuldeni a publikus context-ben (no JWT, no apiClient interceptor).
            "/api/v1/public/",
            "/api/v1/email/accounts/callback",
            "/api/v1/health",
            "/api/v1/error-report",
            "/api/v1/error-log",
            // v2.5.16: kliens-oldali hibajelentes (Penztar.exe -> backend) idempotency-mentes
            "/api/v1/diagnostics/",
            "/swagger-ui/",
            "/v3/api-docs",
            "/api-docs/",
            "/actuator/",
            "/ws/"
    );

    private ProtectedWritePaths() {
    }

    public static boolean shouldNotFilter(HttpServletRequest request) {
        if (!WRITE_METHODS.contains(request.getMethod())) {
            return true;
        }

        String path = request.getRequestURI();
        if (!path.startsWith("/api/v1/")) {
            return true;
        }

        return EXCLUDED_PREFIXES.stream().anyMatch(path::startsWith);
    }
}
