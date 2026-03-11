package com.puzzleir.backend.errorlog;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/error-report")
@RequiredArgsConstructor
public class ErrorReportController {

    private final ErrorMailerService errorMailerService;

    @PostMapping
    public ResponseEntity<Map<String, Object>> reportError(@RequestBody ErrorReportRequest req) {
        try {
            errorMailerService.sendErrorReport(req);
            return ResponseEntity.ok(Map.of("ok", true));
        } catch (Exception e) {
            return ResponseEntity.ok(Map.of("ok", false));
        }
    }
}
