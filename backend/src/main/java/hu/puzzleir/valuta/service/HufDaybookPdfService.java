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

/**
 * HUF naplókönyv formázott PDF-nyomtatvány (FKH-022 kiegészítés FR-K4).
 *
 * <p>A régi papír-minta szerkezetét követi: cégfejléc (cégnév HARDCODED, a
 * {@link DailyClosingPdfService} mintája szerint — elfogadott döntés), telephely-cím,
 * dátum, tételes táblázat (éves sorszám + bizonylat + partner-kód + időpont + irányonkénti
 * összeg), Nyitó/Forgalom/Záró összegző dobozok (rajzolt kerettel) és aláírás-sor.</p>
 *
 * <p>Lapozás: a {@link DailyJournalService} JournalRenderer-mintáját követő
 * {@link FormRenderer} — ha a tartalom eléri a lap alját, új A4 oldal nyílik, és az
 * oszlopfejléc MINDEN folytatólagos oldalon ismétlődik (FR-K4/7 kontraktus: "Sorszam"
 * és "Bizonylat" minden oldalon).</p>
 *
 * <p>Karakter-kezelés: Standard14/WinAnsi — az ő/ű nem része a kódlapnak, ezért minden
 * szabad-szöveges mező a {@link #safe(String)} transliteráción megy át (FR-K4/8).</p>
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class HufDaybookPdfService {

    private static final String COMPANY_HEADER = "EXCLUSIVE BEST CHANGE ZRT";

    private static final float PAGE_WIDTH = PDRectangle.A4.getWidth();
    private static final float MARGIN = 40f;
    private static final float LINE_HEIGHT = 12f;
    private static final float FONT_SIZE_TITLE = 13f;
    private static final float FONT_SIZE_HEADER = 10f;
    private static final float FONT_SIZE_BODY = 9f;
    private static final float BOX_HEIGHT = 18f;
    private static final float BOX_GAP = 5f;
    private static final float CONTENT_WIDTH = PAGE_WIDTH - 2 * MARGIN;

    // Oszlop x-pozíciók (proporcionális fontban a szóköz-padding nem igazít — fix
    // pozíciók + jobbra igazított összeg-oszlopok kellenek).
    private static final float COL_SEQ_X = MARGIN;
    private static final float COL_RECEIPT_X = MARGIN + 48f;
    private static final float COL_PARTNER_X = MARGIN + 152f;
    private static final float COL_TIME_X = MARGIN + 205f;
    private static final float COL_ATADAS_RIGHT = MARGIN + 380f;
    private static final float COL_ATVETEL_RIGHT = PAGE_WIDTH - MARGIN;

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

            try (FormRenderer r = new FormRenderer(document)) {
                renderHeader(r, daybook);
                renderRows(r, daybook);
                renderSummaryBoxes(r, daybook);
                renderSignatures(r);
            } // a FormRenderer.close() a doc.save ELŐTT zárja az utolsó content streamet

            document.save(out);
            return out.toByteArray();
        }
    }

    // ============================ FEJLÉC ============================

    private void renderHeader(FormRenderer r, HufDaybookDto daybook) throws IOException {
        r.centerText(FormRenderer.BOLD, FONT_SIZE_TITLE, COMPANY_HEADER);
        r.advance(LINE_HEIGHT * 1.4f);
        r.centerText(FormRenderer.BODY, FONT_SIZE_HEADER, safe(daybook.getBranchName()));
        r.advance(LINE_HEIGHT);
        if (daybook.getBranchAddress() != null && !daybook.getBranchAddress().isBlank()) {
            r.centerText(FormRenderer.BODY, FONT_SIZE_HEADER, safe(daybook.getBranchAddress()));
            r.advance(LINE_HEIGHT);
        }
        r.advance(LINE_HEIGHT * 0.5f);
        r.centerText(FormRenderer.BOLD, FONT_SIZE_HEADER,
                "NAPLOKONYV (HUF) - Datum: " + safe(daybook.getDate()));
        r.advance(LINE_HEIGHT * 1.6f);
        renderColumnHeader(r, false);
    }

    private void renderColumnHeader(FormRenderer r, boolean continuation) throws IOException {
        float y = r.y();
        r.textAtY(FormRenderer.BOLD, FONT_SIZE_BODY, COL_SEQ_X, y,
                continuation ? "Sorszam (folytatas)" : "Sorszam");
        r.textAtY(FormRenderer.BOLD, FONT_SIZE_BODY, COL_RECEIPT_X, y, "Bizonylat");
        r.textAtY(FormRenderer.BOLD, FONT_SIZE_BODY, COL_PARTNER_X, y, "Partner");
        r.textAtY(FormRenderer.BOLD, FONT_SIZE_BODY, COL_TIME_X, y, "Idopont");
        r.textRightAtY(FormRenderer.BOLD, FONT_SIZE_BODY, COL_ATADAS_RIGHT, y, "Atadas (HUF)");
        r.textRightAtY(FormRenderer.BOLD, FONT_SIZE_BODY, COL_ATVETEL_RIGHT, y, "Atvetel (HUF)");
        r.advance(LINE_HEIGHT * 0.4f);
        r.line(MARGIN, r.y(), MARGIN + CONTENT_WIDTH);
        r.advance(LINE_HEIGHT);
    }

    // ============================ TÉTELSOROK ============================

    private void renderRows(FormRenderer r, HufDaybookDto daybook) throws IOException {
        for (HufDaybookRowDto row : daybook.getRows()) {
            if (r.needsNewPage(LINE_HEIGHT)) {
                r.newPage();
                // FR-K4/7: folytatólagos oldalon az oszlopfejléc ismétlődik.
                renderColumnHeader(r, true);
            }
            float y = r.y();
            r.textAtY(FormRenderer.BODY, FONT_SIZE_BODY, COL_SEQ_X, y,
                    row.getAnnualSequence() != null ? String.valueOf(row.getAnnualSequence()) : "-");
            r.textAtY(FormRenderer.BODY, FONT_SIZE_BODY, COL_RECEIPT_X, y,
                    truncate(safe(row.getReceiptNumber()), 18));
            r.textAtY(FormRenderer.BODY, FONT_SIZE_BODY, COL_PARTNER_X, y,
                    truncate(safe(row.getPartnerCode() != null ? row.getPartnerCode() : "-"), 7));
            r.textAtY(FormRenderer.BODY, FONT_SIZE_BODY, COL_TIME_X, y, safe(row.getTimestamp()));
            if (row.getAtadasHuf() != null) {
                r.textRightAtY(FormRenderer.BODY, FONT_SIZE_BODY, COL_ATADAS_RIGHT, y, fmt(row.getAtadasHuf()));
            }
            if (row.getAtvetelHuf() != null) {
                r.textRightAtY(FormRenderer.BODY, FONT_SIZE_BODY, COL_ATVETEL_RIGHT, y, fmt(row.getAtvetelHuf()));
            }
            r.advance(LINE_HEIGHT);
        }
    }

    // ============================ ÖSSZEGZŐ DOBOZOK ============================

    /**
     * Nyitó / Forgalom (Átadás+Átvétel összesen) / Záró — teljes szélességű, rajzolt
     * keretű dobozok. A blokk lap-biztos: ha nem fér el, előbb új oldal nyílik.
     */
    private void renderSummaryBoxes(FormRenderer r, HufDaybookDto daybook) throws IOException {
        float blockHeight = 3 * (BOX_HEIGHT + BOX_GAP) + LINE_HEIGHT * 2;
        r.advance(LINE_HEIGHT * 0.5f);
        r.ensureSpace(blockHeight);

        summaryBox(r, "Nyito egyenleg:", fmt(daybook.getOpeningBalanceHuf()));
        forgalomBox(r, daybook);
        summaryBox(r, "Zaro egyenleg:", fmt(daybook.getClosingBalanceHuf()));
    }

    /** Egy-soros doboz: bal oldalon címke (félkövér), jobb szélen az összeg. */
    private void summaryBox(FormRenderer r, String label, String value) throws IOException {
        float boxTop = r.y();
        r.box(MARGIN, boxTop - BOX_HEIGHT, CONTENT_WIDTH, BOX_HEIGHT);
        float textY = boxTop - BOX_HEIGHT + 5f;
        r.textAtY(FormRenderer.BOLD, FONT_SIZE_HEADER, MARGIN + 6f, textY, label);
        r.textRightAtY(FormRenderer.BODY, FONT_SIZE_HEADER, MARGIN + CONTENT_WIDTH - 6f, textY, value);
        r.advance(BOX_HEIGHT + BOX_GAP);
    }

    /** Forgalom-doboz: Átadás összesen | Átvétel összesen egy sorban. */
    private void forgalomBox(FormRenderer r, HufDaybookDto daybook) throws IOException {
        float boxTop = r.y();
        r.box(MARGIN, boxTop - BOX_HEIGHT, CONTENT_WIDTH, BOX_HEIGHT);
        float textY = boxTop - BOX_HEIGHT + 5f;
        r.textAtY(FormRenderer.BOLD, FONT_SIZE_HEADER, MARGIN + 6f, textY,
                "Atadas osszesen: " + fmt(daybook.getTotalAtadasHuf()));
        r.textRightAtY(FormRenderer.BOLD, FONT_SIZE_HEADER, MARGIN + CONTENT_WIDTH - 6f, textY,
                "Atvetel osszesen: " + fmt(daybook.getTotalAtvetelHuf()));
        r.advance(BOX_HEIGHT + BOX_GAP);
    }

    // ============================ ALÁÍRÁS ============================

    private void renderSignatures(FormRenderer r) throws IOException {
        r.ensureSpace(LINE_HEIGHT * 4);
        r.advance(LINE_HEIGHT * 2);
        float half = CONTENT_WIDTH / 2f;
        r.textAtY(FormRenderer.BODY, FONT_SIZE_BODY, MARGIN + 20f, r.y(),
                "..............................");
        r.textAtY(FormRenderer.BODY, FONT_SIZE_BODY, MARGIN + half + 20f, r.y(),
                "..............................");
        r.advance(LINE_HEIGHT);
        r.textAtY(FormRenderer.BODY, FONT_SIZE_BODY, MARGIN + 32f, r.y(),
                "Penztaros alairasa");
        r.textAtY(FormRenderer.BODY, FONT_SIZE_BODY, MARGIN + half + 32f, r.y(),
                "Ellenorzo alairasa");
        r.advance(LINE_HEIGHT);
    }

    // ============================ RENDERER ============================

    /**
     * Lap-folyamot kezelő segéd a DailyJournalService JournalRenderer-mintája szerint:
     * ha a tartalom eléri a lap alját, {@link #needsNewPage}/{@link #ensureSpace} alapján
     * automatikusan új A4 oldalt nyit. A content stream laponként külön, ezért oldalváltáskor
     * a régit lezárjuk és újat nyitunk; a {@link #close()} idempotens és a doc.save ELŐTT
     * hívandó. Kiegészítés a nyomtatvány-igényekhez: {@link #centerText},
     * {@link #textRightAtY} (jobbra igazítás) és {@link #box} (rajzolt keret).
     */
    private static final class FormRenderer implements AutoCloseable {
        static final PDType1Font BOLD = new PDType1Font(Standard14Fonts.FontName.HELVETICA_BOLD);
        static final PDType1Font BODY = new PDType1Font(Standard14Fonts.FontName.HELVETICA);
        private static final float TOP_Y = PDRectangle.A4.getHeight() - MARGIN;
        private static final float BOTTOM_Y = MARGIN;

        private final PDDocument doc;
        private PDPageContentStream content;
        private float y;

        FormRenderer(PDDocument doc) throws IOException {
            this.doc = doc;
            startPage();
        }

        private void startPage() throws IOException {
            PDPage page = new PDPage(PDRectangle.A4);
            doc.addPage(page);
            content = new PDPageContentStream(doc, page);
            y = TOP_Y;
        }

        float y() {
            return y;
        }

        void advance(float dy) {
            y -= dy;
        }

        boolean needsNewPage(float needed) {
            return y - needed < BOTTOM_Y;
        }

        void ensureSpace(float needed) throws IOException {
            if (needsNewPage(needed)) {
                newPage();
            }
        }

        void newPage() throws IOException {
            content.close();
            startPage();
        }

        void centerText(PDType1Font font, float size, String s) throws IOException {
            float width = font.getStringWidth(s) / 1000f * size;
            textAtY(font, size, (PAGE_WIDTH - width) / 2f, y, s);
        }

        void textAtY(PDType1Font font, float size, float x, float textY, String s) throws IOException {
            content.beginText();
            content.setFont(font, size);
            content.newLineAtOffset(x, textY);
            content.showText(s);
            content.endText();
        }

        /** Jobb szélre igazított szöveg: az {@code xRight} a szöveg JOBB széle. */
        void textRightAtY(PDType1Font font, float size, float xRight, float textY, String s) throws IOException {
            float width = font.getStringWidth(s) / 1000f * size;
            textAtY(font, size, xRight - width, textY, s);
        }

        /** Rajzolt keret (doboz) — bal-alsó sarok (x, y), szélesség/magasság pontban. */
        void box(float x, float boxY, float width, float height) throws IOException {
            content.addRect(x, boxY, width, height);
            content.stroke();
        }

        /** Vízszintes elválasztó vonal az adott y-on. */
        void line(float x1, float lineY, float x2) throws IOException {
            content.moveTo(x1, lineY);
            content.lineTo(x2, lineY);
            content.stroke();
        }

        @Override
        public void close() throws IOException {
            if (content != null) {
                content.close();
                content = null;
            }
        }
    }

    // ============================ FORMÁZÁS ============================

    private static String fmt(BigDecimal value) {
        return value == null ? "" : HUF_FORMAT.format(value) + " Ft";
    }

    private static String truncate(String s, int max) {
        if (s == null) {
            return "";
        }
        return s.length() > max ? s.substring(0, max) : s;
    }

    /**
     * WinAnsi-biztos transliteráció (FR-K4/8): a Standard14 fontok kódlapja az ő/ű
     * karaktereket nem tartalmazza — minden magyar ékezet ASCII-ra képződik le,
     * ahogy a korábbi verzióban is.
     */
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
