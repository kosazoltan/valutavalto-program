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
 * Enforces Idempotency-Key header on protected write endpoints.
 */
@Component
public class IdempotencyFilter extends OncePerRequestFilter {

    private static final String IDEMPOTENCY_HEADER = "Idempotency-Key";
    private static final String LEGACY_IDEMPOTENCY_HEADER = "X-Idempotency-Key";

    private static final Set<String> WRITE_METHODS = Set.of("POST", "PUT", "PATCH", "DELETE");

    private static final List<String> EXCLUDED_PREFIXES = List.of(
            "/api/v1/auth/",
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