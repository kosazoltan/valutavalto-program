package hu.puzzleir.valuta.dto.retroactiveclosing;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

/**
 * FKH-050 (FR-5 / D6): reconciliation of a past day — expected comes from that
 * day's {@code daily_balance.closing_balance} (book value), actual from the
 * counted EVENING stock with {@code submission_date = pastDate}. Never today's
 * cash_balance / currency_stock (NFR-1).
 */
public record RetroactiveReconciliationDto(
        LocalDate date,
        List<Row> rows,
        boolean anyBlocking) {

    /** One currency row of the reconciliation table. */
    public record Row(
            String currencyCode,
            BigDecimal expected,
            BigDecimal actual,
            BigDecimal difference,
            boolean blocking) {
    }
}
