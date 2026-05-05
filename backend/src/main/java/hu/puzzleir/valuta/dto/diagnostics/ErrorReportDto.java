package hu.puzzleir.valuta.dto.diagnostics;

import com.fasterxml.jackson.databind.JsonNode;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.*;

/**
 * Kliens-oldali hibajelentés payload.
 *
 * <p>Példa kérés:</p>
 * <pre>
 * POST /api/v1/diagnostics/error-report
 * Content-Type: application/json
 *
 * {
 *   "component": "electron-main",
 *   "version": "2.5.13",
 *   "osInfo": "Windows 11 Pro 10.0.26200",
 *   "userIdentifier": "borsi.tamas.ebc@gmail.com",
 *   "errorMessage": "axios timeout",
 *   "stackTrace": "Error: timeout of 15000ms exceeded\n    at ...",
 *   "context": {"url":"https://excvaluta.com/api/v1/auth/google-login","branchCode":"EBC"}
 * }
 * </pre>
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ErrorReportDto {

    /** A hiba forrasa (electron-main / electron-renderer / nsis-installer / axios-http). */
    @NotBlank
    @Pattern(regexp = "^(electron-main|electron-renderer|nsis-installer|axios-http|setup-wizard|sync-engine|other)$",
             message = "component egyik megengedett ertek kell legyen")
    @Size(max = 80)
    private String component;

    @Size(max = 40)
    private String version;

    @Size(max = 200)
    private String osInfo;

    @Size(max = 150)
    private String userIdentifier;

    @NotBlank
    @Size(max = 1000)
    private String errorMessage;

    @Size(max = 8000)
    private String stackTrace;

    /** Strukturált kontextus tetszőleges JSON. */
    private JsonNode context;
}
