package hu.puzzleir.valuta.dto.diagnostics;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

import java.time.Instant;
import java.util.Map;

/**
 * Frontend / Electron kliens-oldali ERROR forward request DTO.
 *
 * <p>Forras: vault/feedback/valutavalto-belso-log-audit-modul-tervezet-2026-05-18.md (4.5 + 5.3)
 *
 * <p>A {@code POST /api/v1/diagnostics/log} endpoint-on at jon. A backend
 * a payload-ot a {@link hu.puzzleir.valuta.logging.VVLogger}-en at logolja
 * (Logback JSON output + audit chain).
 *
 * <p>Csak ERROR / WARN szintek megengedettek - INFO/DEBUG NE menjen a backend-re
 * (lokalis log eleg, kulonben DDoS-ozza a backend log infrat).
 */
public record FrontendLogEntryRequestDto(
        @NotBlank @Size(max = 10) String level,         // "ERROR" | "WARN"
        @NotBlank @Size(max = 80) String eventType,     // pl. "ui.crash"
        @Size(max = 50) String errorCode,               // pl. "VV-VOICE-002"
        @NotBlank @Size(max = 500) String message,
        Instant clientTs,                                // kliens-oldali timestamp
        @Size(max = 32) String traceId,                 // ha a kliens kapcsolja
        @Size(max = 20) String clientContext,           // "CASHIER" | "TREASURY_HQ" | "RFM" | "ADMIN"
        @Size(max = 50) String clientVersion,           // pl. "2.5.57"
        Map<String, Object> attrs,                      // szabad atribuumok (PII-redact-elve)
        @Size(max = 4000) String stackTrace             // truncated
) {}
