package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.compliance.SuspiciousCustomerDto;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.io.ByteArrayInputStream;
import java.math.BigDecimal;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * FS-12 S1: gyanús ügyfél XLSX export artefakt tesztek.
 */
class SuspiciousCustomerExportServiceTest {

    private final SuspiciousCustomerExportService service = new SuspiciousCustomerExportService();

    @Test
    @DisplayName("FS-12 S1: XLSX visszaolvasható, magyar sheet/header és numerikus metrika-cellák")
    void xlsxIsReadableWithHungarianHeaderAndNumericMetrics() throws Exception {
        byte[] bytes = service.toXlsx(List.of(dto("C-123", "Kovács Béla", 17, new BigDecimal("12345678.50"), 4)));

        try (Workbook workbook = new XSSFWorkbook(new ByteArrayInputStream(bytes))) {
            Sheet sheet = workbook.getSheet("Gyanús ügyfelek");
            assertThat(sheet).isNotNull();
            assertThat(sheet.getPhysicalNumberOfRows()).isEqualTo(2);
            assertThat(sheet.getRow(0).getCell(0).getStringCellValue()).isEqualTo("Ügyfél azonosító");
            assertThat(sheet.getRow(0).getCell(3).getStringCellValue()).isEqualTo("Össz. érték (Ft)");
            assertThat(sheet.getRow(1).getCell(0).getStringCellValue()).isEqualTo("C-123");
            assertThat(sheet.getRow(1).getCell(2).getNumericCellValue()).isEqualTo(17d);
            assertThat(sheet.getRow(1).getCell(3).getNumericCellValue()).isEqualTo(12345678.50d);
            assertThat(sheet.getRow(1).getCell(4).getNumericCellValue()).isEqualTo(4d);
        }
    }

    private static SuspiciousCustomerDto dto(String customerId, String customerName, long count, BigDecimal total, long branches) {
        return SuspiciousCustomerDto.builder()
                .customerId(customerId)
                .customerName(customerName)
                .transactionCount(count)
                .totalHufAmount(total)
                .branchCount(branches)
                .highTransactionCount(true)
                .highTotalValue(true)
                .manyBranches(true)
                .build();
    }
}
