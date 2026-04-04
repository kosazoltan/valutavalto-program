package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.report.DailyReportFullDto;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDPage;
import org.apache.pdfbox.pdmodel.PDPageContentStream;
import org.apache.pdfbox.pdmodel.common.PDRectangle;
import org.apache.pdfbox.pdmodel.font.PDType1Font;
import org.apache.pdfbox.pdmodel.font.Standard14Fonts;
import org.springframework.stereotype.Service;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.math.BigDecimal;
import java.text.DecimalFormat;
import java.text.DecimalFormatSymbols;
import java.util.List;
import java.util.Locale;
import java.util.UUID;

/**
 * Napi zaras PDF generalas (Delphi: nznyomt.dll — AKTLST.TXT nyomtatas).
 *
 * <p>A Delphi rendszer 40 karakter szeles szoveges blokkot irt nyomtatora.
 * Ez a service ugyanazt a strukturat reprodukalja PDF-ben, Delphi szekcio-paritassal.</p>
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class DailyClosingPdfService {

    private static final float PAGE_WIDTH = PDRectangle.A4.getWidth();
    private static final float PAGE_HEIGHT = PDRectangle.A4.getHeight();
    private static final float MARGIN = 40f;
    private static final float FONT_SIZE = 10f;
    private static final float LINE_HEIGHT = 14f;
    private static final String SEPARATOR = "----------------------------------------";
    private static final DecimalFormat NUM_FORMAT;
    private static final DecimalFormat RATE_FORMAT;

    static {
        DecimalFormatSymbols symbols = new DecimalFormatSymbols(Locale.forLanguageTag("hu-HU"));
        symbols.setGroupingSeparator(',');
        NUM_FORMAT = new DecimalFormat("#,##0", symbols);
        RATE_FORMAT = new DecimalFormat("#,##0.00", symbols);
    }

    private final DailyReportService dailyReportService;

    /**
     * PDF generalas a teljes napi jelentes adataibol.
     */
    public byte[] generatePdf(UUID branchId, java.time.LocalDate date) throws IOException {
        DailyReportFullDto report = dailyReportService.generateFullReport(branchId, date);
        return renderPdf(report);
    }

    byte[] renderPdf(DailyReportFullDto report) throws IOException {
        try (PDDocument doc = new PDDocument();
             ByteArrayOutputStream baos = new ByteArrayOutputStream()) {

            PdfWriter w = new PdfWriter(doc);

            // === 1. Fejlec (Delphi: BlokkFocimIro) ===
            w.centerLine("EXCLUSIVE BEST CHANGE ZRT");
            w.centerLine(report.getBranchCode() + " " + report.getBranchName());
            if (report.getBranchAddress() != null && !report.getBranchAddress().isBlank()) {
                w.centerLine(report.getBranchAddress());
            }
            if (report.getTaxId() != null && !report.getTaxId().isBlank()) {
                w.centerLine("Adoszam: " + report.getTaxId());
            }
            w.writeLine(SEPARATOR);

            // === 2. Datum ===
            w.centerLine(report.getReportDate() + " NAPI ZARAS");
            w.writeLine(SEPARATOR);

            // === 3. Penztar allasa (Delphi: PenztarAllas — nyito/forgalom/zaro) ===
            w.centerLine(report.getReportDate() + "-i penztar allasa");
            w.writeLine(SEPARATOR);
            w.writeLine("Val.   Nyito     Forgalom      Penztar");
            w.writeLine("nem   osszeg    egyenlege       allas");
            w.writeLine(SEPARATOR);

            for (DailyReportFullDto.CurrencyLineDto line : safe(report.getCurrencyLines())) {
                BigDecimal closing = nz(line.getClosingStock());
                if (closing.compareTo(BigDecimal.ZERO) != 0) {
                    BigDecimal opening = nz(line.getOpeningStock());
                    BigDecimal turnover = closing.subtract(opening);
                    w.writeLine(String.format("%-5s %11s %11s %11s",
                            line.getCurrencyCode(),
                            fmt(opening),
                            fmt(turnover),
                            fmt(closing)));
                }
            }
            w.writeLine(SEPARATOR);
            w.writeLine("");

            // === 4. Napi bankjegy-forgalom I+II (Delphi: ForgalomLista) ===
            w.writeLine("  NAPI BANKJEGY-FORGALOM KIMUTATASA-I");
            w.writeLine(SEPARATOR);
            w.writeLine("VALUTANEM  NYITO KESZLET   VETEL OSSZEG");
            w.writeLine(SEPARATOR);
            for (DailyReportFullDto.CurrencyLineDto line : safe(report.getCurrencyLines())) {
                if (hasActivity(line)) {
                    w.writeLine(String.format("  %-5s     %11s      %11s",
                            line.getCurrencyCode(),
                            fmt(line.getOpeningStock()),
                            fmt(line.getBuyAmount())));
                }
            }
            w.writeLine(SEPARATOR);
            w.writeLine(" NAPI BANKJEGY-FORGALOM KIMUTATASA-II");
            w.writeLine(SEPARATOR);
            w.writeLine("VALUTANEM ELADAS OSSZEG    ZARO KESZLET");
            w.writeLine(SEPARATOR);
            for (DailyReportFullDto.CurrencyLineDto line : safe(report.getCurrencyLines())) {
                if (hasActivity(line)) {
                    w.writeLine(String.format("  %-5s     %11s      %11s",
                            line.getCurrencyCode(),
                            fmt(line.getSellAmount()),
                            fmt(line.getClosingStock())));
                }
            }
            w.writeLine(SEPARATOR);
            w.writeLine("");

            // === 5. DE/DU forgalom ===
            w.centerLine("DE/DU FORGALOM");
            w.writeLine(SEPARATOR);
            w.writeLine(String.format("DE vetel:  %11s HUF", fmt(report.getMorningBuyHuf())));
            w.writeLine(String.format("DE eladas: %11s HUF", fmt(report.getMorningSellHuf())));
            w.writeLine(String.format("DU vetel:  %11s HUF", fmt(report.getAfternoonBuyHuf())));
            w.writeLine(String.format("DU eladas: %11s HUF", fmt(report.getAfternoonSellHuf())));
            w.writeLine(SEPARATOR);
            w.writeLine(String.format("Ossz vetel:  %11s HUF", fmt(report.getTotalBuyHuf())));
            w.writeLine(String.format("Ossz eladas: %11s HUF", fmt(report.getTotalSellHuf())));
            w.writeLine(String.format("Tranzakciok: %d (vetel: %d, eladas: %d, storni: %d)",
                    report.getTransactionCount(), report.getBuyCount(),
                    report.getSellCount(), report.getReversalCount()));
            w.writeLine(SEPARATOR);
            w.writeLine("");

            // === 6. HUF cimletek ===
            if (!safe(report.getHufDenominations()).isEmpty()) {
                w.centerLine("HUF CIMLETEK");
                w.writeLine(SEPARATOR);
                w.writeLine(String.format("%-12s %5s %11s", "Cimlet", "Db", "Osszeg"));
                w.writeLine(SEPARATOR);
                for (DailyReportFullDto.DenominationLineDto d : report.getHufDenominations()) {
                    w.writeLine(String.format("%-12s %5d %11s",
                            d.getLabel(),
                            d.getQuantity() != null ? d.getQuantity() : 0,
                            fmt(d.getTotalValue())));
                }
                w.writeLine(SEPARATOR);
                w.writeLine(String.format("Cimletezett osszesen: %11s HUF", fmt(report.getDenominatedTotalHuf())));
                if (report.getEuroCoin1Count() > 0 || report.getEuroCoin2Count() > 0) {
                    w.writeLine(String.format("Euro ermek: 1 EUR x%d, 2 EUR x%d",
                            report.getEuroCoin1Count(), report.getEuroCoin2Count()));
                }
                w.writeLine(SEPARATOR);
                w.writeLine("");
            }

            // === 7. WU/AFA (Delphi: WuAfaNyomtatas — nyito/bevetel/kiadas/zaro x3) ===
            w.centerLine("Western Union es AFA forgalom");
            w.writeLine(SEPARATOR);
            w.centerLine("Western Union dollar forgalma:");
            w.writeLine("");
            w.writeLine(String.format("         Nyito: %11s USD", fmt(report.getWuUsdOpening())));
            w.writeLine(String.format("       Bevetel: %11s USD", fmt(report.getWuUsdIncome())));
            w.writeLine(String.format("        Kiadas: %11s USD", fmt(report.getWuUsdExpense())));
            w.writeLine(String.format("          Zaro: %11s USD", fmt(report.getWuUsdBalance())));
            w.writeLine("");
            w.centerLine("Western Union forint forgalma:");
            w.writeLine("");
            w.writeLine(String.format("         Nyito: %11s HUF", fmt(report.getWuHufOpening())));
            w.writeLine(String.format("       Bevetel: %11s HUF", fmt(report.getWuHufIncome())));
            w.writeLine(String.format("        Kiadas: %11s HUF", fmt(report.getWuHufExpense())));
            w.writeLine(String.format("          Zaro: %11s HUF", fmt(report.getWuHufBalance())));
            w.writeLine("");
            w.centerLine("Afa visszaigenyles forgalma:");
            w.writeLine("");
            w.writeLine(String.format("         Nyito: %11s HUF", fmt(report.getAfaOpening())));
            w.writeLine(String.format("       Bevetel: %11s HUF", fmt(report.getAfaIncome())));
            w.writeLine(String.format("        Kiadas: %11s HUF", fmt(report.getAfaExpense())));
            w.writeLine(String.format("          Zaro: %11s HUF", fmt(report.getAfaBalance())));
            w.writeLine(SEPARATOR);
            w.writeLine("");

            // === 8. Kezelesi dij (Delphi: Kezelesidijnyomtatas — nyito/atvett/atadott/zaro) ===
            w.writeLine(" KEZELESI KOLTSEG " + report.getReportDate() + "-I LISTAJA");
            w.writeLine(SEPARATOR);
            w.writeLine(String.format(" NAPI NYITO OSSZEG ......:  %11s", fmt(report.getHandlingFeeOpening())));
            w.writeLine(String.format(" ATVETT OSSZEG ..........:  %11s", fmt(report.getHandlingFeeIncome())));
            w.writeLine(String.format(" ATADOTT OSSZEG .........:  %11s", fmt(report.getHandlingFeeExpense())));
            w.writeLine(String.format(" NAPI ZARO OSSZEG .......:  %11s", fmt(report.getDailyHandlingFee())));
            w.writeLine(SEPARATOR);
            w.writeLine("");

            // === 9. E-kereskedelem (Delphi: EkerNyomtatas — nyito/atvett/atadott/zaro) ===
            w.writeLine(" E-KERESKEDELMI MOZGASOK " + report.getReportDate() + "-N");
            w.writeLine(SEPARATOR);
            w.writeLine(String.format(" NAPI NYITO OSSZEG ......:  %11s", fmt(report.getEcommerceOpening())));
            w.writeLine(String.format(" ATVETT OSSZEG ..........:  %11s", fmt(report.getEcommerceIncome())));
            w.writeLine(String.format(" ATADOTT OSSZEG .........:  %11s", fmt(report.getEcommerceExpense())));
            w.writeLine(String.format(" NAPI ZARO OSSZEG .......:  %11s", fmt(report.getEcommerceBalanceHuf())));
            w.writeLine(SEPARATOR);
            w.writeLine("");

            // === 10. Kedvezmenyek ===
            if (!safe(report.getDiscountLines()).isEmpty()) {
                w.centerLine("KEDVEZMENYES TRANZAKCIOK");
                w.writeLine(SEPARATOR);
                for (DailyReportFullDto.DiscountLineDto dl : report.getDiscountLines()) {
                    w.writeLine(String.format("%-5s %11s @ %s  [%s]",
                            dl.getCurrencyCode(),
                            fmt(dl.getAmount()),
                            fmtRate(dl.getDiscountRate()),
                            dl.getReceiptNumber() != null ? dl.getReceiptNumber() : "-"));
                }
                w.writeLine(SEPARATOR);
                w.writeLine("");
            }

            // === 11. Zaro keszlet osszesites ===
            w.centerLine("ZARO KESZLET OSSZESITES");
            w.writeLine(SEPARATOR);
            w.writeLine(String.format("Forint keszlet:  %11s HUF", fmt(report.getClosingBalanceHuf())));
            w.writeLine(String.format("Valuta keszlet:  %11s HUF (ekvivalens)", fmt(report.getClosingBalanceForeign())));
            w.writeLine(String.format("Osszesen:        %11s HUF", fmt(report.getClosingBalanceTotal())));
            w.writeLine(SEPARATOR);
            w.writeLine("");

            // === 12. Penztaros ===
            if (report.getMorningCashierName() != null || report.getAfternoonCashierName() != null) {
                w.writeLine(String.format("DE penztaros: %s",
                        report.getMorningCashierName() != null ? report.getMorningCashierName() : "-"));
                w.writeLine(String.format("DU penztaros: %s",
                        report.getAfternoonCashierName() != null ? report.getAfternoonCashierName() : "-"));
                w.writeLine("");
            }

            // === 13. Nyilatkozat (Delphi: feltételes — ha nem újranyomtatás) ===
            w.writeLine("Buntetojogi felelosegem tudataban kije-");
            w.writeLine("lentem,hogy a penztar allasa es a zaro-");
            w.writeLine("szalagon szereplo osszegek megegyeznek.");
            w.writeLine("");
            w.writeLine("........................................");
            w.writeLine("              penztaros");
            w.writeLine("");

            // === 14. Ellenor bejegyzes (Delphi: EllenorBejegyzes — nev + bejegyzes + jogszabaly) ===
            if (report.getInspectorName() != null && !report.getInspectorName().isBlank()) {
                w.centerLine("Alulirott " + report.getInspectorName());
                if (report.getInspectorNote() != null && !report.getInspectorNote().isBlank()) {
                    w.centerLine(report.getInspectorNote());
                }
            }
            w.writeLine("      alairasommal igazolom, hogy a");
            w.centerLine(report.getBranchCode() + " szamu ertektar");
            if (report.getBranchAddress() != null && !report.getBranchAddress().isBlank()) {
                w.centerLine(report.getBranchAddress());
            }
            w.writeLine(" zarasa az FZS-01/2009 szamu modositott");
            w.writeLine("      korlevel betartasaval tortent");
            w.writeLine("");
            w.writeLine("........................................");
            w.writeLine("       Ellenorzo szemely alairasa");

            w.finish();

            doc.save(baos);
            log.info("S2-02 napi zaras PDF generalva: branch={}, date={}, pages={}",
                    report.getBranchCode(), report.getReportDate(), doc.getNumberOfPages());
            return baos.toByteArray();
        }
    }

    // ============ HELPER ============

    private static String fmt(BigDecimal value) {
        if (value == null || value.compareTo(BigDecimal.ZERO) == 0) return "-";
        // B1 fix: format(BigDecimal) — nem longValue() truncation
        return NUM_FORMAT.format(value);
    }

    private static String fmtRate(BigDecimal value) {
        if (value == null || value.compareTo(BigDecimal.ZERO) == 0) return "-";
        return RATE_FORMAT.format(value);
    }

    private static BigDecimal nz(BigDecimal value) {
        return value != null ? value : BigDecimal.ZERO;
    }

    private static boolean hasActivity(DailyReportFullDto.CurrencyLineDto line) {
        BigDecimal sum = nz(line.getOpeningStock()).abs()
                .add(nz(line.getClosingStock()).abs())
                .add(nz(line.getBuyAmount()).abs())
                .add(nz(line.getSellAmount()).abs());
        return sum.compareTo(BigDecimal.ZERO) > 0;
    }

    private static <T> List<T> safe(List<T> list) {
        return list != null ? list : List.of();
    }

    /**
     * Belso segito: PDFBox page/content stream kezeles automatikus oldaltoressel.
     */
    static class PdfWriter {
        private final PDDocument doc;
        private PDPageContentStream cs;
        private float y;
        private final PDType1Font font = new PDType1Font(Standard14Fonts.FontName.COURIER);

        PdfWriter(PDDocument doc) throws IOException {
            this.doc = doc;
            newPage();
        }

        void writeLine(String text) throws IOException {
            if (y < MARGIN + LINE_HEIGHT) {
                newPage();
            }
            cs.beginText();
            cs.setFont(font, FONT_SIZE);
            cs.newLineAtOffset(MARGIN, y);
            cs.showText(sanitize(text));
            cs.endText();
            y -= LINE_HEIGHT;
        }

        void centerLine(String text) throws IOException {
            float textWidth = font.getStringWidth(sanitize(text)) / 1000 * FONT_SIZE;
            float x = (PAGE_WIDTH - textWidth) / 2;
            if (y < MARGIN + LINE_HEIGHT) {
                newPage();
            }
            cs.beginText();
            cs.setFont(font, FONT_SIZE);
            cs.newLineAtOffset(x, y);
            cs.showText(sanitize(text));
            cs.endText();
            y -= LINE_HEIGHT;
        }

        void finish() throws IOException {
            if (cs != null) cs.close();
        }

        private void newPage() throws IOException {
            if (cs != null) cs.close();
            PDPage page = new PDPage(PDRectangle.A4);
            doc.addPage(page);
            cs = new PDPageContentStream(doc, page);
            y = PAGE_HEIGHT - MARGIN;
        }

        private static String sanitize(String text) {
            if (text == null) return "";
            // PDFBox Type1 font cannot render accented chars — strip to ASCII
            return text.replace('\u00e1', 'a').replace('\u00e9', 'e')
                    .replace('\u00ed', 'i').replace('\u00f3', 'o')
                    .replace('\u00f6', 'o').replace('\u0151', 'o')
                    .replace('\u00fa', 'u').replace('\u00fc', 'u')
                    .replace('\u0171', 'u').replace('\u00c1', 'A')
                    .replace('\u00c9', 'E').replace('\u00cd', 'I')
                    .replace('\u00d3', 'O').replace('\u00d6', 'O')
                    .replace('\u0150', 'O').replace('\u00da', 'U')
                    .replace('\u00dc', 'U').replace('\u0170', 'U');
        }
    }
}
