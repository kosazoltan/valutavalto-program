package hu.puzzleir.valuta.util;

import java.util.Arrays;
import java.util.Comparator;
import java.util.Objects;
import java.util.UUID;
import java.util.function.BiConsumer;

/**
 * Cash_balance lock-ordering — GLOBALIS, DETERMINISZTIKUS deadlock-megelozes.
 *
 * <p>Problema (pre-existing, #944 self-review): a cash_balance sorok PESSIMISTIC_WRITE lockolasanak
 * sorrendje NEM volt egyseges. A vetel (TransactionService.executeBuy) eloszor a HUF sort lockolta
 * (validateCurrencyStock(HUF)), majd a devizat; az eladas (executeSell), a sztorno
 * (TransactionReversalService.executeReversal), a reszleges visszateres es a konverzio viszont a
 * devizat lockolta eloszor, majd a HUF-ot. Egy parhuzamos BUY (HUF -> deviza) es SELL/sztorno
 * (deviza -> HUF) ugyanazon iroda + valuta paroson klasszikus AB-BA deadlockot okozott; a PostgreSQL
 * az egyik tranzakciot {@code deadlock detected}-tel aborteralta -> a vesztes felhasznaloi muvelet
 * 500-zal elhasalt.</p>
 *
 * <p>Megoldas: MINDEN cash-lockolo ut a sorokat NOVEKVO {@code currencyId} sorrendben szerzi meg,
 * a barmilyen mellekhatas / mutacio ELOTT. Mivel a HUF tipikusan {@code currencyId == 1}, ez
 * gyakorlatilag "HUF-first" mindenhol — de a rendezes a HUF konkret id-jetol fuggetlenul helyes
 * (resource-ordering deadlock-prevention: ha minden szal ugyanabban a teljes rendezesben szerzi a
 * lockokat, korkoros varakozas nem alakulhat ki). A kesobbi validateCurrencyStock/updateCashBalance
 * ugyanazokat a sorokat mar lockoltan kapja (no-op re-lock azonos tranzakcion belul), majd mutalja.</p>
 *
 * <p><b>HATOKOR (single-branch):</b> ez a helper EGY iroda (branchId) tobb valuta-sorat rendezi.
 * Lefedett utak: BUY/SELL (TransactionService), sztorno + reszleges visszateres
 * (TransactionReversalService), konverzio (TransactionConversionService), multi-line
 * (TransactionMultiLineService) — ezek mind egyetlen iroda HUF + deviza sorait mozgatjak.</p>
 *
 * <p><b>CROSS-BRANCH valtozat ({@link #lockBranchCurrencyPairsInGlobalOrder}):</b> a tobb iroda
 * cash-sorat MOZGATO utak eseten a determinisztikus rendezesi kulcs a {@code (branchId, currencyId)}
 * PAR (nem csak a currencyId). Egy Trade(A->B) es a forditott Trade(B->A) azonos valutara kulonben
 * AB-BA deadlockot okozna. A globalis rendezes: eloszor {@code branchId} (UUID natural order), majd
 * {@code currencyId}. Lefedve: {@code TradeService.moveTradeInventory} (forras+cel iroda) es
 * {@code TransferService} UF/FF mod (kuldo+fogado iroda) — utobbinal az elo-lock a bizonylatszam-
 * generalas ELOTT all, igy minden penzmozgato ut CASH->RECEIPT sorrendben lockol (#952: a
 * partial-refund cash elo-lockja is a receipt ele kerult), nincs cash<->receipt_sequence deadlock-axis.</p>
 *
 * <p><b>KOVETKEZO FOLLOW-UP:</b> {@code ReservationService} single-branch (createReservation currency+HUF,
 * jelenleg currency-first) — ott a NOVEKVO currencyId ascending elo-lock kell (mint BUY/SELL); kulon PR.</p>
 */
public final class CashLockOrdering {

    private CashLockOrdering() {
    }

    /**
     * A megadott valuta-sorokat NOVEKVO currencyId sorrendben elo-lockolja a megadott iroda kasszajaban.
     *
     * @param branchId    az iroda azonositoja
     * @param rowLock     a tenyleges sor-lock muvelet (pl. {@code cashBalanceRepository::findByBranchIdAndCurrencyIdForUpdate}
     *                    vagy {@code helper::lockCashBalance}); a (branchId, currencyId) paron PESSIMISTIC_WRITE lockot vesz
     * @param currencyIds a lockolando valuta-azonositok (a {@code null}-okat es a duplikatumokat figyelmen kivul hagyja)
     */
    public static void lockInAscendingCurrencyOrder(UUID branchId, BiConsumer<UUID, Long> rowLock, Long... currencyIds) {
        Arrays.stream(currencyIds)
                .filter(Objects::nonNull)
                .distinct()
                .sorted()
                .forEach(currencyId -> rowLock.accept(branchId, currencyId));
    }

    /**
     * Cross-branch lock-kulcs: egy konkret iroda + valuta cash_balance sora.
     */
    public record BranchCurrencyKey(UUID branchId, Long currencyId) {
    }

    /** Globalis teljes rendezes a cross-branch cash-sorokon: eloszor branchId (UUID), majd currencyId. */
    private static final Comparator<BranchCurrencyKey> GLOBAL_ORDER =
            Comparator.comparing(BranchCurrencyKey::branchId)
                    .thenComparing(BranchCurrencyKey::currencyId);

    /**
     * A megadott (iroda, valuta) cash_balance sorokat GLOBALISAN egyseges sorrendben elo-lockolja:
     * eloszor branchId (UUID natural order), majd currencyId szerint. Cross-branch utakhoz
     * (TradeService, TransferService), ahol KET KULONBOZO iroda sorat kell lockolni egy tranzakcioban —
     * a determinisztikus tuple-rendezes megakadalyozza a forditott-iranyu muvelettel (Trade B->A,
     * Transfer fordito) valo AB-BA deadlockot. A {@code null} kulcsokat es a duplikatumokat kihagyja.
     *
     * @param rowLock a tenyleges sor-lock muvelet (PESSIMISTIC_WRITE) a (branchId, currencyId) paron
     * @param keys    a lockolando (iroda, valuta) parok
     */
    public static void lockBranchCurrencyPairsInGlobalOrder(BiConsumer<UUID, Long> rowLock, BranchCurrencyKey... keys) {
        Arrays.stream(keys)
                .filter(Objects::nonNull)
                .filter(k -> k.branchId() != null && k.currencyId() != null)
                .distinct()
                .sorted(GLOBAL_ORDER)
                .forEach(k -> rowLock.accept(k.branchId(), k.currencyId()));
    }
}
