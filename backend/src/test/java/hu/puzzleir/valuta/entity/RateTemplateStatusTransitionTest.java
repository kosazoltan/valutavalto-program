package hu.puzzleir.valuta.entity;

import hu.puzzleir.valuta.entity.RateTemplate.RateTemplateStatus;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * RateTemplateStatus state machine (VV-ELVI v2 5.2) — megengedett átmenetek tesztje.
 */
class RateTemplateStatusTransitionTest {

    @Test
    @DisplayName("DRAFT → APPROVED/REVOKED; DRAFT → PUBLISHED tiltott (jóváhagyás kihagyása)")
    void draftTransitions() {
        assertTrue(RateTemplateStatus.DRAFT.canTransitionTo(RateTemplateStatus.APPROVED));
        assertTrue(RateTemplateStatus.DRAFT.canTransitionTo(RateTemplateStatus.REVOKED));
        assertFalse(RateTemplateStatus.DRAFT.canTransitionTo(RateTemplateStatus.PUBLISHED));
    }

    @Test
    @DisplayName("APPROVED → PUBLISHED/DRAFT/REVOKED megengedett")
    void approvedTransitions() {
        assertTrue(RateTemplateStatus.APPROVED.canTransitionTo(RateTemplateStatus.PUBLISHED));
        assertTrue(RateTemplateStatus.APPROVED.canTransitionTo(RateTemplateStatus.DRAFT));
        assertTrue(RateTemplateStatus.APPROVED.canTransitionTo(RateTemplateStatus.REVOKED));
    }

    @Test
    @DisplayName("PUBLISHED → REVOKED megengedett; PUBLISHED → DRAFT/APPROVED tiltott")
    void publishedTransitions() {
        assertTrue(RateTemplateStatus.PUBLISHED.canTransitionTo(RateTemplateStatus.REVOKED));
        assertFalse(RateTemplateStatus.PUBLISHED.canTransitionTo(RateTemplateStatus.DRAFT));
        assertFalse(RateTemplateStatus.PUBLISHED.canTransitionTo(RateTemplateStatus.APPROVED));
    }

    @Test
    @DisplayName("REVOKED terminális; null/önmaga nincs átmenet")
    void revokedTerminalAndNull() {
        assertTrue(RateTemplateStatus.REVOKED.isTerminal());
        for (RateTemplateStatus t : RateTemplateStatus.values()) {
            assertFalse(RateTemplateStatus.REVOKED.canTransitionTo(t));
        }
        assertFalse(RateTemplateStatus.DRAFT.canTransitionTo(null));
        assertFalse(RateTemplateStatus.DRAFT.canTransitionTo(RateTemplateStatus.DRAFT));
    }
}
