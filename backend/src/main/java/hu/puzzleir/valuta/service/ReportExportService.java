package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.handlingfee.HandlingFeeDailySummaryDto;
import hu.puzzleir.valuta.dto.handlingfee.PosHandlingFeeDailySummaryDto;
import hu.puzzleir.valuta.exception.BusinessException;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.csv.CSVFormat;
import org.apache.commons.csv.CSVPrinter;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.io.StringWriter;
import java.time.format.DateTimeFormatter;

/**
 * CSV export szolgáltatás a riportokhoz.
 *
 * P2-14: CSV export minden riport típushoz.
 * UTF-8 BOM az Excel kompatibilitáshoz.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class ReportExportService {

    private static final byte[] UTF8_BOM = new byte[]{(byte) 0xEF, (byte) 0xBB, (byte) 0xBF};
    private static final DateTimeFormatter DATE_FMT = DateTimeFormatter.ofPattern("yyyy-MM-dd");
    private static final DateTimeFormatter DATETIME_FMT = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    /**
     * UTF-8 BOM bytes az Excel kompatibilitáshoz.
     */
    public byte[] getBom() {
        return UTF8_BOM.clone();
    }

    /**
     * WorkerPerformanceReport CSV export.
     */
    public String exportWorkerPerformanceCsv(ReportService.WorkerPerformanceReport report) {
        StringWriter sw = new StringWriter();
        try (CSVPrinter printer = new CSVPrinter(sw, CSVFormat.DEFAULT.withHeader(
                "Pénztáros kód", "Pénztáros név",
                "Időszak kezdete", "Időszak vége",
                "Összes tranzakció", "Vétel db", "Eladás db", "Sztornó db",
                "Vétel HUF", "Eladás HUF", "Teljes forgalom HUF",
                "Átlagos tranzakció értéke HUF"))) {

            printer.printRecord(
                    report.getWorkerCode(),
                    report.getWorkerName(),
                    report.getStartDate() != null ? report.getStartDate().format(DATE_FMT) : "",
                    report.getEndDate() != null ? report.getEndDate().format(DATE_FMT) : "",
                    report.getTotalTransactions(),
                    report.getBuyTransactions(),
                    report.getSellTransactions(),
                    report.getReversalCount(),
                    report.getTotalBuyHuf(),
                    report.getTotalSellHuf(),
                    report.getTotalTurnoverHuf(),
                    report.getAverageTransactionValue()
            );
        } catch (IOException e) {
            log.error("WorkerPerformanceReport CSV export hiba", e);
            throw new BusinessException("CSV export meghiúsult", "CSV_EXPORT_FAILED");
        }
        return sw.toString();
    }

    /**
     * HandlingFeeReport CSV export.
     */
    public String exportHandlingFeeCsv(ReportService.HandlingFeeReport report) {
        StringWriter sw = new StringWriter();
        try (CSVPrinter printer = new CSVPrinter(sw, CSVFormat.DEFAULT.withHeader(
                "Valuta", "Kezelési díj összeg HUF"))) {

            if (report.getFeesByCurrency() != null) {
                for (ReportService.CurrencyFeeData feeData : report.getFeesByCurrency()) {
                    printer.printRecord(feeData.getCurrencyCode(), feeData.getTotalFees());
                }
            }
            // Összesítő sor
            printer.printRecord("ÖSSZESEN", report.getTotalHandlingFees());

        } catch (IOException e) {
            log.error("HandlingFeeReport CSV export hiba", e);
            throw new BusinessException("CSV export meghiúsult", "CSV_EXPORT_FAILED");
        }
        return sw.toString();
    }

    /** FK-053: napi készpénzes kezelési díj CSV (a daily-summary végponttal azonos adat). */
    public String exportHandlingFeeDailySummaryCsv(HandlingFeeDailySummaryDto report) {
        StringWriter sw = new StringWriter();
        try (CSVPrinter printer = new CSVPrinter(sw, CSVFormat.DEFAULT.withHeader(
                "Dátum", "Banki kód", "Pénztárszám", "Vétel kezelési díj (Ft)", "Eladás kezelési díj (Ft)"))) {
            if (report.getRows() != null) {
                for (HandlingFeeDailySummaryDto.DailyRow row : report.getRows()) {
                    printer.printRecord(
                            row.getDate() != null ? row.getDate().format(DATE_FMT) : "",
                            row.getBankCode() != null ? row.getBankCode() : "",
                            row.getCode() != null ? row.getCode() : "",
                            row.getBuyFee(),
                            row.getSellFee());
                }
            }
            printer.printRecord("Összesen", "", "", report.getTotalBuyFee(), report.getTotalSellFee());
        } catch (IOException e) {
            log.error("HandlingFeeDailySummary CSV export hiba", e);
            throw new BusinessException("CSV export meghiúsult", "CSV_EXPORT_FAILED");
        }
        return sw.toString();
    }

    /** FK-059: daily POS net and handling-fee CSV, matching the JSON report. */
    public String exportPosHandlingFeeDailySummaryCsv(PosHandlingFeeDailySummaryDto report) {
        StringWriter sw = new StringWriter();
        try (CSVPrinter printer = new CSVPrinter(sw, CSVFormat.DEFAULT.withHeader(
                "Dátum", "Banki kód", "Pénztárszám", "POS nettó (Ft)", "POS KK (Ft)"))) {
            if (report.getRows() != null) {
                for (PosHandlingFeeDailySummaryDto.DailyRow row : report.getRows()) {
                    printer.printRecord(
                            row.getDate() != null ? row.getDate().format(DATE_FMT) : "",
                            row.getBankCode() != null ? row.getBankCode() : "",
                            row.getCode() != null ? row.getCode() : "",
                            row.getNetAmount(),
                            row.getFeeAmount());
                }
            }
            printer.printRecord("Összesen", "", "", report.getTotalNetAmount(), report.getTotalFeeAmount());
        } catch (IOException e) {
            log.error("PosHandlingFeeDailySummary CSV export hiba", e);
            throw new BusinessException("CSV export meghiúsult", "CSV_EXPORT_FAILED");
        }
        return sw.toString();
    }

    /**
     * MonthlyTurnoverReport CSV export.
     */
    public String exportMonthlyTurnoverCsv(ReportService.MonthlyTurnoverReport report) {
        StringWriter sw = new StringWriter();
        try (CSVPrinter printer = new CSVPrinter(sw, CSVFormat.DEFAULT.withHeader(
                "Iroda neve", "Iroda ID",
                "Tranzakció db", "Vétel db", "Eladás db", "Sztornó db",
                "Vétel HUF", "Eladás HUF", "Nettó eredmény HUF",
                "Kezelési díj HUF", "Lezárt"))) {

            if (report.getBranchData() != null) {
                for (ReportService.BranchMonthlyData bd : report.getBranchData()) {
                    printer.printRecord(
                            bd.getBranchName(),
                            bd.getBranchId(),
                            bd.getTransactionCount(),
                            bd.getBuyCount(),
                            bd.getSellCount(),
                            bd.getReversalCount(),
                            bd.getBuyHuf(),
                            bd.getSellHuf(),
                            bd.getNetResult(),
                            bd.getHandlingFees(),
                            bd.getFinalized() != null && bd.getFinalized() ? "Igen" : "Nem"
                    );
                }
            }

        } catch (IOException e) {
            log.error("MonthlyTurnoverReport CSV export hiba", e);
            throw new BusinessException("CSV export meghiúsult", "CSV_EXPORT_FAILED");
        }
        return sw.toString();
    }

    /**
     * PeriodReport CSV export.
     */
    public String exportPeriodReportCsv(ReportService.PeriodReport report) {
        StringWriter sw = new StringWriter();
        try (CSVPrinter printer = new CSVPrinter(sw, CSVFormat.DEFAULT.withHeader(
                "Dátum", "Iroda", "Tranzakció db",
                "Vétel HUF", "Eladás HUF", "Nettó HUF", "Kezelési díj HUF"))) {

            if (report.getDailySummaries() != null) {
                for (ReportService.DailySummary ds : report.getDailySummaries()) {
                    printer.printRecord(
                            ds.getDate() != null ? ds.getDate().format(DATE_FMT) : "",
                            ds.getBranchName(),
                            ds.getTransactionCount(),
                            ds.getBuyTurnover(),
                            ds.getSellTurnover(),
                            ds.getNetTurnover(),
                            ds.getHandlingFees()
                    );
                }
            }

        } catch (IOException e) {
            log.error("PeriodReport CSV export hiba", e);
            throw new BusinessException("CSV export meghiúsult", "CSV_EXPORT_FAILED");
        }
        return sw.toString();
    }
}
