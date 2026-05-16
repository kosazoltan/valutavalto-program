package hu.puzzleir.valuta.security;

import com.fasterxml.jackson.databind.ObjectMapper;
import hu.puzzleir.valuta.exception.ErrorResponse;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.List;
import java.util.Set;

/**
 * Enforces Idempotency-Key header on protected write endpoints (POST/PUT/PATCH/DELETE).
 *
 * <p>Excluded endpoint families (intentionally NOT requiring an Idempotency-Key):
 * <ul>
 *   <li><b>/api/v1/auth/</b> - login/logout flows; not write-replays-by-nature.</li>
 *   <li><b>/api/v1/public/</b> - SetupWizard one-time flows reachable WITHOUT JWT.
 *       The frontend interceptor that auto-attaches Idempotency-Key only runs for
 *       authenticated context, so public callers (incl. Google identify, setup-status)
 *       cannot send the header.</li>
 *   <li><b>/api/v1/email/accounts/callback</b> - OAuth callback, single-use.</li>
 *   <li><b>/api/v1/health</b>, <b>/actuator/</b> - liveness/health probes.</li>
 *   <li><b>/api/v1/error-report</b>, <b>/api/v1/error-log</b>,
 *       <b>/api/v1/diagnostics/</b> - best-effort client telemetry.</li>
 *   <li><b>/swagger-ui/</b>, <b>/v3/api-docs</b>, <b>/api-docs/</b> - OpenAPI tooling.</li>
 *   <li><b>/ws/</b> - WebSocket upgrade requests.</li>
 * </ul>
 *
 * <p>All other write endpoints MUST include the {@code Idempotency-Key} (or legacy
 * {@code X-Idempotency-Key}) header; missing/invalid keys return 400.
 */
@Component
public class IdempotencyFilter extends OncePerRequestFilter {

    private static final String IDEMPOTENCY_HEADER = "Idempotency-Key";
    private static final String LEGACY_IDEMPOTENCY_HEADER = "X-Idempotency-Key";

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

        private final ObjectMapper objectMapper;

        public IdempotencyFilter(ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
        }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        if (!WRITE_METHODS.contains(request.getMethod())) {
            return true;
        }

        String path = request.getRequestURI();
        if (!path.startsWith("/api/v1/")) {
            return true;
        }

        return EXCLUDED_PREFIXES.stream().anyMatch(path::startsWith);
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {

        String idempotencyKey = request.getHeader(IDEMPOTENCY_HEADER);
        if (!StringUtils.hasText(idempotencyKey)) {
            idempotencyKey = request.getHeader(LEGACY_IDEMPOTENCY_HEADER);
        }
        if (!StringUtils.hasText(idempotencyKey)) {
            writeMissingIdempotencyResponse(response);
            return;
        }

        filterChain.doFilter(request, response);
    }

    private void writeMissingIdempotencyResponse(HttpServletResponse response) throws IOException {
        ErrorResponse errorResponse = ErrorResponse.builder()
                .status(HttpStatus.BAD_REQUEST.value())
                .error("BAD_REQUEST")
                .message("Missing Idempotency-Key header")
                .build();

        response.setStatus(HttpStatus.BAD_REQUEST.value());
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);
        response.getWriter().write(objectMapper.writeValueAsString(errorResponse));
    }
}