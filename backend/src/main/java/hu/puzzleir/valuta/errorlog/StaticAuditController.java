package hu.puzzleir.valuta.errorlog;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/static-audit")
@RequiredArgsConstructor
public class StaticAuditController {

    private final StaticAuditService staticAuditService;

    /**
     * GET /api/static-audit
     * Admin-only health/audit check. In production, secure with JWT or IP allowlist.
     */
    @GetMapping
    public ResponseEntity<List<AuditCheck>> runAudit(
            @RequestHeader(value = "X-Admin-Token", required = false) String token) {
        // Simple token check — replace with proper auth in prod
        String adminToken = System.getenv("STATIC_AUDIT_TOKEN");
        if (adminToken != null && !adminToken.isBlank() && !adminToken.equals(token)) {
            return ResponseEntity.status(403).build();
        }
        return ResponseEntity.ok(staticAuditService.runStaticAudit());
    }
}
