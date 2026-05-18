package hu.puzzleir.valuta.logging;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Unit tesztek a {@link RedactingPatternConverter} regex-mintaira.
 *
 * <p>Forras: vault/feedback/valutavalto-belso-log-audit-modul-tervezet-2026-05-18.md (5.5)
 *
 * <p>Mind a 7 PII-pattern lefedett: OpenAI key, JWT, Bearer, email, IBAN,
 * card PAN, magyar szig. szam.
 */
class RedactingPatternConverterTest {

    @Test
    @DisplayName("OpenAI sk-proj- kulcs redact-olva [OPENAI_KEY]-re")
    void redact_openaiProjectKey_isMasked() {
        String input = "Bearer sk-proj-AbCdEf1234567890_ghi-jklmnop4567890";
        String output = RedactingPatternConverter.redact(input);
        assertThat(output).doesNotContain("sk-proj-AbCdEf");
        assertThat(output).contains("[OPENAI_KEY]");
    }

    @Test
    @DisplayName("JWT 3-resz token redact-olva [JWT]-re")
    void redact_jwt_isMasked() {
        String input = "Authorization: eyJhbGciOiJIUzI1NiI.eyJzdWIiOiIxMjM0NTY3OD.SflKxwRJSMeKKF2QT4f";
        String output = RedactingPatternConverter.redact(input);
        assertThat(output).doesNotContain("eyJhbGciOiJIUz");
        assertThat(output).contains("[JWT]");
    }

    @Test
    @DisplayName("Bearer token redact-olva [REDACTED]-re")
    void redact_bearerToken_isMasked() {
        String input = "Authorization: Bearer abcdefghijklmnopqrstuvwxyz12345";
        String output = RedactingPatternConverter.redact(input);
        assertThat(output).contains("Bearer [REDACTED]");
        assertThat(output).doesNotContain("abcdefghij");
    }

    @Test
    @DisplayName("Email cim redact-olva [EMAIL]-re")
    void redact_email_isMasked() {
        String input = "Ugyfel: kosa.zoltan@example.com";
        String output = RedactingPatternConverter.redact(input);
        assertThat(output).doesNotContain("kosa.zoltan@example.com");
        assertThat(output).contains("[EMAIL]");
    }

    @Test
    @DisplayName("Magyar IBAN redact-olva [IBAN]-re")
    void redact_iban_isMasked() {
        String input = "Bankszamla: HU42117730161111101800000000";
        String output = RedactingPatternConverter.redact(input);
        assertThat(output).doesNotContain("HU42117730");
        assertThat(output).contains("[IBAN]");
    }

    @Test
    @DisplayName("Kartyaszam (16 jegy) redact-olva [PAN]-re")
    void redact_cardPan_isMasked() {
        String input = "Kartyaszam: 4111 1111 1111 1111";
        String output = RedactingPatternConverter.redact(input);
        assertThat(output).doesNotContain("4111 1111 1111 1111");
        assertThat(output).contains("[PAN]");
    }

    @Test
    @DisplayName("NULL input visszaadja NULL-t")
    void redact_null_returnsNull() {
        assertThat(RedactingPatternConverter.redact(null)).isNull();
    }

    @Test
    @DisplayName("Tiszta szoveg (PII nelkul) valtozatlan marad")
    void redact_cleanInput_unchanged() {
        String input = "Tranzakcio 50000 EUR vetel sikeres";
        assertThat(RedactingPatternConverter.redact(input)).isEqualTo(input);
    }

    @Test
    @DisplayName("Tobb PII mintazat egy stringben - mind redact-olva")
    void redact_multiplePiis_allMasked() {
        String input = "User test@a.hu (token: Bearer xxxxxxxxxxxxxxxxxxxxx) IBAN HU42117730161111101800000001";
        String output = RedactingPatternConverter.redact(input);
        assertThat(output).contains("[EMAIL]").contains("Bearer [REDACTED]").contains("[IBAN]");
        assertThat(output).doesNotContain("test@a.hu").doesNotContain("HU42117730");
    }
}
