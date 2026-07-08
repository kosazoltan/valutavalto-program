package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.compliance.ComplianceTransactionRowDto;
import hu.puzzleir.valuta.entity.TransactionType;
import org.apache.pdfbox.Loader;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.text.PDFTextStripper;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class ComplianceSearchAuditPdfServiceTest {

    private final ComplianceSearchAuditPdfService service = new ComplianceSearchAuditPdfService();

    @Test
    @DisplayName("PDF: fejléc tartalmazza a lekérdezőt, a dátumot, a címet és a darabszámot")
    void renderPdf_headerContainsMandatoryFields() throws Exception {
        byte[] pdf = service.renderPdf(new ComplianceSearchAuditService.ComplianceSearchAuditPdfData(
                "Gyanús PEP tranzakciók", "NAV-megkeresés miatti szűrés",
                "W-001", LocalDateTime.of(2026, 7, 8, 14, 30), 2, rows()));

        assertThat(new String(pdf, 0, 5)).isEqualTo("%PDF-");
        try (PDDocument doc = Loader.loadPDF(pdf)) {
            String text = new PDFTextStripper().getText(doc);
            assertThat(text).contains("W-001");
            assertThat(text).contains("2026-07-08 14:30");
            assertThat(text).contains("Gyanus PEP tranzakciok");
            assertThat(text).contains("Talalatok szama: 2");
            assertThat(text).contains("B-2026-001");
            assertThat(text).contains("B-2026-002");
            assertThat(text).contains("Komuves Odon");
        }
    }

    @Test
    @DisplayName("PDF: ékezetes cím Standard14 fonttal sem dob hibát")
    void renderPdf_accentedTitle_doesNotThrow() throws Exception {
        byte[] pdf = service.renderPdf(new ComplianceSearchAuditService.ComplianceSearchAuditPdfData(
                "Őrült űrlap-szűrés", null,
                "W-001", LocalDateTime.of(2026, 7, 8, 14, 30), 2, rows()));

        try (PDDocument doc = Loader.loadPDF(pdf)) {
            String text = new PDFTextStripper().getText(doc);
            assertThat(text).contains("Orult urlap-szures");
        }
    }

    @Test
    @DisplayName("PDF: sok snapshot-sor automatikusan több oldalra törik")
    void renderPdf_manyRows_paginates() throws Exception {
        byte[] pdf = service.renderPdf(new ComplianceSearchAuditService.ComplianceSearchAuditPdfData(
                "Sok sor", "Lapozási próba",
                "W-001", LocalDateTime.of(2026, 7, 8, 14, 30), 120, generatedRows(120)));

        try (PDDocument doc = Loader.loadPDF(pdf)) {
            assertThat(doc.getNumberOfPages()).isGreaterThanOrEqualTo(2);
        }
    }

    private static List<ComplianceTransactionRowDto> rows() {
        return List.of(
                ComplianceTransactionRowDto.builder()
                        .receiptNumber("B-2026-001")
                        .transactionDate(LocalDate.of(2026, 6, 1))
                        .transactionType(TransactionType.BUY)
                        .currencyCode("EUR")
                        .currencyAmount(new BigDecimal("1000"))
                        .hufAmount(new BigDecimal("390000"))
                        .customerName("Kőműves Ödön")
                        .build(),
                ComplianceTransactionRowDto.builder()
                        .receiptNumber("B-2026-002")
                        .transactionDate(LocalDate.of(2026, 6, 1))
                        .transactionType(TransactionType.SELL)
                        .currencyCode("EUR")
                        .currencyAmount(new BigDecimal("500"))
                        .hufAmount(new BigDecimal("195000"))
                        .customerName("Árvíztűrő Tükörfúrógép")
                        .build());
    }

    private static List<ComplianceTransactionRowDto> generatedRows(int count) {
        List<ComplianceTransactionRowDto> rows = new ArrayList<>();
        for (int i = 1; i <= count; i++) {
            rows.add(ComplianceTransactionRowDto.builder()
                    .receiptNumber(String.format("B-2026-%03d", i))
                    .transactionDate(LocalDate.of(2026, 6, 1))
                    .transactionType(TransactionType.BUY)
                    .currencyCode("EUR")
                    .currencyAmount(new BigDecimal("10"))
                    .hufAmount(new BigDecimal("3900"))
                    .customerName("Teszt Ügyfél")
                    .build());
        }
        return rows;
    }
}
