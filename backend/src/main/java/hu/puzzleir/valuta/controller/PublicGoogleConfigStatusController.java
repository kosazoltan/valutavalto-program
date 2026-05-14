package hu.puzzleir.valuta.controller;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.env.Environment;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Arrays;
import java.util.Map;

/**
 * Diagnosztikai endpoint a Google OAuth konfiguracio ellenorzesere.
 *
 * <p>Production tamogatas: a Bali/Fabulya Google login hibajanak diagnosztikajara
 * (2026-05-14). NEM ad ki valodi client ID-t, csak boolean + 8-karakteres prefix-et.
 * A prefix elegendo a Hetzner systemd env beallitas-allapotanak vizualisara.</p>
 *
 * <p>Publikus, mert a Setup Wizard / login flow eldontheti, hogy melyik
 * Google login modot kell kinalnia (Web vs. Desktop) — ennel csak konfiguracio-allapotot
 * adunk vissza, NEM titkos kulcsot.</p>
 */
@RestController
@RequestMapping("/api/v1/public/auth")
@PreAuthorize("permitAll()")
@Slf4j
public class PublicGoogleConfigStatusController {

    @Value("${google.client.id:}")
    private String googleClientId;

    @Value("${google.desktop.client.id:}")
    private String googleDesktopClientId;

    private final Environment environment;

    public PublicGoogleConfigStatusController(Environment environment) {
        this.environment = environment;
    }

    /**
     * Visszaadja a Google OAuth konfiguracio allapotat redaktalva.
     *
     * <p>2026-05-14: desktopPrefixes lista — backend tamogatja a vesszovel elvalasztott
     * tobb desktop client ID-t (regi+uj installer egyutt mukodese). A desktopPrefix
     * legacy mezo az elso erteket mutatja (backwards compat).</p>
     */
    @GetMapping("/google-config-status")
    public ResponseEntity<Map<String, Object>> getGoogleConfigStatus() {
        boolean webConfigured = googleClientId != null && !googleClientId.isBlank();
        boolean desktopConfigured = googleDesktopClientId != null && !googleDesktopClientId.isBlank();
        String webPrefix = webConfigured ? maskPrefix(googleClientId) : null;
        java.util.List<String> desktopPrefixes = new java.util.ArrayList<>();
        if (desktopConfigured) {
            for (String id : googleDesktopClientId.split(",")) {
                String trimmed = id.trim();
                if (!trimmed.isEmpty()) {
                    desktopPrefixes.add(maskPrefix(trimmed));
                }
            }
        }
        String activeProfile = String.join(",", Arrays.asList(environment.getActiveProfiles()));

        Map<String, Object> response = new java.util.HashMap<>();
        response.put("webConfigured", webConfigured);
        response.put("desktopConfigured", desktopConfigured);
        response.put("webPrefix", webPrefix == null ? "" : webPrefix);
        // Backwards compat: desktopPrefix elso elem + uj desktopPrefixes lista
        response.put("desktopPrefix", desktopPrefixes.isEmpty() ? "" : desktopPrefixes.get(0));
        response.put("desktopPrefixes", desktopPrefixes);
        response.put("activeProfile", activeProfile);
        return ResponseEntity.ok(response);
    }

    private static String maskPrefix(String value) {
        if (value == null || value.length() < 8) return "***";
        return value.substring(0, 8) + "***";
    }
}
