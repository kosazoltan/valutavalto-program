package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.exception.ValidationException;

import java.math.BigDecimal;
import java.math.RoundingMode;

/**
 * RFM spread-kapu (VV-ELVI 7.2/7.4): a publikált árfolyam vételi/eladási spreadje
 * nem lépheti túl a referencia-árfolyam {@value #MAX_RELATIVE_SPREAD_PERCENT}%-át.
 *
 * <p>Üzleti invariáns adatbeviteli hiba és méltánytalan (túl széles) árfolyam ellen.
 * Pure, mellékhatás-mentes osztály — izoláltan tesztelhető ({@code RateSpreadGateTest}).
 *
 * <p>Relatív spread = (sellRate − buyRate) / reference, ahol reference =
 * officialRate (MNB referencia), ha pozitív; különben a vételi/eladási középárfolyam.
 */
public final class RateSpreadGate {

    /** Maximum megengedett relatív spread: (sell − buy) / reference ≤ 0.05 (5%). */
    public static final BigDecimal MAX_RELATIVE_SPREAD = new BigDecimal("0.05");
    public static final int MAX_RELATIVE_SPREAD_PERCENT = 5;

    private static final BigDecimal TWO = new BigDecimal("2");

    private RateSpreadGate() {
    }

    /**
     * Érvényesíti a spread-kaput. Hiányzó (null) vételi/eladási árfolyamnál no-op —
     * a hiányzó-érték ellenőrzés a hívó felelőssége.
     *
     * @throws ValidationException ha a relatív spread meghaladja az 5%-ot
     */
    public static void enforce(BigDecimal buyRate, BigDecimal sellRate, BigDecimal officialRate, Long currencyId) {
        if (buyRate == null || sellRate == null) {
            return;
        }
        BigDecimal reference = (officialRate != null && officialRate.signum() > 0)
                ? officialRate
                : buyRate.add(sellRate).divide(TWO, 10, RoundingMode.HALF_UP);
        if (reference.signum() <= 0) {
            // Nem értelmezhető referencia — a vételi<eladási sanity-check már véd.
            return;
        }
        // Egzakt összehasonlítás kereszt-szorzással: (sell − buy) > reference × 0.05.
        // NEM osztunk a döntés előtt, hogy a kerekítés (pl. 0.0500004 → 0.050000) ne
        // engedjen át ténylegesen 5% fölötti spreadet (Copilot/Codex #719 finding).
        BigDecimal actualSpread = sellRate.subtract(buyRate);
        BigDecimal maxAllowedSpread = reference.multiply(MAX_RELATIVE_SPREAD);
        if (actualSpread.compareTo(maxAllowedSpread) > 0) {
            // A százalék CSAK megjelenítéshez számolódik (kerekítés itt megengedett).
            BigDecimal pct = actualSpread.divide(reference, 6, RoundingMode.HALF_UP)
                    .movePointRight(2).setScale(2, RoundingMode.HALF_UP);
            throw new ValidationException(String.format(
                    "A vételi/eladási spread (%s%%) meghaladja a megengedett %d%%-ot! currencyId=%s",
                    pct.toPlainString(), MAX_RELATIVE_SPREAD_PERCENT, currencyId));
        }
    }
}
