package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.exception.BusinessException;

import hu.puzzleir.valuta.dto.stocksnapshot.*;
import lombok.extern.slf4j.Slf4j;
import org.apache.poi.ss.usermodel.*;
import org.apache.poi.ss.util.CellRangeAddress;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.stereotype.Service;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;

@Service
@Slf4j
public class StockSnapshotExcelService {

    // FK-006 follow-up: a valutakód-lista a snapshot DTO sorrendjét követi (az pedig a központi
    // valutanem-törzset, lásd StockSnapshotService.resolveCurrencyCodes). A megjelenítendő magyar
    // név kódról kulcsolva — ismeretlen leftover kód esetén magát a kódot mutatjuk (defensive).
    private static final Map<String, String> CURRENCY_NAMES = Map.ofEntries(
            Map.entry("AUD", "AUSZTRÁL DOLLÁR"),
            Map.entry("BAM", "BOSNYÁK MÁRKA"),
            Map.entry("BGN", "BOLGÁR LEVA"),
            Map.entry("BRL", "BRAZIL REÁL"),
            Map.entry("CAD", "KANADAI DOLLÁR"),
            Map.entry("CHF", "SVÁJCI FRANK"),
            Map.entry("CNY", "KÍNAI YUAN"),
            Map.entry("CZK", "CSEH KORONA"),
            Map.entry("DKK", "DÁN KORONA"),
            Map.entry("EUR", "EURÓ"),
            Map.entry("GBP", "ANGOL FONT"),
            Map.entry("HRK", "HORVÁT KUNA"),
            Map.entry("ILS", "IZRAELI SHEKEL"),
            Map.entry("JPY", "JAPÁN YEN"),
            Map.entry("MXN", "MEXIKÓI PESO"),
            Map.entry("NOK", "NORVÉG KORONA"),
            Map.entry("NZD", "ÚJ-ZÉLANDI DOLLÁR"),
            Map.entry("PLN", "LENGYEL ZLOTYI"),
            Map.entry("RON", "ROMÁN LEJ"),
            Map.entry("RSD", "SZERB DINÁR"),
            Map.entry("RUB", "OROSZ RUBEL"),
            Map.entry("SEK", "SVÉD KORONA"),
            Map.entry("THB", "THAI BAHT"),
            Map.entry("TRY", "TÖRÖK LÍRA"),
            Map.entry("UAH", "UKRÁN HRIVNYA"),
            Map.entry("USD", "AMERIKAI DOLLÁR"),
            Map.entry("HUF", "MAGYAR FORINT")
    );

    /** A totals DTO sorrendjéből vett kódlista — a snapshot szolgáltatás az igazságforrás. */
    private static List<String> extractCodes(BranchStockTotalsDto totals) {
        if (totals == null || totals.getCurrencies() == null) return List.of();
        return totals.getCurrencies().stream()
                .map(CurrencyStockDetailDto::getCurrencyCode)
                .filter(Objects::nonNull)
                .collect(java.util.stream.Collectors.toList());
    }

    private static String currencyNameOf(String code) {
        return CURRENCY_NAMES.getOrDefault(code, code != null ? code : "");
    }

    private static final DateTimeFormatter DATE_FMT = DateTimeFormatter.ofPattern("yyyy.MM.dd");
    private static final DateTimeFormatter TIME_FMT = DateTimeFormatter.ofPattern("HH:mm");

    // FK-003: a körzet-lapok megjelenítendő neve (a regionName UPPERCASE-ékezetmentes; itt
    // a spec szerinti „Szekszárdi körzet" formára képezzük). Ismeretlen → fallback.
    private static final Map<String, String> REGION_DISPLAY = Map.ofEntries(
            Map.entry("SZEKSZARD", "Szekszárdi körzet"),
            Map.entry("SZEGED", "Szegedi körzet"),
            Map.entry("KECSKEMET", "Kecskeméti körzet"),
            Map.entry("DEBRECEN", "Debreceni körzet"),
            Map.entry("NYIREGYHAZA", "Nyíregyházi körzet"),
            Map.entry("BEKESCSABA", "Békéscsabai körzet"),
            Map.entry("PECS", "Pécsi körzet"),
            Map.entry("KAPOSVAR", "Kaposvári körzet")
    );

    private static String regionDisplay(String regionName) {
        if (regionName == null) return "Körzet";
        String key = regionName.trim().toUpperCase(java.util.Locale.ROOT);
        return REGION_DISPLAY.getOrDefault(key, regionName + "I körzet");
    }

    // Pre-built style holder to reuse across sheets
    private CellStyle titleStyle;
    private CellStyle headerStyle;
    private CellStyle dataStyle;
    private CellStyle dataNumberStyle;
    private CellStyle totalStyle;
    private CellStyle totalNumberStyle;
    private CellStyle dateStyle;
    private CellStyle grayNumberStyle;
    private CellStyle turnoverHeaderStyle;
    private CellStyle currencyCodeStyle;
    private CellStyle currencyNameStyle;

    public byte[] generateFullWorkbook(StockSnapshotDto snapshot) {
        try (XSSFWorkbook workbook = new XSSFWorkbook()) {
            createStyles(workbook);

            // One sheet per region
            for (RegionSnapshotDto region : snapshot.getRegions()) {
                Sheet sheet = workbook.createSheet(regionDisplay(region.getRegionName()));
                writeRegionSheet(sheet, region, snapshot.getSnapshotTime());
            }

            // FK-003: 9. lap = Összesítő (teljes cég)
            Sheet summarySheet = workbook.createSheet("Összesítő");
            writeSummarySheet(summarySheet, snapshot);

            ByteArrayOutputStream baos = new ByteArrayOutputStream();
            workbook.write(baos);
            return baos.toByteArray();
        } catch (IOException e) {
            log.error("Készlet-snapshot Excel generálás sikertelen", e);
            throw new BusinessException("Failed to generate Excel workbook", "EXCEL_GENERATION_FAILED");
        }
    }

    private void createStyles(Workbook workbook) {
        // Fonts
        Font timesRoman16BoldItalic = workbook.createFont();
        timesRoman16BoldItalic.setFontName("Times New Roman");
        timesRoman16BoldItalic.setFontHeightInPoints((short) 16);
        timesRoman16BoldItalic.setBold(true);
        timesRoman16BoldItalic.setItalic(true);

        Font timesRoman12BoldItalic = workbook.createFont();
        timesRoman12BoldItalic.setFontName("Times New Roman");
        timesRoman12BoldItalic.setFontHeightInPoints((short) 12);
        timesRoman12BoldItalic.setBold(true);
        timesRoman12BoldItalic.setItalic(true);

        Font arial10 = workbook.createFont();
        arial10.setFontName("Arial");
        arial10.setFontHeightInPoints((short) 10);

        Font arial12BoldItalic = workbook.createFont();
        arial12BoldItalic.setFontName("Arial");
        arial12BoldItalic.setFontHeightInPoints((short) 12);
        arial12BoldItalic.setBold(true);
        arial12BoldItalic.setItalic(true);


        Font arial10Gray = workbook.createFont();
        arial10Gray.setFontName("Arial");
        arial10Gray.setFontHeightInPoints((short) 10);
        arial10Gray.setColor(IndexedColors.GREY_50_PERCENT.getIndex());

        // Title style: Times New Roman 16 bold italic, center
        titleStyle = workbook.createCellStyle();
        titleStyle.setFont(timesRoman16BoldItalic);
        titleStyle.setAlignment(HorizontalAlignment.CENTER);
        titleStyle.setVerticalAlignment(VerticalAlignment.CENTER);

        // Header style: Times New Roman 12 bold italic, center
        headerStyle = workbook.createCellStyle();
        headerStyle.setFont(timesRoman12BoldItalic);
        headerStyle.setAlignment(HorizontalAlignment.CENTER);
        headerStyle.setVerticalAlignment(VerticalAlignment.CENTER);

        // Data style: Arial 10
        dataStyle = workbook.createCellStyle();
        dataStyle.setFont(arial10);

        // Data number style: Arial 10, number format
        dataNumberStyle = workbook.createCellStyle();
        dataNumberStyle.setFont(arial10);
        dataNumberStyle.setDataFormat(workbook.createDataFormat().getFormat("### ### ###"));
        dataNumberStyle.setAlignment(HorizontalAlignment.CENTER);

        // Total style: Arial 12 bold italic, center
        totalStyle = workbook.createCellStyle();
        totalStyle.setFont(arial12BoldItalic);
        totalStyle.setAlignment(HorizontalAlignment.CENTER);

        // Total number style: Arial 12 bold italic, center, number format
        totalNumberStyle = workbook.createCellStyle();
        totalNumberStyle.setFont(arial12BoldItalic);
        totalNumberStyle.setAlignment(HorizontalAlignment.CENTER);
        totalNumberStyle.setDataFormat(workbook.createDataFormat().getFormat("### ### ###"));

        // Date style: Arial 10, center
        dateStyle = workbook.createCellStyle();
        dateStyle.setFont(arial10);
        dateStyle.setAlignment(HorizontalAlignment.CENTER);

        // Gray number style: Arial 10, gray color, number format
        grayNumberStyle = workbook.createCellStyle();
        grayNumberStyle.setFont(arial10Gray);
        grayNumberStyle.setDataFormat(workbook.createDataFormat().getFormat("### ### ###"));
        grayNumberStyle.setAlignment(HorizontalAlignment.CENTER);

        // Turnover header style (same as header)
        turnoverHeaderStyle = workbook.createCellStyle();
        turnoverHeaderStyle.setFont(timesRoman12BoldItalic);
        turnoverHeaderStyle.setAlignment(HorizontalAlignment.CENTER);

        // Currency code style: Arial 10
        currencyCodeStyle = workbook.createCellStyle();
        currencyCodeStyle.setFont(arial10);
        currencyCodeStyle.setAlignment(HorizontalAlignment.CENTER);

        // Currency name style: Arial 10
        currencyNameStyle = workbook.createCellStyle();
        currencyNameStyle.setFont(arial10);
    }

    private void writeRegionSheet(Sheet sheet, RegionSnapshotDto region, LocalDateTime snapshotTime) {
        List<BranchSnapshotDto> branches = region.getBranches();
        int branchCount = branches.size();
        // Columns: A=code, B=name, then per branch 2 cols (stock, stockHuf), then 2 cols totals
        int totalDataCols = 2 + branchCount * 2 + 2;

        setColumnWidths(sheet, totalDataCols);

        // Row 1 (index 1): Title
        Row titleRow = getOrCreateRow(sheet, 1);
        Cell titleCell = titleRow.createCell(0);
        titleCell.setCellValue(regionDisplay(region.getRegionName()).toUpperCase(java.util.Locale.forLanguageTag("hu")) + " KÉSZLETEI ÉS FORGALMA");
        titleCell.setCellStyle(titleStyle);
        sheet.addMergedRegion(new CellRangeAddress(1, 1, 0, 7));

        // Row 3-4 (index 3-4): Branch headers
        Row headerRow1 = getOrCreateRow(sheet, 3);
        Row headerRow2 = getOrCreateRow(sheet, 4);
        for (int i = 0; i < branchCount; i++) {
            int col = 2 + i * 2;
            Cell branchNameCell = headerRow1.createCell(col);
            branchNameCell.setCellValue(branches.get(i).getBranchName());
            branchNameCell.setCellStyle(headerStyle);
            // Merge branch name across 2 columns
            sheet.addMergedRegion(new CellRangeAddress(3, 3, col, col + 1));

            Cell stockHeader = headerRow2.createCell(col);
            stockHeader.setCellValue("KÉSZLET");
            stockHeader.setCellStyle(headerStyle);

            Cell valueHeader = headerRow2.createCell(col + 1);
            valueHeader.setCellValue("ÉRTÉK(Ft)");
            valueHeader.setCellStyle(headerStyle);
        }
        // Totals columns
        int totCol = 2 + branchCount * 2;
        Cell totHeader = headerRow1.createCell(totCol);
        totHeader.setCellValue("ÖSSZESEN");
        totHeader.setCellStyle(headerStyle);
        sheet.addMergedRegion(new CellRangeAddress(3, 3, totCol, totCol + 1));

        Cell totStockHeader = headerRow2.createCell(totCol);
        totStockHeader.setCellValue("KÉSZLET");
        totStockHeader.setCellStyle(headerStyle);
        Cell totValueHeader = headerRow2.createCell(totCol + 1);
        totValueHeader.setCellValue("ÉRTÉK(Ft)");
        totValueHeader.setCellStyle(headerStyle);

        // Row 5-6 (index 5-6): Date / Time per branch
        Row dateRow = getOrCreateRow(sheet, 5);
        Row timeRow = getOrCreateRow(sheet, 6);
        for (int i = 0; i < branchCount; i++) {
            int col = 2 + i * 2;
            BranchSnapshotDto branch = branches.get(i);
            LocalDateTime lastUpd = branch.getLastUpdated();
            if (lastUpd != null) {
                Cell dCell = dateRow.createCell(col);
                dCell.setCellValue(lastUpd.format(DATE_FMT));
                dCell.setCellStyle(dateStyle);
                sheet.addMergedRegion(new CellRangeAddress(5, 5, col, col + 1));

                Cell tCell = timeRow.createCell(col);
                tCell.setCellValue(lastUpd.format(TIME_FMT));
                tCell.setCellStyle(dateStyle);
                sheet.addMergedRegion(new CellRangeAddress(6, 6, col, col + 1));
            }
        }

        // FK-006: a valutakód-sorrend a snapshot szolgáltatástól jön (aktív törzs + leftover);
        // a sor-pozíciók DINAMIKUSAK — nincs fix 27-soros sablon. Self-review P1: 27<N esetén
        // a régi hardcoded 34-es ÖSSZESEN-sor ütközött volna a stock-blokkal.
        BranchStockTotalsDto totals = region.getTotals();
        List<String> codes = extractCodes(totals);
        final int stockStartRow = 7;
        final int totalRowIdx = stockStartRow + codes.size();       // ÖSSZESEN (volt 34, ha N=27)
        final int turnoverHeaderRowIdx = totalRowIdx + 12;          // 12 sor gap (volt 46, ha N=27)
        final int turnoverSubRowIdx = turnoverHeaderRowIdx + 1;
        final int turnoverStartRow = turnoverSubRowIdx + 1;         // forgalom-sorok kezdete (volt 48)

        for (int vi = 0; vi < codes.size(); vi++) {
            int rowIdx = stockStartRow + vi;
            Row row = getOrCreateRow(sheet, rowIdx);

            Cell codeCell = row.createCell(0);
            codeCell.setCellValue(codes.get(vi));
            codeCell.setCellStyle(currencyCodeStyle);

            Cell nameCell = row.createCell(1);
            nameCell.setCellValue(currencyNameOf(codes.get(vi)));
            nameCell.setCellStyle(currencyNameStyle);

            // Per-branch data
            for (int bi = 0; bi < branchCount; bi++) {
                CurrencyStockDetailDto cd = branches.get(bi).getCurrencies().get(vi);
                int col = 2 + bi * 2;
                setCellNumber(row, col, cd.getStock(), dataNumberStyle);
                setCellNumber(row, col + 1, cd.getStockHuf(), dataNumberStyle);
            }

            // Totals
            CurrencyStockDetailDto totCurr = totals.getCurrencies().get(vi);
            setCellNumber(row, totCol, totCurr.getStock(), dataNumberStyle);
            setCellNumber(row, totCol + 1, totCurr.getStockHuf(), dataNumberStyle);
        }

        // ÖSSZESEN (total HUF across currencies) — DINAMIKUS sor
        Row totalRow = getOrCreateRow(sheet, totalRowIdx);
        Cell totalLabel = totalRow.createCell(0);
        totalLabel.setCellValue("ÖSSZESEN");
        totalLabel.setCellStyle(totalStyle);
        sheet.addMergedRegion(new CellRangeAddress(totalRowIdx, totalRowIdx, 0, 1));

        for (int bi = 0; bi < branchCount; bi++) {
            int col = 2 + bi * 2;
            long branchTotalHuf = branches.get(bi).getCurrencies().stream()
                    .mapToLong(CurrencyStockDetailDto::getStockHuf).sum();
            // Merge the two columns for the total
            sheet.addMergedRegion(new CellRangeAddress(totalRowIdx, totalRowIdx, col, col + 1));
            setCellNumber(totalRow, col, branchTotalHuf, totalNumberStyle);
        }
        long regionTotalHuf = totals.getCurrencies().stream()
                .mapToLong(CurrencyStockDetailDto::getStockHuf).sum();
        sheet.addMergedRegion(new CellRangeAddress(totalRowIdx, totalRowIdx, totCol, totCol + 1));
        setCellNumber(totalRow, totCol, regionTotalHuf, totalNumberStyle);

        // FK-003: a WESTERN UNION / ÁFA / KEZELÉSI DÍJ / ELEKT. KERESKEDÉS / FOGLALÓK sorok
        // az új exportban NEM szerepelnek (Kasza Helga spec) → a writeWuRows hívás eltávolítva.

        // NAPI FORGALOM header — DINAMIKUS sor
        Row turnoverHeaderRow = getOrCreateRow(sheet, turnoverHeaderRowIdx);
        Cell turnoverLabel = turnoverHeaderRow.createCell(0);
        turnoverLabel.setCellValue("NAPI FORGALOM");
        turnoverLabel.setCellStyle(turnoverHeaderStyle);
        sheet.addMergedRegion(new CellRangeAddress(turnoverHeaderRowIdx, turnoverHeaderRowIdx, 0, 1));

        // Turnover sub-headers: VÉTEL/ELADÁS per branch
        Row turnoverSubRow = getOrCreateRow(sheet, turnoverSubRowIdx);
        for (int bi = 0; bi < branchCount; bi++) {
            int col = 2 + bi * 2;
            Cell buyHeader = turnoverSubRow.createCell(col);
            buyHeader.setCellValue("VÉTEL");
            buyHeader.setCellStyle(headerStyle);
            Cell sellHeader = turnoverSubRow.createCell(col + 1);
            sellHeader.setCellValue("ELADÁS");
            sellHeader.setCellStyle(headerStyle);
        }
        Cell totBuyHeader = turnoverSubRow.createCell(totCol);
        totBuyHeader.setCellValue("VÉTEL");
        totBuyHeader.setCellStyle(headerStyle);
        Cell totSellHeader = turnoverSubRow.createCell(totCol + 1);
        totSellHeader.setCellValue("ELADÁS");
        totSellHeader.setCellStyle(headerStyle);

        // Per currency turnover (2 rows each: quantity + HUF) — DINAMIKUS kezdősor
        for (int vi = 0; vi < codes.size(); vi++) {
            int qtyRowIdx = turnoverStartRow + vi * 2;
            int hufRowIdx = turnoverStartRow + vi * 2 + 1;

            Row qtyRow = getOrCreateRow(sheet, qtyRowIdx);
            Row hufRow = getOrCreateRow(sheet, hufRowIdx);

            Cell codeCell = qtyRow.createCell(0);
            codeCell.setCellValue(codes.get(vi));
            codeCell.setCellStyle(currencyCodeStyle);

            Cell nameCell = qtyRow.createCell(1);
            nameCell.setCellValue(currencyNameOf(codes.get(vi)));
            nameCell.setCellStyle(currencyNameStyle);

            for (int bi = 0; bi < branchCount; bi++) {
                CurrencyStockDetailDto cd = branches.get(bi).getCurrencies().get(vi);
                int col = 2 + bi * 2;
                setCellNumber(qtyRow, col, cd.getDailyBuy(), dataNumberStyle);
                setCellNumber(qtyRow, col + 1, cd.getDailySell(), dataNumberStyle);
                setCellNumber(hufRow, col, cd.getDailyBuyHuf(), grayNumberStyle);
                setCellNumber(hufRow, col + 1, cd.getDailySellHuf(), grayNumberStyle);
            }

            // Totals
            CurrencyStockDetailDto totCurr = totals.getCurrencies().get(vi);
            setCellNumber(qtyRow, totCol, totCurr.getDailyBuy(), dataNumberStyle);
            setCellNumber(qtyRow, totCol + 1, totCurr.getDailySell(), dataNumberStyle);
            setCellNumber(hufRow, totCol, totCurr.getDailyBuyHuf(), grayNumberStyle);
            setCellNumber(hufRow, totCol + 1, totCurr.getDailySellHuf(), grayNumberStyle);
        }

        // Turnover ÖSSZESEN — DINAMIKUS sor (volt 102, ha N=27: 48 + 27*2 = 102)
        final int turnoverTotalRowIdx = turnoverStartRow + codes.size() * 2;
        Row turnoverTotalRow = getOrCreateRow(sheet, turnoverTotalRowIdx);
        Cell turnoverTotalLabel = turnoverTotalRow.createCell(0);
        turnoverTotalLabel.setCellValue("ÖSSZESEN");
        turnoverTotalLabel.setCellStyle(totalStyle);
        sheet.addMergedRegion(new CellRangeAddress(turnoverTotalRowIdx, turnoverTotalRowIdx, 0, 1));

        for (int bi = 0; bi < branchCount; bi++) {
            int col = 2 + bi * 2;
            long branchBuyTotal = branches.get(bi).getCurrencies().stream()
                    .mapToLong(CurrencyStockDetailDto::getDailyBuyHuf).sum();
            long branchSellTotal = branches.get(bi).getCurrencies().stream()
                    .mapToLong(CurrencyStockDetailDto::getDailySellHuf).sum();
            setCellNumber(turnoverTotalRow, col, branchBuyTotal, totalNumberStyle);
            setCellNumber(turnoverTotalRow, col + 1, branchSellTotal, totalNumberStyle);
        }
        long regionBuyTotal = totals.getCurrencies().stream()
                .mapToLong(CurrencyStockDetailDto::getDailyBuyHuf).sum();
        long regionSellTotal = totals.getCurrencies().stream()
                .mapToLong(CurrencyStockDetailDto::getDailySellHuf).sum();
        setCellNumber(turnoverTotalRow, totCol, regionBuyTotal, totalNumberStyle);
        setCellNumber(turnoverTotalRow, totCol + 1, regionSellTotal, totalNumberStyle);

        // Freeze pane at C8 (col=2, row=7 in 0-indexed... but freeze is 0-based split position)
        sheet.createFreezePane(2, 7);
    }

    private void writeSummarySheet(Sheet sheet, StockSnapshotDto snapshot) {
        List<RegionSnapshotDto> regions = snapshot.getRegions();
        int regionCount = regions.size();
        int totalDataCols = 2 + regionCount * 2 + 2;

        setColumnWidths(sheet, totalDataCols);

        // Row 1 (index 1): Title
        Row titleRow = getOrCreateRow(sheet, 1);
        Cell titleCell = titleRow.createCell(0);
        // FK-003 spec (Kasza Helga): az Összesítő lap A2 címe a teljes cégnév legyen.
        titleCell.setCellValue("EXCLUSIVE BEST CHANGE ZRT. KÉSZLETEI ÉS FORGALMA");
        titleCell.setCellStyle(titleStyle);
        sheet.addMergedRegion(new CellRangeAddress(1, 1, 0, 7));

        // Row 3-4 (index 3-4): Region headers (instead of branch headers)
        Row headerRow1 = getOrCreateRow(sheet, 3);
        Row headerRow2 = getOrCreateRow(sheet, 4);
        for (int i = 0; i < regionCount; i++) {
            int col = 2 + i * 2;
            Cell regionNameCell = headerRow1.createCell(col);
            regionNameCell.setCellValue(regionDisplay(regions.get(i).getRegionName()));
            regionNameCell.setCellStyle(headerStyle);
            sheet.addMergedRegion(new CellRangeAddress(3, 3, col, col + 1));

            Cell stockHeader = headerRow2.createCell(col);
            stockHeader.setCellValue("KÉSZLET");
            stockHeader.setCellStyle(headerStyle);
            Cell valueHeader = headerRow2.createCell(col + 1);
            valueHeader.setCellValue("ÉRTÉK(Ft)");
            valueHeader.setCellStyle(headerStyle);
        }
        int totCol = 2 + regionCount * 2;
        Cell totHeader = headerRow1.createCell(totCol);
        totHeader.setCellValue("ÖSSZESEN");
        totHeader.setCellStyle(headerStyle);
        sheet.addMergedRegion(new CellRangeAddress(3, 3, totCol, totCol + 1));
        Cell totStockHeader = headerRow2.createCell(totCol);
        totStockHeader.setCellValue("KÉSZLET");
        totStockHeader.setCellStyle(headerStyle);
        Cell totValueHeader = headerRow2.createCell(totCol + 1);
        totValueHeader.setCellValue("ÉRTÉK(Ft)");
        totValueHeader.setCellStyle(headerStyle);

        // FK-006: a kódlista a cég-szintű totals-ból (a snapshot szolgáltatás az igazságforrás);
        // a sor-pozíciók DINAMIKUSAK (self-review P1: 27<N esetén a régi hardcoded 34/46/48 ütközne).
        BranchStockTotalsDto companyTotals = snapshot.getCompanyTotals();
        List<String> codes = extractCodes(companyTotals);
        final int stockStartRow = 7;
        final int totalRowIdx = stockStartRow + codes.size();
        final int turnoverHeaderRowIdx = totalRowIdx + 12;
        final int turnoverSubRowIdx = turnoverHeaderRowIdx + 1;
        final int turnoverStartRow = turnoverSubRowIdx + 1;

        for (int vi = 0; vi < codes.size(); vi++) {
            int rowIdx = stockStartRow + vi;
            Row row = getOrCreateRow(sheet, rowIdx);

            Cell codeCell = row.createCell(0);
            codeCell.setCellValue(codes.get(vi));
            codeCell.setCellStyle(currencyCodeStyle);

            Cell nameCell = row.createCell(1);
            nameCell.setCellValue(currencyNameOf(codes.get(vi)));
            nameCell.setCellStyle(currencyNameStyle);

            for (int ri = 0; ri < regionCount; ri++) {
                CurrencyStockDetailDto cd = regions.get(ri).getTotals().getCurrencies().get(vi);
                int col = 2 + ri * 2;
                setCellNumber(row, col, cd.getStock(), dataNumberStyle);
                setCellNumber(row, col + 1, cd.getStockHuf(), dataNumberStyle);
            }

            CurrencyStockDetailDto totCurr = companyTotals.getCurrencies().get(vi);
            setCellNumber(row, totCol, totCurr.getStock(), dataNumberStyle);
            setCellNumber(row, totCol + 1, totCurr.getStockHuf(), dataNumberStyle);
        }

        // ÖSSZESEN — DINAMIKUS sor
        Row totalRow = getOrCreateRow(sheet, totalRowIdx);
        Cell totalLabel = totalRow.createCell(0);
        totalLabel.setCellValue("ÖSSZESEN");
        totalLabel.setCellStyle(totalStyle);
        sheet.addMergedRegion(new CellRangeAddress(totalRowIdx, totalRowIdx, 0, 1));

        for (int ri = 0; ri < regionCount; ri++) {
            int col = 2 + ri * 2;
            long regionTotalHuf = regions.get(ri).getTotals().getCurrencies().stream()
                    .mapToLong(CurrencyStockDetailDto::getStockHuf).sum();
            sheet.addMergedRegion(new CellRangeAddress(totalRowIdx, totalRowIdx, col, col + 1));
            setCellNumber(totalRow, col, regionTotalHuf, totalNumberStyle);
        }
        long companyTotalHuf = companyTotals.getCurrencies().stream()
                .mapToLong(CurrencyStockDetailDto::getStockHuf).sum();
        sheet.addMergedRegion(new CellRangeAddress(totalRowIdx, totalRowIdx, totCol, totCol + 1));
        setCellNumber(totalRow, totCol, companyTotalHuf, totalNumberStyle);

        // FK-003: WU / ÁFA / KEZELÉSI DÍJ / FOGLALÓK sorok NEM szerepelnek az új exportban.

        // NAPI FORGALOM — DINAMIKUS sor
        Row turnoverHeaderRow = getOrCreateRow(sheet, turnoverHeaderRowIdx);
        Cell turnoverLabel = turnoverHeaderRow.createCell(0);
        turnoverLabel.setCellValue("NAPI FORGALOM");
        turnoverLabel.setCellStyle(turnoverHeaderStyle);
        sheet.addMergedRegion(new CellRangeAddress(turnoverHeaderRowIdx, turnoverHeaderRowIdx, 0, 1));

        Row turnoverSubRow = getOrCreateRow(sheet, turnoverSubRowIdx);
        for (int ri = 0; ri < regionCount; ri++) {
            int col = 2 + ri * 2;
            Cell buyHeader = turnoverSubRow.createCell(col);
            buyHeader.setCellValue("VÉTEL");
            buyHeader.setCellStyle(headerStyle);
            Cell sellHeader = turnoverSubRow.createCell(col + 1);
            sellHeader.setCellValue("ELADÁS");
            sellHeader.setCellStyle(headerStyle);
        }
        Cell totBuyHeader = turnoverSubRow.createCell(totCol);
        totBuyHeader.setCellValue("VÉTEL");
        totBuyHeader.setCellStyle(headerStyle);
        Cell totSellHeader = turnoverSubRow.createCell(totCol + 1);
        totSellHeader.setCellValue("ELADÁS");
        totSellHeader.setCellStyle(headerStyle);

        for (int vi = 0; vi < codes.size(); vi++) {
            int qtyRowIdx = turnoverStartRow + vi * 2;
            int hufRowIdx = turnoverStartRow + vi * 2 + 1;
            Row qtyRow = getOrCreateRow(sheet, qtyRowIdx);
            Row hufRow = getOrCreateRow(sheet, hufRowIdx);

            Cell codeCell = qtyRow.createCell(0);
            codeCell.setCellValue(codes.get(vi));
            codeCell.setCellStyle(currencyCodeStyle);
            Cell nameCell = qtyRow.createCell(1);
            nameCell.setCellValue(currencyNameOf(codes.get(vi)));
            nameCell.setCellStyle(currencyNameStyle);

            for (int ri = 0; ri < regionCount; ri++) {
                CurrencyStockDetailDto cd = regions.get(ri).getTotals().getCurrencies().get(vi);
                int col = 2 + ri * 2;
                setCellNumber(qtyRow, col, cd.getDailyBuy(), dataNumberStyle);
                setCellNumber(qtyRow, col + 1, cd.getDailySell(), dataNumberStyle);
                setCellNumber(hufRow, col, cd.getDailyBuyHuf(), grayNumberStyle);
                setCellNumber(hufRow, col + 1, cd.getDailySellHuf(), grayNumberStyle);
            }

            CurrencyStockDetailDto totCurr = companyTotals.getCurrencies().get(vi);
            setCellNumber(qtyRow, totCol, totCurr.getDailyBuy(), dataNumberStyle);
            setCellNumber(qtyRow, totCol + 1, totCurr.getDailySell(), dataNumberStyle);
            setCellNumber(hufRow, totCol, totCurr.getDailyBuyHuf(), grayNumberStyle);
            setCellNumber(hufRow, totCol + 1, totCurr.getDailySellHuf(), grayNumberStyle);
        }

        // Turnover ÖSSZESEN — DINAMIKUS sor
        final int turnoverTotalRowIdx = turnoverStartRow + codes.size() * 2;
        Row turnoverTotalRow = getOrCreateRow(sheet, turnoverTotalRowIdx);
        Cell turnoverTotalLabel = turnoverTotalRow.createCell(0);
        turnoverTotalLabel.setCellValue("ÖSSZESEN");
        turnoverTotalLabel.setCellStyle(totalStyle);
        sheet.addMergedRegion(new CellRangeAddress(turnoverTotalRowIdx, turnoverTotalRowIdx, 0, 1));

        for (int ri = 0; ri < regionCount; ri++) {
            int col = 2 + ri * 2;
            long buyTotal = regions.get(ri).getTotals().getCurrencies().stream()
                    .mapToLong(CurrencyStockDetailDto::getDailyBuyHuf).sum();
            long sellTotal = regions.get(ri).getTotals().getCurrencies().stream()
                    .mapToLong(CurrencyStockDetailDto::getDailySellHuf).sum();
            setCellNumber(turnoverTotalRow, col, buyTotal, totalNumberStyle);
            setCellNumber(turnoverTotalRow, col + 1, sellTotal, totalNumberStyle);
        }
        long companyBuyTotal = companyTotals.getCurrencies().stream()
                .mapToLong(CurrencyStockDetailDto::getDailyBuyHuf).sum();
        long companySellTotal = companyTotals.getCurrencies().stream()
                .mapToLong(CurrencyStockDetailDto::getDailySellHuf).sum();
        setCellNumber(turnoverTotalRow, totCol, companyBuyTotal, totalNumberStyle);
        setCellNumber(turnoverTotalRow, totCol + 1, companySellTotal, totalNumberStyle);

        sheet.createFreezePane(2, 7);
    }

    private void setColumnWidths(Sheet sheet, int totalCols) {
        sheet.setColumnWidth(0, 5 * 256);
        sheet.setColumnWidth(1, 18 * 256);
        for (int i = 2; i < totalCols; i++) {
            sheet.setColumnWidth(i, 15 * 256);
        }
    }

    private void setCellNumber(Row row, int col, long value, CellStyle style) {
        Cell cell = row.createCell(col);
        cell.setCellValue(value);
        cell.setCellStyle(style);
    }

    private Row getOrCreateRow(Sheet sheet, int rowIdx) {
        Row row = sheet.getRow(rowIdx);
        return row != null ? row : sheet.createRow(rowIdx);
    }
}
