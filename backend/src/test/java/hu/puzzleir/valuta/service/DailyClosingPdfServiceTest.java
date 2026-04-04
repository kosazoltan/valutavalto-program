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
    @DisplayName("PDF generálás: teljes napi záró report -> valid PDF, tartalom ellenőrzés")
    void generatePdf_fullReport() throws Exception {
        DailyReportFullDto report = DailyReportFullDto.builder()
                .reportDate("2026-04-04")
                .branchId("11111111-1111-1111-1111-111111111111")
                .branchCode("101")
                .branchName("Test Iroda")
                .closingBalanceHuf(new BigDecimal("5000000"))
                .closingBalanceForeign(new BigDecimal("2000000"))
                .closingBalanceTotal(new BigDecimal("7000000"))
                .currencyLines(List.of(
                        DailyReportFullDto.CurrencyLineDto.builder()
                                .currencyCode("EUR")
                                .currencyName("Euro")
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
                .wuUsdBalance(new BigDecimal("1250"))
                .wuHufBalance(new BigDecimal("500000"))
                .afaBalance(new BigDecimal("35000"))
                .discountLines(List.of(
                        DailyReportFullDto.DiscountLineDto.builder()
                                .currencyCode("EUR")
                                .amount(new BigDecimal("200"))
                                .discountRate(new BigDecimal("396"))
                                .receiptNumber("B-2026-001")
                                .build()
                ))
                .dailyHandlingFee(new BigDecimal("15000"))
                .ecommerceBalanceHuf(new BigDecimal("125000"))
                .morningCashierName("Kovacs Anna")
                .afternoonCashierName("Nagy Bela")
                .requestNotes(List.of())
                .sendNotes(List.of())
                .build();

        byte[] pdf = service.renderPdf(report);

        assertThat(pdf).isNotNull();
        assertThat(pdf.length).isGreaterThan(500);

        // PDF header check
        assertThat(new String(pdf, 0, 5)).isEqualTo("%PDF-");

        // Content extraction
        try (PDDocument doc = Loader.loadPDF(pdf)) {
            assertThat(doc.getNumberOfPages()).isGreaterThanOrEqualTo(1);

            PDFTextStripper stripper = new PDFTextStripper();
            String text = stripper.getText(doc);

            // Fejlec
            assertThat(text).contains("EXCLUSIVE BEST CHANGE ZRT");
            assertThat(text).contains("101 Test Iroda");
            assertThat(text).contains("2026-04-04 NAPI ZARAS");

            // Penztar allasa
            assertThat(text).contains("EUR");
            assertThat(text).contains("5,000");

            // DE/DU forgalom
            assertThat(text).contains("DE vetel");
            assertThat(text).contains("DU eladas");

            // Cimletek
            assertThat(text).contains("20000 Ft");
            assertThat(text).contains("Euro ermek");

            // WU/AFA
            assertThat(text).contains("Western Union");
            assertThat(text).contains("1,250");

            // Kezelesi dij
            assertThat(text).contains("KEZELESI DIJAS");
            assertThat(text).contains("15,000");

            // E-kereskedelem
            assertThat(text).contains("E-KERESKEDELMI");

            // Kedvezmenyek
            assertThat(text).contains("KEDVEZMENYES");
            assertThat(text).contains("B-2026-001");

            // Penztaros
            assertThat(text).contains("Kovacs Anna");
            assertThat(text).contains("Nagy Bela");

            // Nyilatkozat
            assertThat(text).contains("Buntetojogi felelosegem");
            assertThat(text).contains("penztaros");

            // Ellenor
            assertThat(text).contains("Ellenorzo szemely");
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
        }
    }
}
