package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.receipt.ReceiptData;
import hu.puzzleir.valuta.entity.WuTransaction;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

import static org.assertj.core.api.Assertions.*;

/**
 * ReceiptPdfService UNIT tesztek — valódi PDFBox renderelés, nincs mock.
 */
class ReceiptPdfServiceTest {

    private ReceiptPdfService service;

    @BeforeEach
    void setUp() {
        service = new ReceiptPdfService();
    }

    private ReceiptData buildFullReceipt() {
        return ReceiptData.builder()
                .receiptNumber("E-260316-0001")
                .receiptType("SELL")
                .companyName("Teszt Valuta Kft.")
                .branchName("Keleti iroda")
                .workerName("Nagy Peter")
                .date(LocalDateTime.of(2026, 3, 16, 10, 30))
                .currencyCode("EUR")
                .foreignAmount(new BigDecimal("500.00"))
                .rate(new BigDecimal("395.50"))
                .hufAmount(new BigDecimal("197750"))
                .handlingFee(new BigDecimal("500"))
                .customerName("Kovacs Bela")
                .customerIdNumber("123456AB")
                .lines(List.of(
                        ReceiptData.ReceiptLineData.builder().label("Megjegyzes").value("Teszt sor").build()
                ))
                .qrCode("E-260316-0001")
                .build();
    }

    @Test
    @DisplayName("generatePdf → valódi PDF, %PDF magic bytes-szal kezdodik")
    void testGeneratePdfStartsWithMagicBytes() {
        ReceiptData data = buildFullReceipt();

        byte[] pdf = service.generatePdf(data);

        assertThat(pdf).isNotNull();
        assertThat(pdf.length).isGreaterThan(100);
        // PDF magic bytes: %PDF
        assertThat(new String(pdf, 0, 4)).isEqualTo("%PDF");
    }

    @Test
    @DisplayName("generatePdfCopy → valódi PDF, MASOLAT vizjellel nagyobb mint az eredeti")
    void testGeneratePdfCopyIsLargerDueToWatermark() {
        ReceiptData data = buildFullReceipt();

        byte[] original = service.generatePdf(data);
        byte[] copy = service.generatePdfCopy(data);

        assertThat(copy).isNotNull();
        assertThat(new String(copy, 0, 4)).isEqualTo("%PDF");
        // A másolat tartalmaz extra "MASOLAT" szöveget → várhatóan nagyobb
        assertThat(copy.length).isGreaterThan(original.length);
    }

    @Test
    @DisplayName("generatePdf WU bizonylat MTCN-nel → valid PDF")
    void testGeneratePdfForWuReceiptWithMtcn() {
        ReceiptData data = ReceiptData.builder()
                .receiptNumber("W-260316-0010")
                .receiptType("WU_SEND")
                .companyName("Teszt Kft.")
                .branchName("Fo iroda")
                .workerName("Penztar Peter")
                .date(LocalDateTime.of(2026, 3, 16, 14, 0))
                .currencyCode("USD")
                .foreignAmount(new BigDecimal("1000.00"))
                .rate(new BigDecimal("360.00"))
                .hufAmount(new BigDecimal("360000"))
                .lines(List.of(
                        ReceiptData.ReceiptLineData.builder().label("MTCN").value("1234567890").build(),
                        ReceiptData.ReceiptLineData.builder().label("Tipus").value("SEND").build(),
                        ReceiptData.ReceiptLineData.builder().label("Kuldo").value("Nagy Jozsef").build()
                ))
                .qrCode("W-260316-0010")
                .build();

        byte[] pdf = service.generatePdf(data);

        assertThat(pdf).isNotNull();
        assertThat(new String(pdf, 0, 4)).isEqualTo("%PDF");
    }

    @Test
    @DisplayName("generatePdf zaras bizonylat → valid PDF")
    void testGeneratePdfForClosingReceipt() {
        ReceiptData data = ReceiptData.builder()
                .receiptNumber("Z-260316-0001")
                .receiptType("CLOSING")
                .companyName("Teszt Kft.")
                .branchName("Kozponti iroda")
                .workerName("Penztar Piroska")
                .date(LocalDateTime.of(2026, 3, 16, 18, 0))
                .hufAmount(new BigDecimal("5000000"))
                .lines(List.of(
                        ReceiptData.ReceiptLineData.builder().label("Zaras datuma").value("2026-03-16").build(),
                        ReceiptData.ReceiptLineData.builder().label("Tranzakciok szama").value("42").build(),
                        ReceiptData.ReceiptLineData.builder().label("Napi forgalom (HUF)").value("5000000").build()
                ))
                .qrCode("Z-260316-0001")
                .build();

        byte[] pdf = service.generatePdf(data);

        assertThat(pdf).isNotNull();
        assertThat(new String(pdf, 0, 4)).isEqualTo("%PDF");
    }

    @Test
    @DisplayName("generatePdf null mezokkel → nincs NPE, valid PDF jon letre")
    void testGeneratePdfHandlesNullFields() {
        // Minimalis ReceiptData — csak a kotelezo mezok
        ReceiptData data = ReceiptData.builder()
                .receiptNumber("E-260316-0099")
                .receiptType("SELL")
                .date(LocalDateTime.now())
                .build();

        // Nem dob NPE-t
        assertThatCode(() -> service.generatePdf(data)).doesNotThrowAnyException();

        byte[] pdf = service.generatePdf(data);
        assertThat(pdf).isNotNull();
        assertThat(new String(pdf, 0, 4)).isEqualTo("%PDF");
    }
}
