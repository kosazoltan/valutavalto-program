package hu.puzzleir.valuta.service;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Unit tesztek a {@link AuditEventService#computeHash} statikus metodushoz.
 *
 * <p>Lefedett invariansok:
 * <ul>
 *   <li>determinisztikus: ugyanaz a bemenet → ugyanaz a hash</li>
 *   <li>SHA-256 hossz: 64 hex karakter</li>
 *   <li>kulonbozo prev_hash → kulonbozo this_hash (lanc kovetkezo bejegyzes-fuggosege)</li>
 *   <li>kulonbozo event_type → kulonbozo this_hash</li>
 *   <li>kulonbozo after_state → kulonbozo this_hash</li>
 *   <li>NULL after_state nem doblja</li>
 * </ul>
 */
class AuditEventServiceHashChainTest {

    private static final String GENESIS = "0".repeat(64);
    private static final UUID FIXED_EVENT_ID = UUID.fromString("11111111-1111-1111-1111-111111111111");
    private static final Instant FIXED_TS = Instant.parse("2026-05-18T10:00:00Z");

    @Test
    @DisplayName("computeHash determinisztikus - ugyanaz input → ugyanaz output")
    void computeHash_isDeterministic() {
        String h1 = AuditEventService.computeHash(GENESIS, FIXED_EVENT_ID, FIXED_TS,
                "transaction.committed", "{\"amount\":50000}");
        String h2 = AuditEventService.computeHash(GENESIS, FIXED_EVENT_ID, FIXED_TS,
                "transaction.committed", "{\"amount\":50000}");
        assertThat(h1).isEqualTo(h2);
    }

    @Test
    @DisplayName("computeHash SHA-256 64 hex karakter hosszu")
    void computeHash_is64HexChars() {
        String h = AuditEventService.computeHash(GENESIS, FIXED_EVENT_ID, FIXED_TS,
                "transaction.committed", "{}");
        assertThat(h).hasSize(64);
        assertThat(h).matches("[0-9a-f]{64}");
    }

    @Test
    @DisplayName("Kulonbozo prev_hash → kulonbozo this_hash (lanc kotelez)")
    void computeHash_differsByPrev() {
        String h1 = AuditEventService.computeHash("a".repeat(64), FIXED_EVENT_ID, FIXED_TS,
                "transaction.committed", "{}");
        String h2 = AuditEventService.computeHash("b".repeat(64), FIXED_EVENT_ID, FIXED_TS,
                "transaction.committed", "{}");
        assertThat(h1).isNotEqualTo(h2);
    }

    @Test
    @DisplayName("Kulonbozo event_type → kulonbozo this_hash")
    void computeHash_differsByEventType() {
        String h1 = AuditEventService.computeHash(GENESIS, FIXED_EVENT_ID, FIXED_TS,
                "transaction.committed", "{}");
        String h2 = AuditEventService.computeHash(GENESIS, FIXED_EVENT_ID, FIXED_TS,
                "transaction.reverted", "{}");
        assertThat(h1).isNotEqualTo(h2);
    }

    @Test
    @DisplayName("Kulonbozo after_state → kulonbozo this_hash")
    void computeHash_differsByAfterState() {
        String h1 = AuditEventService.computeHash(GENESIS, FIXED_EVENT_ID, FIXED_TS,
                "transaction.committed", "{\"amount\":50000}");
        String h2 = AuditEventService.computeHash(GENESIS, FIXED_EVENT_ID, FIXED_TS,
                "transaction.committed", "{\"amount\":99999}");
        assertThat(h1).isNotEqualTo(h2);
    }

    @Test
    @DisplayName("NULL after_state nem doblja - barmely hash ervenyes")
    void computeHash_acceptsNullAfterState() {
        String h = AuditEventService.computeHash(GENESIS, FIXED_EVENT_ID, FIXED_TS,
                "rate.published", null);
        assertThat(h).hasSize(64);
    }

    @Test
    @DisplayName("3 esemeny lancban kovetik egymast (chain test)")
    void computeHash_chainOfThree() {
        UUID e1 = UUID.randomUUID();
        UUID e2 = UUID.randomUUID();
        UUID e3 = UUID.randomUUID();
        Instant t1 = Instant.parse("2026-05-18T10:00:00Z");
        Instant t2 = Instant.parse("2026-05-18T10:01:00Z");
        Instant t3 = Instant.parse("2026-05-18T10:02:00Z");

        String h1 = AuditEventService.computeHash(GENESIS, e1, t1, "tx.start", "{}");
        String h2 = AuditEventService.computeHash(h1, e2, t2, "tx.commit", "{\"amt\":1000}");
        String h3 = AuditEventService.computeHash(h2, e3, t3, "tx.posted", "{\"posted\":true}");

        assertThat(h1).isNotEqualTo(h2).isNotEqualTo(h3);
        assertThat(h2).isNotEqualTo(h3);
        // Tamper-detect: ha valaki h2-t modositja, h3 input-jaba mar nem fer be
        String h2Tampered = AuditEventService.computeHash(h1, e2, t2, "tx.commit", "{\"amt\":99999}");
        String h3OnTamperedChain = AuditEventService.computeHash(h2Tampered, e3, t3, "tx.posted", "{\"posted\":true}");
        assertThat(h3OnTamperedChain).isNotEqualTo(h3);
    }
}
