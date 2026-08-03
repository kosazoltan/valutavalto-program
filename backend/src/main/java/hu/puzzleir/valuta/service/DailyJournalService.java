package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.entity.TransactionStatus;
import hu.puzzleir.valuta.entity.TransactionType;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDPage;
import org.apache.pdfbox.pdmodel.PDPageContentStream;
import org.apache.pdfbox.pdmodel.common.PDRectangle;
import org.apache.pdfbox.pdmodel.font.PDType1Font;
import org.apache.pdfbox.pdmodel.font.Standard14Fonts;
import org.apache.pdfbox.pdmodel.font.encoding.Encoding;
import org.apache.pdfbox.pdmodel.font.encoding.GlyphList;
import org.apache.pdfbox.pdmodel.font.encoding.WinAnsiEncoding;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.math.BigDecimal;
import java.text.DecimalFormat;
import java.text.DecimalFormatSymbols;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;

/**
 * Napkönyv (daily transaction journal) PDF service — legacy NAPKONYV (33K, 65f) parity.
 *
 * <p>v2.5.68 Sprint A P2.4: napi forgalmi napló — minden tranzakció kronologikusan
 * listázva + valutánkénti és típusonkénti összesítés a lap alján. KÜLÖNBÖZIK a
 * {@link DailyClosingPdfService}-től, ami napzárás (cash count + reconciliation).</p>
 *
 * <p>Multi-tenant: a branch.company FK kötelező — a controller @PreAuthorize-zal
 * szűri az illetékességet, plus a JPQL `t.branch.id = :branchId` természeténél fogva
 * tenant-skópolt (a branch.id egyedi globally, FK constraint).</p>
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
@Slf4j
public class DailyJournalService {

    @PersistenceContext
    private EntityManager entityManager;

    private final BranchRepository branchRepository;

    private static final float PAGE_WIDTH = PDRectangle.A4.getWidth();
    private static final float PAGE_HEIGHT = PDRectangle.A4.getHeight();
    private static final float MARGIN = 40f;
    private static final float FONT_SIZE_HEADER = 12f;
    private static final float FONT_SIZE_BODY = 9f;
    private static final float LINE_HEIGHT = 12f;

    /** A {@link #safeText(String)} karakter-tagsági ellenőrzéséhez (lásd ott a részleteket). */
    private static final GlyphList ADOBE_GLYPH_LIST = GlyphList.getAdobeGlyphList();
    private static final Encoding WIN_ANSI_ENCODING = WinAnsiEncoding.INSTANCE;

    private static final DecimalFormat AMOUNT_FORMAT;
    private static final DecimalFormat RATE_FORMAT;
    private static final DateTimeFormatter TIME_FORMAT = DateTimeFormatter.ofPattern("HH:mm");
    private static final DateTimeFormatter DATE_FORMAT = DateTimeFormatter.ofPattern("yyyy-MM-dd");

    static {
        DecimalFormatSymbols sym = new DecimalFormatSymbols(Locale.forLanguageTag("hu-HU"));
        sym.setGroupingSeparator(' ');
        AMOUNT_FORMAT = new DecimalFormat("#,##0", sym);
        RATE_FORMAT = new DecimalFormat("#,##0.00", sym);
    }

    /**
     * Generálja a napi forgalmi naplót PDF-ben az adott iroda + nap kombinációra.
     */
    public byte[] generatePdf(UUID branchId, LocalDate date) throws IOException {
        if (branchId == null || date == null) {
            throw new IllegalArgumentException("branchId és date kötelező");
        }

        Branch branch = branchRepository.findById(branchId)
                .orElseThrow(() -> new IllegalArgumentException("Nem létező branch: " + branchId));

        // Copilot P0 #705 fix: multi-tenant IDOR védelem — a controller @PreAuthorize
        // role-szinten véd, de a branchId URL paraméter user-controlled. Itt verifikáljuk,
        // hogy a branch a jelenlegi cég-hez tartozik (defense-in-depth).
        UUID currentCompanyId = SecurityUtils.getCurrentCompanyId();
        // Copilot P2 #706 fix: null-safe equals minta (currentCompanyId.equals(...))
        // — ha a branch.company.id valamiért null (partial test entity), a régi
        // `branch.getCompany().getId().equals(...)` NPE-zett volna.
        if (branch.getCompany() == null || !currentCompanyId.equals(branch.getCompany().getId())) {
            log.warn("Cross-tenant access blocked: branchId={}, currentCompanyId={}, branchCompanyId={}",
                    branchId, currentCompanyId,
                    branch.getCompany() != null ? branch.getCompany().getId() : null);
            throw new ValidationException("A megadott branch nem tartozik a jelenlegi céghez (cross-tenant access blocked)");
        }

        List<Transaction> transactions = fetchTransactions(branchId, date);
        Map<String, BigDecimal> currencySummary = aggregateByCurrency(transactions);
        Map<TransactionType, Integer> typeSummary = aggregateByType(transactions);

        return renderPdf(branch, date, transactions, currencySummary, typeSummary);
    }

    @SuppressWarnings("unchecked")
    private List<Transaction> fetchTransactions(UUID branchId, LocalDate date) {
        return entityManager.createQuery(
                "SELECT t FROM Transaction t " +
                        "LEFT JOIN FETCH t.currency " +
                        "LEFT JOIN FETCH t.worker " +
                        "WHERE t.branch.id = :branchId " +
                        "AND t.transactionDate = :date " +
                        "AND t.status = :status " +
                        "AND t.financialEffective = TRUE " +
                        "ORDER BY t.transactionTime ASC, t.receiptNumber ASC",
                Transaction.class)
                .setParameter("branchId", branchId)
                .setParameter("date", date)
                .setParameter("status", TransactionStatus.COMPLETED)
                .getResultList();
    }

    private Map<String, BigDecimal> aggregateByCurrency(List<Transaction> txs) {
        Map<String, BigDecimal> map = new HashMap<>();
        for (Transaction t : txs) {
            if (t.getCurrency() == null) continue;
            String code = t.getCurrency().getCode();
            BigDecimal hufAmount = t.getHufAmount() != null ? t.getHufAmount() : BigDecimal.ZERO;
            map.merge(code, hufAmount, BigDecimal::add);
        }
        return map;
    }

    private Map<TransactionType, Integer> aggregateByType(List<Transaction> txs) {
        Map<TransactionType, Integer> map = new HashMap<>();
        for (Transaction t : txs) {
            map.merge(t.getTransactionType(), 1, Integer::sum);
        }
        return map;
    }

    private byte[] renderPdf(Branch branch, LocalDate date, List<Transaction> txs,
                              Map<String, BigDecimal> currencySummary,
                              Map<TransactionType, Integer> typeSummary) throws IOException {
        try (PDDocument doc = new PDDocument();
             ByteArrayOutputStream baos = new ByteArrayOutputStream()) {

            // MULTI-PAGE: a JournalRenderer automatikusan új A4 oldalt nyit, ha a tartalom eléri a
            // lap alját. Így nagy forgalmú napon sem csonkul a tételes lista (a totálok eddig is
            // helyesek voltak; korábban a tételsorok cap-elve voltak egy "...tovabbi tranzakcio" markerrel).
            final String columnHeader = "Ido   Bizonylat   Tipus       Valuta  Mennyiseg     HUF egyenertek";
            try (JournalRenderer r = new JournalRenderer(doc)) {

                // === Fejléc (első oldal) ===
                r.textLeft(JournalRenderer.BOLD, FONT_SIZE_HEADER, "NAPKONYV — Napi forgalmi naplo");
                r.advance(LINE_HEIGHT * 1.5f);
                r.textLeft(JournalRenderer.BODY, FONT_SIZE_BODY,
                        "Iroda: " + safeText(branch.getCode() + " - " + branch.getName()));
                r.advance(LINE_HEIGHT);
                r.textLeft(JournalRenderer.BODY, FONT_SIZE_BODY, "Datum: " + DATE_FORMAT.format(date));
                r.advance(LINE_HEIGHT);
                r.textLeft(JournalRenderer.BODY, FONT_SIZE_BODY, "Tranzakciok szama: " + txs.size());
                r.advance(LINE_HEIGHT * 2);

                // === Tranzakció lista oszlopfejléc ===
                r.textLeft(JournalRenderer.BOLD, FONT_SIZE_BODY, columnHeader);
                r.advance(LINE_HEIGHT);

                // === Tranzakciók (MINDET kirendereljük, lapokra törve) ===
                for (Transaction t : txs) {
                    if (r.needsNewPage(LINE_HEIGHT)) {
                        r.newPage();
                        // Folytatólagos oldalon megismételjük az oszlopfejlécet.
                        r.textLeft(JournalRenderer.BOLD, FONT_SIZE_BODY, columnHeader + "  (folytatas)");
                        r.advance(LINE_HEIGHT);
                    }
                    renderTransactionRow(r.content(), t, r.y()); // a sor önállóan állítja a BODY fontot
                    r.advance(LINE_HEIGHT);
                }
                r.advance(LINE_HEIGHT);

                // === Összesítés valutánként (lap-biztos) ===
                r.ensureSpace(LINE_HEIGHT * 2);
                r.textLeft(JournalRenderer.BOLD, FONT_SIZE_BODY, "OSSZESITES VALUTANKENT (HUF egyenertek):");
                r.advance(LINE_HEIGHT);
                for (var entry : currencySummary.entrySet()) {
                    r.ensureSpace(LINE_HEIGHT);
                    r.textAt(JournalRenderer.BODY, FONT_SIZE_BODY, MARGIN + 20,
                            "  " + entry.getKey() + ": " + AMOUNT_FORMAT.format(entry.getValue()) + " Ft");
                    r.advance(LINE_HEIGHT);
                }
                r.advance(LINE_HEIGHT);

                // === Összesítés típusonként (lap-biztos) ===
                r.ensureSpace(LINE_HEIGHT * 2);
                r.textLeft(JournalRenderer.BOLD, FONT_SIZE_BODY, "OSSZESITES TIPUSONKENT:");
                r.advance(LINE_HEIGHT);
                for (var entry : typeSummary.entrySet()) {
                    r.ensureSpace(LINE_HEIGHT);
                    r.textAt(JournalRenderer.BODY, FONT_SIZE_BODY, MARGIN + 20,
                            "  " + entry.getKey().name() + ": " + entry.getValue() + " db");
                    r.advance(LINE_HEIGHT);
                }
            } // a JournalRenderer.close() lezárja az utolsó content stream-et a doc.save ELŐTT

            doc.save(baos);
            return baos.toByteArray();
        }
    }

    /**
     * Lap-folyamot kezelő segéd a Napkönyv PDF-hez: ha a tartalom eléri a lap alját, a hívó
     * {@link #needsNewPage}/{@link #ensureSpace} alapján automatikusan új A4 oldalt nyit
     * ({@link #newPage}). A PDFBox content stream laponként külön, ezért oldalváltáskor a régit
     * lezárjuk és újat nyitunk. Az {@link AutoCloseable#close()} idempotens (a doc.save ELŐTT
     * kell hívni, hogy a stream véglegesítődjön).
     */
    private static final class JournalRenderer implements AutoCloseable {
        static final PDType1Font BOLD = new PDType1Font(Standard14Fonts.FontName.HELVETICA_BOLD);
        static final PDType1Font BODY = new PDType1Font(Standard14Fonts.FontName.HELVETICA);
        private static final float TOP_Y = PAGE_HEIGHT - MARGIN;
        private static final float BOTTOM_Y = MARGIN;

        private final PDDocument doc;
        private PDPageContentStream content;
        private float y;

        JournalRenderer(PDDocument doc) throws IOException {
            this.doc = doc;
            startPage();
        }

        private void startPage() throws IOException {
            PDPage page = new PDPage(PDRectangle.A4);
            doc.addPage(page);
            content = new PDPageContentStream(doc, page);
            y = TOP_Y;
        }

        PDPageContentStream content() {
            return content;
        }

        float y() {
            return y;
        }

        /** Sorelőrelépés (az y-t csökkenti). */
        void advance(float dy) {
            y -= dy;
        }

        /** True, ha a következő {@code needed} magasságú blokk már nem fér el az aktuális lapon. */
        boolean needsNewPage(float needed) {
            return y - needed < BOTTOM_Y;
        }

        /** Ha a {@code needed} blokk nem fér el, új oldalt nyit. */
        void ensureSpace(float needed) throws IOException {
            if (needsNewPage(needed)) {
                newPage();
            }
        }

        /** Lezárja az aktuális stream-et és új A4 oldalt nyit (a fejlécet a hívó rajzolja újra). */
        void newPage() throws IOException {
            content.close();
            startPage();
        }

        /** Szöveg a bal margón, az aktuális y-on (a sort NEM lépteti). */
        void textLeft(PDType1Font font, float size, String s) throws IOException {
            textAt(font, size, MARGIN, s);
        }

        /** Szöveg adott x-en, az aktuális y-on. */
        void textAt(PDType1Font font, float size, float x, String s) throws IOException {
            content.beginText();
            content.setFont(font, size);
            content.newLineAtOffset(x, y);
            content.showText(s);
            content.endText();
        }

        @Override
        public void close() throws IOException {
            if (content != null) {
                content.close();
                content = null;
            }
        }
    }

    private void renderTransactionRow(PDPageContentStream content, Transaction t, float y) throws IOException {
        String time = t.getTransactionTime() != null
                ? TIME_FORMAT.format(t.getTransactionTime()) : "?????";
        String receipt = safeText(t.getReceiptNumber());
        String type = t.getTransactionType().name();
        String currency = t.getCurrency() != null ? t.getCurrency().getCode() : "???";
        String currAmt = t.getCurrencyAmount() != null
                ? RATE_FORMAT.format(t.getCurrencyAmount()) : "0";
        String hufAmt = t.getHufAmount() != null
                ? AMOUNT_FORMAT.format(t.getHufAmount()) : "0";

        content.beginText();
        // Önálló font-beállítás: a sor NEM függ a hívó által hagyott font-állapottól (különben a
        // megelőző BOLD oszlopfejléc miatt a tételsorok kövéren renderelődnének — multi-page review P1).
        content.setFont(JournalRenderer.BODY, FONT_SIZE_BODY);
        content.newLineAtOffset(MARGIN, y);
        content.showText(String.format("%-6s%-12s%-12s%-7s%12s   %12s Ft",
                time, truncate(receipt, 11), truncate(type, 11), currency, currAmt, hufAmt));
        content.endText();
    }

    /**
     * PDF-render-biztos string a Standard-14 Helvetica + {@link WinAnsiEncoding} párosához.
     *
     * <p><b>A WinAnsiEncoding NEM ismeri a teljes magyar ábécét.</b> Az á/é/í/ó/ö/ú/ü és
     * nagybetűs párjaik benne vannak, de a kettős hosszú ékezetes
     * <b>ő (U+0151 / U+0150) és ű (U+0171 / U+0170) NINCS</b> — ezekre a PDFBox
     * {@code showText()} {@code IllegalArgumentException}-t dob
     * ("U+0151 ('odblacute') is not available in the font Helvetica"), ami korábban
     * HTTP 500-at okozott, ha a fiók neve vagy a bizonylatszám ilyen betűt tartalmazott.</p>
     *
     * <p>Tényleges viselkedés:</p>
     * <ul>
     *   <li><b>ő→ö, Ő→Ö, ű→ü, Ű→Ü</b> — jóváhagyott üzleti döntés: a vizuálisan
     *       legközelebbi, WinAnsiban létező karakter.</li>
     *   <li>Minden egyéb, WinAnsiban nem létező code point (emoji, CJK, extra-Unicode,
     *       sorvég) → {@code '?'}; kivétel helyett látható helyettesítő jel.</li>
     *   <li>A WinAnsiban létező karakterek <b>változatlanul</b> maradnak — nincs
     *       szűkítő ASCII-fehérlista, a helyes magyar ékezetek nem sérülnek.</li>
     * </ul>
     *
     * <p>A tagságot a tényleges {@link WinAnsiEncoding} tábla dönti el, az Adobe Glyph List
     * szerinti névfeloldással — ugyanaz a két lépés, amit a PDFBox
     * {@code PDType1Font.encode()} is végez —, nem kézzel karbantartott karakterlista.</p>
     */
    private static String safeText(String s) {
        if (s == null) return "";
        StringBuilder sb = new StringBuilder(s.length());
        for (int i = 0; i < s.length(); ) {
            int cp = s.codePointAt(i);
            i += Character.charCount(cp);   // surrogate pár = EGY code point
            int mapped = switch (cp) {
                case 0x0151 -> 'ö';   // ő
                case 0x0150 -> 'Ö';   // Ő
                case 0x0171 -> 'ü';   // ű
                case 0x0170 -> 'Ü';   // Ű
                default -> cp;
            };
            sb.appendCodePoint(isWinAnsiRenderable(mapped) ? mapped : '?');
        }
        return sb.toString();
    }

    /** True, ha a code point a WinAnsiEncoding tábla tagja (AGL névfeloldás után). */
    private static boolean isWinAnsiRenderable(int codePoint) {
        String glyphName = ADOBE_GLYPH_LIST.codePointToName(codePoint);
        return glyphName != null
                && !".notdef".equals(glyphName)
                && WIN_ANSI_ENCODING.contains(glyphName);
    }

    private static String truncate(String s, int max) {
        if (s == null) return "";
        return s.length() > max ? s.substring(0, max) : s;
    }
}
