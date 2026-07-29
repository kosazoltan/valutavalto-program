package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.daybook.HufDaybookDto;

import java.lang.reflect.Field;
import java.math.BigDecimal;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.fail;

/**
 * FKH-022 kiegészítés FR-K4/FR-K5 (RED-fázis): DTO-kontraktus tesztek a Nyitó/Záró
 * egyenleghez és a nyomtatvány telephely-sorához.
 *
 * <p>A {@link HufDaybookFrKContractTest} mintáját követi: Docker/Testcontainers NÉLKÜL
 * is fut (lokális RED-bizonyíték), és a viselkedés-alapú tesztek
 * ({@code HufDaybookOpeningClosingFrK5PostgresTest}, {@code HufDaybookPdfFrK4Test})
 * kiegészítője — a hiányzó DTO-mezőket rögzíti szerkezeti kontraktusként.
 * Az implementáció után módosítás nélkül válik zölddé.</p>
 *
 * <p>Kontraktus-döntés (spec-hézag, dokumentálva a beadási jelentésben): a nyomtatvány
 * telephely-címe a DTO-n utazik ({@code branchAddress}), a {@code branchName} mintájára —
 * így a PDF-service DTO-vezérelt és mockolhatóan tesztelhető marad, nem kell külön
 * Branch-lekérés a PDF-rétegben.</p>
 */
class HufDaybookBalanceFrK45ContractTest {

    @Test
    @DisplayName("FR-K5: a HufDaybookDto-n létezik az openingBalanceHuf mező (BigDecimal — Nyitó egyenleg)")
    void dtoHasOpeningBalanceHufField() {
        assertFieldOfType("openingBalanceHuf", BigDecimal.class,
                "RED (FR-K5): a HufDaybookDto.openingBalanceHuf (Nyitó HUF-egyenleg, implicit horgonyú "
                        + "kumulált UF−FF a nap előtt) mező még nem létezik");
    }

    @Test
    @DisplayName("FR-K5: a HufDaybookDto-n létezik a closingBalanceHuf mező (BigDecimal — Záró egyenleg)")
    void dtoHasClosingBalanceHufField() {
        assertFieldOfType("closingBalanceHuf", BigDecimal.class,
                "RED (FR-K5): a HufDaybookDto.closingBalanceHuf (Záró = Nyitó + napi UF − napi FF) "
                        + "mező még nem létezik");
    }

    @Test
    @DisplayName("FR-K4: a HufDaybookDto-n létezik a branchAddress mező (String — a nyomtatvány telephely-sora)")
    void dtoHasBranchAddressField() {
        assertFieldOfType("branchAddress", String.class,
                "RED (FR-K4): a HufDaybookDto.branchAddress (telephely-cím a formázott nyomtatvány "
                        + "fejlécéhez, forrás: Branch.address) mező még nem létezik");
    }

    private static void assertFieldOfType(String fieldName, Class<?> expectedType, String redMessage) {
        try {
            Field field = HufDaybookDto.class.getDeclaredField(fieldName);
            assertThat(field.getType())
                    .as("A HufDaybookDto.%s mező típusa %s kell legyen", fieldName, expectedType.getSimpleName())
                    .isEqualTo(expectedType);
        } catch (NoSuchFieldException e) {
            fail(redMessage);
        }
    }
}
