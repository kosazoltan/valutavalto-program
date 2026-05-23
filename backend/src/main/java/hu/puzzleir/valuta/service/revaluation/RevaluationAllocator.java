package hu.puzzleir.valuta.service.revaluation;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Értéktári nem-realizált átértékelési eredmény lecsorgatása a pénztárakra.
 *
 * <p><b>Üzleti elv (Kósa Zoltán direktíva 2026-05-23):</b> az értéktár puffer, NEM
 * haszoncenter; a pénztár és a terület a haszoncenter. A pufferkészlet
 * átértékelődéséből (MNB − WAC) keletkező +/− eredményt valutánként osztjuk le a
 * terület pénztáraira, a súly = <b>értéktárból lehívott mennyiség × pénztári átlag-árrés</b>
 * (mindhárom hajtóerő: lehívás + forgalom [az árrésben: profit/forgalom] + árrés).</p>
 *
 * <p>Invariáns: pénztáranként összegezve a kiosztott átértékelés <b>pontosan</b> egyenlő a
 * valuta REVAL-jával (legnagyobb-maradék kerekítés-korrekció), így a területi reconciliation
 * azonosság teljesül: terület = Σ(pénztár tiszta WAC-marzs) + Σ(allokált átértékelés).</p>
 *
 * Tiszta, függőség-mentes (statikus) — könnyen tesztelhető.
 */
public final class RevaluationAllocator {

    private RevaluationAllocator() {
    }

    /** Egy pénztár egy valutában: lehívott mennyiség + átlag-árrés (Ft/egység). */
    public record CashierDriver(String cashierId, BigDecimal drawnVolume, BigDecimal avgSpread) {
    }

    /** Egy pénztárra kiosztott átértékelés egy valutában. */
    public record Allocation(String cashierId, String currencyCode, BigDecimal allocatedReval) {
    }

    /**
     * Egy valuta REVAL-jának lecsorgatása a pénztárakra a (lehívás × árrés) súly szerint.
     * Σ(kiosztott) == reval (egész forintra kerekítve, legnagyobb-maradék korrekcióval).
     *
     * Fallback ha Σsúly == 0: (1) lehívott mennyiség arányában, (2) ha az is 0, egyenlő osztás.
     */
    public static List<Allocation> allocateCurrency(String currencyCode, BigDecimal reval,
                                                    List<CashierDriver> drivers) {
        List<Allocation> out = new ArrayList<>();
        if (drivers == null || drivers.isEmpty() || reval == null || reval.signum() == 0) {
            for (CashierDriver d : nz(drivers)) {
                out.add(new Allocation(d.cashierId(), currencyCode, BigDecimal.ZERO));
            }
            return out;
        }

        // Súly = lehívott mennyiség × max(árrés, 0)  (negatív árrés nem fordítja meg az előjelet)
        Map<String, BigDecimal> weights = new LinkedHashMap<>();
        BigDecimal sumW = BigDecimal.ZERO;
        for (CashierDriver d : drivers) {
            BigDecimal drawn = nz(d.drawnVolume());
            BigDecimal spread = nz(d.avgSpread()).max(BigDecimal.ZERO);
            BigDecimal w = drawn.multiply(spread);
            weights.put(d.cashierId(), w);
            sumW = sumW.add(w);
        }

        // Fallback 1: lehívott mennyiség arányában
        if (sumW.signum() == 0) {
            sumW = BigDecimal.ZERO;
            for (CashierDriver d : drivers) {
                BigDecimal drawn = nz(d.drawnVolume());
                weights.put(d.cashierId(), drawn);
                sumW = sumW.add(drawn);
            }
        }
        // Fallback 2: egyenlő osztás
        if (sumW.signum() == 0) {
            for (CashierDriver d : drivers) {
                weights.put(d.cashierId(), BigDecimal.ONE);
            }
            sumW = BigDecimal.valueOf(drivers.size());
        }

        // Arányos osztás egész forintra, majd legnagyobb-maradék korrekció hogy Σ == reval
        BigDecimal revalRounded = reval.setScale(0, RoundingMode.HALF_UP);
        Map<String, BigDecimal> base = new LinkedHashMap<>();
        Map<String, BigDecimal> remainder = new LinkedHashMap<>();
        BigDecimal allocatedSoFar = BigDecimal.ZERO;
        for (CashierDriver d : drivers) {
            BigDecimal exact = revalRounded.multiply(weights.get(d.cashierId()))
                    .divide(sumW, 6, RoundingMode.HALF_UP);
            BigDecimal floor = exact.setScale(0, RoundingMode.DOWN);
            base.put(d.cashierId(), floor);
            remainder.put(d.cashierId(), exact.subtract(floor));
            allocatedSoFar = allocatedSoFar.add(floor);
        }

        // a maradékot (revalRounded − Σfloor) a legnagyobb tört-maradékú pénztáraknak adjuk,
        // egyesével (előjel-helyesen)
        BigDecimal residual = revalRounded.subtract(allocatedSoFar);
        int units = residual.abs().intValue();
        BigDecimal step = residual.signum() >= 0 ? BigDecimal.ONE : BigDecimal.ONE.negate();
        List<String> order = new ArrayList<>(remainder.keySet());
        order.sort((a, b) -> remainder.get(b).compareTo(remainder.get(a)));
        for (int k = 0; k < units && k < order.size(); k++) {
            String id = order.get(k);
            base.put(id, base.get(id).add(step));
        }
        // ha több egységnyi maradék van, mint pénztár (nagy kerekítés), körbe-osztás
        int idx = 0;
        while (units > order.size() && idx < units - order.size()) {
            String id = order.get(idx % order.size());
            base.put(id, base.get(id).add(step));
            idx++;
        }

        for (CashierDriver d : drivers) {
            out.add(new Allocation(d.cashierId(), currencyCode,
                    base.get(d.cashierId()).setScale(2, RoundingMode.HALF_UP)));
        }
        return out;
    }

    private static BigDecimal nz(BigDecimal b) {
        return b == null ? BigDecimal.ZERO : b;
    }

    private static <T> List<T> nz(List<T> l) {
        return l == null ? List.of() : l;
    }
}
