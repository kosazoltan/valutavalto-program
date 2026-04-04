package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.report.MonthlyReportFullDto;
import org.apache.pdfbox.Loader;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.text.PDFTextStripper;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class MonthlyClosingPdfServiceTest {

    private final MonthlyClosingPdfService service = new MonthlyClosingPdfService(null);

    @Test
    @DisplayName("Havi zaras PDF: teljes report -> valid PDF, Delphi havizar paritas")
    void generatePdf_fullMonthlyReport() throws Exception {
        MonthlyReportFullDto report = MonthlyReportFullDto.builder()
                .yearMonth("2026-03")
                .branchId("11111111-1111-1111-1111-111111111111")
                .branchCode("101")
                .branchName("Test Iroda")
                .branchAddress("7621 Pecs, Kiraly u. 10.")
                .taxId("32313332-2-02")
                .closingBalanceHuf(new BigDecimal("15000000"))
                .closingBalanceForeign(new BigDecimal("8000000"))
                .closingBalanceTotal(new BigDecimal("23000000"))
                .currencyLines(List.of(
                        MonthlyReportFullDto.CurrencyLineDto.builder()
                                .currencyCode("EUR")
                                .currencyName("Euro")
                                .openingStock(new BigDecimal("10000"))
                                .closingStock(new BigDecimal("12000"))
                                .totalBuyAmount(new BigDecimal("5000"))
                                .totalSellAmount(new BigDecimal("3000"))
                                .totalBuyHuf(new BigDecimal("1975000"))
                                .totalSellHuf(new BigDecimal("1200000"))
                                .avgBuyRate(new BigDecimal("395"))
                                .avgSellRate(new BigDecimal("400"))
                                .mnbRate(new BigDecimal("397.50"))
                                .build(),
                        MonthlyReportFullDto.CurrencyLineDto.builder()
                                .currencyCode("USD")
                                .currencyName("Dollar")
                                .openingStock(new BigDecimal("5000"))
                                .closingStock(new BigDecimal("6000"))
                                .totalBuyAmount(new BigDecimal("2000"))
                                .totalSellAmount(new BigDecimal("1000"))
                                .totalBuyHuf(new BigDecimal("720000"))
                                .totalSellHuf(new BigDecimal("365000"))
                                .avgBuyRate(new BigDecimal("360"))
                                .avgSellRate(new BigDecimal("365"))
                                .mnbRate(new BigDecimal("362.25"))
                                .build()
                ))
                .totalBuyHuf(new BigDecimal("2695000"))
                .totalSellHuf(new BigDecimal("1565000"))
                .transactionCount(150)
                .buyCount(70)
                .sellCount(65)
                .reversalCount(15)
                // WU/AFA
                .wuUsdOpening(new BigDecimal("5000"))
                .wuUsdIncome(new BigDecimal("3000"))
                .wuUsdExpense(new BigDecimal("1500"))
                .wuUsdBalance(new BigDecimal("6500"))
                .wuHufOpening(new BigDecimal("2000000"))
                .wuHufIncome(new BigDecimal("1200000"))
                .wuHufExpense(new BigDecimal("600000"))
                .wuHufBalance(new BigDecimal("2600000"))
                .afaOpening(new BigDecimal("150000"))
                .afaIncome(new BigDecimal("80000"))
                .afaExpense(new BigDecimal("30000"))
                .afaBalance(new BigDecimal("200000"))
                // Kezelesi dij
                .handlingFeeOpening(new BigDecimal("50000"))
                .handlingFeeIncome(new BigDecimal("120000"))
                .handlingFeeExpense(new BigDecimal("80000"))
                .handlingFeeBalance(new BigDecimal("90000"))
                // E-kereskedelem
                .ecommerceOpening(new BigDecimal("500000"))
                .ecommerceIncome(new BigDecimal("300000"))
                .ecommerceExpense(new BigDecimal("150000"))
                .ecommerceBalance(new BigDecimal("650000"))
                // Transfer lines (AtadAtvet)
                .transferLines(List.of(
                        MonthlyReportFullDto.TransferLineDto.builder()
                                .currencyCode("EUR")
                                .currencyName("Euro")
                                .receivedAmount(new BigDecimal("2000"))
                                .sentAmount(new BigDecimal("500"))
                                .netAmount(new BigDecimal("1500"))
                                .build()
                ))
                .workingDays(22)
                .closedDays(20)
                .build();

        byte[] pdf = service.renderPdf(report);

        assertThat(pdf).isNotNull();
        assertThat(pdf.length).isGreaterThan(500);
        assertThat(new String(pdf, 0, 5)).isEqualTo("%PDF-");

        try (PDDocument doc = Loader.loadPDF(pdf)) {
            assertThat(doc.getNumberOfPages()).isGreaterThanOrEqualTo(1);

            PDFTextStripper stripper = new PDFTextStripper();
            String text = stripper.getText(doc);

            // Fejlec
            assertThat(text).contains("EXCLUSIVE BEST CHANGE ZRT");
            assertThat(text).contains("101 Test Iroda");
            assertThat(text).contains("Pecs, Kiraly u. 10.");
            assertThat(text).contains("Adoszam: 32313332-2-02");

            // Idoszak
            assertThat(text).contains("2026-03 HAVI ZARAS OSSZESITO");
            assertThat(text).contains("Munkanapok: 22");
            assertThat(text).contains("Lezart napok: 20");

            // Penztar allas
            assertThat(text).contains("HAVI PENZTAR ALLAS");
            assertThat(text).contains("EUR");
            assertThat(text).contains("USD");

            // Transfer (AtadAtvet)
            assertThat(text).contains("PENZTARAK KOZOTTI MOZGASOK");
            assertThat(text).contains("ATVETT");
            assertThat(text).contains("ATADOTT");

            // Forgalom I + II + osszesites
            assertThat(text).contains("HAVI BANKJEGY-FORGALOM KIMUTATASA I.");
            assertThat(text).contains("HAVI BANKJEGY-FORGALOM KIMUTATASA II.");
            assertThat(text).contains("HAVI BANKJEGY-FORGALOM OSSZESITES");
            assertThat(text).contains("MNB ARF");

            // Forgalom osszesites
            assertThat(text).contains("HAVI FORGALOM OSSZESITES");
            assertThat(text).contains("Tranzakciok: 150");

            // WU/AFA — 12 sor (nyito/bevetel/kiadas/zaro x3)
            assertThat(text).contains("Western Union dollar forgalma:");
            assertThat(text).contains("Western Union forint forgalma:");
            assertThat(text).contains("Afa visszaigenyles forgalma:");
            // Nyito sorok ellenorzese
            int nyitoCount = countOccurrences(text, "Nyito:");
            assertThat(nyitoCount).isGreaterThanOrEqualTo(3);

            // Kezelesi dij 4 sor
            assertThat(text).contains("KEZELESI KOLTSEG HAVI OSSZESITES");
            assertThat(text).contains("HAVI NYITO OSSZEG");
            assertThat(text).contains("ATVETT OSSZEG");
            assertThat(text).contains("ATADOTT OSSZEG");
            assertThat(text).contains("HAVI ZARO OSSZEG");

            // E-kereskedelem 4 sor
            assertThat(text).contains("E-KERESKEDELMI MOZGASOK HAVI OSSZESITES");

            // Zaro osszesites
            assertThat(text).contains("HAVI ZARO KESZLET OSSZESITES");

            // Alairas
            assertThat(text).contains("Buntetojogi felelosegem");
            assertThat(text).contains("Ellenorzo szemely");
        }
    }

    @Test
    @DisplayName("Havi zaras PDF: ures report -> valid PDF")
    void generatePdf_emptyMonthlyReport() throws Exception {
        MonthlyReportFullDto report = MonthlyReportFullDto.builder()
                .yearMonth("2026-03")
                .branchId("11111111-1111-1111-1111-111111111111")
                .branchCode("102")
                .branchName("Ures Iroda")
                .currencyLines(List.of())
                .workingDays(0)
                .closedDays(0)
                .build();

        byte[] pdf = service.renderPdf(report);

        assertThat(pdf).isNotNull();
        assertThat(new String(pdf, 0, 5)).isEqualTo("%PDF-");
        try (PDDocument doc = Loader.loadPDF(pdf)) {
            assertThat(doc.getNumberOfPages()).isGreaterThanOrEqualTo(1);
            PDFTextStripper stripper = new PDFTextStripper();
            String text = stripper.getText(doc);
            assertThat(text).contains("EXCLUSIVE BEST CHANGE ZRT");
            assertThat(text).contains("2026-03 HAVI ZARAS OSSZESITO");
        }
    }

    private static int countOccurrences(String text, String sub) {
        int count = 0;
        int idx = 0;
        while ((idx = text.indexOf(sub, idx)) != -1) {
            count++;
            idx += sub.length();
        }
        return count;
    }
}
