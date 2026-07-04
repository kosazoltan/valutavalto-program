package hu.puzzleir.valuta.logging;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.time.Duration;

import static org.assertj.core.api.Assertions.assertThat;
import static org.junit.jupiter.api.Assertions.assertTimeoutPreemptively;

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
    @DisplayName("Kartyaszam Visa 16 jegy IIN prefix-szel redact-olva [PAN]-re")
    void redact_cardPan_visa_isMasked() {
        // Visa IIN: 4xxxxxxx... (16 jegy total)
        String input = "Kartyaszam: 4111111111111111";
        String output = RedactingPatternConverter.redact(input);
        assertThat(output).doesNotContain("4111111111111111");
        assertThat(output).contains("[PAN]");
    }

    @Test
    @DisplayName("Copilot PR #681 P1: W3C trace ID 16-32 hex NEM redact-olva [PAN]-kent")
    void redact_traceId_notMaskedAsPan() {
        // W3C trace ID format: 32 hex chars (NEM 13-19 digit kartya pattern)
        String input = "trace=4bf92f3577b34da6a3ce929d0e0e4736";
        String output = RedactingPatternConverter.redact(input);
        assertThat(output).contains("4bf92f3577b34da6a3ce929d0e0e4736");
        assertThat(output).doesNotContain("[PAN]");
    }

    @Test
    @DisplayName("Copilot PR #681 P1: NAV bizonylat (V123456789, 9-10 jegy) NEM redact-olva [PAN]-kent")
    void redact_navReceipt_notMaskedAsPan() {
        // Tipikus bizonylat: 13 jegy random number-rel, NEM kezdodik 4/5/3/6-tal IIN-modra
        String input = "bizonylat=V234567000001";
        String output = RedactingPatternConverter.redact(input);
        assertThat(output).contains("V234567000001");
        assertThat(output).doesNotContain("[PAN]");
    }

    @Test
    @DisplayName("Copilot PR #681 P1: hu_tax_id csak kontextus-fuggo (adoszam kulcsszo)")
    void redact_huTaxId_onlyWithContext() {
        // Kontextus nelkul: NEM redact-olja a 10 jegyu szamot (lehet sequence ID)
        String inputNoCtx = "kezel_id=1234567890";
        String outputNoCtx = RedactingPatternConverter.redact(inputNoCtx);
        assertThat(outputNoCtx).contains("1234567890");

        // Kontextusban: redact (a kulcsszo megmarad, az ertek elveszik)
        String inputCtx = "adoszam: 1234567890 tovabbi adat";
        String outputCtx = RedactingPatternConverter.redact(inputCtx);
        assertThat(outputCtx).contains("adoszam");
        assertThat(outputCtx).contains("[TAXID]");
        assertThat(outputCtx).doesNotContain("1234567890");
    }

    @Test
    @DisplayName("Copilot PR #681 P1: hu_id_card csak kontextus-fuggo (szigszam kulcsszo)")
    void redact_huIdCard_onlyWithContext() {
        // Kontextus nelkul: a 6 digit + 2 letter pattern NEM redact
        String inputNoCtx = "receipt=123456AB";
        String outputNoCtx = RedactingPatternConverter.redact(inputNoCtx);
        assertThat(outputNoCtx).contains("123456AB");

        // Kontextusban: redact
        String inputCtx = "szig.szam: 123456AB megjegyzes";
        String outputCtx = RedactingPatternConverter.redact(inputCtx);
        assertThat(outputCtx).contains("[IDCARD]");
        assertThat(outputCtx).doesNotContain("123456AB");
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

    @Test
    @DisplayName("Adverzarial email input teljes redact() alatt 2s-on belul lefut")
    void redact_adversarialEmailInput_finishesUnderTimeout() {
        String adversarial = "a".repeat(50_000) + "@" + "a.".repeat(25_000);
        String output = assertTimeoutPreemptively(
                Duration.ofSeconds(2), () -> RedactingPatternConverter.redact(adversarial));
        assertThat(output).isNotNull();
    }

    @Test
    @DisplayName("Adverzarial nem-email mintak teljes redact() alatt 2s-on belul lefutnak")
    void redact_allPatterns_adversarialInputs_underTimeout() {
        assertTimeoutPreemptively(Duration.ofSeconds(2), () -> {
            String jwtLike = "eyJ" + "aaaaaaaaaa.".repeat(9_000);
            String bearerLike = "Bearer " + "A.".repeat(45_000);
            String ibanLike = "HU" + "4".repeat(90_000);

            assertThat(RedactingPatternConverter.redact(jwtLike)).isNotNull();
            assertThat(RedactingPatternConverter.redact(bearerLike)).isNotNull();
            assertThat(RedactingPatternConverter.redact(ibanLike)).isNotNull();
        });
    }

    @Test
    @DisplayName("Ures string valtozatlanul ures string marad")
    void redact_emptyString_returnsEmpty() {
        assertThat(RedactingPatternConverter.redact("")).isEmpty();
    }

    @Test
    @DisplayName("OpenAI sk-svcacct- kulcs redact-olva [OPENAI_KEY]-re")
    void redact_openaiSvcacctKey_isMasked() {
        String key = "sk-svcacct-" + "AbcdefghijklmnopQRST_123";
        String input = "OpenAI service account key: " + key;

        String output = RedactingPatternConverter.redact(input);

        assertThat(output).contains("[OPENAI_KEY]");
        assertThat(output).doesNotContain(key);
    }

    @Test
    @DisplayName("Bearer-ben levo JWT-t elobb a JWT pattern maszkolja")
    void redact_bearerWithJwt_jwtWinsInOrder() {
        String token = "eyJ" + "a".repeat(20) + "." + "b".repeat(20) + "." + "c".repeat(20);
        String input = "Authorization: Bearer " + token;

        String output = RedactingPatternConverter.redact(input);

        assertThat(output).contains("Bearer [JWT]");
        assertThat(output).doesNotContain("a".repeat(20)).doesNotContain("b".repeat(20)).doesNotContain("c".repeat(20));
    }

    @Test
    @DisplayName("Hosszu PII-mentes input gyors es valtozatlan marad")
    void redact_longCleanInput_unchangedAndFast() {
        String input = "Tranzakcio 50000 EUR vetel sikeres. ".repeat(5_556);

        String output = assertTimeoutPreemptively(Duration.ofSeconds(2), () -> RedactingPatternConverter.redact(input));

        assertThat(output).isEqualTo(input);
    }
}
