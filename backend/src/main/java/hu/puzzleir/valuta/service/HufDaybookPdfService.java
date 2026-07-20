package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.daybook.HufDaybookDto;
import hu.puzzleir.valuta.dto.daybook.HufDaybookRowDto;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.math.BigDecimal;
import java.text.DecimalFormat;
import java.text.DecimalFormatSymbols;
import java.util.Locale;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDPage;
import org.apache.pdfbox.pdmodel.PDPageContentStream;
import org.apache.pdfbox.pdmodel.common.PDRectangle;
import org.apache.pdfbox.pdmodel.font.PDType1Font;
import org.apache.pdfbox.pdmodel.font.Standard14Fonts;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class HufDaybookPdfService {

    private static final DecimalFormat HUF_FORMAT;

    static {
        DecimalFormatSymbols sym = new DecimalFormatSymbols(Locale.forLanguageTag("hu-HU"));
        sym.setGroupingSeparator(' ');
        HUF_FORMAT = new DecimalFormat("#,##0", sym);
    }

    private final HufDaybookService hufDaybookService;

    public byte[] generatePdf(UUID branchId, java.time.LocalDate date) throws IOException {
        HufDaybookDto daybook = hufDaybookService.getDaybook(branchId, date);
        try (PDDocument document = new PDDocument();
             ByteArrayOutputStream out = new ByteArrayOutputStream()) {
            PDPage page = new PDPage(PDRectangle.A4);
            document.addPage(page);

            PDType1Font bold = new PDType1Font(Standard14Fonts.FontName.HELVETICA_BOLD);
            PDType1Font regular = new PDType1Font(Standard14Fonts.FontName.HELVETICA);

            try (PDPageContentStream content = new PDPageContentStream(document, page)) {
                float y = page.getMediaBox().getHeight() - 40;
                y = writeLine(content, bold, 13, 40, y, "Napi HUF naplokonyv");
                y = writeLine(content, regular, 10, 40, y - 8,
                        "Iroda: " + safe(daybook.getBranchName()) + " | Datum: " + safe(daybook.getDate()));
                y = writeLine(content, bold, 10, 40, y - 16,
                        "Sorszam | Bizonylat | Idopont | Atadas (HUF) | Atvetel (HUF)");

                for (HufDaybookRowDto row : daybook.getRows()) {
                    String line = String.format(
                            "%s | %s | %s | %s | %s",
                            row.getAnnualSequence() != null ? row.getAnnualSequence() : "-",
                            safe(row.getReceiptNumber()),
                            safe(row.getTimestamp()),
                            fmt(row.getAtadasHuf()),
                            fmt(row.getAtvetelHuf()));
                    y = writeLine(content, regular, 9, 40, y - 12, line);
                }

                writeLine(content, bold, 10, 40, y - 20,
                        "Osszesen |  |  | " + fmt(daybook.getTotalAtadasHuf()) + " | " + fmt(daybook.getTotalAtvetelHuf()));
            }

            document.save(out);
            return out.toByteArray();
        }
    }

    private static float writeLine(PDPageContentStream content, PDType1Font font, float size, float x, float y, String text)
            throws IOException {
        content.beginText();
        content.setFont(font, size);
        content.newLineAtOffset(x, y);
        content.showText(text);
        content.endText();
        return y;
    }

    private static String fmt(BigDecimal value) {
        return value == null ? "" : HUF_FORMAT.format(value) + " Ft";
    }

    private static String safe(String value) {
        if (value == null) {
            return "";
        }
        return value
                .replace('á', 'a').replace('Á', 'A')
                .replace('é', 'e').replace('É', 'E')
                .replace('í', 'i').replace('Í', 'I')
                .replace('ó', 'o').replace('Ó', 'O')
                .replace('ö', 'o').replace('Ö', 'O')
                .replace('ő', 'o').replace('Ő', 'O')
                .replace('ú', 'u').replace('Ú', 'U')
                .replace('ü', 'u').replace('Ü', 'U')
                .replace('ű', 'u').replace('Ű', 'U');
    }
}
