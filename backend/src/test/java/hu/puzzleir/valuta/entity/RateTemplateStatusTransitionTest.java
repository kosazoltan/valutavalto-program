package hu.puzzleir.valuta.entity;

import hu.puzzleir.valuta.entity.RateTemplate.RateTemplateStatus;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * RateTemplateStatus state machine (VV-ELVI v2 5.2) — megengedett átmenetek tesztje.
 *
 * <p>Az átmenettábla a tényleges service-logikát tükrözi (egyetlen igazságforrás):
 * approve = DRAFT→APPROVED, publish = DRAFT|APPROVED→PUBLISHED, revoke = APPROVED|PUBLISHED→REVOKED.
 */
class RateTemplateStatusTransitionTest {

    @Test
    @DisplayName("DRAFT → APPROVED/PUBLISHED megengedett; DRAFT → REVOKED tiltott (DRAFT nem vonható vissza)")
    void draftTransitions() {
        assertThat(RateTemplateStatus.DRAFT.canTransitionTo(RateTemplateStatus.APPROVED)).isTrue();
        assertThat(RateTemplateStatus.DRAFT.canTransitionTo(RateTemplateStatus.PUBLISHED)).isTrue();
        assertThat(RateTemplateStatus.DRAFT.canTransitionTo(RateTemplateStatus.REVOKED)).isFalse();
    }

    @Test
    @DisplayName("APPROVED → PUBLISHED/REVOKED megengedett; APPROVED → DRAFT tiltott")
    void approvedTransitions() {
        assertThat(RateTemplateStatus.APPROVED.canTransitionTo(RateTemplateStatus.PUBLISHED)).isTrue();
        assertThat(RateTemplateStatus.APPROVED.canTransitionTo(RateTemplateStatus.REVOKED)).isTrue();
        assertThat(RateTemplateStatus.APPROVED.canTransitionTo(RateTemplateStatus.DRAFT)).isFalse();
    }

    @Test
    @DisplayName("PUBLISHED → REVOKED megengedett; PUBLISHED → DRAFT/APPROVED tiltott")
    void publishedTransitions() {
        assertThat(RateTemplateStatus.PUBLISHED.canTransitionTo(RateTemplateStatus.REVOKED)).isTrue();
        assertThat(RateTemplateStatus.PUBLISHED.canTransitionTo(RateTemplateStatus.DRAFT)).isFalse();
        assertThat(RateTemplateStatus.PUBLISHED.canTransitionTo(RateTemplateStatus.APPROVED)).isFalse();
    }

    @Test
    @DisplayName("REVOKED terminális; null/önmaga nincs átmenet")
    void revokedTerminalAndNull() {
        assertThat(RateTemplateStatus.REVOKED.isTerminal()).isTrue();
        for (RateTemplateStatus t : RateTemplateStatus.values()) {
            assertThat(RateTemplateStatus.REVOKED.canTransitionTo(t)).isFalse();
        }
        assertThat(RateTemplateStatus.DRAFT.canTransitionTo(null)).isFalse();
        assertThat(RateTemplateStatus.DRAFT.canTransitionTo(RateTemplateStatus.DRAFT)).isFalse();
    }

    @Test
    @DisplayName("DRAFT/APPROVED/PUBLISHED nem-terminális (van kimenő átmenetük)")
    void nonTerminalStates() {
        for (RateTemplateStatus s : new RateTemplateStatus[]{
                RateTemplateStatus.DRAFT, RateTemplateStatus.APPROVED, RateTemplateStatus.PUBLISHED}) {
            assertThat(s.isTerminal()).as("%s nem terminális", s).isFalse();
        }
    }
}
