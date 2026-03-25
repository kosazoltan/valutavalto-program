package hu.puzzleir.valuta.service;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Havi riport specializalt szolgaltatas.
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class MonthlyReportService {

    private final ReportService reportService;

    public ReportService.MonthlyTurnoverReport generateMonthlyTurnoverReport(Integer year, Integer month) {
        return reportService.generateMonthlyTurnoverReport(year, month);
    }
}
