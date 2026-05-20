package hu.puzzleir.valuta.entity;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * TransactionStatus state machine (VV-ELVI v2 5.1) — megengedett átmenetek tesztje.
 */
class TransactionStatusTransitionTest {

    @Test
    @DisplayName("PENDING → COMPLETED/FAILED/CANCELLED megengedett; PENDING → REVERSED/ARCHIVED tiltott")
    void pendingTransitions() {
        assertThat(TransactionStatus.PENDING.canTransitionTo(TransactionStatus.COMPLETED)).isTrue();
        assertThat(TransactionStatus.PENDING.canTransitionTo(TransactionStatus.FAILED)).isTrue();
        assertThat(TransactionStatus.PENDING.canTransitionTo(TransactionStatus.CANCELLED)).isTrue();
        assertThat(TransactionStatus.PENDING.canTransitionTo(TransactionStatus.REVERSED)).isFalse();
        assertThat(TransactionStatus.PENDING.canTransitionTo(TransactionStatus.ARCHIVED)).isFalse();
    }

    @Test
    @DisplayName("COMPLETED → REVERSED/ARCHIVED megengedett; COMPLETED → PENDING tiltott")
    void completedTransitions() {
        assertThat(TransactionStatus.COMPLETED.canTransitionTo(TransactionStatus.REVERSED)).isTrue();
        assertThat(TransactionStatus.COMPLETED.canTransitionTo(TransactionStatus.ARCHIVED)).isTrue();
        assertThat(TransactionStatus.COMPLETED.canTransitionTo(TransactionStatus.PENDING)).isFalse();
    }

    @Test
    @DisplayName("REVERSED → ARCHIVED megengedett; egyébként tiltott")
    void reversedTransitions() {
        assertThat(TransactionStatus.REVERSED.canTransitionTo(TransactionStatus.ARCHIVED)).isTrue();
        assertThat(TransactionStatus.REVERSED.canTransitionTo(TransactionStatus.COMPLETED)).isFalse();
    }

    @Test
    @DisplayName("FAILED / CANCELLED / ARCHIVED terminális — semmilyen átmenet nem megengedett")
    void terminalStates() {
        for (TransactionStatus terminal : new TransactionStatus[]{
                TransactionStatus.FAILED, TransactionStatus.CANCELLED, TransactionStatus.ARCHIVED}) {
            assertThat(terminal.isTerminal()).as("%s terminális", terminal).isTrue();
            for (TransactionStatus target : TransactionStatus.values()) {
                assertThat(terminal.canTransitionTo(target)).as("%s → %s tiltott", terminal, target).isFalse();
            }
        }
    }

    @Test
    @DisplayName("PENDING / COMPLETED / REVERSED nem-terminális (van kimenő átmenetük)")
    void nonTerminalStates() {
        for (TransactionStatus s : new TransactionStatus[]{
                TransactionStatus.PENDING, TransactionStatus.COMPLETED, TransactionStatus.REVERSED}) {
            assertThat(s.isTerminal()).as("%s nem terminális", s).isFalse();
        }
    }

    @Test
    @DisplayName("null célra és önmagába nincs átmenet")
    void nullAndSelf() {
        assertThat(TransactionStatus.PENDING.canTransitionTo(null)).isFalse();
        assertThat(TransactionStatus.PENDING.canTransitionTo(TransactionStatus.PENDING)).isFalse();
        assertThat(TransactionStatus.COMPLETED.canTransitionTo(TransactionStatus.COMPLETED)).isFalse();
    }
}
