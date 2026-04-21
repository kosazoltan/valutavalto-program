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

            rows.add(CashierKpiRowDto.builder()
                    .workerId((Long) r[0])
                    .workerName((String) r[1])
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

    private static BigDecimal toBigDecimal(Object o) {
        if (o == null) return BigDecimal.ZERO;
        if (o instanceof BigDecimal b) return b;
        if (o instanceof Number n) return BigDecimal.valueOf(n.doubleValue());
        return BigDecimal.ZERO;
    }
}