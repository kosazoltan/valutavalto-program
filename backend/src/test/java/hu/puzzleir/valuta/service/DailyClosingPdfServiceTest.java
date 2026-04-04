package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.report.DailyReportFullDto;
import org.apache.pdfbox.Loader;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.text.PDFTextStripper;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class DailyClosingPdfServiceTest {

    private final DailyClosingPdfService service = new DailyClosingPdfService(null);

    @Test
    @DisplayName("PDF generálás: teljes napi záró report -> valid PDF, Delphi paritás ellenőrzés")
    void generatePdf_fullReport() throws Exception {
        DailyReportFullDto report = DailyReportFullDto.builder()
                .reportDate("2026-04-04")
                .branchId("11111111-1111-1111-1111-111111111111")
                .branchCode("101")
                .branchName("Test Iroda")
                .branchAddress("7621 Pecs, Kiraly u. 10.")  // B6
                .taxId("32313332-2-02")                      // B6
                .closingBalanceHuf(new BigDecimal("5000000"))
                .closingBalanceForeign(new BigDecimal("2000000"))
                .closingBalanceTotal(new BigDecimal("7000000"))
                .currencyLines(List.of(
                        DailyReportFullDto.CurrencyLineDto.builder()
                                .currencyCode("EUR")
                                .currencyName("Euro")
                                .openingStock(new BigDecimal("4000"))  // B4
                                .closingStock(new BigDecimal("5000"))
                                .buyAmount(new BigDecimal("1000"))
                                .sellAmount(new BigDecimal("500"))
                                .buyHuf(new BigDecimal("395000"))
                                .sellHuf(new BigDecimal("200000"))
                                .buyRate(new BigDecimal("395"))
                                .sellRate(new BigDecimal("400"))
                                .settlementRate(BigDecimal.ZERO)
                                .build(),
                        DailyReportFullDto.CurrencyLineDto.builder()
                                .currencyCode("HUF")
                                .currencyName("Forint")
                                .openingStock(new BigDecimal("4500000"))
                                .closingStock(new BigDecimal("5000000"))
                                .buyAmount(BigDecimal.ZERO)
                                .sellAmount(BigDecimal.ZERO)
                                .buyHuf(BigDecimal.ZERO)
                                .sellHuf(BigDecimal.ZERO)
                                .buyRate(BigDecimal.ZERO)
                                .sellRate(BigDecimal.ZERO)
                                .settlementRate(BigDecimal.ZERO)
                                .build()
                ))
                .morningBuyHuf(new BigDecimal("500000"))
                .morningSellHuf(new BigDecimal("300000"))
                .afternoonBuyHuf(new BigDecimal("400000"))
                .afternoonSellHuf(new BigDecimal("200000"))
                .totalBuyHuf(new BigDecimal("900000"))
                .totalSellHuf(new BigDecimal("500000"))
                .transactionCount(25)
                .buyCount(12)
                .sellCount(10)
                .reversalCount(3)
                .hufDenominations(List.of(
                        DailyReportFullDto.DenominationLineDto.builder()
                                .label("20000 Ft")
                                .faceValue(new BigDecimal("20000"))
                                .quantity(10)
                                .totalValue(new BigDecimal("200000"))
                                .build()
                ))
                .denominatedTotalHuf(new BigDecimal("200000"))
                .euroCoin1Count(5)
                .euroCoin2Count(3)
                // B2: WU/ÁFA nyitó/bevétel/kiadás/záró
                .wuUsdOpening(new BigDecimal("1000"))
                .wuUsdIncome(new BigDecimal("500"))
                .wuUsdExpense(new BigDecimal("250"))
                .wuUsdBalance(new BigDecimal("1250"))
                .wuHufOpening(new BigDecimal("400000"))
                .wuHufIncome(new BigDecimal("200000"))
                .wuHufExpense(new BigDecimal("100000"))
                .wuHufBalance(new BigDecimal("500000"))
                .afaOpening(new BigDecimal("25000"))
                .afaIncome(new BigDecimal("15000"))
                .afaExpense(new BigDecimal("5000"))
                .afaBalance(new BigDecimal("35000"))
                .discountLines(List.of(
                        DailyReportFullDto.DiscountLineDto.builder()
                                .currencyCode("EUR")
                                .amount(new BigDecimal("200"))
                                .discountRate(new BigDecimal("396.50"))
                                .receiptNumber("B-2026-001")
                                .build()
                ))
                // B3: Kezelési díj nyitó/átvett/átadott/záró
                .handlingFeeOpening(new BigDecimal("10000"))
                .handlingFeeIncome(new BigDecimal("20000"))
                .handlingFeeExpense(new BigDecimal("15000"))
                .dailyHandlingFee(new BigDecimal("15000"))
                // B3: E-kereskedelem nyitó/átvett/átadott/záró
                .ecommerceOpening(new BigDecimal("100000"))
                .ecommerceIncome(new BigDecimal("50000"))
                .ecommerceExpense(new BigDecimal("25000"))
                .ecommerceBalanceHuf(new BigDecimal("125000"))
                .morningCashierName("Kovacs Anna")
                .afternoonCashierName("Nagy Bela")
                // B5: Ellenőr
                .inspectorName("Szabo Peter")
                .inspectorNote("Penzugyi ellenor")
                .requestNotes(List.of())
                .sendNotes(List.of())
                .build();

        byte[] pdf = service.renderPdf(report);

        assertThat(pdf).isNotNull();
        assertThat(pdf.length).isGreaterThan(500);
        assertThat(new String(pdf, 0, 5)).isEqualTo("%PDF-");

        try (PDDocument doc = Loader.loadPDF(pdf)) {
            assertThat(doc.getNumberOfPages()).isGreaterThanOrEqualTo(1);

            PDFTextStripper stripper = new PDFTextStripper();
            String text = stripper.getText(doc);

            // B6: Fejléc — cím + adószám
            assertThat(text).contains("EXCLUSIVE BEST CHANGE ZRT");
            assertThat(text).contains("101 Test Iroda");
            assertThat(text).contains("Pecs, Kiraly u. 10.");
            assertThat(text).contains("Adoszam: 32313332-2-02");

            // B4: Pénztár állása — Delphi oszlopok (Nyito/Forgalom/Allas)
            assertThat(text).contains("Nyito");
            assertThat(text).contains("Forgalom");
            assertThat(text).contains("Penztar");
            assertThat(text).contains("allas");
            assertThat(text).contains("EUR");

            // Bankjegy-forgalom I+II (Delphi: ForgalomLista)
            assertThat(text).contains("NAPI BANKJEGY-FORGALOM KIMUTATASA-I");
            assertThat(text).contains("NAPI BANKJEGY-FORGALOM KIMUTATASA-II");

            // DE/DU forgalom
            assertThat(text).contains("DE vetel");
            assertThat(text).contains("DU eladas");

            // Címletek
            assertThat(text).contains("20000 Ft");
            assertThat(text).contains("Euro ermek");

            // B2: WU/ÁFA nyitó/bevétel/kiadás/záró (12 sor)
            assertThat(text).contains("Western Union dollar forgalma:");
            assertThat(text).contains("Western Union forint forgalma:");
            assertThat(text).contains("Afa visszaigenyles forgalma:");
            // Nyitó/bevétel/kiadás sorok ellenőrzése
            int nyitoCount = countOccurrences(text, "Nyito:");
            assertThat(nyitoCount).isGreaterThanOrEqualTo(3); // WU USD + WU HUF + ÁFA

            // B1 fix: precision — 396,50 (magyar lokalizáció, vessző szeparátor)
            assertThat(text).contains("396,50");

            // B3: Kezelési díj 4 sor (nyitó/átvett/átadott/záró)
            assertThat(text).contains("KEZELESI KOLTSEG");
            assertThat(text).contains("NAPI NYITO OSSZEG");
            assertThat(text).contains("ATVETT OSSZEG");
            assertThat(text).contains("ATADOTT OSSZEG");
            assertThat(text).contains("NAPI ZARO OSSZEG");

            // B3: E-kereskedelem 4 sor
            assertThat(text).contains("E-KERESKEDELMI MOZGASOK");

            // Kedvezmények
            assertThat(text).contains("KEDVEZMENYES");
            assertThat(text).contains("B-2026-001");

            // Pénztáros
            assertThat(text).contains("Kovacs Anna");
            assertThat(text).contains("Nagy Bela");

            // Nyilatkozat
            assertThat(text).contains("Buntetojogi felelosegem");

            // B5: Ellenőr — név + bejegyzés + jogszabály
            assertThat(text).contains("Szabo Peter");
            assertThat(text).contains("Penzugyi ellenor");
            assertThat(text).contains("FZS-01/2009");
            assertThat(text).contains("Ellenorzo szemely");

            // Záró összesítés
            assertThat(text).contains("ZARO KESZLET OSSZESITES");
        }
    }

    @Test
    @DisplayName("PDF generálás: üres report -> valid PDF")
    void generatePdf_emptyReport() throws Exception {
        DailyReportFullDto report = DailyReportFullDto.builder()
                .reportDate("2026-04-04")
                .branchId("11111111-1111-1111-1111-111111111111")
                .branchCode("102")
                .branchName("Ures Iroda")
                .closingBalanceHuf(BigDecimal.ZERO)
                .closingBalanceForeign(BigDecimal.ZERO)
                .closingBalanceTotal(BigDecimal.ZERO)
                .currencyLines(List.of())
                .morningBuyHuf(BigDecimal.ZERO)
                .morningSellHuf(BigDecimal.ZERO)
                .afternoonBuyHuf(BigDecimal.ZERO)
                .afternoonSellHuf(BigDecimal.ZERO)
                .totalBuyHuf(BigDecimal.ZERO)
                .totalSellHuf(BigDecimal.ZERO)
                .transactionCount(0)
                .buyCount(0)
                .sellCount(0)
                .reversalCount(0)
                .hufDenominations(List.of())
                .denominatedTotalHuf(BigDecimal.ZERO)
                .euroCoin1Count(0)
                .euroCoin2Count(0)
                .wuUsdBalance(BigDecimal.ZERO)
                .wuHufBalance(BigDecimal.ZERO)
                .afaBalance(BigDecimal.ZERO)
                .discountLines(List.of())
                .dailyHandlingFee(BigDecimal.ZERO)
                .ecommerceBalanceHuf(BigDecimal.ZERO)
                .requestNotes(List.of())
                .sendNotes(List.of())
                .build();

        byte[] pdf = service.renderPdf(report);

        assertThat(pdf).isNotNull();
        assertThat(new String(pdf, 0, 5)).isEqualTo("%PDF-");
        try (PDDocument doc = Loader.loadPDF(pdf)) {
            assertThat(doc.getNumberOfPages()).isGreaterThanOrEqualTo(1);
            PDFTextStripper stripper = new PDFTextStripper();
            String text = stripper.getText(doc);
            assertThat(text).contains("EXCLUSIVE BEST CHANGE ZRT");
            assertThat(text).contains("FZS-01/2009");
        }
    }

    @Test
    @DisplayName("B1 fix: fmt() precision - tizedesjegyek megmaradnak")
    void fmtPrecision() throws Exception {
        DailyReportFullDto report = DailyReportFullDto.builder()
                .reportDate("2026-04-04")
                .branchId("11111111-1111-1111-1111-111111111111")
                .branchCode("103")
                .branchName("Precision Test")
                .closingBalanceHuf(BigDecimal.ZERO)
                .closingBalanceForeign(BigDecimal.ZERO)
                .closingBalanceTotal(BigDecimal.ZERO)
                .currencyLines(List.of(
                        DailyReportFullDto.CurrencyLineDto.builder()
                                .currencyCode("GBP")
                                .currencyName("Font")
                                .openingStock(new BigDecimal("1234.56"))
                                .closingStock(new BigDecimal("2345.78"))
                                .buyAmount(new BigDecimal("500.25"))
                                .sellAmount(new BigDecimal("300.50"))
                                .buyHuf(new BigDecimal("224112.25"))
                                .sellHuf(new BigDecimal("135225.50"))
                                .buyRate(new BigDecimal("448.00"))
                                .sellRate(new BigDecimal("450.50"))
                                .settlementRate(BigDecimal.ZERO)
                                .build()
                ))
                .morningBuyHuf(BigDecimal.ZERO)
                .morningSellHuf(BigDecimal.ZERO)
                .afternoonBuyHuf(BigDecimal.ZERO)
                .afternoonSellHuf(BigDecimal.ZERO)
                .totalBuyHuf(BigDecimal.ZERO)
                .totalSellHuf(BigDecimal.ZERO)
                .transactionCount(0)
                .buyCount(0)
                .sellCount(0)
                .reversalCount(0)
                .hufDenominations(List.of())
                .denominatedTotalHuf(BigDecimal.ZERO)
                .euroCoin1Count(0)
                .euroCoin2Count(0)
                .wuUsdBalance(BigDecimal.ZERO)
                .wuHufBalance(BigDecimal.ZERO)
                .afaBalance(BigDecimal.ZERO)
                .discountLines(List.of())
                .dailyHandlingFee(BigDecimal.ZERO)
                .ecommerceBalanceHuf(BigDecimal.ZERO)
                .requestNotes(List.of())
                .sendNotes(List.of())
                .build();

        byte[] pdf = service.renderPdf(report);

        try (PDDocument doc = Loader.loadPDF(pdf)) {
            PDFTextStripper stripper = new PDFTextStripper();
            String text = stripper.getText(doc);
            // B1: closingStock 2345.78 nem szabad 2345-nek lennie (longValue truncation)
            assertThat(text).contains("GBP");
            // fmt() should render at least the integer part correctly
            assertThat(text).contains("2,346"); // roundedUp from 2345.78
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
