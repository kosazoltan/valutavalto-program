package hu.puzzleir.valuta.security;

import tools.jackson.databind.ObjectMapper;
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

/**
 * Enforces Idempotency-Key header on protected write endpoints (POST/PUT/PATCH/DELETE).
 *
 * <p>Excluded endpoint families (intentionally NOT requiring an Idempotency-Key):
 * <ul>
 *   <li><b>/api/v1/auth/</b> - login/logout flows; not write-replays-by-nature.</li>
 *   <li><b>/api/v1/public/</b> - SetupWizard one-time flows reachable WITHOUT JWT.
 *       The frontend axios interceptor that normally auto-attaches Idempotency-Key
 *       does not attach it in the public (no-auth) context, so SetupWizard requests
 *       (Google identify, setup-status, etc.) arrive without the header. The endpoint
 *       could still receive the header from an arbitrary HTTP client, but enforcing
 *       it here would break the legitimate first-install flow.</li>
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

    private final ObjectMapper objectMapper;

    public IdempotencyFilter(ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        return ProtectedWritePaths.shouldNotFilter(request);
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