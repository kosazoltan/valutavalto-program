package hu.puzzleir.valuta.errorlog;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/v1/error-report")
@RequiredArgsConstructor
public class ErrorReportController {

    private final ErrorMailerService errorMailerService;

    @PostMapping
    public ResponseEntity<Map<String, Object>> reportError(@jakarta.validation.Valid @RequestBody ErrorReportRequest req) {
        try {
            errorMailerService.sendErrorReport(req);
            return ResponseEntity.ok(Map.of("ok", true));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("ok", false));
        }
    }
}
