package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.report.AverageRateReportResponse;
import hu.puzzleir.valuta.dto.report.AverageRateReportResponse.ColumnGroup;
import hu.puzzleir.valuta.dto.report.AverageRateReportResponse.ColumnValues;
import hu.puzzleir.valuta.dto.report.AverageRateReportResponse.CurrencyRow;
import hu.puzzleir.valuta.dto.report.AverageRateReportResponse.GroupType;
import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.CellType;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.io.ByteArrayInputStream;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

/**
 * FK-027 (FR-8) — az átlag árfolyam Excel export tesztje: a generált .xlsx olvasható és
 * tartalmazza a valuta-sorokat + az oszlopcsoport-fejlécet.
 */
@ExtendWith(MockitoExtension.class)
class AverageRateReportExcelServiceTest {

    @Mock
    private AverageRateReportService reportService;

    @InjectMocks
    private AverageRateReportExcelService excelService;

    @Test
    @DisplayName("Az export olvasható .xlsx-et ad, a valuta-sorral és az oszlopcsoport-névvel")
    void generate_producesReadableXlsx() throws Exception {
        ColumnGroup total = ColumnGroup.builder()
                .groupCode("total").groupName("EXCLUSIVE BEST CHANGE ZRT")
                .groupType(GroupType.TOTAL).build();
        ColumnValues vals = ColumnValues.builder()
                .buyAvgRate(new BigDecimal("400")).buySumAmount(new BigDecimal("1000"))
                .sellAvgRate(new BigDecimal("420")).sellSumAmount(new BigDecimal("500")).build();
        CurrencyRow eur = CurrencyRow.builder()
                .currencyCode("EUR").values(Map.of("total", vals)).build();
        AverageRateReportResponse resp = AverageRateReportResponse.builder()
                .periodStart(LocalDate.of(2026, 6, 1)).periodEnd(LocalDate.of(2026, 6, 30))
                .columnGroups(List.of(total)).currencyRows(List.of(eur)).build();

        when(reportService.generatePivot(any(), any(), any(), any())).thenReturn(resp);

        byte[] xlsx = excelService.generate(
                UUID.randomUUID(), LocalDate.of(2026, 6, 1), LocalDate.of(2026, 6, 30));

        assertThat(xlsx).isNotEmpty();

        boolean foundEur = false;
        boolean foundGroup = false;
        try (XSSFWorkbook wb = new XSSFWorkbook(new ByteArrayInputStream(xlsx))) {
            Sheet sheet = wb.getSheetAt(0);
            for (Row row : sheet) {
                for (Cell cell : row) {
                    if (cell.getCellType() == CellType.STRING) {
                        String s = cell.getStringCellValue();
                        if ("EUR".equals(s)) {
                            foundEur = true;
                        }
                        if (s.contains("EXCLUSIVE BEST CHANGE")) {
                            foundGroup = true;
                        }
                    }
                }
            }
        }
        assertThat(foundEur).as("EUR valuta-sor").isTrue();
        assertThat(foundGroup).as("EXCLUSIVE BEST CHANGE ZRT oszlopcsoport-fejléc").isTrue();
    }
}
