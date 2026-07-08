package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.compliance.ComplianceTransactionRowDto;
import hu.puzzleir.valuta.exception.BusinessException;
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
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

/**
 * FS-11 S2b: compliance keresés-audit PDF a TÁROLT snapshotból.
 */
@Slf4j
@Service
public class ComplianceSearchAuditPdfService {

    private static final float PAGE_WIDTH = PDRectangle.A4.getWidth();
    private static final float PAGE_HEIGHT = PDRectangle.A4.getHeight();
    private static final float MARGIN = 40f;
    private static final float FONT_SIZE = 10f;
    private static final float LINE_HEIGHT = 14f;
    private static final String SEPARATOR = "----------------------------------------";
    private static final DateTimeFormatter TS_FORMAT = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm");
    private static final int WRAP_WIDTH = 85;
    private static final DecimalFormat NUM_FORMAT;

    static {
        DecimalFormatSymbols symbols = new DecimalFormatSymbols(Locale.forLanguageTag("hu-HU"));
        symbols.setGroupingSeparator(',');
        NUM_FORMAT = new DecimalFormat("#,##0.##", symbols);
    }

    public byte[] renderPdf(ComplianceSearchAuditService.ComplianceSearchAuditPdfData data) {
        try (PDDocument doc = new PDDocument();
             ByteArrayOutputStream baos = new ByteArrayOutputStream()) {
            PdfWriter w = new PdfWriter(doc);
            w.centerLine("COMPLIANCE KERESES-AUDIT NAPLO");
            w.writeLine(SEPARATOR);
            for (String line : wrapText("Cim: " + data.title(), WRAP_WIDTH)) {
                w.writeLine(line);
            }
            if (data.description() != null) {
                for (String line : wrapText("Leiras: " + data.description(), WRAP_WIDTH)) {
                    w.writeLine(line);
                }
            }
            w.writeLine("Lekerdezo (worker): " + nz(data.createdByWorkerCode()));
            w.writeLine("Lekerdezes datuma:  " + data.createdAt().format(TS_FORMAT));
            w.writeLine("Talalatok szama: " + data.resultCount());
            w.writeLine(SEPARATOR);
            w.writeLine(String.format("%-14s %-10s %-8s %-4s %14s %12s %-18s",
                    "Bizonylat", "Datum", "Tipus", "Dev", "Osszeg", "HUF", "Ugyfel"));
            w.writeLine(SEPARATOR);
            for (ComplianceTransactionRowDto row : safe(data.rows())) {
                w.writeLine(String.format("%-14s %-10s %-8s %-4s %14s %12s %-18s",
                        nz(row.getReceiptNumber()),
                        row.getTransactionDate() != null ? row.getTransactionDate().toString() : "-",
                        row.getTransactionType() != null ? row.getTransactionType().name() : "-",
                        nz(row.getCurrencyCode()),
                        fmt(row.getCurrencyAmount()),
                        fmt(row.getHufAmount()),
                        truncate(nz(row.getCustomerName()), 18)));
            }
            w.writeLine(SEPARATOR);
            w.finish();
            doc.save(baos);
            return baos.toByteArray();
        } catch (IOException e) {
            log.error("Compliance audit PDF generálási hiba", e);
            throw new BusinessException("A PDF nem generálható", "PDF_COMPLIANCE_AUDIT");
        }
    }

    /** COURIER 10pt A4-en ~85 karakter fér el — a hosszú leírást tördelni kell. */
    private static List<String> wrapText(String text, int maxLen) {
        List<String> lines = new ArrayList<>();
        String remaining = text == null ? "" : text;
        while (remaining.length() > maxLen) {
            int cut = remaining.lastIndexOf(' ', maxLen);
            if (cut <= 0) {
                cut = maxLen;
            }
            lines.add(remaining.substring(0, cut));
            remaining = remaining.substring(cut).trim();
        }
        lines.add(remaining);
        return lines;
    }

    private static String fmt(BigDecimal value) {
        if (value == null) {
            return "-";
        }
        return NUM_FORMAT.format(value);
    }

    private static String nz(String value) {
        return value != null ? value : "-";
    }

    private static String truncate(String value, int max) {
        return value.length() <= max ? value : value.substring(0, max);
    }

    private static List<ComplianceTransactionRowDto> safe(List<ComplianceTransactionRowDto> rows) {
        return rows != null ? rows : List.of();
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
