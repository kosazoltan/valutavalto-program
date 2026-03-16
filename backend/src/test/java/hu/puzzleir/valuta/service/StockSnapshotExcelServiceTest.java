package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.stocksnapshot.*;
import org.apache.poi.ss.usermodel.*;
import org.apache.poi.ss.util.PaneInformation;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

class StockSnapshotExcelServiceTest {

    private StockSnapshotExcelService service;

    @BeforeEach
    void setUp() {
        service = new StockSnapshotExcelService();
    }

    @Test
    void generateFullWorkbook_sheetCountAndNames() throws IOException {
        StockSnapshotDto snapshot = buildSnapshot(2); // 2 regions
        byte[] bytes = service.generateFullWorkbook(snapshot);
        try (Workbook wb = new XSSFWorkbook(new ByteArrayInputStream(bytes))) {
            // 2 region sheets + 1 summary = 3
            assertEquals(3, wb.getNumberOfSheets());
            assertEquals("REGION_0I KÖRZET", wb.getSheetName(0));
            assertEquals("REGION_1I KÖRZET", wb.getSheetName(1));
            assertEquals("EXCLUSIVE CHANGE", wb.getSheetName(2));
        }
    }

    @Test
    void generateFullWorkbook_currencyDataInCorrectCells() throws IOException {
        StockSnapshotDto snapshot = buildSnapshotWithData();
        byte[] bytes = service.generateFullWorkbook(snapshot);
        try (Workbook wb = new XSSFWorkbook(new ByteArrayInputStream(bytes))) {
            Sheet sheet = wb.getSheetAt(0);

            // EUR is index 9 in CURRENCY_CODES → row index 7+9=16
            Row eurRow = sheet.getRow(16);
            assertNotNull(eurRow, "EUR row (index 16) should exist");
            assertEquals("EUR", eurRow.getCell(0).getStringCellValue());
            assertEquals("EURÓ", eurRow.getCell(1).getStringCellValue());

            // Branch 0 stock in col 2, stockHuf in col 3
            assertEquals(1000.0, eurRow.getCell(2).getNumericCellValue(), 0.01);
            assertEquals(360000.0, eurRow.getCell(3).getNumericCellValue(), 0.01);

            // AUD is index 0 → row index 7
            Row audRow = sheet.getRow(7);
            assertNotNull(audRow);
            assertEquals("AUD", audRow.getCell(0).getStringCellValue());

            // USD is index 26 → row index 33
            Row usdRow = sheet.getRow(33);
            assertNotNull(usdRow);
            assertEquals("USD", usdRow.getCell(0).getStringCellValue());
        }
    }

    @Test
    void generateFullWorkbook_wuDataInCorrectRow() throws IOException {
        StockSnapshotDto snapshot = buildSnapshotWithData();
        byte[] bytes = service.generateFullWorkbook(snapshot);
        try (Workbook wb = new XSSFWorkbook(new ByteArrayInputStream(bytes))) {
            Sheet sheet = wb.getSheetAt(0);

            // WU USD at row index 37
            Row wuUsdRow = sheet.getRow(37);
            assertNotNull(wuUsdRow, "WU USD row (index 37) should exist");
            assertEquals("WESTERN UNION (USD)", wuUsdRow.getCell(0).getStringCellValue());
            // WU USD value for branch 0 at col 2
            assertEquals(500.0, wuUsdRow.getCell(2).getNumericCellValue(), 0.01);

            // WU HUF at row index 38
            Row wuHufRow = sheet.getRow(38);
            assertNotNull(wuHufRow);
            assertEquals("WESTERN UNION (HUF)", wuHufRow.getCell(0).getStringCellValue());
            assertEquals(150000.0, wuHufRow.getCell(2).getNumericCellValue(), 0.01);
        }
    }

    @Test
    void generateFullWorkbook_summarySheetExists() throws IOException {
        StockSnapshotDto snapshot = buildSnapshot(3);
        byte[] bytes = service.generateFullWorkbook(snapshot);
        try (Workbook wb = new XSSFWorkbook(new ByteArrayInputStream(bytes))) {
            Sheet summary = wb.getSheet("EXCLUSIVE CHANGE");
            assertNotNull(summary, "EXCLUSIVE CHANGE sheet should exist");

            // Title row
            Row titleRow = summary.getRow(1);
            assertNotNull(titleRow);
            assertEquals("EXCLUSIVE CHANGE KÉSZLETEI ÉS FORGALMA",
                    titleRow.getCell(0).getStringCellValue());
        }
    }

    @Test
    void generateFullWorkbook_turnoverDataInCorrectRows() throws IOException {
        StockSnapshotDto snapshot = buildSnapshotWithData();
        byte[] bytes = service.generateFullWorkbook(snapshot);
        try (Workbook wb = new XSSFWorkbook(new ByteArrayInputStream(bytes))) {
            Sheet sheet = wb.getSheetAt(0);

            // EUR is index 9 → turnover qty row = 48 + 9*2 = 66
            Row eurTurnoverQty = sheet.getRow(66);
            assertNotNull(eurTurnoverQty, "EUR turnover row (index 66) should exist");
            assertEquals("EUR", eurTurnoverQty.getCell(0).getStringCellValue());
            // dailyBuy for branch 0 at col 2
            assertEquals(50.0, eurTurnoverQty.getCell(2).getNumericCellValue(), 0.01);
            // dailySell for branch 0 at col 3
            assertEquals(30.0, eurTurnoverQty.getCell(3).getNumericCellValue(), 0.01);

            // EUR HUF turnover row = 67
            // EUR index=9, baseStock=1000, baseStockHuf=360000
            // dailyBuyHuf=360000/20=18000, dailySellHuf=360000/33=10909 (integer division)
            Row eurTurnoverHuf = sheet.getRow(67);
            assertNotNull(eurTurnoverHuf);
            assertEquals(18000.0, eurTurnoverHuf.getCell(2).getNumericCellValue(), 0.01);
            assertEquals(10909.0, eurTurnoverHuf.getCell(3).getNumericCellValue(), 0.01);

            // AUD is index 0 → turnover row = 48
            Row audTurnover = sheet.getRow(48);
            assertNotNull(audTurnover);
            assertEquals("AUD", audTurnover.getCell(0).getStringCellValue());
        }
    }

    @Test
    void generateFullWorkbook_freezePaneAtC8() throws IOException {
        StockSnapshotDto snapshot = buildSnapshot(1);
        byte[] bytes = service.generateFullWorkbook(snapshot);
        try (Workbook wb = new XSSFWorkbook(new ByteArrayInputStream(bytes))) {
            Sheet sheet = wb.getSheetAt(0);
            // Freeze pane: col split=2 (C), row split=7 (row 8 in 1-based)
            PaneInformation pane = sheet.getPaneInformation();
            assertNotNull(pane, "Freeze pane should be set");
            assertEquals(2, pane.getVerticalSplitPosition());
            assertEquals(7, pane.getHorizontalSplitPosition());
        }
    }

    @Test
    void generateFullWorkbook_totalRowAt34() throws IOException {
        StockSnapshotDto snapshot = buildSnapshotWithData();
        byte[] bytes = service.generateFullWorkbook(snapshot);
        try (Workbook wb = new XSSFWorkbook(new ByteArrayInputStream(bytes))) {
            Sheet sheet = wb.getSheetAt(0);
            Row totalRow = sheet.getRow(34);
            assertNotNull(totalRow);
            assertEquals("ÖSSZESEN", totalRow.getCell(0).getStringCellValue());
        }
    }

    @Test
    void generateFullWorkbook_turnoverTotalRowAt102() throws IOException {
        StockSnapshotDto snapshot = buildSnapshotWithData();
        byte[] bytes = service.generateFullWorkbook(snapshot);
        try (Workbook wb = new XSSFWorkbook(new ByteArrayInputStream(bytes))) {
            Sheet sheet = wb.getSheetAt(0);
            Row turnoverTotal = sheet.getRow(102);
            assertNotNull(turnoverTotal);
            assertEquals("ÖSSZESEN", turnoverTotal.getCell(0).getStringCellValue());
        }
    }

    @Test
    void generateFullWorkbook_summarySheetUsesRegionsAsColumns() throws IOException {
        StockSnapshotDto snapshot = buildSnapshot(2);
        byte[] bytes = service.generateFullWorkbook(snapshot);
        try (Workbook wb = new XSSFWorkbook(new ByteArrayInputStream(bytes))) {
            Sheet summary = wb.getSheet("EXCLUSIVE CHANGE");
            Row headerRow = summary.getRow(3);
            // Region names in col 2 and col 4
            assertEquals("REGION_0", headerRow.getCell(2).getStringCellValue());
            assertEquals("REGION_1", headerRow.getCell(4).getStringCellValue());
        }
    }

    @Test
    void generateFullWorkbook_emptyRegions() throws IOException {
        StockSnapshotDto snapshot = StockSnapshotDto.builder()
                .snapshotTime(LocalDateTime.now())
                .companyId(UUID.randomUUID())
                .regions(List.of())
                .companyTotals(createEmptyTotals())
                .build();
        byte[] bytes = service.generateFullWorkbook(snapshot);
        try (Workbook wb = new XSSFWorkbook(new ByteArrayInputStream(bytes))) {
            // Only summary sheet
            assertEquals(1, wb.getNumberOfSheets());
            assertEquals("EXCLUSIVE CHANGE", wb.getSheetName(0));
        }
    }

    // --- Helper methods ---

    private StockSnapshotDto buildSnapshot(int regionCount) {
        List<RegionSnapshotDto> regions = new ArrayList<>();
        List<BranchSnapshotDto> allBranches = new ArrayList<>();

        for (int r = 0; r < regionCount; r++) {
            List<BranchSnapshotDto> branches = List.of(
                    createBranch("Branch_" + r + "_0"),
                    createBranch("Branch_" + r + "_1")
            );
            allBranches.addAll(branches);
            regions.add(RegionSnapshotDto.builder()
                    .regionCode(String.valueOf(r * 10))
                    .regionName("REGION_" + r)
                    .branches(branches)
                    .totals(aggregateTotals(branches))
                    .build());
        }

        return StockSnapshotDto.builder()
                .snapshotTime(LocalDateTime.of(2026, 3, 16, 14, 30))
                .companyId(UUID.randomUUID())
                .regions(regions)
                .companyTotals(aggregateTotals(allBranches))
                .build();
    }

    private StockSnapshotDto buildSnapshotWithData() {
        List<CurrencyStockDetailDto> currencies = new ArrayList<>();
        for (int i = 0; i < StockSnapshotService.CURRENCY_CODES.size(); i++) {
            String code = StockSnapshotService.CURRENCY_CODES.get(i);
            long baseStock = (i + 1) * 100L;
            long baseStockHuf = baseStock * 360;
            currencies.add(CurrencyStockDetailDto.builder()
                    .currencyCode(code)
                    .stock(baseStock)
                    .stockHuf(baseStockHuf)
                    .dailyBuy(baseStock / 20)
                    .dailyBuyHuf(baseStockHuf / 20)
                    .dailySell(baseStock / 33)
                    .dailySellHuf(baseStockHuf / 33)
                    .build());
        }

        BranchSnapshotDto branch = BranchSnapshotDto.builder()
                .branchId(UUID.randomUUID())
                .branchName("TestBranch")
                .branchCode("TB01")
                .lastUpdated(LocalDateTime.of(2026, 3, 16, 14, 30))
                .currencies(currencies)
                .wuBalance(WuBalanceDetailDto.builder()
                        .wuUsd(500).wuHuf(150000).vat(27000).handlingFee(5000).eCommerce(8000)
                        .build())
                .reservations(List.of())
                .build();

        List<BranchSnapshotDto> branches = List.of(branch);
        BranchStockTotalsDto totals = aggregateTotals(branches);

        RegionSnapshotDto region = RegionSnapshotDto.builder()
                .regionCode("10")
                .regionName("TESTREGION")
                .branches(branches)
                .totals(totals)
                .build();

        return StockSnapshotDto.builder()
                .snapshotTime(LocalDateTime.of(2026, 3, 16, 14, 30))
                .companyId(UUID.randomUUID())
                .regions(List.of(region))
                .companyTotals(totals)
                .build();
    }

    private BranchSnapshotDto createBranch(String name) {
        List<CurrencyStockDetailDto> currencies = StockSnapshotService.CURRENCY_CODES.stream()
                .map(code -> CurrencyStockDetailDto.builder().currencyCode(code).build())
                .toList();

        return BranchSnapshotDto.builder()
                .branchId(UUID.randomUUID())
                .branchName(name)
                .branchCode(name)
                .lastUpdated(LocalDateTime.of(2026, 3, 16, 14, 0))
                .currencies(currencies)
                .wuBalance(WuBalanceDetailDto.builder().build())
                .reservations(List.of())
                .build();
    }

    private BranchStockTotalsDto aggregateTotals(List<BranchSnapshotDto> branches) {
        List<String> codes = StockSnapshotService.CURRENCY_CODES;
        List<CurrencyStockDetailDto> totalCurrencies = new ArrayList<>();

        for (int i = 0; i < codes.size(); i++) {
            long stock = 0, stockHuf = 0, dailyBuy = 0, dailyBuyHuf = 0, dailySell = 0, dailySellHuf = 0;
            for (BranchSnapshotDto branch : branches) {
                CurrencyStockDetailDto c = branch.getCurrencies().get(i);
                stock += c.getStock();
                stockHuf += c.getStockHuf();
                dailyBuy += c.getDailyBuy();
                dailyBuyHuf += c.getDailyBuyHuf();
                dailySell += c.getDailySell();
                dailySellHuf += c.getDailySellHuf();
            }
            totalCurrencies.add(CurrencyStockDetailDto.builder()
                    .currencyCode(codes.get(i))
                    .stock(stock).stockHuf(stockHuf)
                    .dailyBuy(dailyBuy).dailyBuyHuf(dailyBuyHuf)
                    .dailySell(dailySell).dailySellHuf(dailySellHuf)
                    .build());
        }

        long wuUsd = 0, wuHuf = 0, vat = 0, fee = 0, ecom = 0;
        for (BranchSnapshotDto b : branches) {
            if (b.getWuBalance() != null) {
                wuUsd += b.getWuBalance().getWuUsd();
                wuHuf += b.getWuBalance().getWuHuf();
                vat += b.getWuBalance().getVat();
                fee += b.getWuBalance().getHandlingFee();
                ecom += b.getWuBalance().getECommerce();
            }
        }

        return BranchStockTotalsDto.builder()
                .currencies(totalCurrencies)
                .wuBalance(WuBalanceDetailDto.builder()
                        .wuUsd(wuUsd).wuHuf(wuHuf).vat(vat).handlingFee(fee).eCommerce(ecom).build())
                .reservations(List.of())
                .build();
    }

    private BranchStockTotalsDto createEmptyTotals() {
        return BranchStockTotalsDto.builder()
                .currencies(StockSnapshotService.CURRENCY_CODES.stream()
                        .map(code -> CurrencyStockDetailDto.builder().currencyCode(code).build())
                        .toList())
                .wuBalance(WuBalanceDetailDto.builder().build())
                .reservations(List.of())
                .build();
    }
}
