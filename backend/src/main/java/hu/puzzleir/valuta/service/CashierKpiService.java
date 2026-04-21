package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.dashboard.CashierKpiRowDto;
import hu.puzzleir.valuta.dto.dashboard.CashierKpiSummaryDto;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * B2: Penztaros KPI dashboard szolgaltatas.
 *
 * Aggregal:
 *  - Penztarosonkent: tx_szam, BUY/SELL/REVERSAL megoszlas, forgalom HUF, kezelesi dij
 *  - Cegszinten (felette): osszesitett szamok, aktiv penztarosok szama, sztorno %
 *
 * Idotartomany szerint (pl. ma, ez a honap, elmult 30 nap).
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class CashierKpiService {

    private final TransactionRepository transactionRepository;

    @Transactional(readOnly = true)
    public CashierKpiSummaryDto getKpis(LocalDate dateFrom, LocalDate dateTo) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return buildSummary(companyId, dateFrom, dateTo);
    }

    private CashierKpiSummaryDto buildSummary(UUID companyId, LocalDate dateFrom, LocalDate dateTo) {
        // 1) Penztarosonkenti bontas
        List<Object[]> groupRows = transactionRepository.cashierKpiByCompanyAndDateRange(companyId, dateFrom, dateTo);
        List<CashierKpiRowDto> rows = new ArrayList<>();
        for (Object[] r : groupRows) {
            long txCount = toLong(r[2]);
            long buyCount = toLong(r[3]);
            long sellCount = toLong(r[4]);
            long reversalCount = toLong(r[5]);
            BigDecimal totalHuf = toBigDecimal(r[6]);
            BigDecimal buyHuf = toBigDecimal(r[7]);
            BigDecimal sellHuf = toBigDecimal(r[8]);
            BigDecimal totalFees = toBigDecimal(r[9]);
            long customerCount = toLong(r[10]);

            long effectiveCount = buyCount + sellCount;
            BigDecimal avgTxHuf = effectiveCount > 0
                    ? totalHuf.divide(BigDecimal.valueOf(effectiveCount), 0, RoundingMode.HALF_UP)
                    : BigDecimal.ZERO;
            BigDecimal reversalRatio = txCount > 0
                    ? BigDecimal.valueOf(reversalCount)
                        .multiply(BigDecimal.valueOf(100))
                        .divide(BigDecimal.valueOf(txCount), 2, RoundingMode.HALF_UP)
                    : BigDecimal.ZERO;

            // Safe cast: PostgreSQL driver Long/BigInteger varianciara felkeszulve
            Long workerId = r[0] instanceof Number n ? n.longValue() : null;
            String workerName = r[1] != null ? r[1].toString() : null;
            rows.add(CashierKpiRowDto.builder()
                    .workerId(workerId)
                    .workerName(workerName)
                    .txCount(txCount)
                    .buyCount(buyCount)
                    .sellCount(sellCount)
                    .reversalCount(reversalCount)
                    .totalHuf(totalHuf)
                    .buyHuf(buyHuf)
                    .sellHuf(sellHuf)
                    .totalFees(totalFees)
                    .customerCount(customerCount)
                    .avgTxHuf(avgTxHuf)
                    .reversalRatio(reversalRatio)
                    .build());
        }

        // 2) Ceges osszesito (1 sor)
        Object[] totals = transactionRepository.cashierKpiCompanyTotals(companyId, dateFrom, dateTo);
        long totalTx = 0, totalBuy = 0, totalSell = 0, totalReversal = 0, workerCount = 0, customerCount = 0;
        BigDecimal totalHuf = BigDecimal.ZERO, totalFees = BigDecimal.ZERO;
        if (totals != null && totals.length >= 8) {
            totalTx = toLong(totals[0]);
            totalBuy = toLong(totals[1]);
            totalSell = toLong(totals[2]);
            totalReversal = toLong(totals[3]);
            totalHuf = toBigDecimal(totals[4]);
            totalFees = toBigDecimal(totals[5]);
            workerCount = toLong(totals[6]);
            customerCount = toLong(totals[7]);
        }
        BigDecimal reversalRatio = totalTx > 0
                ? BigDecimal.valueOf(totalReversal)
                    .multiply(BigDecimal.valueOf(100))
                    .divide(BigDecimal.valueOf(totalTx), 2, RoundingMode.HALF_UP)
                : BigDecimal.ZERO;

        return CashierKpiSummaryDto.builder()
                .dateFrom(dateFrom)
                .dateTo(dateTo)
                .totalTxCount(totalTx)
                .totalBuyCount(totalBuy)
                .totalSellCount(totalSell)
                .totalReversalCount(totalReversal)
                .totalHuf(totalHuf)
                .totalFees(totalFees)
                .activeWorkerCount(workerCount)
                .totalCustomerCount(customerCount)
                .reversalRatio(reversalRatio)
                .rows(rows)
                .build();
    }

    private static long toLong(Object o) {
        if (o == null) return 0L;
        if (o instanceof Number n) return n.longValue();
        return 0L;
    }

    private BigDecimal toBigDecimal(Object o) {
        if (o == null) return BigDecimal.ZERO;
        if (o instanceof BigDecimal b) return b;
        // Sourcery AI bug_risk: doubleValue() precision loss — helyette String conversion
        if (o instanceof Long l) return BigDecimal.valueOf(l);
        if (o instanceof Integer i) return BigDecimal.valueOf(i);
        if (o instanceof java.math.BigInteger bi) return new BigDecimal(bi);
        if (o instanceof Number n) return new BigDecimal(n.toString());
        // Sourcery: silent BigDecimal.ZERO maskolna data issue-kat — most loggoljuk
        log.warn("Unsupported object type in toBigDecimal: {} (value={}). Returning ZERO fallback.",
                o.getClass().getName(), o);
        return BigDecimal.ZERO;
    }
}