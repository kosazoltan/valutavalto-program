package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.entity.TransactionStatus;
import hu.puzzleir.valuta.entity.TransactionType;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import jakarta.persistence.EntityManager;
import jakarta.persistence.TypedQuery;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.io.IOException;
import java.lang.reflect.Field;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.when;

/**
 * Sprint A P2.4 (v2.5.68) + v2.5.69 Copilot P0 #705 follow-up — DailyJournalService unit tesztek.
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class DailyJournalServiceTest {

    @Mock private EntityManager entityManager;
    @Mock private BranchRepository branchRepository;
    @Mock private TypedQuery<Transaction> typedQuery;

    @InjectMocks
    private DailyJournalService service;

    private final UUID branchId = UUID.randomUUID();
    private final UUID companyId = UUID.randomUUID();
    private final LocalDate testDate = LocalDate.of(2026, 5, 19);

    @BeforeEach
    void setUp() throws Exception {
        Field f = DailyJournalService.class.getDeclaredField("entityManager");
        f.setAccessible(true);
        f.set(service, entityManager);

        when(entityManager.createQuery(anyString(), eq(Transaction.class))).thenReturn(typedQuery);
        when(typedQuery.setParameter(anyString(), org.mockito.ArgumentMatchers.any())).thenReturn(typedQuery);
    }

    @Test
    @DisplayName("Null branchId → IllegalArgumentException")
    void nullBranchId_throws() {
        assertThatThrownBy(() -> service.generatePdf(null, testDate))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("kötelező");
    }

    @Test
    @DisplayName("Null date → IllegalArgumentException")
    void nullDate_throws() {
        assertThatThrownBy(() -> service.generatePdf(branchId, null))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("kötelező");
    }

    @Test
    @DisplayName("Nem létező branch → IllegalArgumentException")
    void nonExistentBranch_throws() {
        when(branchRepository.findById(branchId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.generatePdf(branchId, testDate))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Nem létező branch");
    }

    @Test
    @DisplayName("Copilot P0 #705: cross-tenant branch → ValidationException (IDOR védelem)")
    void crossTenantBranch_throws() {
        UUID otherCompanyId = UUID.randomUUID();
        Branch otherBranch = createBranch(otherCompanyId);
        when(branchRepository.findById(branchId)).thenReturn(Optional.of(otherBranch));

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);  // ELTÉRŐ

            assertThatThrownBy(() -> service.generatePdf(branchId, testDate))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("cross-tenant access blocked");
        }
    }

    @Test
    @DisplayName("Branch.company NULL → ValidationException (cross-tenant blokk)")
    void branchWithoutCompany_throws() {
        Branch branchNoCompany = new Branch();
        branchNoCompany.setId(branchId);
        branchNoCompany.setCode("BR001");
        branchNoCompany.setName("Test");
        branchNoCompany.setCompany(null);
        when(branchRepository.findById(branchId)).thenReturn(Optional.of(branchNoCompany));

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);

            assertThatThrownBy(() -> service.generatePdf(branchId, testDate))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("cross-tenant access blocked");
        }
    }

    @Test
    @DisplayName("Üres tranzakció lista (saját cég branch) → PDF generálódik")
    void emptyTransactions_ownCompany_pdfWithHeader() throws IOException {
        Branch branch = createBranch(companyId);
        when(branchRepository.findById(branchId)).thenReturn(Optional.of(branch));
        when(typedQuery.getResultList()).thenReturn(List.of());

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);

            byte[] pdf = service.generatePdf(branchId, testDate);

            assertThat(pdf).isNotEmpty();
            assertThat(new String(pdf, 0, 5)).isEqualTo("%PDF-");
        }
    }

    @Test
    @DisplayName("3 tranzakció (saját cég) → PDF + összesítés")
    void threeTxs_ownCompany_pdfGenerated() throws IOException {
        Branch branch = createBranch(companyId);
        when(branchRepository.findById(branchId)).thenReturn(Optional.of(branch));

        Currency eur = new Currency();
        eur.setCode("EUR");

        Transaction buy = createTx("V202600001", TransactionType.BUY, eur, "1000", "365000", LocalTime.of(9, 15));
        Transaction sell = createTx("V202600002", TransactionType.SELL, eur, "500", "180000", LocalTime.of(11, 30));
        Transaction conv = createTx("V202600003", TransactionType.CONVERSION, eur, "200", "73000", LocalTime.of(14, 0));

        when(typedQuery.getResultList()).thenReturn(List.of(buy, sell, conv));

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);

            byte[] pdf = service.generatePdf(branchId, testDate);

            assertThat(pdf).isNotEmpty();
            assertThat(new String(pdf, 0, 5)).isEqualTo("%PDF-");
            assertThat(pdf.length).isGreaterThan(1000);
        }
    }

    @Test
    @DisplayName("100 tranzakció → MULTI-PAGE PDF, MINDEN tétel megjelenik, nincs csonkolás-marker")
    void manyTransactions_multiPage_noTruncation() throws IOException {
        Branch branch = createBranch(companyId);
        when(branchRepository.findById(branchId)).thenReturn(Optional.of(branch));

        Currency eur = new Currency();
        eur.setCode("EUR");

        java.util.List<Transaction> manyTxs = new java.util.ArrayList<>();
        for (int i = 0; i < 100; i++) {
            manyTxs.add(createTx("V2026" + String.format("%06d", i + 1),
                    TransactionType.BUY, eur, "100", "36500",
                    LocalTime.of(8 + i / 60, i % 60)));
        }
        when(typedQuery.getResultList()).thenReturn(manyTxs);

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);

            byte[] pdf = service.generatePdf(branchId, testDate);

            assertThat(pdf).isNotEmpty();
            assertThat(new String(pdf, 0, 5)).isEqualTo("%PDF-");

            try (var doc = org.apache.pdfbox.Loader.loadPDF(pdf)) {
                // Nagy forgalmú nap → TÖBB oldal (a régi viselkedés egyetlen oldalra csonkolt).
                assertThat(doc.getNumberOfPages()).isGreaterThan(1);

                String text = new org.apache.pdfbox.text.PDFTextStripper().getText(doc);
                // A fejléc + tranzakciószám
                assertThat(text).contains("NAPKONYV");
                assertThat(text).contains("Tranzakciok szama: 100");
                // MINDEN tétel megjelenik: az ELSŐ és az UTOLSÓ bizonylat is (nincs cap).
                assertThat(text).contains("V2026000001");
                assertThat(text).contains("V2026000100");
                // Nincs csonkolás-marker (a multi-page render kiváltotta a "...tovabbi tranzakcio" sort).
                assertThat(text).doesNotContain("tovabbi tranzakcio");
                // Az összesítés (HUF-egyenérték: 100 × 36500 = 3.650.000) szintén jelen van.
                assertThat(text).contains("OSSZESITES VALUTANKENT");
            }
        }
    }

    @Test
    @DisplayName("ő/ű a fiók nevében → NEM száll el, a PDF legenerálódik (ő→ö, ű→ü csere)")
    void branchNameWithOHungarumlaut_pdfGenerated_charsSubstituted() throws IOException {
        // A WinAnsiEncoding NEM tartalmazza az ő (U+0151) / ű (U+0171) karaktereket,
        // ezért a PDFBox showText() korábban IllegalArgumentException-t dobott → HTTP 500.
        Branch branch = createBranch(companyId);
        branch.setName("Fűzfő teszt fiók");
        when(branchRepository.findById(branchId)).thenReturn(Optional.of(branch));
        when(typedQuery.getResultList()).thenReturn(List.of());

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);

            byte[] pdf = service.generatePdf(branchId, testDate);

            assertThat(pdf).isNotEmpty();
            try (var doc = org.apache.pdfbox.Loader.loadPDF(pdf)) {
                String text = new org.apache.pdfbox.text.PDFTextStripper().getText(doc);
                // ő → ö, ű → ü (vizuálisan legközelebbi, WinAnsiban létező karakterek)
                assertThat(text).contains("Iroda: BR001 - Füzfö teszt fiók");
                // A nem-renderelhető eredeti karakterek nem maradhatnak benne.
                assertThat(text).doesNotContain("ű").doesNotContain("ő");
            }
        }
    }

    @Test
    @DisplayName("Nagy Ő/Ű a fiók nevében → Ö/Ü csere, a PDF legenerálódik")
    void branchNameWithUppercaseOHungarumlaut_pdfGenerated_charsSubstituted() throws IOException {
        Branch branch = createBranch(companyId);
        branch.setName("ŐRBOTTYÁN ŰRHAJÓ");
        when(branchRepository.findById(branchId)).thenReturn(Optional.of(branch));
        when(typedQuery.getResultList()).thenReturn(List.of());

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);

            byte[] pdf = service.generatePdf(branchId, testDate);

            try (var doc = org.apache.pdfbox.Loader.loadPDF(pdf)) {
                String text = new org.apache.pdfbox.text.PDFTextStripper().getText(doc);
                assertThat(text).contains("Iroda: BR001 - ÖRBOTTYÁN ÜRHAJÓ");
                assertThat(text).doesNotContain("Ű").doesNotContain("Ő");
            }
        }
    }

    @Test
    @DisplayName("REGRESSZIÓ: a WinAnsiban létező magyar ékezetek (á é í ó ö ú ü) VÁLTOZATLANUL renderelődnek")
    void branchNameWithWinAnsiAccents_charactersPreserved() throws IOException {
        Branch branch = createBranch(companyId);
        branch.setName("Óbudai fiók áéíóöúü ÁÉÍÓÖÚÜ");
        when(branchRepository.findById(branchId)).thenReturn(Optional.of(branch));
        when(typedQuery.getResultList()).thenReturn(List.of());

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);

            byte[] pdf = service.generatePdf(branchId, testDate);

            try (var doc = org.apache.pdfbox.Loader.loadPDF(pdf)) {
                String text = new org.apache.pdfbox.text.PDFTextStripper().getText(doc);
                // Egyetlen helyes ékezet sem sérülhet (nincs ASCII-fehérlista!).
                assertThat(text).contains("Iroda: BR001 - Óbudai fiók áéíóöúü ÁÉÍÓÖÚÜ");
            }
        }
    }

    @Test
    @DisplayName("WinAnsin kívüli egyéb karakter (pl. emoji / CJK) → '?' fallback, nincs kivétel")
    void branchNameWithNonWinAnsiSymbols_replacedWithQuestionMark() throws IOException {
        Branch branch = createBranch(companyId);
        branch.setName("Teszt 😀 東京 fiók");   // emoji (surrogate pair) + CJK
        when(branchRepository.findById(branchId)).thenReturn(Optional.of(branch));
        when(typedQuery.getResultList()).thenReturn(List.of());

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);

            byte[] pdf = service.generatePdf(branchId, testDate);

            try (var doc = org.apache.pdfbox.Loader.loadPDF(pdf)) {
                String text = new org.apache.pdfbox.text.PDFTextStripper().getText(doc);
                // A surrogate pair EGY code point → EGY '?'; a két CJK írásjel → két '?'.
                assertThat(text).contains("Iroda: BR001 - Teszt ? ?? fiók");
            }
        }
    }

    @Test
    @DisplayName("ő/ű a bizonylatszámban (tételsor) → nem száll el a render")
    void receiptNumberWithOHungarumlaut_rendersRow() throws IOException {
        Branch branch = createBranch(companyId);
        when(branchRepository.findById(branchId)).thenReturn(Optional.of(branch));

        Currency eur = new Currency();
        eur.setCode("EUR");
        Transaction tx = createTx("Vő2026ű001", TransactionType.BUY, eur, "1000", "365000", LocalTime.of(9, 15));
        when(typedQuery.getResultList()).thenReturn(List.of(tx));

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);

            byte[] pdf = service.generatePdf(branchId, testDate);

            try (var doc = org.apache.pdfbox.Loader.loadPDF(pdf)) {
                String text = new org.apache.pdfbox.text.PDFTextStripper().getText(doc);
                assertThat(text).contains("Vö2026ü001");
            }
        }
    }

    @Test
    @DisplayName("GARANCIA: a safeText() által megtartott MINDEN WinAnsi karakter valóban renderelhető")
    void everyWinAnsiCharacter_rendersWithoutException() throws IOException {
        // Empirikus bizonyíték arra, hogy a safeText() tagsági predikátuma (AGL név +
        // WinAnsiEncoding.contains) egybeesik azzal, amit a PDFBox showText() ténylegesen
        // elfogad — így a szűrés se nem szigorúbb (ékezet-vesztés), se nem lazább (HTTP 500).
        var winAnsi = org.apache.pdfbox.pdmodel.font.encoding.WinAnsiEncoding.INSTANCE;
        var glyphs = org.apache.pdfbox.pdmodel.font.encoding.GlyphList.getAdobeGlyphList();

        StringBuilder allWinAnsi = new StringBuilder();
        for (String glyphName : winAnsi.getCodeToNameMap().values()) {
            String unicode = glyphs.toUnicode(glyphName);
            if (unicode != null) {
                allWinAnsi.append(unicode);
            }
        }
        assertThat(allWinAnsi.length()).isGreaterThan(100);   // értelmes lefedettség

        Branch branch = createBranch(companyId);
        branch.setName(allWinAnsi.toString());
        when(branchRepository.findById(branchId)).thenReturn(Optional.of(branch));
        when(typedQuery.getResultList()).thenReturn(List.of());

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);

            byte[] pdf = service.generatePdf(branchId, testDate);   // nem dobhat kivételt

            assertThat(pdf).isNotEmpty();
            assertThat(new String(pdf, 0, 5)).isEqualTo("%PDF-");
        }
    }

    @Test
    @DisplayName("JPQL financialEffective=TRUE + status=COMPLETED")
    void query_filtersFinancialEffectiveAndStatus() throws IOException {
        Branch branch = createBranch(companyId);
        when(branchRepository.findById(branchId)).thenReturn(Optional.of(branch));
        when(typedQuery.getResultList()).thenReturn(List.of());

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);

            service.generatePdf(branchId, testDate);

            org.mockito.ArgumentCaptor<String> jpqlCaptor =
                    org.mockito.ArgumentCaptor.forClass(String.class);
            org.mockito.Mockito.verify(entityManager).createQuery(jpqlCaptor.capture(), eq(Transaction.class));
            String jpql = jpqlCaptor.getValue();
            assertThat(jpql).contains("financialEffective");
            assertThat(jpql).contains("TRUE");
            assertThat(jpql).contains("status");
        }
    }

    // ==========================================================================
    // Helpers
    // ==========================================================================

    private Branch createBranch(UUID branchCompanyId) {
        Company c = new Company();
        c.setId(branchCompanyId);
        c.setCode("EBC");

        Branch b = new Branch();
        b.setId(branchId);
        b.setCode("BR001");
        b.setName("Teszt iroda");
        b.setCompany(c);
        return b;
    }

    private Transaction createTx(String receipt, TransactionType type, Currency currency,
                                  String currAmt, String hufAmt, LocalTime time) {
        Transaction t = Transaction.builder()
                .receiptNumber(receipt)
                .transactionType(type)
                .currency(currency)
                .currencyAmount(new BigDecimal(currAmt))
                .hufAmount(new BigDecimal(hufAmt))
                .transactionDate(testDate)
                .transactionTime(time)
                .status(TransactionStatus.COMPLETED)
                .financialEffective(true)
                .build();
        return t;
    }
}
