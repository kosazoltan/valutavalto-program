package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.turnover.TurnoverReportDto;
import hu.puzzleir.valuta.repository.TransactionRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.YearMonth;
import java.time.temporal.TemporalAdjusters;
import java.util.Collections;
import java.util.UUID;

/**
 * Forgalom összesítő szolgáltatás — napi, heti, havi, éves, cégszintű.
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
@Slf4j
public class TurnoverService {

    private final TransactionRepository transactionRepository;

    public TurnoverReportDto getDailyTurnover(UUID branchId, LocalDate date) {
        return buildReport(
            branchId,
            date.toString(),
            date.atStartOfDay(),
            date.atTime(LocalTime.MAX)
        );
    }

    public TurnoverReportDto getWeeklyTurnover(UUID branchId, LocalDate weekStart) {
        LocalDate mondayStart = weekStart.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY));
        LocalDate sundayEnd = mondayStart.plusDays(6);
        return buildReport(
            branchId,
            mondayStart + " - " + sundayEnd,
            mondayStart.atStartOfDay(),
            sundayEnd.atTime(LocalTime.MAX)
        );
    }

    public TurnoverReportDto getMonthlyTurnover(UUID branchId, YearMonth month) {
        LocalDate first = month.atDay(1);
        LocalDate last = month.atEndOfMonth();
        return buildReport(
            branchId,
            month.toString(),
            first.atStartOfDay(),
            last.atTime(LocalTime.MAX)
        );
    }

    public TurnoverReportDto getYearlyTurnover(UUID branchId, int year) {
        LocalDate first = LocalDate.of(year, 1, 1);
        LocalDate last = LocalDate.of(year, 12, 31);
        return buildReport(
            branchId,
            String.valueOf(year),
            first.atStartOfDay(),
            last.atTime(LocalTime.MAX)
        );
    }

    public TurnoverReportDto getCompanyTurnover(UUID companyId, LocalDate from, LocalDate to) {
        LocalDateTime fromDt = from.atStartOfDay();
        LocalDateTime toDt = to.atTime(LocalTime.MAX);

        BigDecimal totalBuy = transactionRepository.sumHufAmountByCompanyAndTypeAndPeriod(
            companyId, "BUY", fromDt, toDt);
        BigDecimal totalSell = transactionRepository.sumHufAmountByCompanyAndTypeAndPeriod(
            companyId, "SELL", fromDt, toDt);
        BigDecimal fees = transactionRepository.sumFeeByCompanyAndPeriod(companyId, fromDt, toDt);

        totalBuy = totalBuy != null ? totalBuy : BigDecimal.ZERO;
        totalSell = totalSell != null ? totalSell : BigDecimal.ZERO;
        fees = fees != null ? fees : BigDecimal.ZERO;

        return TurnoverReportDto.builder()
            .period(from + " - " + to)
            .totalBuy(totalBuy)
            .totalSell(totalSell)
            .spread(totalSell.subtract(totalBuy))
            .fees(fees)
            .netProfit(totalSell.subtract(totalBuy).add(fees))
            .byCurrency(Collections.emptyList())
            .byWorker(Collections.emptyList())
            .build();
    }

    // ============ HELPER ============

    private TurnoverReportDto buildReport(UUID branchId, String period,
                                           LocalDateTime from, LocalDateTime to) {
        BigDecimal totalBuy = transactionRepository.sumHufAmountByBranchAndTypeAndPeriod(
            branchId, "BUY", from, to);
        BigDecimal totalSell = transactionRepository.sumHufAmountByBranchAndTypeAndPeriod(
            branchId, "SELL", from, to);
        BigDecimal fees = transactionRepository.sumFeeByBranchAndPeriod(branchId, from, to);

        totalBuy = totalBuy != null ? totalBuy : BigDecimal.ZERO;
        totalSell = totalSell != null ? totalSell : BigDecimal.ZERO;
        fees = fees != null ? fees : BigDecimal.ZERO;

        BigDecimal spread = totalSell.subtract(totalBuy);
        BigDecimal netProfit = spread.add(fees);

        return TurnoverReportDto.builder()
            .period(period)
            .totalBuy(totalBuy)
            .totalSell(totalSell)
            .spread(spread)
            .fees(fees)
            .netProfit(netProfit)
            .byCurrency(Collections.emptyList())
            .byWorker(Collections.emptyList())
            .build();
    }
}
