package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Circular;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * A4 (b9-korlevelek FR-02) — a kötelező körlevél-nyugtázás tranzakció-blokkoló gate
 * tiszta, függőség-mentes logikája (TransactionService.circularAckBlockReason).
 */
class CircularAckGateTest {

    @Test
    @DisplayName("Enforcement KI → soha nem blokkol (akkor sem, ha van olvasatlan kötelező)")
    void disabledNeverBlocks() {
        List<Circular> unacked = List.of(Circular.builder().title("9. sz. körlevél").build());
        assertThat(TransactionService.circularAckBlockReason(unacked, false)).isNull();
    }

    @Test
    @DisplayName("Enforcement BE + nincs olvasatlan kötelező → nem blokkol")
    void enabledNoUnacked() {
        assertThat(TransactionService.circularAckBlockReason(List.of(), true)).isNull();
        assertThat(TransactionService.circularAckBlockReason(null, true)).isNull();
    }

    @Test
    @DisplayName("Enforcement BE + van olvasatlan kötelező → blokkol, a címeket felsorolja")
    void enabledBlocksWithTitles() {
        List<Circular> unacked = List.of(
                Circular.builder().title("9. sz. FATF körlevél").build(),
                Circular.builder().title("7. sz. bankkártya-csalás").build());
        String reason = TransactionService.circularAckBlockReason(unacked, true);
        assertThat(reason).isNotNull();
        assertThat(reason).contains("9. sz. FATF körlevél");
        assertThat(reason).contains("7. sz. bankkártya-csalás");
    }

    @Test
    @DisplayName("Enforcement BE + cím nélküli körlevél → blokkol, de nem dob NPE-t (üres cím-lista)")
    void enabledBlocksEvenWithoutTitle() {
        List<Circular> unacked = List.of(Circular.builder().build());
        String reason = TransactionService.circularAckBlockReason(unacked, true);
        assertThat(reason).isNotNull();
        assertThat(reason).contains("nyugtázni kell");
    }
}
