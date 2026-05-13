package hu.puzzleir.valuta.entity;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.NullAndEmptySource;
import org.junit.jupiter.params.provider.ValueSource;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * ForeignStatus enum tesztek — v2.5.50+ (2026-05-13).
 *
 * <p>Biztosítjuk, hogy a parseOrNull() biztonságosan kezeli a null/üres/case-elférő/
 * érvénytelen értékeket.</p>
 */
class ForeignStatusTest {

    @Test
    @DisplayName("Standard értékek: DOMESTIC + FOREIGN")
    void enumValues_haveCorrectDisplayNames() {
        assertThat(ForeignStatus.DOMESTIC.getDisplayName()).isEqualTo("Belföldi");
        assertThat(ForeignStatus.FOREIGN.getDisplayName()).isEqualTo("Külföldi");
        assertThat(ForeignStatus.values()).hasSize(2);
    }

    @Test
    @DisplayName("parseOrNull: DOMESTIC string → enum DOMESTIC")
    void parseOrNull_domesticUpper_returnsEnum() {
        assertThat(ForeignStatus.parseOrNull("DOMESTIC")).isEqualTo(ForeignStatus.DOMESTIC);
    }

    @Test
    @DisplayName("parseOrNull: FOREIGN string → enum FOREIGN")
    void parseOrNull_foreignUpper_returnsEnum() {
        assertThat(ForeignStatus.parseOrNull("FOREIGN")).isEqualTo(ForeignStatus.FOREIGN);
    }

    @ParameterizedTest
    @ValueSource(strings = {"domestic", "Domestic", "DoMeStIc", "  domestic  ", "domestic\n"})
    @DisplayName("parseOrNull: case-insensitive + whitespace trim → DOMESTIC")
    void parseOrNull_variousCaseAndWhitespace_normalizesToDomestic(String input) {
        assertThat(ForeignStatus.parseOrNull(input)).isEqualTo(ForeignStatus.DOMESTIC);
    }

    @ParameterizedTest
    @ValueSource(strings = {"foreign", "Foreign", "fOrEiGn", "  FOREIGN  "})
    @DisplayName("parseOrNull: case-insensitive + whitespace trim → FOREIGN")
    void parseOrNull_variousCaseAndWhitespace_normalizesToForeign(String input) {
        assertThat(ForeignStatus.parseOrNull(input)).isEqualTo(ForeignStatus.FOREIGN);
    }

    @ParameterizedTest
    @NullAndEmptySource
    @ValueSource(strings = {"   ", "\t", "\n"})
    @DisplayName("parseOrNull: null/üres/whitespace-only → null")
    void parseOrNull_nullOrBlank_returnsNull(String input) {
        assertThat(ForeignStatus.parseOrNull(input)).isNull();
    }

    @ParameterizedTest
    @ValueSource(strings = {"INVALID", "belfoldi", "kulfoldi", "DOMESTIC_EXTRA", "OTHER", "X"})
    @DisplayName("parseOrNull: érvénytelen érték → null (NEM dob exception-t)")
    void parseOrNull_invalidValue_returnsNull(String input) {
        assertThat(ForeignStatus.parseOrNull(input)).isNull();
    }

    @Test
    @DisplayName("parseOrNull: NULL explicit string érték → null")
    void parseOrNull_explicitNullString_returnsNull() {
        // A frontend néha null-t küldhet "null" string-ként
        assertThat(ForeignStatus.parseOrNull("null")).isNull();
    }
}
