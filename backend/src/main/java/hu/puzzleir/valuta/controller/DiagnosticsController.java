package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.diagnostics.ErrorReportDto;
import hu.puzzleir.valuta.entity.ClientErrorLog;
import hu.puzzleir.valuta.repository.ClientErrorLogRepository;
import hu.puzzleir.valuta.service.GitHubIssueAutoCreator;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * Diagnosztikai endpoint kliens-oldali hibajelentések fogadására.
 *
 * <p>Iparági standard inspiráció: Sentry data-ingest model. Az endpoint
 * nyilvános (no auth), de rate-limit-elt (a globális RateLimitingFilter által).</p>
 *
 * <p>2026-05-05 user-direktíva: a kollégák gépén történő hibákat
 * AUTOMATIKUSAN ide küldjük, NEM kell manuálisan debug-olni.
 * SSH-val SQL-lekerdezessel bármikor kiolvasható:</p>
 * <pre>
 * sudo -u postgres psql -d valuta -c \
 *   "SELECT created_at, component, version, error_message FROM client_error_log
 *    ORDER BY created_at DESC LIMIT 20;"
 * </pre>
 */
@RestController
@RequestMapping("/api/v1/diagnostics")
@RequiredArgsConstructor
@Slf4j
public class DiagnosticsController {

    private final ClientErrorLogRepository errorLogRepository;
    private final GitHubIssueAutoCreator gitHubIssueAutoCreator;

    /**
     * Hibajelentés fogadása. Permitall, no auth.
     */
    @PostMapping("/error-report")
    @PreAuthorize("permitAll()")
    @Transactional
    public ResponseEntity<Map<String, Object>> reportError(
            @Valid @RequestBody ErrorReportDto dto,
            HttpServletRequest request) {

        // IP + UA kinyerése (audit + rate-limiting)
        String clientIp = extractClientIp(request);
        String userAgent = request.getHeader("User-Agent");
        if (userAgent != null && userAgent.length() > 300) {
            userAgent = userAgent.substring(0, 300);
        }

        ClientErrorLog entry = ClientErrorLog.builder()
                .component(dto.getComponent())
                .version(safeTruncate(dto.getVersion(), 40))
                .osInfo(safeTruncate(dto.getOsInfo(), 200))
                .userIdentifier(safeTruncate(dto.getUserIdentifier(), 150))
                .errorMessage(safeTruncate(dto.getErrorMessage(), 1000))
                .stackTrace(safeTruncate(dto.getStackTrace(), 8000))
                .contextJson(dto.getContext() != null ? dto.getContext().toString() : null)
                .clientIp(clientIp)
                .userAgent(userAgent)
                .build();

        errorLogRepository.save(entry);

        log.warn("[client-error] {} v{} {} | user={} | ip={} | msg='{}'",
                dto.getComponent(),
                dto.getVersion(),
                dto.getOsInfo(),
                dto.getUserIdentifier(),
                clientIp,
                safeTruncate(dto.getErrorMessage(), 200));

        // Aszinkron eskala: kritikus mintazatra GitHub Issue auto-create
        gitHubIssueAutoCreator.evaluateAndEscalate(entry);

        return ResponseEntity.ok(Map.of(
                "ok", true,
                "id", entry.getId()
        ));
    }

    /**
     * Egyszerű egészségellenőrzés. (Külön ettől létezik az `/auth/bootstrap-status` is.)
     */
    @GetMapping("/health")
    @PreAuthorize("permitAll()")
    public ResponseEntity<Map<String, Object>> health() {
        long totalErrors = errorLogRepository.count();
        return ResponseEntity.ok(Map.of(
                "ok", true,
                "totalReportedErrors", totalErrors
        ));
    }

    private String extractClientIp(HttpServletRequest req) {
        // Reverse-proxy mögött (Caddy → Tomcat) az X-Forwarded-For-ban van a valódi IP
        String fwd = req.getHeader("X-Forwarded-For");
        if (fwd != null && !fwd.isBlank()) {
            // Az első IP a kliens, a többi proxy chain
            return fwd.split(",")[0].trim();
        }
        return req.getRemoteAddr();
    }

    private String safeTruncate(String s, int max) {
        if (s == null) return null;
        if (s.length() <= max) return s;
        return s.substring(0, max);
    }
}
