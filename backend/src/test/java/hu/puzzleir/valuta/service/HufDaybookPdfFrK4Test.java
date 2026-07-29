package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.daybook.HufDaybookDto;
import hu.puzzleir.valuta.dto.daybook.HufDaybookRowDto;

import java.lang.reflect.Field;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import org.apache.pdfbox.Loader;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.text.PDFTextStripper;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.fail;
import static org.mockito.ArgumentMatchers.any;

/**
 * FKH-022 kiegészítés FR-K4 (RED-fázis): formázott naplókönyv-nyomtatvány PDF.
 *
 * <p>A bevett PDF-teszt mintát követi ({@link DailyClosingPdfServiceTest}): DTO →
 * render → {@code PDFTextStripper} szöveg-visszaolvasás → {@code contains()} asszerciók.
 * A {@link HufDaybookPdfService} a {@link HufDaybookService}-ből kapja az adatot, ezért
 * itt Mockito-mockkal adjuk be a DTO-t.</p>
 *
 * <p>Kontraktus-döntések (spec-hézagok, dokumentálva a beadási jelentésben):
 * <ul>
 *   <li>Cégnév: HARDCODED "EXCLUSIVE BEST CHANGE ZRT" a {@link DailyClosingPdfService}
 *       mintája szerint (ELFOGADOTT döntés, nem hiba).</li>
 *   <li>Az egyenleg-címkék transliterált formában legalább a "Nyito" és "Zaro" szót
 *       tartalmazzák; az összegformátum a meglévő HUF_FORMAT (szóköz-ezrestagolás).</li>
 *   <li>"Forgalom" a nyomtatványon két irányban jelenik meg (átadás/átvétel összesen,
 *       a meglévő totálokból) — a teszt a formázott összegeket és az "Osszesen" címkét
 *       várja el, nem egyetlen skalár "Forgalom" mezőt.</li>
 *   <li>Oszlopfejléc-ismétlés: minden oldalon szerepel a "Sorszam" és "Bizonylat"
 *       oszlopcím (JournalRenderer-minta, folytatólagos oldalon is).</li>
 *   <li>Aláírás-blokk: a szöveg tartalmazza az "alairas" szót (transliterált).</li>
 *   <li>Az új DTO-mezők (openingBalanceHuf/closingBalanceHuf/branchAddress) írása
 *       reflectionnel történik, hogy a RED-fázisban a suite forduljon — a hiányzó mező
 *       egyértelmű RED-üzenettel bukik, az implementáció után módosítás nélkül működik.</li>
 * </ul></p>
 */
class HufDaybookPdfFrK4Test {

    private final HufDaybookService daybookService = Mockito.mock(HufDaybookService.class);
    private final HufDaybookPdfService pdfService = new HufDaybookPdfService(daybookService);

    // =====================================================================
    // FR-K4 / 6. G-W-T: teljes nyomtatvány — fejléc, tételek, egyenlegek, aláírás
    // =====================================================================
    @Test
    @DisplayName("FR-K4/6: a PDF tartalmazza a cégfejlécet, telephely-címet, dátumot, minden tétel sorszámát/partner-kódját/összegét, a Nyitó/Záró/Összesen értékeket és az aláírás-sort")
    void formattedFormContainsHeaderRowsBalancesAndSignature() throws Exception {
        HufDaybookDto dto = HufDaybookDto.builder()
                .branchId(UUID.randomUUID().toString())
                .branchName("Szeged Ertektar")
                .date("2026-07-01")
                .rows(List.of(
                        row(101, "UF-000201", "076", "09:15:00", null, huf(80_000), false),
                        row(102, "FF-000021", "PRB", "10:30:00", huf(50_000), null, false)))
                .totalAtadasHuf(huf(50_000))
                .totalAtvetelHuf(huf(80_000))
                .build();
        setNewField(dto, "branchAddress", "6720 Szeged, Karasz utca 9.");
        setNewField(dto, "openingBalanceHuf", huf(1_234_500));
        setNewField(dto, "closingBalanceHuf", huf(1_264_500));
        Mockito.when(daybookService.getDaybook(any(UUID.class), any(LocalDate.class))).thenReturn(dto);

        byte[] pdf = pdfService.generatePdf(UUID.randomUUID(), LocalDate.of(2026, 7, 1));

        assertThat(pdf).isNotNull();
        assertThat(new String(pdf, 0, 5)).isEqualTo("%PDF-");

        try (PDDocument doc = Loader.loadPDF(pdf)) {
            String text = new PDFTextStripper().getText(doc);

            // Fejléc: hardcoded cégnév (elfogadott döntés) + fiók + telephely-cím + dátum.
            assertThat(text)
                    .as("RED (FR-K4): a nyomtatvány cégfejléce (EXCLUSIVE BEST CHANGE ZRT) még hiányzik")
                    .contains("EXCLUSIVE BEST CHANGE ZRT");
            assertThat(text).contains("Szeged Ertektar");
            assertThat(text)
                    .as("RED (FR-K4): a telephely-cím sor még hiányzik a fejlécből")
                    .contains("6720 Szeged, Karasz utca 9.");
            assertThat(text).contains("2026-07-01");

            // Tételsorok: éves sorszám + bizonylatszám + partner-kód + összeg.
            assertThat(text).contains("101").contains("102");
            assertThat(text).contains("UF-000201").contains("FF-000021");
            assertThat(text)
                    .as("RED (FR-K4): a partner-kód oszlop (076 / PRB) még nem renderelődik")
                    .contains("076")
                    .contains("PRB");
            assertThat(text).contains("80 000").contains("50 000");

            // Összegző blokk: Nyitó / Záró / Összesen.
            assertThat(text)
                    .as("RED (FR-K5/K4): a Nyitó egyenleg címke+érték még hiányzik")
                    .containsIgnoringCase("Nyito")
                    .contains("1 234 500");
            assertThat(text)
                    .as("RED (FR-K5/K4): a Záró egyenleg címke+érték még hiányzik")
                    .containsIgnoringCase("Zaro")
                    .contains("1 264 500");
            assertThat(text).containsIgnoringCase("Osszesen");

            // Aláírás-sor (transliterált).
            assertThat(text)
                    .as("RED (FR-K4): az aláírás-blokk még hiányzik")
                    .containsIgnoringCase("alairas");
        }
    }

    // =====================================================================
    // FR-K4 / 7. G-W-T: ~80 tétel → többoldalas render, sorvesztés nélkül
    // =====================================================================
    @Test
    @DisplayName("FR-K4/7: 80 tételes nap TÖBB oldalon renderelődik, minden oldalon ismételt oszlopfejléccel, és egyetlen tételsor sem vész el")
    void longDayRendersOnMultiplePagesWithRepeatedHeader() throws Exception {
        List<HufDaybookRowDto> rows = new ArrayList<>();
        for (int i = 1; i <= 80; i++) {
            rows.add(row(i, String.format("UF-%06d", i), "076",
                    String.format("%02d:%02d:00", 8 + i / 60, i % 60), null, huf(1_000), false));
        }
        HufDaybookDto dto = HufDaybookDto.builder()
                .branchId(UUID.randomUUID().toString())
                .branchName("Pecs Ertektar")
                .date("2026-07-01")
                .rows(rows)
                .totalAtadasHuf(BigDecimal.ZERO)
                .totalAtvetelHuf(huf(80_000))
                .build();
        Mockito.when(daybookService.getDaybook(any(UUID.class), any(LocalDate.class))).thenReturn(dto);

        byte[] pdf = pdfService.generatePdf(UUID.randomUUID(), LocalDate.of(2026, 7, 1));

        try (PDDocument doc = Loader.loadPDF(pdf)) {
            assertThat(doc.getNumberOfPages())
                    .as("RED (FR-K4): 80 tétel egyetlen A4 oldalra nem fér el — lapozás (JournalRenderer-minta) szükséges")
                    .isGreaterThanOrEqualTo(2);

            String fullText = new PDFTextStripper().getText(doc);
            for (int i = 1; i <= 80; i++) {
                assertThat(fullText)
                        .as("A(z) %d. tételsor nem veszhet el a lapozásnál", i)
                        .contains(String.format("UF-%06d", i));
            }

            for (int page = 2; page <= doc.getNumberOfPages(); page++) {
                PDFTextStripper pageStripper = new PDFTextStripper();
                pageStripper.setStartPage(page);
                pageStripper.setEndPage(page);
                String pageText = pageStripper.getText(doc);
                assertThat(pageText)
                        .as("RED (FR-K4): a folytatólagos %d. oldalon ismételni kell az oszlopfejlécet", page)
                        .containsIgnoringCase("Sorszam")
                        .containsIgnoringCase("Bizonylat");
            }
        }
    }

    // =====================================================================
    // FR-K4 / 8. G-W-T: ékezetes fiók-adatok — a render nem törhet el
    // =====================================================================
    @Test
    @DisplayName("FR-K4/8: ő/ű ékezetes Branch-név és -cím mellett a render nem dob hibát (transliteráció megtartva); ékezetes kimenet NEM elvárás")
    void accentedBranchDataDoesNotBreakRendering() {
        HufDaybookDto dto = HufDaybookDto.builder()
                .branchId(UUID.randomUUID().toString())
                .branchName("Győri Értéktár")
                .date("2026-07-01")
                .rows(List.of(
                        row(1, "UF-000001", "076", "09:00:00", null, huf(10_000), false)))
                .totalAtadasHuf(BigDecimal.ZERO)
                .totalAtvetelHuf(huf(10_000))
                .build();
        // ő/ű: a Standard14/WinAnsi ezeket nem tudja — a transliterációnak (safe() minta)
        // az ÚJ cím-mezőre is működnie kell, különben a showText kivételt dob.
        setNewField(dto, "branchAddress", "9021 Győr, Kőszegi ű-utca 5.");
        setNewField(dto, "openingBalanceHuf", BigDecimal.ZERO);
        setNewField(dto, "closingBalanceHuf", huf(10_000));
        Mockito.when(daybookService.getDaybook(any(UUID.class), any(LocalDate.class))).thenReturn(dto);

        assertThatCode(() -> {
            byte[] pdf = pdfService.generatePdf(UUID.randomUUID(), LocalDate.of(2026, 7, 1));
            assertThat(new String(pdf, 0, 5)).isEqualTo("%PDF-");
        })
                .as("RED (FR-K4): az ékezetes fiók-adat (ő/ű) nem törheti el a rendert — transliteráció kötelező")
                .doesNotThrowAnyException();
    }

    // ============================ HELPEREK ============================

    private static HufDaybookRowDto row(int annualSequence, String receiptNumber, String partnerCode,
                                        String timestamp, BigDecimal atadasHuf, BigDecimal atvetelHuf,
                                        boolean storno) {
        return HufDaybookRowDto.builder()
                .annualSequence(annualSequence)
                .receiptNumber(receiptNumber)
                .partnerCode(partnerCode)
                .timestamp(timestamp)
                .atadasHuf(atadasHuf)
                .atvetelHuf(atvetelHuf)
                .storno(storno)
                .build();
    }

    private static BigDecimal huf(long value) {
        return BigDecimal.valueOf(value);
    }

    /**
     * RED-biztos mező-író: amíg a HufDaybookDto-n nincs meg az új mező, egyértelmű
     * RED-üzenettel bukik (nem compile-hibával); az implementáció után módosítás
     * nélkül a valódi értéket állítja be.
     */
    private static void setNewField(Object target, String fieldName, Object value) {
        try {
            Field field = target.getClass().getDeclaredField(fieldName);
            field.setAccessible(true);
            field.set(target, value);
        } catch (NoSuchFieldException e) {
            fail("RED (FR-K4/K5): a " + target.getClass().getSimpleName() + "." + fieldName
                    + " mező még nem létezik — a bővített DTO + nyomtatvány-implementáció hiányzik");
        } catch (IllegalAccessException e) {
            throw new IllegalStateException(e);
        }
    }
}
