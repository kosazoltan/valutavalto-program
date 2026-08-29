package hu.puzzleir.valuta.util;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

/**
 * FK-099 — pénzügyi tranzakciós illeték (2012. évi CXVI. tv.) tiszta számítás.
 *
 * <p>Domain-réteg: Spring/JPA/I-O mentes. Az illeték ADÓ-számítás, nem
 * készpénz-kerekítés: {@code HALF_UP} 0 tizedesre, majd cap — a
 * {@link HungarianRounding#roundToFive} 5 Ft-os készpénz-szabály NEM alkalmazható
 * (ticket C8).</p>
 */
public final class TransactionLevyCalculator {

    private static final BigDecimal ONE_HUNDRED = BigDecimal.valueOf(100);

    /**
     * Egy hatályos ráta-sor számításhoz szükséges adatai.
     * {@code ratePercent} jelentése: százalék (0.450 = 0,45%).
     */
    public record LevyRate(LocalDate effectiveFrom,
                           BigDecimal baseRatePercent, BigDecimal baseRateCapHuf,
                           BigDecimal supplementRatePercent, BigDecimal supplementRateCapHuf,
                           boolean conversionSingleSide) {}

    /** Egy tranzakcióra számított illeték-pár + küszöb-besorolás. */
    public record LevyAmounts(BigDecimal baseLevy, BigDecimal supplementLevy, boolean aboveThreshold) {}

    /**
     * Egy illeték-komponens: {@code min( HALF_UP(hufAmount * ratePercent / 100, 0), capHuf )}.
     *
     * <p>C8: adó-számítás — NEM hívható rá a {@link HungarianRounding#roundToFive}
     * 5 Ft-os készpénz-szabály (a 13 501 Ft-os eset pineli).</p>
     */
    public static BigDecimal component(BigDecimal hufAmount, BigDecimal ratePercent, BigDecimal capHuf) {
        return hufAmount.multiply(ratePercent)
                .divide(ONE_HUNDRED)
                .setScale(0, RoundingMode.HALF_UP)
                .min(capHuf.setScale(0, RoundingMode.HALF_UP));
    }

    /**
     * Küszöb (HUF-alap): a legkisebb összeg, ahol MINDKÉT komponens eléri a cap-jét —
     * {@code max( ceil(baseCap × 100 / baseRate), ceil(suppCap × 100 / suppRate) )}
     * (D4). Seed 0.45%/20 000 mellett pontosan 4 444 445.
     *
     * <p>{@code null}, ha valamely ráta 0: a cap elérhetetlen, tehát küszöb
     * feletti besorolás sincs (az illeték amúgy is 0 lenne).</p>
     */
    public static BigDecimal thresholdHuf(LevyRate rate) {
        if (rate.baseRatePercent().signum() == 0 || rate.supplementRatePercent().signum() == 0) {
            return null;
        }
        BigDecimal baseThreshold = rate.baseRateCapHuf().multiply(ONE_HUNDRED)
                .divide(rate.baseRatePercent(), 0, RoundingMode.CEILING);
        BigDecimal supplementThreshold = rate.supplementRateCapHuf().multiply(ONE_HUNDRED)
                .divide(rate.supplementRatePercent(), 0, RoundingMode.CEILING);
        return baseThreshold.max(supplementThreshold);
    }

    /**
     * Mindkét komponens + küszöb feletti besorolás egy tranzakcióra.
     *
     * <p>D4: a besorolás ARITMETIKAI ({@code hufAmount >= thresholdHuf}, a küszöb
     * a kerekítetlen {@code huf × rate ≥ cap} egyenértékű alakja) — a 4 444 444-es
     * esetnél ezért lesz a kerekített illeték 20 000 miközben a sor még normál.
     * Null küszöb (0 ráta) → nincs küszöb feletti besorolás.</p>
     */
    public static LevyAmounts compute(BigDecimal hufAmount, LevyRate rate) {
        BigDecimal baseLevy = component(hufAmount, rate.baseRatePercent(), rate.baseRateCapHuf());
        BigDecimal supplementLevy = component(hufAmount, rate.supplementRatePercent(), rate.supplementRateCapHuf());
        BigDecimal threshold = thresholdHuf(rate);
        boolean aboveThreshold = threshold != null && hufAmount.compareTo(threshold) >= 0;
        return new LevyAmounts(baseLevy, supplementLevy, aboveThreshold);
    }

    /**
     * A {@code date}-n hatályos ráta: a DESC-rendezett listából az első
     * {@code effectiveFrom <= date} sor; üres, ha nincs ilyen (a hívó fail-closed, D7).
     */
    public static Optional<LevyRate> resolveRate(List<LevyRate> ratesDesc, LocalDate date) {
        return ratesDesc.stream()
                .filter(rate -> rate.effectiveFrom() != null && !rate.effectiveFrom().isAfter(date))
                .findFirst();
    }

    private TransactionLevyCalculator() {}
}
