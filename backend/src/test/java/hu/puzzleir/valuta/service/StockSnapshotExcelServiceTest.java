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

    // FK-006 follow-up: a snapshot DTO most a központi valutanem-törzs sorrendjét hordozza
    // (StockSnapshotService.resolveCurrencyCodes). A teszt-fixture-höz egy stabil, a korábbi
    // FK-003/004 sorrendű 27-elemű lista — a teszt kifejezetten azt méri, hogy az Excel
    // dinamikusan, a megkapott DTO sorrendjére épít, függetlenül a service belső kódlistájától.
    private static final List<String> TEST_CURRENCY_CODES = List.of(
            "AUD", "BAM", "BGN", "BRL", "CAD", "CHF",
            "CNY", "CZK", "DKK", "EUR", "GBP", "HRK",
            "ILS", "JPY", "MXN", "NOK", "NZD", "PLN",
            "RON", "RSD", "RUB", "SEK", "THB", "TRY",
            "UAH", "USD", "HUF"
    );

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
            // FK-003: lap-elnevezés a megjelenítő névből (ismeretlen régiónévre fallback: "...I körzet"),
            // a 9. lap = "Összesítő".
            assertEquals("REGION_0I körzet", wb.getSheetName(0));
            assertEquals("REGION_1I körzet", wb.getSheetName(1));
            assertEquals("Összesítő", wb.getSheetName(2));
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

            // FK-003: HUF-utolsó sorrend → USD index 25 (row 32), HUF index 26 (row 33, utolsó).
            Row usdRow = sheet.getRow(32);
            assertNotNull(usdRow);
            assertEquals("USD", usdRow.getCell(0).getStringCellValue());
            Row hufRow = sheet.getRow(33);
            assertNotNull(hufRow);
            assertEquals("HUF", hufRow.getCell(0).getStringCellValue());
        }
    }

    @Test
    void generateFullWorkbook_noWuRows() throws IOException {
        // FK-003: a WESTERN UNION / ÁFA / KEZELÉSI DÍJ / ELEKT. KERESKEDÉS / FOGLALÓK sorok
        // az új exportban NEM szerepelnek — a korábbi WU-sorok helyén (index 37-42) nincs WU-címke.
        StockSnapshotDto snapshot = buildSnapshotWithData();
        byte[] bytes = service.generateFullWorkbook(snapshot);
        try (Workbook wb = new XSSFWorkbook(new ByteArrayInputStream(bytes))) {
            Sheet sheet = wb.getSheetAt(0);
            for (int r = 35; r <= 45; r++) {
                Row row = sheet.getRow(r);
                if (row == null) continue;
                Cell c0 = row.getCell(0);
                if (c0 != null && c0.getCellType() == CellType.STRING) {
                    String v = c0.getStringCellValue();
                    assertFalse(v.contains("WESTERN UNION") || v.equals("ÁFA")
                            || v.equals("KEZELÉSI DÍJ") || v.equals("ELEKT. KERESKEDÉS") || v.equals("FOGLALÓK"),
                            "WU/ÁFA/díj sor nem szerepelhet az új exportban (row " + r + "): " + v);
                }
            }
        }
    }

    @Test
    void generateFullWorkbook_summarySheetExists() throws IOException {
        StockSnapshotDto snapshot = buildSnapshot(3);
        byte[] bytes = service.generateFullWorkbook(snapshot);
        try (Workbook wb = new XSSFWorkbook(new ByteArrayInputStream(bytes))) {
            Sheet summary = wb.getSheet("Összesítő");
            assertNotNull(summary, "Összesítő sheet should exist");

            // Title row
            Row titleRow = summary.getRow(1);
            assertNotNull(titleRow);
            assertEquals("EXCLUSIVE BEST CHANGE ZRT. KÉSZLETEI ÉS FORGALMA",
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
            Sheet summary = wb.getSheet("Összesítő");
            Row headerRow = summary.getRow(3);
            // Region names in col 2 and col 4 — megjelenítő név (fallback: "...I körzet")
            assertEquals("REGION_0I körzet", headerRow.getCell(2).getStringCellValue());
            assertEquals("REGION_1I körzet", headerRow.getCell(4).getStringCellValue());
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
            assertEquals("Összesítő", wb.getSheetName(0));
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
        for (int i = 0; i < TEST_CURRENCY_CODES.size(); i++) {
            String code = TEST_CURRENCY_CODES.get(i);
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
        List<CurrencyStockDetailDto> currencies = TEST_CURRENCY_CODES.stream()
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
        List<String> codes = TEST_CURRENCY_CODES;
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

    @Test
    void generateFullWorkbook_dynamicRowPositions_30Currencies_noOverlap() throws IOException {
        // FK-006 P1: 30 kódú lista (27 alap + 3 leftover) — a régi hardcoded 34/46/48 sor-pozíciók
        // ütközéssel jártak volna (7+29=36 > 34). A dinamikus pozíciók: total=7+30=37,
        // turnoverHeader=37+12=49, turnoverStart=51. Asserteljük, hogy a teszt valutái a HELYES
        // sorokban jelennek meg, és nincs ÖSSZESEN-felülírás.
        List<String> codes30 = new ArrayList<>(TEST_CURRENCY_CODES);
        codes30.add("XAU"); codes30.add("XAG"); codes30.add("XPT"); // 3 extra leftover-szerű kód

        List<CurrencyStockDetailDto> currencies = new ArrayList<>();
        for (int i = 0; i < codes30.size(); i++) {
            currencies.add(CurrencyStockDetailDto.builder()
                    .currencyCode(codes30.get(i)).stock((i + 1) * 100L).stockHuf((i + 1) * 360L * 100L)
                    .build());
        }
        BranchSnapshotDto branch = BranchSnapshotDto.builder()
                .branchId(UUID.randomUUID()).branchName("B").branchCode("B").currencies(currencies)
                .wuBalance(WuBalanceDetailDto.builder().build()).reservations(List.of()).build();
        BranchStockTotalsDto totals = BranchStockTotalsDto.builder()
                .currencies(currencies).wuBalance(WuBalanceDetailDto.builder().build()).reservations(List.of()).build();
        RegionSnapshotDto region = RegionSnapshotDto.builder()
                .regionCode("10").regionName("TESTREGION").branches(List.of(branch)).totals(totals).build();
        StockSnapshotDto snapshot = StockSnapshotDto.builder()
                .snapshotTime(LocalDateTime.now()).companyId(UUID.randomUUID())
                .regions(List.of(region)).companyTotals(totals).build();

        byte[] bytes = service.generateFullWorkbook(snapshot);
        try (Workbook wb = new XSSFWorkbook(new ByteArrayInputStream(bytes))) {
            Sheet sheet = wb.getSheetAt(0); // region sheet

            // Stock-szekció: utolsó kód (XPT) a 7+29=36-os sorban
            Row lastStockRow = sheet.getRow(36);
            assertNotNull(lastStockRow, "30. valuta sora létezik (dinamikus pozíció)");
            assertEquals("XPT", lastStockRow.getCell(0).getStringCellValue());

            // ÖSSZESEN a 37-es sorban (7+30) — NEM az adat-blokkban
            Row totalRow = sheet.getRow(37);
            assertNotNull(totalRow);
            assertEquals("ÖSSZESEN", totalRow.getCell(0).getStringCellValue());

            // NAPI FORGALOM a 49-es sorban (37+12)
            Row turnoverHeaderRow = sheet.getRow(49);
            assertNotNull(turnoverHeaderRow);
            assertEquals("NAPI FORGALOM", turnoverHeaderRow.getCell(0).getStringCellValue());

            // Első forgalom-sor a 51-es sorban (49+2): AUD (codes30.get(0))
            Row firstTurnoverRow = sheet.getRow(51);
            assertNotNull(firstTurnoverRow);
            assertEquals("AUD", firstTurnoverRow.getCell(0).getStringCellValue());
        }
    }

    private BranchStockTotalsDto createEmptyTotals() {
        return BranchStockTotalsDto.builder()
                .currencies(TEST_CURRENCY_CODES.stream()
                        .map(code -> CurrencyStockDetailDto.builder().currencyCode(code).build())
                        .toList())
                .wuBalance(WuBalanceDetailDto.builder().build())
                .reservations(List.of())
                .build();
    }
}
