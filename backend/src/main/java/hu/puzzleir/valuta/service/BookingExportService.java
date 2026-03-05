package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.InventorySummary;
import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.repository.InventorySummaryRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.time.YearMonth;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.UUID;

/**
 * Könyvelési export szolgáltatás — CSV export napi/havi bontásban.
 *
 * Formátum: UTF-8 BOM, pontosvessző szeparátor (Excel-barát magyar)
 */
@Service
@RequiredArgsConstructor
@Slf4j
@Transactional(readOnly = true)
public class BookingExportService {

    private static final byte[] UTF8_BOM = new byte[]{(byte) 0xEF, (byte) 0xBB, (byte) 0xBF};
    private static final String SEP = ";";
    private static final DateTimeFormatter DATE_FMT = DateTimeFormatter.ofPattern("yyyy-MM-dd");
    private static final DateTimeFormatter TIME_FMT = DateTimeFormatter.ofPattern("HH:mm:ss");

    private final TransactionRepository transactionRepository;
    private final InventorySummaryRepository inventorySummaryRepository;

    /**
     * Napi könyvelési export CSV.
     */
    public byte[] exportDailyBooking(UUID branchId, LocalDate date) {
        List<Transaction> transactions = transactionRepository.findActiveByBranchAndDate(branchId, date);

        StringBuilder sb = new StringBuilder();
        sb.append("Bizonylat szám").append(SEP)
          .append("Típus").append(SEP)
          .append("Dátum").append(SEP)
          .append("Idő").append(SEP)
          .append("Valuta").append(SEP)
          .append("Valuta összeg").append(SEP)
          .append("Árfolyam").append(SEP)
          .append("HUF összeg").append(SEP)
          .append("Kezelési díj").append(SEP)
          .append("Kedvezmény").append(SEP)
          .append("Ügyfél").append(SEP)
          .append("Pénztáros").append("\n");

        for (Transaction t : transactions) {
            sb.append(esc(t.getReceiptNumber())).append(SEP)
              .append(esc(t.getTransactionType().getDisplayName())).append(SEP)
              .append(t.getTransactionDate().format(DATE_FMT)).append(SEP)
              .append(t.getTransactionTime().format(TIME_FMT)).append(SEP)
              .append(t.getCurrency() != null ? t.getCurrency().getCode() : "").append(SEP)
              .append(fmtNum(t.getCurrencyAmount())).append(SEP)
              .append(fmtNum(t.getExchangeRate())).append(SEP)
              .append(fmtNum(t.getHufAmount())).append(SEP)
              .append(fmtNum(t.getHandlingFee())).append(SEP)
              .append(fmtNum(t.getDiscountAmount())).append(SEP)
              .append(esc(t.getCustomerName() != null ? t.getCustomerName() : "")).append(SEP)
              .append(t.getWorker() != null ? esc(t.getWorker().getName()) : "").append("\n");
        }

        log.info("Napi booking export: branch={}, date={}, rows={}", branchId, date, transactions.size());
        return addBom(sb.toString());
    }

    /**
     * Havi könyvelési export CSV.
     */
    public byte[] exportMonthlyBooking(UUID branchId, String yearMonth) {
        YearMonth ym = YearMonth.parse(yearMonth);
        LocalDate monthStart = ym.atDay(1);
        LocalDate monthEnd = ym.atEndOfMonth();

        List<Transaction> transactions = transactionRepository.findByBranchAndMonth(branchId, monthStart, monthEnd);

        StringBuilder sb = new StringBuilder();
        sb.append("Bizonylat szám").append(SEP)
          .append("Típus").append(SEP)
          .append("Dátum").append(SEP)
          .append("Idő").append(SEP)
          .append("Valuta").append(SEP)
          .append("Valuta összeg").append(SEP)
          .append("Árfolyam").append(SEP)
          .append("HUF összeg").append(SEP)
          .append("Kezelési díj").append(SEP)
          .append("Kedvezmény").append(SEP)
          .append("Ügyfél").append(SEP)
          .append("Pénztáros").append("\n");

        for (Transaction t : transactions) {
            sb.append(esc(t.getReceiptNumber())).append(SEP)
              .append(esc(t.getTransactionType().getDisplayName())).append(SEP)
              .append(t.getTransactionDate().format(DATE_FMT)).append(SEP)
              .append(t.getTransactionTime().format(TIME_FMT)).append(SEP)
              .append(t.getCurrency() != null ? t.getCurrency().getCode() : "").append(SEP)
              .append(fmtNum(t.getCurrencyAmount())).append(SEP)
              .append(fmtNum(t.getExchangeRate())).append(SEP)
              .append(fmtNum(t.getHufAmount())).append(SEP)
              .append(fmtNum(t.getHandlingFee())).append(SEP)
              .append(fmtNum(t.getDiscountAmount())).append(SEP)
              .append(esc(t.getCustomerName() != null ? t.getCustomerName() : "")).append(SEP)
              .append(t.getWorker() != null ? esc(t.getWorker().getName()) : "").append("\n");
        }

        log.info("Havi booking export: branch={}, month={}, rows={}", branchId, yearMonth, transactions.size());
        return addBom(sb.toString());
    }

    /**
     * Készlet export CSV.
     */
    public byte[] exportInventoryReport(UUID branchId, LocalDate date) {
        List<InventorySummary> summaries = inventorySummaryRepository.findByBranchIdAndSummaryDate(branchId, date);

        StringBuilder sb = new StringBuilder();
        sb.append("Valuta").append(SEP)
          .append("Készlet").append(SEP)
          .append("Napi vétel (HUF)").append(SEP)
          .append("Napi eladás (HUF)").append(SEP)
          .append("Napi díj (HUF)").append(SEP)
          .append("Bank kivét").append(SEP)
          .append("Bank befizetés").append(SEP)
          .append("Dátum").append("\n");

        for (InventorySummary s : summaries) {
            sb.append(s.getCurrency() != null ? s.getCurrency().getCode() : "").append(SEP)
              .append(fmtNum(s.getCurrentStock())).append(SEP)
              .append(fmtNum(s.getDailyBuyTotal())).append(SEP)
              .append(fmtNum(s.getDailySellTotal())).append(SEP)
              .append(fmtNum(s.getDailyFeeTotal())).append(SEP)
              .append(fmtNum(s.getBankWithdrawTotal())).append(SEP)
              .append(fmtNum(s.getBankDepositTotal())).append(SEP)
              .append(date.format(DATE_FMT)).append("\n");
        }

        log.info("Készlet export: branch={}, date={}, rows={}", branchId, date, summaries.size());
        return addBom(sb.toString());
    }

    // ============ HELPER ============

    private byte[] addBom(String csv) {
        byte[] csvBytes = csv.getBytes(StandardCharsets.UTF_8);
        byte[] result = new byte[UTF8_BOM.length + csvBytes.length];
        System.arraycopy(UTF8_BOM, 0, result, 0, UTF8_BOM.length);
        System.arraycopy(csvBytes, 0, result, UTF8_BOM.length, csvBytes.length);
        return result;
    }

    private String esc(String value) {
        if (value == null) return "";
        if (value.contains(SEP) || value.contains("\"") || value.contains("\n")) {
            return "\"" + value.replace("\"", "\"\"") + "\"";
        }
        return value;
    }

    private String fmtNum(BigDecimal value) {
        if (value == null) return "0";
        return value.toPlainString();
    }
}
