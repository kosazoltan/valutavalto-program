package hu.puzzleir.valuta.util;

import java.util.Arrays;
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
 * <p><b>KULON, SZELESEBB FOLLOW-UP (NEM ez a helper fedi):</b> a CROSS-BRANCH cash-mozgato utak
 * (TradeService.moveTradeInventory — forras- es cel-iroda azonos valutaja; esetleg TransferService),
 * ahol KET KULONBOZO iroda sorat lockoljak: itt a determinisztikus rendezesi kulcs a (branchId,
 * currencyId) PAR, nem csak a currencyId. Egy Trade(A->B) es a forditott Trade(B->A) azonos valutara
 * AB-BA deadlockot okozhat. Ezt egy kovetkezo, fokuszalt PR rendezi (altalanos (branch,currency)-tuple
 * rendezessel); a jelen helper szandekosan a single-branch tranzakcios utakra korlatozott.</p>
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
}
