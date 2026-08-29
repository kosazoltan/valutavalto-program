package hu.puzzleir.valuta.util;

import java.math.BigDecimal;
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
     */
    public static BigDecimal component(BigDecimal hufAmount, BigDecimal ratePercent, BigDecimal capHuf) {
        throw new UnsupportedOperationException("FK-099 RED");
    }

    /**
     * Küszöb (HUF-alap): az a legkisebb összeg, ahol mindkét komponens eléri a cap-jét.
     * {@code null}, ha valamely ráta 0 (a cap elérhetetlen).
     */
    public static BigDecimal thresholdHuf(LevyRate rate) {
        throw new UnsupportedOperationException("FK-099 RED");
    }

    /** Mindkét komponens + küszöb feletti besorolás egy tranzakcióra. */
    public static LevyAmounts compute(BigDecimal hufAmount, LevyRate rate) {
        throw new UnsupportedOperationException("FK-099 RED");
    }

    /**
     * A {@code date}-n hatályos ráta: a DESC-rendezett listából az első
     * {@code effectiveFrom <= date} sor; üres, ha nincs ilyen (a hívó fail-closed, D7).
     */
    public static Optional<LevyRate> resolveRate(List<LevyRate> ratesDesc, LocalDate date) {
        throw new UnsupportedOperationException("FK-099 RED");
    }

    private TransactionLevyCalculator() {}
}
