package hu.puzzleir.valuta.logging;

import ch.qos.logback.classic.pattern.ClassicConverter;
import ch.qos.logback.classic.spi.ILoggingEvent;

import java.util.regex.Pattern;

/**
 * EBC Valutavalto - Logback custom converter PII redactor-ral.
 *
 * <p>Forras: vault/feedback/valutavalto-belso-log-audit-modul-tervezet-2026-05-18.md (5.5)
 *
 * <p>Hasznalat a logback-spring.xml-ben:
 * <pre>{@code
 *   <conversionRule conversionWord="redact"
 *                   converterClass="hu.puzzleir.valuta.logging.RedactingPatternConverter"/>
 *   <encoder>
 *     <pattern>%redact(%msg)</pattern>
 *   </encoder>
 * }</pre>
 *
 * <p>Redakt-olja a kovetkezo mintakat (jelszo, JWT, IBAN, kartyaszam, OpenAI-kulcs,
 * Bearer token, magyar adoszam, szemelyi szam, email cim):
 *
 * <p>FONTOS: ez NEM helyettesiti a strukturalt logolas mezo-szintu redactor-at
 * (a {@link VVLogger} az `attrs` mezoket nev alapjan is mossa). Ez egy
 * defense-in-depth resz: ha valaki regress-modon nyersen logol egy stringet,
 * a regex meg igy is elkapja.
 */
public final class RedactingPatternConverter extends ClassicConverter {

    private static final Pattern OPENAI_KEY = Pattern.compile("sk-(?:proj|svcacct)-[A-Za-z0-9_-]{20,}");
    private static final Pattern JWT_PATTERN = Pattern.compile(
            "eyJ[A-Za-z0-9_-]{10,}\\.[A-Za-z0-9_-]{10,}\\.[A-Za-z0-9_-]{10,}");
    private static final Pattern BEARER = Pattern.compile("(?i)Bearer\\s+[A-Za-z0-9._\\-+/=]{20,}");
    private static final Pattern IBAN = Pattern.compile("\\b[A-Z]{2}\\d{2}[A-Z0-9]{4,30}\\b");
    private static final Pattern CARD_PAN = Pattern.compile("\\b(?:\\d[ -]*?){13,19}\\b");
    private static final Pattern HU_ID_CARD = Pattern.compile("\\b\\d{6}[A-Z]{2}\\b");
    private static final Pattern EMAIL_PATTERN = Pattern.compile(
            "\\b[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}\\b");
    // A magyar adoszam regex (10 jegyu) extremul agresszivnek tunhet (sok tranzakcio-szam
    // is 10 jegyu lenne), ezert csak akkor mosogep, ha a kontextusban `taxId|adoszam|tax_id`
    // szo van a 30 char-on belul. Egyelore csak password-szeruen mukodik.

    @Override
    public String convert(ILoggingEvent event) {
        String formatted = event.getFormattedMessage();
        if (formatted == null || formatted.isEmpty()) return formatted;
        return redact(formatted);
    }

    /**
     * Test-only public hozzaferes a redact logikahoz (a {@code
     * RedactingPatternConverterTest}-bol hivhato unit teszt).
     */
    public static String redact(String input) {
        if (input == null) return null;
        String out = input;
        // Sorrendben: leghatekonyabb (legszigorubb) elsoként
        out = OPENAI_KEY.matcher(out).replaceAll("[OPENAI_KEY]");
        out = JWT_PATTERN.matcher(out).replaceAll("[JWT]");
        out = BEARER.matcher(out).replaceAll("Bearer [REDACTED]");
        out = EMAIL_PATTERN.matcher(out).replaceAll("[EMAIL]");
        out = IBAN.matcher(out).replaceAll("[IBAN]");
        out = CARD_PAN.matcher(out).replaceAll("[PAN]");
        out = HU_ID_CARD.matcher(out).replaceAll("[IDCARD]");
        return out;
    }
}
