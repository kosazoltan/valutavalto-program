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

/**
 * Napi zaras PDF generalas (Delphi: nznyomt.dll — AKTLST.TXT nyomtatas).
 *
 * <p>A Delphi rendszer 40 karakter szeles szoveges blokkot irt nyomtatora.
 * Ez a service ugyanazt a strukturat reprodukalja PDF-ben.</p>
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

    static {
        DecimalFormatSymbols symbols = new DecimalFormatSymbols(Locale.forLanguageTag("hu-HU"));
        symbols.setGroupingSeparator(',');
        NUM_FORMAT = new DecimalFormat("#,##0", symbols);
    }

    private final DailyReportService dailyReportService;

    /**
     * PDF generalas a teljes napi jelentes adataibol.
     */
    public byte[] generatePdf(java.util.UUID branchId, java.time.LocalDate date) throws IOException {
        DailyReportFullDto report = dailyReportService.generateFullReport(branchId, date);
        return renderPdf(report);
    }

    byte[] renderPdf(DailyReportFullDto report) throws IOException {
        try (PDDocument doc = new PDDocument();
             ByteArrayOutputStream baos = new ByteArrayOutputStream()) {

            PdfWriter writer = new PdfWriter(doc);

            // 1. Fejlec (Delphi: BlokkFocimIro)
            writer.centerLine("EXCLUSIVE BEST CHANGE ZRT");
            writer.centerLine(report.getBranchCode() + " " + report.getBranchName());
            writer.writeLine(SEPARATOR);

            // 2. Datum
            writer.centerLine(report.getReportDate() + " NAPI ZARAS");
            writer.writeLine(SEPARATOR);

            // 3. Penztar allasa (Delphi: PenztarAllas)
            writer.centerLine(report.getReportDate() + "-i penztar allasa");
            writer.writeLine(SEPARATOR);
            writer.writeLine("Val.   Zaro keszlet    Vetel HUF     Eladas HUF");
            writer.writeLine(SEPARATOR);

            for (DailyReportFullDto.CurrencyLineDto line : safe(report.getCurrencyLines())) {
                if (line.getClosingStock() != null && line.getClosingStock().compareTo(BigDecimal.ZERO) != 0) {
                    writer.writeLine(String.format("%-5s %11s  %11s  %11s",
                            line.getCurrencyCode(),
                            fmt(line.getClosingStock()),
                            fmt(line.getBuyHuf()),
                            fmt(line.getSellHuf())));
                }
            }
            writer.writeLine(SEPARATOR);
            writer.writeLine("");

            // 4. DE/DU forgalom (Delphi: DataKibonto de/du)
            writer.centerLine("DE/DU FORGALOM");
            writer.writeLine(SEPARATOR);
            writer.writeLine(String.format("DE vetel:  %11s HUF", fmt(report.getMorningBuyHuf())));
            writer.writeLine(String.format("DE eladas: %11s HUF", fmt(report.getMorningSellHuf())));
            writer.writeLine(String.format("DU vetel:  %11s HUF", fmt(report.getAfternoonBuyHuf())));
            writer.writeLine(String.format("DU eladas: %11s HUF", fmt(report.getAfternoonSellHuf())));
            writer.writeLine(SEPARATOR);
            writer.writeLine(String.format("Ossz vetel:  %11s HUF", fmt(report.getTotalBuyHuf())));
            writer.writeLine(String.format("Ossz eladas: %11s HUF", fmt(report.getTotalSellHuf())));
            writer.writeLine(String.format("Tranzakciok: %d (vetel: %d, eladas: %d, storni: %d)",
                    report.getTransactionCount(), report.getBuyCount(),
                    report.getSellCount(), report.getReversalCount()));
            writer.writeLine(SEPARATOR);
            writer.writeLine("");

            // 5. Cimletek (Delphi: cimlet szekciok a DLP-ben — 12 Ft cimlet)
            if (!safe(report.getHufDenominations()).isEmpty()) {
                writer.centerLine("HUF CIMLETEK");
                writer.writeLine(SEPARATOR);
                writer.writeLine(String.format("%-12s %5s %11s", "Cimlet", "Db", "Osszeg"));
                writer.writeLine(SEPARATOR);
                for (DailyReportFullDto.DenominationLineDto d : report.getHufDenominations()) {
                    writer.writeLine(String.format("%-12s %5d %11s",
                            d.getLabel(),
                            d.getQuantity() != null ? d.getQuantity() : 0,
                            fmt(d.getTotalValue())));
                }
                writer.writeLine(SEPARATOR);
                writer.writeLine(String.format("Cimletezett osszesen: %11s HUF", fmt(report.getDenominatedTotalHuf())));

                if (report.getEuroCoin1Count() > 0 || report.getEuroCoin2Count() > 0) {
                    writer.writeLine(String.format("Euro ermek: 1 EUR x%d, 2 EUR x%d",
                            report.getEuroCoin1Count(), report.getEuroCoin2Count()));
                }
                writer.writeLine(SEPARATOR);
                writer.writeLine("");
            }

            // 6. WU/AFA (Delphi: WuAfaNyomtatas)
            writer.centerLine("Western Union es AFA forgalom");
            writer.writeLine(SEPARATOR);
            writer.writeLine(String.format("WU USD zaro: %11s USD", fmt(report.getWuUsdBalance())));
            writer.writeLine(String.format("WU HUF zaro: %11s HUF", fmt(report.getWuHufBalance())));
            writer.writeLine(String.format("AFA zaro:    %11s HUF", fmt(report.getAfaBalance())));
            writer.writeLine(SEPARATOR);
            writer.writeLine("");

            // 7. Kezelesi dij (Delphi: Kezelesidijnyomtatas)
            writer.centerLine("KEZELESI DIJAS FORGALOM");
            writer.writeLine(SEPARATOR);
            writer.writeLine(String.format("Napi kezelesi dij osszesen: %11s HUF", fmt(report.getDailyHandlingFee())));
            writer.writeLine(SEPARATOR);
            writer.writeLine("");

            // 8. E-kereskedelem (Delphi: EkerNyomtatas)
            writer.centerLine("E-KERESKEDELMI MOZGASOK");
            writer.writeLine(SEPARATOR);
            writer.writeLine(String.format("Zaro egyenleg: %11s HUF", fmt(report.getEcommerceBalanceHuf())));
            writer.writeLine(SEPARATOR);
            writer.writeLine("");

            // 9. Kedvezmenyek
            if (!safe(report.getDiscountLines()).isEmpty()) {
                writer.centerLine("KEDVEZMENYES TRANZAKCIOK");
                writer.writeLine(SEPARATOR);
                for (DailyReportFullDto.DiscountLineDto dl : report.getDiscountLines()) {
                    writer.writeLine(String.format("%-5s %11s @ %s  [%s]",
                            dl.getCurrencyCode(),
                            fmt(dl.getAmount()),
                            fmt(dl.getDiscountRate()),
                            dl.getReceiptNumber() != null ? dl.getReceiptNumber() : "-"));
                }
                writer.writeLine(SEPARATOR);
                writer.writeLine("");
            }

            // 10. Zarokeszlet osszesites
            writer.centerLine("ZARO KESZLET OSSZESITES");
            writer.writeLine(SEPARATOR);
            writer.writeLine(String.format("Forint keszlet:  %11s HUF", fmt(report.getClosingBalanceHuf())));
            writer.writeLine(String.format("Valuta keszlet:  %11s HUF (ekvivalens)", fmt(report.getClosingBalanceForeign())));
            writer.writeLine(String.format("Osszesen:        %11s HUF", fmt(report.getClosingBalanceTotal())));
            writer.writeLine(SEPARATOR);
            writer.writeLine("");

            // 11. Penztaros (Delphi: DataKibonto — de/du dolgozo)
            if (report.getMorningCashierName() != null || report.getAfternoonCashierName() != null) {
                writer.writeLine(String.format("DE penztaros: %s",
                        report.getMorningCashierName() != null ? report.getMorningCashierName() : "-"));
                writer.writeLine(String.format("DU penztaros: %s",
                        report.getAfternoonCashierName() != null ? report.getAfternoonCashierName() : "-"));
                writer.writeLine("");
            }

            // 12. Nyilatkozat (Delphi: ha nem ujranyomtatas)
            writer.writeLine("Buntetojogi felelosegem tudataban kije-");
            writer.writeLine("lentem,hogy a penztar allasa es a zaro-");
            writer.writeLine("szalagon szereplo osszegek megegyeznek.");
            writer.writeLine("");
            writer.writeLine("........................................");
            writer.writeLine("              penztaros");
            writer.writeLine("");

            // 13. Ellenor bejegyzes (Delphi: EllenorBejegyzes)
            writer.writeLine("........................................");
            writer.writeLine("       Ellenorzo szemely alairasa");

            writer.finish();

            doc.save(baos);
            log.info("S2-02 napi zaras PDF generálva: branch={}, date={}, pages={}",
                    report.getBranchCode(), report.getReportDate(), doc.getNumberOfPages());
            return baos.toByteArray();
        }
    }

    // ============ HELPER ============

    private static String fmt(BigDecimal value) {
        if (value == null || value.compareTo(BigDecimal.ZERO) == 0) return "-";
        return NUM_FORMAT.format(value.longValue());
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
