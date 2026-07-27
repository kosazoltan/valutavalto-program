package hu.puzzleir.valuta.service;

import java.math.BigDecimal;

/**
 * FK-066: záráskori eltérés-tolerancia egy pénznemre — érték + ág (explicit/fallback).
 *
 * <p>ÁG-FÜGGŐ OPERÁTOR (FR-2/FR-3/FR-6, a blokkoló-kérdés válasz-dokumentuma szerint):
 * <ul>
 *   <li>EXPLICIT ág (van system_parameter sor): {@code |diff| >= value} BLOKKOL —
 *       a pontosan egyező eltérés IS blokkol; az utolsó átengedett érték
 *       {@code |diff| == value - 1}.</li>
 *   <li>FALLBACK ág (nincs sor / érvénytelen sor): {@code |diff| > value} blokkol —
 *       az FK-066 előtti, változatlan viselkedés.</li>
 *   <li>Nulla eltérés SOHA nem blokkol (explicit 0-toleranciánál sem).</li>
 * </ul>
 *
 * <p>A {@link #blocks(BigDecimal)} az EGYETLEN hely, ahol az operátor eldől — a kemény
 * kapu (DailyClosingService) és a puha kapu (ClosingWizardService) is ezt hívja, saját
 * összehasonlítást nem implementálhatnak (FR-6: közös forrás, nem két külön implementáció).
 *
 * @param value    a tolerancia értéke (a pénznem saját egységében; HUF-nál Ft)
 * @param explicit {@code true}, ha explicit system_parameter sorból jön; {@code false},
 *                 ha kód-szintű fallback-default
 */
public record ClosingTolerance(BigDecimal value, boolean explicit) {

    public static ClosingTolerance explicitOf(BigDecimal value) {
        return new ClosingTolerance(value, true);
    }

    public static ClosingTolerance fallbackOf(BigDecimal value) {
        return new ClosingTolerance(value, false);
    }

    /**
     * Ág-függő blokkolási döntés: explicit ágon {@code |diff| >= value}, fallback ágon
     * {@code |diff| > value}. Nulla (vagy null) eltérés soha nem blokkol.
     */
    public boolean blocks(BigDecimal diff) {
        if (diff == null || diff.signum() == 0) {
            return false;
        }
        int comparison = diff.abs().compareTo(value);
        return explicit ? comparison >= 0 : comparison > 0;
    }
}
