package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.report.AverageRateReportResponse;
import hu.puzzleir.valuta.dto.report.AverageRateReportResponse.ColumnGroup;
import hu.puzzleir.valuta.dto.report.AverageRateReportResponse.ColumnValues;
import hu.puzzleir.valuta.dto.report.AverageRateReportResponse.CurrencyRow;
import lombok.RequiredArgsConstructor;
import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.CellStyle;
import org.apache.poi.ss.usermodel.Font;
import org.apache.poi.ss.usermodel.HorizontalAlignment;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.ss.util.CellRangeAddress;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.stereotype.Service;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

/**
 * FK-027: az átlag árfolyam pivot riport Excel exportja (legacy Atlagarfolyam.xls parity).
 *
 * <p>MINDIG a teljes "Összes iroda" struktúra (8 terület + "EXCLUSIVE BEST CHANGE ZRT"
 * összesítő), 22 valuta-sorral, oszlopcsoportonként 4 oszloppal: Vétel Árfolyam, Vétel
 * Összeg, Eladás Árfolyam, Eladás Összeg. Az "Iroda" képernyő-szűrő NEM szűkíti az
 * exportot — csak a dátum-intervallum (FR-8).</p>
 */
@Service
@RequiredArgsConstructor
public class AverageRateReportExcelService {

    private final AverageRateReportService reportService;

    private static final String[] SUB_HEADERS = {
            "Vétel Árfolyam", "Vétel Összeg", "Eladás Árfolyam", "Eladás Összeg"
    };

    public byte[] generate(UUID companyId, LocalDate from, LocalDate to) {
        // FR-8: az export mindig a teljes 9-oszlopcsoportos struktúra (branchId = null).
        AverageRateReportResponse data = reportService.generatePivot(companyId, from, to, null);

        try (XSSFWorkbook wb = new XSSFWorkbook();
             ByteArrayOutputStream baos = new ByteArrayOutputStream()) {

            Sheet sheet = wb.createSheet("Átlag árfolyam");
            CellStyle titleStyle = boldStyle(wb, 14);
            CellStyle headerStyle = boldStyle(wb, 10);
            CellStyle numberStyle = wb.createCellStyle();
            numberStyle.setDataFormat(wb.createDataFormat().getFormat("#,##0.0000"));

            int r = 0;
            Row titleRow = sheet.createRow(r++);
            Cell titleCell = titleRow.createCell(0);
            titleCell.setCellValue("Átlag árfolyam riport  " + from + " — " + to);
            titleCell.setCellStyle(titleStyle);
            r++; // üres sor

            // Fejléc: 1. sor = oszlopcsoport-nevek (4 oszlopra mergelve), 2. sor = alfejlécek.
            int groupRowIdx = r;
            int subRowIdx = r + 1;
            Row groupRow = sheet.createRow(groupRowIdx);
            Row subRow = sheet.createRow(subRowIdx);
            Cell currencyHdr = groupRow.createCell(0);
            currencyHdr.setCellValue("Valuta");
            currencyHdr.setCellStyle(headerStyle);

            int col = 1;
            for (ColumnGroup g : data.getColumnGroups()) {
                Cell gc = groupRow.createCell(col);
                gc.setCellValue(g.getGroupName());
                gc.setCellStyle(headerStyle);
                sheet.addMergedRegion(new CellRangeAddress(groupRowIdx, groupRowIdx, col, col + 3));
                for (int i = 0; i < SUB_HEADERS.length; i++) {
                    Cell sc = subRow.createCell(col + i);
                    sc.setCellValue(SUB_HEADERS[i]);
                    sc.setCellStyle(headerStyle);
                }
                col += 4;
            }
            r += 2;

            // Adatsorok: 22 valuta, oszlopcsoportonként 4 érték.
            for (CurrencyRow cr : data.getCurrencyRows()) {
                Row row = sheet.createRow(r++);
                row.createCell(0).setCellValue(cr.getCurrencyCode());
                int c = 1;
                for (ColumnGroup g : data.getColumnGroups()) {
                    ColumnValues v = cr.getValues().get(g.getGroupCode());
                    writeNumber(row, c++, v == null ? null : v.getBuyAvgRate(), numberStyle);
                    writeNumber(row, c++, v == null ? null : v.getBuySumAmount(), numberStyle);
                    writeNumber(row, c++, v == null ? null : v.getSellAvgRate(), numberStyle);
                    writeNumber(row, c++, v == null ? null : v.getSellSumAmount(), numberStyle);
                }
            }

            sheet.createFreezePane(1, subRowIdx + 1);
            wb.write(baos);
            return baos.toByteArray();
        } catch (IOException e) {
            throw new IllegalStateException("Átlag árfolyam Excel export sikertelen", e);
        }
    }

    private static void writeNumber(Row row, int col, BigDecimal value, CellStyle style) {
        Cell cell = row.createCell(col);
        cell.setCellValue(value != null ? value.doubleValue() : 0d);
        cell.setCellStyle(style);
    }

    private static CellStyle boldStyle(Workbook wb, int points) {
        CellStyle style = wb.createCellStyle();
        Font font = wb.createFont();
        font.setBold(true);
        font.setFontHeightInPoints((short) points);
        style.setFont(font);
        style.setAlignment(HorizontalAlignment.CENTER);
        return style;
    }
}
