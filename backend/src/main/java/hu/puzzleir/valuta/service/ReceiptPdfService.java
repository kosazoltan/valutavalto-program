package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.receipt.ReceiptData;
import lombok.extern.slf4j.Slf4j;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDPage;
import org.apache.pdfbox.pdmodel.PDPageContentStream;
import org.apache.pdfbox.pdmodel.common.PDRectangle;
import org.apache.pdfbox.pdmodel.font.PDType1Font;
import org.apache.pdfbox.pdmodel.font.Standard14Fonts;
import org.apache.pdfbox.util.Matrix;
import org.springframework.stereotype.Service;

import java.awt.Color;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.math.BigDecimal;
import java.time.format.DateTimeFormatter;

/**
 * Proper PDF bizonylat generálás Apache PDFBox 3.x-szel.
 * A4 lap, 50 pt margó, cégnév fejléc, valuta adatok, aláírássor.
 */
@Service
@Slf4j
public class ReceiptPdfService {

    private static final float MARGIN = 50f;
    private static final float PAGE_WIDTH = PDRectangle.A4.getWidth();
    private static final float PAGE_HEIGHT = PDRectangle.A4.getHeight();
    private static final float CONTENT_WIDTH = PAGE_WIDTH - 2 * MARGIN;
    private static final float LINE_HEIGHT = 14f;
    private static final String SEPARATOR = "─────────────────────────────────────────────";
    private static final DateTimeFormatter DATE_FMT = DateTimeFormatter.ofPattern("yyyy.MM.dd HH:mm");

    /**
     * Valódi A4 PDF generálása ReceiptData-ból.
     */
    public byte[] generatePdf(ReceiptData data) {
        try (PDDocument doc = new PDDocument()) {
            PDPage page = new PDPage(PDRectangle.A4);
            doc.addPage(page);
            writePage(doc, page, data, false);
            ByteArrayOutputStream out = new ByteArrayOutputStream();
            doc.save(out);
            return out.toByteArray();
        } catch (IOException e) {
            log.error("PDF generálási hiba", e);
            throw new RuntimeException("PDF generálás sikertelen", e);
        }
    }

    /**
     * A4 PDF generálása "MÁSOLAT" vízjellel.
     */
    public byte[] generatePdfCopy(ReceiptData data) {
        try (PDDocument doc = new PDDocument()) {
            PDPage page = new PDPage(PDRectangle.A4);
            doc.addPage(page);
            writePage(doc, page, data, true);
            ByteArrayOutputStream out = new ByteArrayOutputStream();
            doc.save(out);
            return out.toByteArray();
        } catch (IOException e) {
            log.error("PDF másolat generálási hiba", e);
            throw new RuntimeException("PDF másolat generálás sikertelen", e);
        }
    }

    // ── private helpers ──────────────────────────────────────────────────────

    private void writePage(PDDocument doc, PDPage page, ReceiptData data, boolean withWatermark)
            throws IOException {

        PDType1Font fontBold   = new PDType1Font(Standard14Fonts.FontName.HELVETICA_BOLD);
        PDType1Font fontNormal = new PDType1Font(Standard14Fonts.FontName.HELVETICA);

        try (PDPageContentStream cs = new PDPageContentStream(doc, page)) {

            // Watermark first (drawn under content)
            if (withWatermark) {
                drawWatermark(cs, fontBold);
            }

            float y = PAGE_HEIGHT - MARGIN;

            // ── Fejléc ───────────────────────────────────────────────────────
            y = drawCenteredText(cs, fontBold, 16, safe(data.getCompanyName()), y);
            y -= 4;
            y = drawCenteredText(cs, fontNormal, 10, safe(data.getBranchName()), y);
            y -= 6;
            y = drawCenteredText(cs, fontNormal, 9, SEPARATOR, y);
            y -= 8;

            // ── Bizonylat info ────────────────────────────────────────────────
            y = drawLabelValue(cs, fontBold, fontNormal, 10,
                    "Bizonylat:", safe(data.getReceiptNumber()), y);
            y = drawLabelValue(cs, fontBold, fontNormal, 10,
                    "Dátum:", data.getDate() != null ? data.getDate().format(DATE_FMT) : "", y);
            y = drawLabelValue(cs, fontBold, fontNormal, 10,
                    "Pénztáros:", safe(data.getWorkerName()), y);
            y -= 6;
            y = drawCenteredText(cs, fontNormal, 9, SEPARATOR, y);
            y -= 8;

            // ── Valuta adatok ─────────────────────────────────────────────────
            if (data.getCurrencyCode() != null && !data.getCurrencyCode().isBlank()) {
                y = drawLabelValue(cs, fontBold, fontNormal, 10,
                        "Valuta:", data.getCurrencyCode(), y);
                y = drawLabelValue(cs, fontBold, fontNormal, 10,
                        "Összeg:",
                        data.getForeignAmount() != null ? data.getForeignAmount().toPlainString() : "0", y);
                y = drawLabelValue(cs, fontBold, fontNormal, 10,
                        "Árfolyam:",
                        data.getRate() != null ? data.getRate().toPlainString() : "0", y);
                // HUF value bold
                y = drawLabelValueBold(cs, fontBold, 10,
                        "HUF összeg:",
                        (data.getHufAmount() != null ? data.getHufAmount().toPlainString() : "0") + " Ft", y);
            }

            if (data.getHandlingFee() != null
                    && data.getHandlingFee().compareTo(BigDecimal.ZERO) > 0) {
                y = drawLabelValue(cs, fontBold, fontNormal, 10,
                        "Kezelési díj:", data.getHandlingFee().toPlainString() + " Ft", y);
            }

            y -= 6;
            y = drawCenteredText(cs, fontNormal, 9, SEPARATOR, y);
            y -= 8;

            // ── Ügyfél ────────────────────────────────────────────────────────
            if (data.getCustomerName() != null && !data.getCustomerName().isBlank()) {
                y = drawLabelValue(cs, fontBold, fontNormal, 10,
                        "Ügyfél:", data.getCustomerName(), y);
            }
            if (data.getCustomerIdNumber() != null && !data.getCustomerIdNumber().isBlank()) {
                y = drawLabelValue(cs, fontBold, fontNormal, 10,
                        "Okmány:", data.getCustomerIdNumber(), y);
            }

            // ── Extra sorok ───────────────────────────────────────────────────
            if (data.getLines() != null) {
                for (ReceiptData.ReceiptLineData line : data.getLines()) {
                    if (line.getLabel() != null && line.getValue() != null) {
                        y = drawLabelValue(cs, fontBold, fontNormal, 10,
                                line.getLabel() + ":", line.getValue(), y);
                    }
                }
            }

            y -= 10;
            y = drawCenteredText(cs, fontNormal, 9, SEPARATOR, y);
            y -= 16;

            // ── Aláírássor ────────────────────────────────────────────────────
            String sigLine = data.getSignatureLine() != null
                    ? data.getSignatureLine() : "Aláírás: ____________________";
            drawText(cs, fontNormal, 10, MARGIN, y, sigLine);
        }
    }

    /** Nagy szürke "MÁSOLAT" vízjel középre, 45 fokban elforgatva. */
    private void drawWatermark(PDPageContentStream cs, PDType1Font font) throws IOException {
        cs.saveGraphicsState();
        cs.setNonStrokingColor(new Color(200, 200, 200));
        cs.beginText();
        cs.setFont(font, 48);
        // Affine: rotate 45°, center of A4
        cs.setTextMatrix(Matrix.getRotateInstance(
                Math.toRadians(45),
                PAGE_WIDTH / 2f - 80,
                PAGE_HEIGHT / 2f - 30));
        cs.showText(sanitize("MÁSOLAT"));
        cs.endText();
        cs.restoreGraphicsState();
    }

    /** Szöveg kiírása megadott pozícióba, visszaad új y értéket. */
    private float drawText(PDPageContentStream cs, PDType1Font font, float size,
                           float x, float y, String text) throws IOException {
        cs.beginText();
        cs.setFont(font, size);
        cs.setNonStrokingColor(Color.BLACK);
        cs.newLineAtOffset(x, y);
        cs.showText(sanitize(text));
        cs.endText();
        return y - LINE_HEIGHT;
    }

    /** Középre igazított szöveg. */
    private float drawCenteredText(PDPageContentStream cs, PDType1Font font, float size,
                                   float y, String text) throws IOException {
        // swap parameter order to match calls: (cs, font, size, text, y)
        return drawCenteredTextInternal(cs, font, size, text, y);
    }

    private float drawCenteredText(PDPageContentStream cs, PDType1Font font, float size,
                                   String text, float y) throws IOException {
        return drawCenteredTextInternal(cs, font, size, text, y);
    }

    private float drawCenteredTextInternal(PDPageContentStream cs, PDType1Font font, float size,
                                           String text, float y) throws IOException {
        float textWidth = font.getStringWidth(sanitize(text)) / 1000f * size;
        float x = MARGIN + (CONTENT_WIDTH - textWidth) / 2f;
        if (x < MARGIN) x = MARGIN;
        return drawText(cs, font, size, x, y, text);
    }

    /** Label (bold): Value (normal) sor, két oszlopban. */
    private float drawLabelValue(PDPageContentStream cs, PDType1Font boldFont, PDType1Font normalFont,
                                 float size, String label, String value, float y) throws IOException {
        float labelWidth = boldFont.getStringWidth(sanitize(label)) / 1000f * size;
        // label
        cs.beginText();
        cs.setFont(boldFont, size);
        cs.setNonStrokingColor(Color.BLACK);
        cs.newLineAtOffset(MARGIN, y);
        cs.showText(sanitize(label));
        cs.endText();
        // value
        cs.beginText();
        cs.setFont(normalFont, size);
        cs.setNonStrokingColor(Color.BLACK);
        cs.newLineAtOffset(MARGIN + labelWidth + 6, y);
        cs.showText(sanitize(value));
        cs.endText();
        return y - LINE_HEIGHT;
    }

    /** Label + value mindkettő bold. */
    private float drawLabelValueBold(PDPageContentStream cs, PDType1Font boldFont,
                                     float size, String label, String value, float y) throws IOException {
        float labelWidth = boldFont.getStringWidth(sanitize(label)) / 1000f * size;
        cs.beginText();
        cs.setFont(boldFont, size);
        cs.setNonStrokingColor(Color.BLACK);
        cs.newLineAtOffset(MARGIN, y);
        cs.showText(sanitize(label));
        cs.endText();

        cs.beginText();
        cs.setFont(boldFont, size);
        cs.setNonStrokingColor(Color.BLACK);
        cs.newLineAtOffset(MARGIN + labelWidth + 6, y);
        cs.showText(sanitize(value));
        cs.endText();
        return y - LINE_HEIGHT;
    }

    private String safe(String s) {
        return s != null ? s : "";
    }

    /**
     * PDFBox Type1 fontok csak Latin-1 karaktereket tudnak megjeleníteni.
     * Magyar ékezetes betűket ASCII közelítéssel helyettesítjük.
     */
    private String sanitize(String text) {
        if (text == null) return "";
        return text
                .replace("á", "a").replace("Á", "A")
                .replace("é", "e").replace("É", "E")
                .replace("í", "i").replace("Í", "I")
                .replace("ó", "o").replace("Ó", "O")
                .replace("ö", "o").replace("Ö", "O")
                .replace("ő", "o").replace("Ő", "O")
                .replace("ú", "u").replace("Ú", "U")
                .replace("ü", "u").replace("Ü", "U")
                .replace("ű", "u").replace("Ű", "U")
                .replace("─", "-");
    }
}
