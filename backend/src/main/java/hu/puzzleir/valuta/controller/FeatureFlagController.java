package hu.puzzleir.valuta.controller;

import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
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
 * Publikus (JWT nem kotelezo) mert a menuGroups render elott fut.
 */
@RestController
@RequestMapping("/api/v1/features")
@RequiredArgsConstructor
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