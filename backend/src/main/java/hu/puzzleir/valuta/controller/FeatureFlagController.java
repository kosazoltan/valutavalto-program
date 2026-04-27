package hu.puzzleir.valuta.controller;

import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

/**
 * Feature flag discovery endpoint.
 *
 * A frontend bejelentkezes utan lekerdezi, hogy mely szolgaltatasok
 * vannak engedelyezve production-on (pl. camera.enabled=false
 * eseten a Camera menu elrejtheto).
 *
 * AUTHENTICATED (Codex PR #146 P1 fix): a bejelentkezes utan mountolt
 * MainLayout-ban hivjuk, igy a uthenticated() rule vonatkozik ra.
 * Unauthenticated 401-gyel vegzodik, a useFeatureFlags hook catch blokkja
 * fallback default flag-ekre esik (camera=false).
 */
/**
 * AUDIT (audit-NO-GO-iter3 P1, 2026-04-27): policy szerint minden controlleren
 * kotelezo @PreAuthorize. Class-level annotacio teszi explicit-te, hogy
 * authentikalt szerepkor szukseges (a SecurityConfig anyRequest().authenticated()
 * mar igy is biztositja, de a project policy explicit annotaciot ker).
 */
@RestController
@RequestMapping("/api/v1/features")
@RequiredArgsConstructor
@PreAuthorize("isAuthenticated()")
public class FeatureFlagController {

    @Value("${camera.enabled:false}")
    private boolean cameraEnabled;

    @Value("${valuta.scheduler.year-opening.enabled:true}")
    private boolean yearOpeningScheduler;

    @Value("${nav.integration.enabled:true}")
    private boolean navIntegration;

    /**
     * GET /api/v1/features
     * 
     * @return Map<String, boolean> feature flag-ek
     */
    @GetMapping
    public ResponseEntity<Map<String, Boolean>> getFeatures() {
        Map<String, Boolean> features = new HashMap<>();
        features.put("camera", cameraEnabled);
        features.put("yearOpeningScheduler", yearOpeningScheduler);
        features.put("navIntegration", navIntegration);
        return ResponseEntity.ok(features);
    }
}