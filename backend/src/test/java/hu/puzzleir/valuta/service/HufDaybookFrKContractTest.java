package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.daybook.HufDaybookRowDto;
import hu.puzzleir.valuta.entity.ShipmentRequest;
import hu.puzzleir.valuta.entity.Transfer;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.fail;

/**
 * FKH-022 kiegészítés (RED-fázis): adatmodell- és DTO-kontraktus tesztek FR-K2/FR-K3-hoz.
 *
 * <p>Ezek a tesztek Docker/Testcontainers NÉLKÜL is futnak (lokális RED-bizonyíték),
 * és a viselkedés-alapú Postgres-integrációs tesztek ({@code ...FrK2PostgresTest},
 * {@code ...FrK3PostgresTest}, {@code ...FrK6PostgresTest}) kiegészítői:
 * a hiányzó entity-mezőket/DTO-mezőt rögzítik szerkezeti kontraktusként.
 * Az implementáció után módosítás nélkül válnak zölddé.</p>
 */
class HufDaybookFrKContractTest {

    @Test
    @DisplayName("FR-K2: a Transfer entity-n létezik az annualJournalSequence mező (annual_journal_sequence oszlop párja)")
    void transferEntityHasAnnualJournalSequenceField() {
        assertDeclaredField(Transfer.class, "annualJournalSequence",
                "RED (FR-K2): a transfer tábla éves naplókönyv-sorszám mezője még nem létezik "
                        + "(Transfer.annualJournalSequence + Flyway ADD COLUMN migráció szükséges)");
    }

    @Test
    @DisplayName("FR-K2/3: a Transfer entity-n létezik a stornoJournalSequence mező (a sztornó-sor SAJÁT sorszáma)")
    void transferEntityHasStornoJournalSequenceField() {
        assertDeclaredField(Transfer.class, "stornoJournalSequence",
                "RED (FR-K2/3): a transfer sztornó-sor önálló naplókönyv-sorszám mezője még nem létezik "
                        + "(Transfer.stornoJournalSequence)");
    }

    @Test
    @DisplayName("FR-K2/3: a ShipmentRequest entity-n létezik a stornoJournalSequence mező (a sztornó-sor SAJÁT sorszáma)")
    void shipmentRequestEntityHasStornoJournalSequenceField() {
        assertDeclaredField(ShipmentRequest.class, "stornoJournalSequence",
                "RED (FR-K2/3): a shipment_request sztornó-sor önálló naplókönyv-sorszám mezője még nem "
                        + "létezik (ShipmentRequest.stornoJournalSequence)");
    }

    @Test
    @DisplayName("FR-K3: a HufDaybookRowDto-n létezik a partnerCode mező (partner-azonosító oszlop)")
    void hufDaybookRowDtoHasPartnerCodeField() {
        assertDeclaredField(HufDaybookRowDto.class, "partnerCode",
                "RED (FR-K3): a naplókönyv-sor partner-azonosító mezője még nem létezik "
                        + "(HufDaybookRowDto.partnerCode: numerikus pénztárszám VAGY counterparty betűkód)");
    }

    private static void assertDeclaredField(Class<?> type, String fieldName, String redMessage) {
        try {
            assertThat(type.getDeclaredField(fieldName)).isNotNull();
        } catch (NoSuchFieldException e) {
            fail(redMessage);
        }
    }
}
