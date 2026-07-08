package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.compliance.ComplianceTransactionRowDto;
import hu.puzzleir.valuta.entity.PaymentMethod;
import hu.puzzleir.valuta.entity.TransactionStatus;
import hu.puzzleir.valuta.entity.TransactionType;
import hu.puzzleir.valuta.exception.BusinessException;
import lombok.extern.slf4j.Slf4j;
import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.stereotype.Service;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.List;

/**
 * FS-11 S1: cégszintű compliance tranzakció-lista CSV/XLSX export.
 * Az export ugyanazokat a RowDto értékeket írja ki, újrakerekítés és csonkolás nélkül.
 */
@Service
@Slf4j
public class ComplianceTransactionExportService {

    private static final DateTimeFormatter DATE_FMT = DateTimeFormatter.ofPattern("yyyy.MM.dd");
    private static final String[] HEADERS = {
            "Bizonylatszám", "Típus", "Státusz", "Dátum", "Idő", "Iroda", "Valuta",
            "Valuta összeg", "Árfolyam", "Ft összeg", "Fizetés módja", "Egyedi árfolyam",
            "KK kedvezmény", "PEP", "Más nevében", "AML gyanús", "Ügyfél név", "Születési dátum",
            "Állampolgárság", "Okmányszám", "Jogi személy", "Cégnév", "Adószám", "Pénztáros"
    };

    public byte[] toCsv(List<ComplianceTransactionRowDto> rows) {
        StringBuilder builder = new StringBuilder("\uFEFF");
        appendCsvLine(builder, List.of(HEADERS));
        for (ComplianceTransactionRowDto row : rows) {
            appendCsvLine(builder, values(row));
        }
        return builder.toString().getBytes(StandardCharsets.UTF_8);
    }

    public byte[] toXlsx(List<ComplianceTransactionRowDto> rows) {
        try (XSSFWorkbook workbook = new XSSFWorkbook()) {
            Sheet sheet = workbook.createSheet("Tranzakciók");
            Row headerRow = sheet.createRow(0);
            for (int i = 0; i < HEADERS.length; i++) {
                headerRow.createCell(i).setCellValue(HEADERS[i]);
                sheet.setColumnWidth(i, 18 * 256);
            }
            for (int rowIndex = 0; rowIndex < rows.size(); rowIndex++) {
                writeXlsxRow(sheet.createRow(rowIndex + 1), rows.get(rowIndex));
            }
            ByteArrayOutputStream baos = new ByteArrayOutputStream();
            workbook.write(baos);
            return baos.toByteArray();
        } catch (IOException e) {
            log.error("Compliance export XLSX generálás sikertelen", e);
            throw new BusinessException("Compliance export Excel generálás sikertelen", "EXCEL_GENERATION_FAILED");
        }
    }

    private static void appendCsvLine(StringBuilder builder, List<String> values) {
        for (int i = 0; i < values.size(); i++) {
            if (i > 0) {
                builder.append(CsvUtils.SEPARATOR);
            }
            builder.append(CsvUtils.escapeCsvCell(values.get(i)));
        }
        builder.append('\n');
    }

    private static List<String> values(ComplianceTransactionRowDto row) {
        return List.of(
                text(row.getReceiptNumber()),
                display(row.getTransactionType()),
                display(row.getStatus()),
                date(row.getTransactionDate()),
                time(row.getTransactionTime()),
                branch(row),
                text(row.getCurrencyCode()),
                decimal(row.getCurrencyAmount()),
                decimal(row.getExchangeRate()),
                decimal(row.getHufAmount()),
                display(row.getPaymentMethod()),
                yesNo(row.getCashierCustomRate()),
                yesNo(row.getKkDiscount()),
                yesNo(row.getCustomerIsPep()),
                onBehalf(row.getCustomerOnOwnBehalf()),
                yesNo(row.getAmlSuspicious()),
                text(row.getCustomerName()),
                date(row.getCustomerBirthDate()),
                text(row.getCustomerNationality()),
                text(row.getCustomerDocumentNumber()),
                yesNo(row.getIsLegalEntityCustomer()),
                text(row.getLegalEntityName()),
                text(row.getLegalEntityTaxNumber()),
                worker(row)
        );
    }

    private static void writeXlsxRow(Row xlsxRow, ComplianceTransactionRowDto row) {
        List<String> values = values(row);
        for (int i = 0; i < values.size(); i++) {
            Cell cell = xlsxRow.createCell(i);
            if (i == 7 || i == 8 || i == 9) {
                setNumericOrText(cell, values.get(i));
            } else {
                cell.setCellValue(values.get(i));
            }
        }
    }

    private static void setNumericOrText(Cell cell, String value) {
        if (value == null || value.isEmpty()) {
            cell.setBlank();
            return;
        }
        cell.setCellValue(new BigDecimal(value).doubleValue());
    }

    private static String display(TransactionType type) {
        return type == null ? "" : type.getDisplayName();
    }

    private static String display(TransactionStatus status) {
        return status == null ? "" : status.getDisplayName();
    }

    private static String display(PaymentMethod paymentMethod) {
        return paymentMethod == null ? "" : paymentMethod.getDisplayName();
    }

    private static String decimal(BigDecimal value) {
        return value == null ? "" : value.toPlainString();
    }

    private static String date(LocalDate value) {
        return value == null ? "" : value.format(DATE_FMT);
    }

    private static String time(LocalTime value) {
        return value == null ? "" : value.toString();
    }

    private static String yesNo(Boolean value) {
        return Boolean.TRUE.equals(value) ? "igen" : "nem";
    }

    private static String onBehalf(Boolean customerOnOwnBehalf) {
        if (customerOnOwnBehalf == null) {
            return "";
        }
        return Boolean.FALSE.equals(customerOnOwnBehalf) ? "igen" : "nem";
    }

    private static String branch(ComplianceTransactionRowDto row) {
        if (row.getBranchCode() == null || row.getBranchCode().isBlank()) {
            return text(row.getBranchName());
        }
        if (row.getBranchName() == null || row.getBranchName().isBlank()) {
            return text(row.getBranchCode());
        }
        return row.getBranchCode() + " - " + row.getBranchName();
    }

    private static String worker(ComplianceTransactionRowDto row) {
        if (row.getWorkerCode() == null || row.getWorkerCode().isBlank()) {
            return text(row.getWorkerName());
        }
        if (row.getWorkerName() == null || row.getWorkerName().isBlank()) {
            return text(row.getWorkerCode());
        }
        return row.getWorkerCode() + " - " + row.getWorkerName();
    }

    private static String text(String value) {
        return value == null ? "" : value;
    }
}
