package hu.puzzleir.valuta.logging;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.slf4j.MDC;

import java.util.Map;

/**
 * EBC Valutavalto - centralizalt structured logger.
 *
 * <p>Forras: vault/feedback/valutavalto-belso-log-audit-modul-tervezet-2026-05-18.md (5.1)
 *
 * <p>A {@code VVLogger} wrapper a sima SLF4J {@link Logger} ele,
 * automatikus MDC-managementtel az alabbi mezokhez:
 * <ul>
 *   <li>{@code event_type} - uzleti esemeny tipusa (pl. "transaction.committed")</li>
 *   <li>{@code error_code} - AI-olvashato hibakod (pl. "VV-AML-001"),
 *       lasd packages/shared-logging/error-codes.yaml</li>
 *   <li>{@code error_category} - AML | BUSINESS | TECHNICAL | NETWORK | SECURITY | INTEGRATION</li>
 *   <li>{@code trace_id, span_id} - Micrometer Tracing automatikusan kitölti,
 *       NEM kell manualisan</li>
 *   <li>Egyeb attribuumok az `attrs` Map-en at -> JSON output `attrs.*`</li>
 * </ul>
 *
 * <p>Hasznalat:
 * <pre>{@code
 *   private static final VVLogger log = VVLogger.of(AmlService.class);
 *
 *   public void checkThreshold(BigDecimal amount, Currency currency) {
 *     if (amount.compareTo(new BigDecimal("100000")) > 0 && !isIdentified()) {
 *       log.error("VV-AML-001", "aml.identification.required",
 *                 new AmlThresholdViolation(),
 *                 Map.of("amount", amount, "currency", currency));
 *       throw new AmlThresholdViolation();
 *     }
 *   }
 * }</pre>
 *
 * <p>A {@code MDC} kontextus minden hivas vegen takaritva van (try/finally).
 * Az SLF4J + Logback automatikusan a JSON output `attrs.*` mezoiba teszi.
 */
public final class VVLogger {

    private final Logger delegate;

    private VVLogger(Logger delegate) {
        this.delegate = delegate;
    }

    /**
     * Logger letrehozasa egy adott Java class-hoz.
     *
     * @param cls a hivo class (pl. {@code AmlService.class})
     * @return egy uj {@link VVLogger} instance
     */
    public static VVLogger of(Class<?> cls) {
        return new VVLogger(LoggerFactory.getLogger(cls));
    }

    /**
     * INFO szintu uzleti esemeny logolasa (pl. tranzakcio committed).
     *
     * @param eventType az esemeny tipusa (pl. "transaction.committed")
     * @param attrs szabad atributumok (pl. {@code Map.of("amount", 50000, "currency", "EUR")})
     */
    public void info(String eventType, Map<String, Object> attrs) {
        log("INFO", eventType, null, null, null, attrs);
    }

    /**
     * WARN szintu anomalia (a folyamat megy tovabb, de figyelmezteto).
     */
    public void warn(String eventType, String errorCode, Map<String, Object> attrs) {
        log("WARN", eventType, errorCode, null, null, attrs);
    }

    /**
     * ERROR szintu hiba (a muvelet meghiusult).
     *
     * @param errorCode AI-olvashato hibakod (pl. "VV-AML-001"), lasd error-codes.yaml
     * @param eventType az esemeny tipusa (pl. "aml.identification.required")
     * @param cause az exception-objektum (a stack trace a `error.stack` mezobe kerul)
     * @param attrs szabad atributumok
     */
    public void error(String errorCode, String eventType, Throwable cause, Map<String, Object> attrs) {
        log("ERROR", eventType, errorCode, categoryFromCode(errorCode), cause, attrs);
    }

    /**
     * FATAL szintu rendszer-kritikus hiba.
     */
    public void fatal(String errorCode, String eventType, Throwable cause, Map<String, Object> attrs) {
        // SLF4J nem ismeri a FATAL szintet kulonallnak; ERROR-ban logoljuk, de
        // a MDC-ben jelezzuk az emelt szintet (a Loki/audit query-ben szurheto).
        try {
            MDC.put("level_severity", "FATAL");
            log("ERROR", eventType, errorCode, categoryFromCode(errorCode), cause, attrs);
        } finally {
            MDC.remove("level_severity");
        }
    }

    /**
     * DEBUG szintu fejlesztoi diagnosztika (dev mode-ban latszik).
     */
    public void debug(String eventType, Map<String, Object> attrs) {
        if (!delegate.isDebugEnabled()) return;
        log("DEBUG", eventType, null, null, null, attrs);
    }

    /**
     * Foglalt MDC kulcsok, amelyeket az `attrs` nem irhat felul.
     *
     * <p>Copilot+Codex PR #681 P1 finding: a kliens-attrs.keySet() omlesztese
     * az MDC-be felulirhatna a Micrometer Tracing trace_id-jat / span_id-jat,
     * a Logstash encoder strukturalt fieldjeit (level, logger, thread), vagy
     * a sajat reserved kulcsainkat (event_type, error_code, error_category).
     */
    private static final java.util.Set<String> RESERVED_MDC_KEYS = java.util.Set.of(
            "event_type", "error_code", "error_category",
            "trace_id", "traceId", "span_id", "spanId",
            "level", "logger", "thread", "ts", "message",
            "error.stack", "schema_version", "service", "service_version", "env"
    );

    private void log(
            String level,
            String eventType,
            String errorCode,
            String errorCategory,
            Throwable cause,
            Map<String, Object> attrs) {
        java.util.Set<String> appliedAttrKeys = new java.util.HashSet<>();
        try {
            MDC.put("event_type", eventType);
            if (errorCode != null) MDC.put("error_code", errorCode);
            if (errorCategory != null) MDC.put("error_category", errorCategory);
            if (attrs != null) {
                attrs.forEach((k, v) -> {
                    if (k == null || k.isBlank() || v == null) return;
                    // Copilot+Codex PR #681 P1: NE foglaljuk MDC reserved kulcsot
                    if (RESERVED_MDC_KEYS.contains(k)) return;
                    // Namespace prefix: `attrs.<key>` - igy NEM utkozik a strukturalt
                    // top-level fielddel + Loki query-ban konnyen szurheto
                    String prefixedKey = k.startsWith("attrs.") || k.startsWith("client.")
                            ? k : "attrs." + k;
                    // Defense-in-depth: a redactor a value-stringen is fut
                    MDC.put(prefixedKey, RedactingPatternConverter.redact(String.valueOf(v)));
                    appliedAttrKeys.add(prefixedKey);
                });
            }
            // PR #681 P0 defense-in-depth: a redactor a message-en SOURCE-szinten is fut
            String rawMessage = "event=" + eventType;
            String message = RedactingPatternConverter.redact(rawMessage);
            switch (level) {
                case "ERROR" -> {
                    if (cause != null) delegate.error(message, cause);
                    else delegate.error(message);
                }
                case "WARN" -> delegate.warn(message);
                case "INFO" -> delegate.info(message);
                case "DEBUG" -> delegate.debug(message);
                default -> delegate.info(message);
            }
        } finally {
            // takarits MDC-bol csak amit beraktunk (NE az osszeset,
            // mert a trace_id-t Micrometer Tracing manage-eli)
            MDC.remove("event_type");
            MDC.remove("error_code");
            MDC.remove("error_category");
            appliedAttrKeys.forEach(MDC::remove);
        }
    }

    /**
     * A {@code VV-<KATEGORIA>-NNN} formatumbol kiolvassa a kategoriat.
     * Lasd packages/shared-logging/error-codes.yaml-t a teljes listahoz.
     */
    private static String categoryFromCode(String errorCode) {
        if (errorCode == null || !errorCode.startsWith("VV-")) return null;
        int firstDash = 2;
        int secondDash = errorCode.indexOf('-', firstDash + 1);
        if (secondDash < 0) return null;
        String code = errorCode.substring(firstDash + 1, secondDash);
        return switch (code) {
            case "AML" -> "AML";
            case "BIZ" -> "BUSINESS";
            case "RATE" -> "BUSINESS";
            case "MT", "SEC" -> "SECURITY";
            case "SYNC", "TECH" -> "TECHNICAL";
            case "NET" -> "NETWORK";
            case "REG", "VOICE" -> "INTEGRATION";
            default -> null;
        };
    }
}
