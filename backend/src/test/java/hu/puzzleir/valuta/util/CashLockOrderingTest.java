package hu.puzzleir.valuta.util;

import hu.puzzleir.valuta.util.CashLockOrdering.BranchCurrencyKey;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.function.BiConsumer;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * CashLockOrdering — determinisztikus cash_balance lock-sorrend (deadlock-megelozes) unit tesztek.
 *
 * A korkoros varakozas (AB-BA deadlock) kizarasanak elofeltetele: MINDEN szal UGYANABBAN a teljes
 * rendezesben szerzi meg a lockokat. A teszt ezt igazolja: a lock-hivasok sorrendje az INPUT
 * sorrendtol FUGGETLENUL a rogzitett globalis rendezes.
 */
class CashLockOrderingTest {

    private static final UUID BRANCH_A = UUID.fromString("00000000-0000-0000-0000-00000000000a");
    private static final UUID BRANCH_B = UUID.fromString("00000000-0000-0000-0000-00000000000b");

    private List<String> recorder() {
        return new ArrayList<>();
    }

    private BiConsumer<UUID, Long> recordingLock(List<String> sink) {
        return (branchId, currencyId) -> sink.add(branchId + ":" + currencyId);
    }

    // === single-branch (#947) — NOVEKVO currencyId ===

    @Test
    @DisplayName("lockInAscendingCurrencyOrder: NOVEKVO currencyId sorrend, az input sorrendtol fuggetlenul")
    void ascending_sortsByCurrencyIdRegardlessOfInputOrder() {
        List<String> locked = recorder();
        // Input: szandekosan FORDITOTT/kevert sorrend.
        CashLockOrdering.lockInAscendingCurrencyOrder(BRANCH_A, recordingLock(locked), 10L, 1L, 5L);

        assertThat(locked).containsExactly(BRANCH_A + ":1", BRANCH_A + ":5", BRANCH_A + ":10");
    }

    @Test
    @DisplayName("lockInAscendingCurrencyOrder: dedup + null-kihagyas")
    void ascending_dedupesAndSkipsNulls() {
        List<String> locked = recorder();
        CashLockOrdering.lockInAscendingCurrencyOrder(BRANCH_A, recordingLock(locked), 1L, 1L, null, 5L);

        assertThat(locked).containsExactly(BRANCH_A + ":1", BRANCH_A + ":5");
    }

    // === cross-branch — globalis (branchId, currencyId) rendezes ===

    @Test
    @DisplayName("lockBranchCurrencyPairsInGlobalOrder: (branchId, majd currencyId) globalis sorrend, input-fuggetlen")
    void crossBranch_sortsByBranchThenCurrencyRegardlessOfInputOrder() {
        List<String> locked = recorder();
        // Input: kevert sorrend (B/10, A/5, A/1, B/1).
        CashLockOrdering.lockBranchCurrencyPairsInGlobalOrder(recordingLock(locked),
                new BranchCurrencyKey(BRANCH_B, 10L),
                new BranchCurrencyKey(BRANCH_A, 5L),
                new BranchCurrencyKey(BRANCH_A, 1L),
                new BranchCurrencyKey(BRANCH_B, 1L));

        // Elvart: eloszor branch (A < B), azon belul currencyId novekvo.
        assertThat(locked).containsExactly(
                BRANCH_A + ":1", BRANCH_A + ":5", BRANCH_B + ":1", BRANCH_B + ":10");
    }

    @Test
    @DisplayName("lockBranchCurrencyPairsInGlobalOrder: a FORDITOTT iranyu hivas UGYANAZT a sorrendet adja (AB-BA kizart)")
    void crossBranch_reverseDirectionProducesSameOrder() {
        List<String> forward = recorder();
        CashLockOrdering.lockBranchCurrencyPairsInGlobalOrder(recordingLock(forward),
                new BranchCurrencyKey(BRANCH_A, 7L),
                new BranchCurrencyKey(BRANCH_B, 7L));

        List<String> reverse = recorder();
        // Forditott iranyu muvelet (B->A) ugyanazt a ket sort lockolja, de forditott INPUT sorrendben.
        CashLockOrdering.lockBranchCurrencyPairsInGlobalOrder(recordingLock(reverse),
                new BranchCurrencyKey(BRANCH_B, 7L),
                new BranchCurrencyKey(BRANCH_A, 7L));

        // A ket lock-sorrend AZONOS -> nincs AB-BA korkoros varakozas.
        assertThat(forward).containsExactly(BRANCH_A + ":7", BRANCH_B + ":7");
        assertThat(reverse).isEqualTo(forward);
    }

    @Test
    @DisplayName("lockBranchCurrencyPairsInGlobalOrder: dedup + null kulcs/branch/currency kihagyas")
    void crossBranch_dedupesAndSkipsNulls() {
        List<String> locked = recorder();
        CashLockOrdering.lockBranchCurrencyPairsInGlobalOrder(recordingLock(locked),
                new BranchCurrencyKey(BRANCH_A, 1L),
                new BranchCurrencyKey(BRANCH_A, 1L),   // duplikatum
                null,                                   // null kulcs
                new BranchCurrencyKey(BRANCH_A, null),  // null currency
                new BranchCurrencyKey(null, 5L));       // null branch

        assertThat(locked).containsExactly(BRANCH_A + ":1");
    }
}
