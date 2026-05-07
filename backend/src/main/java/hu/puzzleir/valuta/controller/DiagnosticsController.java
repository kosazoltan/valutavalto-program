package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.diagnostics.ErrorReportDto;
import hu.puzzleir.valuta.entity.ClientErrorLog;
import hu.puzzleir.valuta.repository.ClientErrorLogRepository;
import hu.puzzleir.valuta.service.GitHubIssueAutoCreator;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
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
                .contextJson(serializeContext(dto.getContext()))
                .clientIp(clientIp)
                .userAgent(userAgent)
                .build();

        errorLogRepository.save(entry);

        String logComponent = stripCrlf(dto.getComponent());
        String logVersion = stripCrlf(dto.getVersion());
        String logOsInfo = stripCrlf(dto.getOsInfo());
        String logUser = stripCrlf(dto.getUserIdentifier());
        String logClientIp = stripCrlf(clientIp);
        String logMessage = stripCrlf(safeTruncate(dto.getErrorMessage(), 200));
        log.warn("[client-error] {} v{} {} | user={} | ip={} | msg='{}'",
                logComponent,
                logVersion,
                logOsInfo,
                logUser,
                logClientIp,
                logMessage);

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

    /**
     * Admin monitoring dashboard: utolsó N hibajelentés (paginated).
     *
     * <p>Csak ADMIN/MANAGER/SUPERVISOR role-nak. A frontend-react
     * `/admin/error-monitor` oldal hívja.</p>
     */
    @GetMapping("/errors")
    @PreAuthorize("hasAnyRole('ADMIN','MANAGER','SUPERVISOR')")
    public ResponseEntity<Page<ClientErrorLog>> listErrors(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "50") int size) {
        int safeSize = Math.min(Math.max(size, 1), 200);
        Page<ClientErrorLog> result = errorLogRepository
                .findAllByOrderByCreatedAtDesc(PageRequest.of(page, safeSize));
        return ResponseEntity.ok(result);
    }

    /**
     * Admin monitoring summary — komponens + verzió szerinti hibaeloszlás
     * az utolsó 24 / 7 / 30 napra.
     */
    @GetMapping("/errors/summary")
    @PreAuthorize("hasAnyRole('ADMIN','MANAGER','SUPERVISOR')")
    public ResponseEntity<Map<String, Object>> errorSummary() {
        LocalDateTime now = LocalDateTime.now();
        LocalDateTime last24h = now.minusHours(24);
        LocalDateTime last7d = now.minusDays(7);
        LocalDateTime last30d = now.minusDays(30);

        Map<String, Object> response = new HashMap<>();
        response.put("totalAllTime", errorLogRepository.count());
        response.put("last24h", errorLogRepository.countByCreatedAtAfter(last24h));
        response.put("last7d", errorLogRepository.countByCreatedAtAfter(last7d));
        response.put("last30d", errorLogRepository.countByCreatedAtAfter(last30d));

        List<ClientErrorLogRepository.ComponentCount> componentBreakdown7d =
                errorLogRepository.countByComponentSince(last7d);
        response.put("componentBreakdown7d", componentBreakdown7d);

        List<ClientErrorLogRepository.VersionCount> versionBreakdown7d =
                errorLogRepository.countByVersionSince(last7d);
        response.put("versionBreakdown7d", versionBreakdown7d);

        response.put("generatedAt", now);
        return ResponseEntity.ok(response);
    }

    /**
     * Egy konkrét hibajelentés részletei (stack trace + context JSON).
     */
    @GetMapping("/errors/{id}")
    @PreAuthorize("hasAnyRole('ADMIN','MANAGER','SUPERVISOR')")
    public ResponseEntity<ClientErrorLog> getError(@PathVariable Long id) {
        return errorLogRepository.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    private String extractClientIp(HttpServletRequest req) {
        // Reverse-proxy mögött (Caddy → Tomcat) az X-Forwarded-For-ban van a valódi IP
        String fwd = req.getHeader("X-Forwarded-For");
        if (fwd != null && !fwd.isBlank()) {
            // Az első IP a kliens, a többi proxy chain
            return stripCrlf(fwd.split(",")[0].trim());
        }
        return stripCrlf(req.getRemoteAddr());
    }

    private String safeTruncate(String s, int max) {
        if (s == null) return null;
        if (s.length() <= max) return s;
        return s.substring(0, max);
    }

    private static String stripCrlf(String s) {
        if (s == null) return "";
        return s.replace("\r", "").replace("\n", " ");
    }

    /**
     * Map -> JSON string konverzio. Jackson 3 dual-stack kompatibilis: a Spring Boot
     * default `ObjectMapper` Map-ot ki tudja irni JSON-ba akkor is, ha a `JacksonConfig`
     * a Jackson 2 stop-gap modulnal regisztralt is. Ha a serializacio fail-el, a
     * `Map.toString()` fallback-re vissza-eshetunk (NEM commitoljuk a hibajelentest).
     */
    private String serializeContext(Map<String, Object> ctx) {
        if (ctx == null || ctx.isEmpty()) return null;
        try {
            // Spring Boot default Jackson - injektaljuk csak ha kell, kulonben Map.toString()
            return new com.fasterxml.jackson.databind.ObjectMapper().writeValueAsString(ctx);
        } catch (Exception ex) {
            log.warn("Context serialize failed, fallback to toString: {}", ex.getMessage());
            return ctx.toString();
        }
    }
}
