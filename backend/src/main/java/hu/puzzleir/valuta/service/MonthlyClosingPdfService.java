package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.report.MonthlyReportFullDto;
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
 * Havi zaras PDF generalas (Delphi: HAVIZAR.DLL — havi osszesito nyomtatas).
 *
 * <p>A Delphi rendszer havi szinten osszesitette a napi zarasok adatait,
 * es nyomtatott osszesitot keszitett: BlokkFocimIro, PenztarAllas,
 * ForgalomLista, WuAfaNyomtatas, Kezelesidijnyomtatas, Ekernyomtatas.</p>
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class MonthlyClosingPdfService {

    private static final float PAGE_WIDTH = PDRectangle.A4.getWidth();
    private static final float PAGE_HEIGHT = PDRectangle.A4.getHeight();
    private static final float MARGIN = 40f;
    private static final float FONT_SIZE = 10f;
    private static final float LINE_HEIGHT = 14f;
    private static final String SEPARATOR = "----------------------------------------";
    private static final DecimalFormat NUM_FORMAT;

    static {
        DecimalFormatSymbols symbols = new DecimalFormatSymbols(Locale.forLanguageTag("hu-HU"));
        symbols.setGroupingSeparator(',');
        NUM_FORMAT = new DecimalFormat("#,##0", symbols);
    }

    private final MonthlyReportService monthlyReportService;

    /**
     * PDF generalas a teljes havi jelentes adataibol.
     */
    public byte[] generatePdf(UUID branchId, String yearMonth) throws IOException {
        MonthlyReportFullDto report = monthlyReportService.generateFullReport(branchId, yearMonth);
        return renderPdf(report);
    }

    byte[] renderPdf(MonthlyReportFullDto report) throws IOException {
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

            // === 2. Idoszak ===
            w.centerLine(report.getYearMonth() + " HAVI ZARAS OSSZESITO");
            w.writeLine(String.format("Munkanapok: %d | Lezart napok: %d",
                    report.getWorkingDays(), report.getClosedDays()));
            w.writeLine(SEPARATOR);

            // === 3. Penztarak kozotti mozgasok (Delphi: AtadAtvetLista) ===
            if (report.getTransferLines() != null && !report.getTransferLines().isEmpty()) {
                w.centerLine("PENZTARAK KOZOTTI MOZGASOK");
                w.writeLine(SEPARATOR);
                w.writeLine("VALUTANEM  ATVETT       ATADOTT      NETTO");
                w.writeLine(SEPARATOR);
                for (MonthlyReportFullDto.TransferLineDto tl : report.getTransferLines()) {
                    w.writeLine(String.format("  %-5s   %11s  %11s  %11s",
                            tl.getCurrencyCode(),
                            fmt(tl.getReceivedAmount()),
                            fmt(tl.getSentAmount()),
                            fmt(tl.getNetAmount())));
                }
                w.writeLine(SEPARATOR);
                w.writeLine("");
            }

            // === 4. Penztar allasa (Delphi: PenztarAllas — havi zaro) ===
            w.centerLine("HAVI PENZTAR ALLAS");
            w.writeLine(SEPARATOR);
            w.writeLine("Val.   Nyito     Forgalom      Zaro");
            w.writeLine("nem   osszeg    egyenlege      allas");
            w.writeLine(SEPARATOR);

            for (MonthlyReportFullDto.CurrencyLineDto line : safe(report.getCurrencyLines())) {
                BigDecimal closing = nz(line.getClosingStock());
                if (closing.compareTo(BigDecimal.ZERO) != 0 || nz(line.getTotalBuyAmount()).compareTo(BigDecimal.ZERO) != 0) {
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

            // === 5. Havi bankjegy-forgalom I. (Delphi: ForgalomLista I. resz) ===
            w.writeLine("  HAVI BANKJEGY-FORGALOM KIMUTATASA I.");
            w.writeLine(SEPARATOR);
            w.writeLine("VALUTANEM  NYITO KESZLET  ATVETT OSSZEG");
            w.writeLine(SEPARATOR);
            for (MonthlyReportFullDto.CurrencyLineDto line : safe(report.getCurrencyLines())) {
                if (hasActivity(line)) {
                    // Atvett = closing - opening - buy + sell (netto bejovo transfer)
                    BigDecimal received = nz(line.getClosingStock()).subtract(nz(line.getOpeningStock()))
                            .subtract(nz(line.getTotalBuyAmount())).add(nz(line.getTotalSellAmount()));
                    if (received.compareTo(BigDecimal.ZERO) < 0) received = BigDecimal.ZERO;
                    w.writeLine(String.format("  %-5s   %11s  %11s",
                            line.getCurrencyCode(),
                            fmt(line.getOpeningStock()),
                            fmt(received)));
                }
            }
            w.writeLine(SEPARATOR);
            w.writeLine("");

            // === 5b. Havi bankjegy-forgalom II. (Delphi: ForgalomLista II. resz) ===
            w.writeLine("  HAVI BANKJEGY-FORGALOM KIMUTATASA II.");
            w.writeLine(SEPARATOR);
            w.writeLine("VALUTANEM  ATADOTT OSSZEG  ZARO KESZLET");
            w.writeLine(SEPARATOR);
            for (MonthlyReportFullDto.CurrencyLineDto line : safe(report.getCurrencyLines())) {
                if (hasActivity(line)) {
                    BigDecimal sent = BigDecimal.ZERO; // Atadott = transfer out, kozelites
                    w.writeLine(String.format("  %-5s   %11s  %11s",
                            line.getCurrencyCode(),
                            fmt(sent),
                            fmt(line.getClosingStock())));
                }
            }
            w.writeLine(SEPARATOR);
            w.writeLine("");

            // === 5c. Havi forgalom osszesites (osszvetel/osszeladas/MNB) ===
            w.writeLine("  HAVI BANKJEGY-FORGALOM OSSZESITES");
            w.writeLine(SEPARATOR);
            w.writeLine("VALUTANEM  OSSZVETEL    OSSZELADAS   MNB ARF");
            w.writeLine(SEPARATOR);
            for (MonthlyReportFullDto.CurrencyLineDto line : safe(report.getCurrencyLines())) {
                if (hasActivity(line)) {
                    w.writeLine(String.format("  %-5s   %11s  %11s  %8s",
                            line.getCurrencyCode(),
                            fmt(line.getTotalBuyAmount()),
                            fmt(line.getTotalSellAmount()),
                            line.getMnbRate().compareTo(BigDecimal.ZERO) > 0
                                    ? NUM_FORMAT.format(line.getMnbRate()) : "-"));
                }
            }
            w.writeLine(SEPARATOR);
            w.writeLine("");

            // === 6. Havi forgalom osszesites ===
            w.centerLine("HAVI FORGALOM OSSZESITES");
            w.writeLine(SEPARATOR);
            w.writeLine(String.format("Ossz vetel:  %11s HUF", fmt(report.getTotalBuyHuf())));
            w.writeLine(String.format("Ossz eladas: %11s HUF", fmt(report.getTotalSellHuf())));
            w.writeLine(String.format("Tranzakciok: %d (vetel: %d, eladas: %d, storni: %d)",
                    report.getTransactionCount(), report.getBuyCount(),
                    report.getSellCount(), report.getReversalCount()));
            w.writeLine(SEPARATOR);
            w.writeLine("");

            // === 7. WU/AFA (Delphi: WuAfaNyomtatas — havi osszesites) ===
            w.centerLine("Western Union es AFA havi forgalom");
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

            // === 8. Kezelesi dij (Delphi: Kezelesidijnyomtatas — havi) ===
            w.writeLine(" KEZELESI KOLTSEG HAVI OSSZESITES");
            w.writeLine(SEPARATOR);
            w.writeLine(String.format(" HAVI NYITO OSSZEG ......:  %11s", fmt(report.getHandlingFeeOpening())));
            w.writeLine(String.format(" ATVETT OSSZEG ..........:  %11s", fmt(report.getHandlingFeeIncome())));
            w.writeLine(String.format(" ATADOTT OSSZEG .........:  %11s", fmt(report.getHandlingFeeExpense())));
            w.writeLine(String.format(" HAVI ZARO OSSZEG .......:  %11s", fmt(report.getHandlingFeeBalance())));
            w.writeLine(SEPARATOR);
            w.writeLine("");

            // === 9. E-kereskedelem (Delphi: Ekernyomtatas — havi) ===
            w.writeLine(" E-KERESKEDELMI MOZGASOK HAVI OSSZESITES");
            w.writeLine(SEPARATOR);
            w.writeLine(String.format(" HAVI NYITO OSSZEG ......:  %11s", fmt(report.getEcommerceOpening())));
            w.writeLine(String.format(" ATVETT OSSZEG ..........:  %11s", fmt(report.getEcommerceIncome())));
            w.writeLine(String.format(" ATADOTT OSSZEG .........:  %11s", fmt(report.getEcommerceExpense())));
            w.writeLine(String.format(" HAVI ZARO OSSZEG .......:  %11s", fmt(report.getEcommerceBalance())));
            w.writeLine(SEPARATOR);
            w.writeLine("");

            // === 10. Zaro keszlet osszesites ===
            w.centerLine("HAVI ZARO KESZLET OSSZESITES");
            w.writeLine(SEPARATOR);
            w.writeLine(String.format("Forint keszlet:  %11s HUF", fmt(report.getClosingBalanceHuf())));
            w.writeLine(String.format("Valuta keszlet:  %11s HUF (ekvivalens)", fmt(report.getClosingBalanceForeign())));
            w.writeLine(String.format("Osszesen:        %11s HUF", fmt(report.getClosingBalanceTotal())));
            w.writeLine(SEPARATOR);
            w.writeLine("");

            // === 11. Alairas ===
            w.writeLine("Buntetojogi felelosegem tudataban kije-");
            w.writeLine("lentem,hogy a havi penztar allasa es a");
            w.writeLine("zaroszalagon szereplo osszegek megegy-");
            w.writeLine("eznek.");
            w.writeLine("");
            w.writeLine("........................................");
            w.writeLine("       penztaros / irodavezeto");
            w.writeLine("");
            w.writeLine("........................................");
            w.writeLine("       Ellenorzo szemely alairasa");

            w.finish();

            doc.save(baos);
            log.info("S3 havi zaras PDF generalva: branch={}, yearMonth={}, pages={}",
                    report.getBranchCode(), report.getYearMonth(), doc.getNumberOfPages());
            return baos.toByteArray();
        }
    }

    // ============ HELPER ============

    private static String fmt(BigDecimal value) {
        if (value == null || value.compareTo(BigDecimal.ZERO) == 0) return "-";
        return NUM_FORMAT.format(value);
    }

    private static BigDecimal nz(BigDecimal value) {
        return value != null ? value : BigDecimal.ZERO;
    }

    private static boolean hasActivity(MonthlyReportFullDto.CurrencyLineDto line) {
        BigDecimal sum = nz(line.getOpeningStock()).abs()
                .add(nz(line.getClosingStock()).abs())
                .add(nz(line.getTotalBuyAmount()).abs())
                .add(nz(line.getTotalSellAmount()).abs());
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
