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
    // IBAN: szigorubb hossz-korlat (HU 28 char tipikus), 11..30 az alanumeric body
    private static final Pattern IBAN = Pattern.compile("\\b[A-Z]{2}\\d{2}[A-Z0-9]{11,30}\\b");
    private static final Pattern EMAIL_PATTERN = Pattern.compile(
            "\\b[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}\\b");

    // Copilot PR #681 P1: a sima 13-19 digit pattern false-positive-okra szuretik
    // (W3C trace ID, UUID hex, NAV bizonylat, transaction ID). IIN prefix-szel
    // kezdje: Visa(4), MasterCard(51..55), Amex(34/37), Discover(6011/65xx).
    private static final Pattern CARD_PAN = Pattern.compile(
            "\\b(?:4\\d{12}(?:\\d{3})?|5[1-5]\\d{14}|3[47]\\d{13}|6(?:011|5\\d{2})\\d{12})\\b");

    // Copilot PR #681 P1: magyar szig.szam (6+2) es adoszam (10 jegy) NEM
    // szabad kontextus nelkul redact-elni. Csak akkor moss, ha a kornyezetben
    // a megfelelo kulcsszo van (~5 char keret-en belul). A {2} capture group a
    // tenyleges szam, az {1} a kulcsszo - mindketto megmarad.
    private static final Pattern HU_ID_CARD_CTX = Pattern.compile(
            "(?i)(szig\\.?szam|szemelyi\\.?ig\\.?|id[_-]?card|identity[_-]?card)([^A-Za-z0-9]{0,5})(\\d{6}[A-Z]{2})");
    private static final Pattern HU_TAX_ID_CTX = Pattern.compile(
            "(?i)(adoszam|tax[_-]?id)([^A-Za-z0-9]{0,5})(\\d{10})");

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
        // Kontextus-fuggo: a kulcsszo + szeparator megmarad, csak a tenyleges
        // ertek redact-olodik (group 1 = kulcsszo, 2 = separator, 3 = ertek)
        out = HU_ID_CARD_CTX.matcher(out).replaceAll("$1$2[IDCARD]");
        out = HU_TAX_ID_CTX.matcher(out).replaceAll("$1$2[TAXID]");
        return out;
    }
}
