package hu.puzzleir.valuta.entity;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * TransactionStatus state machine (VV-ELVI v2 5.1) — megengedett átmenetek tesztje.
 */
class TransactionStatusTransitionTest {

    @Test
    @DisplayName("PENDING → COMPLETED/FAILED/CANCELLED megengedett; PENDING → REVERSED/ARCHIVED tiltott")
    void pendingTransitions() {
        assertTrue(TransactionStatus.PENDING.canTransitionTo(TransactionStatus.COMPLETED));
        assertTrue(TransactionStatus.PENDING.canTransitionTo(TransactionStatus.FAILED));
        assertTrue(TransactionStatus.PENDING.canTransitionTo(TransactionStatus.CANCELLED));
        assertFalse(TransactionStatus.PENDING.canTransitionTo(TransactionStatus.REVERSED));
        assertFalse(TransactionStatus.PENDING.canTransitionTo(TransactionStatus.ARCHIVED));
    }

    @Test
    @DisplayName("COMPLETED → REVERSED/ARCHIVED megengedett; COMPLETED → PENDING tiltott")
    void completedTransitions() {
        assertTrue(TransactionStatus.COMPLETED.canTransitionTo(TransactionStatus.REVERSED));
        assertTrue(TransactionStatus.COMPLETED.canTransitionTo(TransactionStatus.ARCHIVED));
        assertFalse(TransactionStatus.COMPLETED.canTransitionTo(TransactionStatus.PENDING));
    }

    @Test
    @DisplayName("REVERSED → ARCHIVED megengedett; egyébként tiltott")
    void reversedTransitions() {
        assertTrue(TransactionStatus.REVERSED.canTransitionTo(TransactionStatus.ARCHIVED));
        assertFalse(TransactionStatus.REVERSED.canTransitionTo(TransactionStatus.COMPLETED));
    }

    @Test
    @DisplayName("FAILED / CANCELLED / ARCHIVED terminális — semmilyen átmenet nem megengedett")
    void terminalStates() {
        for (TransactionStatus terminal : new TransactionStatus[]{
                TransactionStatus.FAILED, TransactionStatus.CANCELLED, TransactionStatus.ARCHIVED}) {
            assertTrue(terminal.isTerminal(), terminal + " terminális");
            for (TransactionStatus target : TransactionStatus.values()) {
                assertFalse(terminal.canTransitionTo(target), terminal + " → " + target + " tiltott");
            }
        }
    }

    @Test
    @DisplayName("null célra és önmagába nincs átmenet")
    void nullAndSelf() {
        assertFalse(TransactionStatus.PENDING.canTransitionTo(null));
        assertFalse(TransactionStatus.PENDING.canTransitionTo(TransactionStatus.PENDING));
        assertFalse(TransactionStatus.COMPLETED.canTransitionTo(TransactionStatus.COMPLETED));
    }
}
