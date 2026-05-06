package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.service.SupervisorPinService;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * P2-2 Supervisor PIN REST controller.
 *
 * <p>Endpointok:</p>
 * <ul>
 *   <li><code>POST /api/v1/supervisor-pin/set</code> — saját PIN beállítás (jelszóval)</li>
 *   <li><code>POST /api/v1/supervisor-pin/verify</code> — PIN ellenőrzés (csak ADMIN/MANAGER/SUPERVISOR)</li>
 *   <li><code>POST /api/v1/supervisor-pin/clear</code> — saját PIN törlés</li>
 * </ul>
 */
@RestController
@RequestMapping("/api/v1/supervisor-pin")
@RequiredArgsConstructor
public class SupervisorPinController {

    private final SupervisorPinService supervisorPinService;

    /** Saját PIN beállítás. Body: { currentPassword, pin } */
    @PostMapping("/set")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<Map<String, Object>> setPin(@RequestBody Map<String, String> body) {
        Long workerId = SecurityUtils.getCurrentWorkerId();
        if (workerId == null) {
            return ResponseEntity.status(401).body(Map.of("ok", false, "error", "Nincs bejelentkezve"));
        }
        String currentPassword = body.get("currentPassword");
        String pin = body.get("pin");
        supervisorPinService.setPin(workerId, currentPassword, pin);
        return ResponseEntity.ok(Map.of("ok", true, "message", "PIN beállítva"));
    }

    /**
     * PIN ellenőrzés egy másik workerhez (sztornó / supervisor jóváhagyás).
     * Body: { workerId, pin }. Csak privilegizált role-nak.
     */
    @PostMapping("/verify")
    @PreAuthorize("hasAnyRole('ADMIN','MANAGER','SUPERVISOR')")
    public ResponseEntity<Map<String, Object>> verifyPin(
            @RequestBody Map<String, Object> body,
            HttpServletRequest request) {
        Object workerIdObj = body.get("workerId");
        Long workerId = workerIdObj instanceof Number n ? n.longValue()
                : workerIdObj instanceof String s ? Long.parseLong(s)
                : null;
        String pin = (String) body.get("pin");
        if (workerId == null || pin == null) {
            return ResponseEntity.badRequest().body(Map.of("ok", false, "error", "workerId + pin kötelező"));
        }
        String ip = extractClientIp(request);
        String ua = request.getHeader("User-Agent");
        boolean ok = supervisorPinService.verifyPin(workerId, pin, ip, ua);
        return ok
                ? ResponseEntity.ok(Map.of("ok", true))
                : ResponseEntity.status(401).body(Map.of("ok", false, "error", "Hibás PIN"));
    }

    /** Saját PIN törlés. Body: { currentPassword } */
    @PostMapping("/clear")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<Map<String, Object>> clearPin(@RequestBody Map<String, String> body) {
        String currentPassword = body.get("currentPassword");
        supervisorPinService.clearOwnPin(currentPassword);
        return ResponseEntity.ok(Map.of("ok", true, "message", "PIN törölve"));
    }

    private String extractClientIp(HttpServletRequest req) {
        String fwd = req.getHeader("X-Forwarded-For");
        if (fwd != null && !fwd.isBlank()) {
            return fwd.split(",")[0].trim();
        }
        return req.getRemoteAddr();
    }
}
