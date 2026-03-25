package hu.puzzleir.valuta.service;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;

/**
 * NAV/NB jellegu riportok specializalt szolgaltatasa.
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class NbReportService {

    private final ReportService reportService;

    public ReportService.PeriodReport generatePeriodReport(LocalDate startDate, LocalDate endDate) {
        return reportService.generatePeriodReport(startDate, endDate);
    }

    public ReportService.HandlingFeeReport generateHandlingFeeReport(LocalDate startDate, LocalDate endDate) {
        return reportService.generateHandlingFeeReport(startDate, endDate);
    }
}
