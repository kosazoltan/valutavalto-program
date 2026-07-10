package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.compliance.SuspiciousCustomerDto;
import hu.puzzleir.valuta.exception.BusinessException;
import lombok.extern.slf4j.Slf4j;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.stereotype.Service;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.List;

/**
 * FS-12 S1: gyanús ügyfél XLSX export.
 */
@Service
@Slf4j
public class SuspiciousCustomerExportService {

    private static final String[] HEADERS = {
            "Ügyfél azonosító", "Ügyfél név", "Tranzakciók száma", "Össz. érték (Ft)", "Váltópontok száma"
    };

    public byte[] toXlsx(List<SuspiciousCustomerDto> rows) {
        try (XSSFWorkbook workbook = new XSSFWorkbook()) {
            Sheet sheet = workbook.createSheet("Gyanús ügyfelek");
            Row headerRow = sheet.createRow(0);
            for (int i = 0; i < HEADERS.length; i++) {
                headerRow.createCell(i).setCellValue(HEADERS[i]);
                sheet.setColumnWidth(i, 18 * 256);
            }
            for (int rowIndex = 0; rowIndex < rows.size(); rowIndex++) {
                writeRow(sheet.createRow(rowIndex + 1), rows.get(rowIndex));
            }
            ByteArrayOutputStream baos = new ByteArrayOutputStream();
            workbook.write(baos);
            return baos.toByteArray();
        } catch (IOException e) {
            log.error("Gyanús ügyfél export XLSX generálás sikertelen", e);
            throw new BusinessException("Gyanús ügyfél export Excel generálás sikertelen", "EXCEL_GENERATION_FAILED");
        }
    }

    private static void writeRow(Row row, SuspiciousCustomerDto dto) {
        row.createCell(0).setCellValue(dto.getCustomerId() != null ? dto.getCustomerId() : "");
        row.createCell(1).setCellValue(dto.getCustomerName() != null ? dto.getCustomerName() : "");
        row.createCell(2).setCellValue(dto.getTransactionCount());
        row.createCell(3).setCellValue(dto.getTotalHufAmount() != null ? dto.getTotalHufAmount().doubleValue() : 0d);
        row.createCell(4).setCellValue(dto.getBranchCount());
    }
}
