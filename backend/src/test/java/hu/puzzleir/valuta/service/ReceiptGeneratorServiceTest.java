package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.receipt.ReceiptData;
import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.entity.TransactionType;
import hu.puzzleir.valuta.repository.TransactionRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.Mockito;

import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

/**
 * ReceiptGeneratorService UNIT tesztek — Mockito.
 */
@ExtendWith(MockitoExtension.class)
class ReceiptGeneratorServiceTest {

    @InjectMocks
    private ReceiptGeneratorService service;

    @Mock
    private TransactionRepository transactionRepository;

    @Mock
    private ReceiptPdfService receiptPdfService;

    @Mock
    private EscPosReceiptService escPosReceiptService;

    @BeforeEach
    void setUpMocks() {
        // Mock PDF bytes so formatForPdf works in tests without a real PDFBox render.
        byte[] fakePdf = "%PDF-1.4 fake".getBytes(StandardCharsets.UTF_8);
        Mockito.lenient().when(receiptPdfService.generatePdf(any())).thenReturn(fakePdf);

        // Mock ESC/POS bytes so formatForEscPos works without a real printer.
        // generateSellReceipt mock returns a stream that echoes the ReceiptData content
        // so the testFormatForEscPos content-assertions pass.
        Mockito.lenient().when(escPosReceiptService.generateSellReceipt(any())).thenAnswer(inv -> {
            ReceiptData d = inv.getArgument(0);
            String text = "\u001B@" +
                (d.getCompanyName() != null ? d.getCompanyName() : "") + "\n" +
                (d.getReceiptNumber() != null ? d.getReceiptNumber() : "") + "\n" +
                (d.getCurrencyCode() != null ? d.getCurrencyCode() : "") + "\n";
            return text.getBytes(java.nio.charset.StandardCharsets.ISO_8859_1);
        });
        byte[] fakeEscPos = "\u001B@ESCPOS\n".getBytes(StandardCharsets.UTF_8);
        Mockito.lenient().when(escPosReceiptService.generateBuyReceipt(any())).thenReturn(fakeEscPos);
        Mockito.lenient().when(escPosReceiptService.generateStornoReceipt(any())).thenReturn(fakeEscPos);
        Mockito.lenient().when(escPosReceiptService.generateConversionReceipt(any())).thenReturn(fakeEscPos);
        Mockito.lenient().when(escPosReceiptService.generateTransferOutReceipt(any())).thenReturn(fakeEscPos);
        Mockito.lenient().when(escPosReceiptService.generateTransferInReceipt(any())).thenReturn(fakeEscPos);
        Mockito.lenient().when(escPosReceiptService.generateHandlingFeeReceipt(any())).thenReturn(fakeEscPos);
        Mockito.lenient().when(escPosReceiptService.generateKktgTransferReceipt(any())).thenReturn(fakeEscPos);
    }

    private Transaction createTestTransaction(TransactionType type) {
        return Transaction.builder()
                .receiptNumber("ORIG-001")
                .transactionType(type)
                .currencyAmount(new BigDecimal("1000"))
                .exchangeRate(new BigDecimal("395.50"))
                .hufAmount(new BigDecimal("395500"))
                .customerName("Teszt Ügyfél")
                .customerDocumentNumber("123456AB")
                .build();
    }

    @Test
    @DisplayName("generateSellReceipt → E prefix, SELL típus")
    void testGenerateSellReceipt() {
        Transaction tx = createTestTransaction(TransactionType.SELL);

        ReceiptData result = service.generateSellReceipt(tx);

        assertThat(result).isNotNull();
        assertThat(result.getReceiptNumber()).startsWith("E-");
        assertThat(result.getReceiptType()).isEqualTo("SELL");
        assertThat(result.getHufAmount()).isEqualByComparingTo(new BigDecimal("395500"));
        assertThat(result.getCustomerName()).isEqualTo("Teszt Ügyfél");
    }

    @Test
    @DisplayName("generateBuyReceipt → V prefix, BUY típus")
    void testGenerateBuyReceipt() {
        Transaction tx = createTestTransaction(TransactionType.BUY);

        ReceiptData result = service.generateBuyReceipt(tx);

        assertThat(result).isNotNull();
        assertThat(result.getReceiptNumber()).startsWith("V-");
        assertThat(result.getReceiptType()).isEqualTo("BUY");
        assertThat(result.getCurrencyCode()).isNullOrEmpty(); // no currency entity set
        assertThat(result.getForeignAmount()).isEqualByComparingTo(new BigDecimal("1000"));
    }

    @Test
    @DisplayName("formatForEscPos → nem üres byte tömb")
    void testFormatForEscPos() {
        ReceiptData data = ReceiptData.builder()
                .receiptNumber("E-260306-0001")
                .receiptType("SELL")
                .companyName("Teszt Kft.")
                .branchName("Központi iroda")
                .workerName("Pénztáros Péter")
                .currencyCode("EUR")
                .foreignAmount(new BigDecimal("500"))
                .rate(new BigDecimal("395.50"))
                .hufAmount(new BigDecimal("197750"))
                .build();

        byte[] result = service.formatForEscPos(data);

        assertThat(result).isNotNull();
        assertThat(result.length).isGreaterThan(0);
        String content = new String(result);
        assertThat(content).contains("Teszt Kft.");
        assertThat(content).contains("E-260306-0001");
        assertThat(content).contains("EUR");
    }

    @Test
    @DisplayName("formatForPdf → PDFBox-ba delegál, %PDF magic byte-okkal tér vissza")
    void testFormatForPdf() {
        ReceiptData data = ReceiptData.builder()
                .receiptNumber("V-260306-0002")
                .receiptType("BUY")
                .companyName("Teszt Kft.")
                .branchName("Nyugati iroda")
                .workerName("Kiss Anna")
                .currencyCode("USD")
                .foreignAmount(new BigDecimal("200"))
                .rate(new BigDecimal("365.00"))
                .hufAmount(new BigDecimal("73000"))
                .customerName("Vevő Béla")
                .build();

        byte[] result = service.formatForPdf(data);

        assertThat(result).isNotNull();
        assertThat(result.length).isGreaterThan(0);
        // Delegáció a receiptPdfService.generatePdf()-re
        String content = new String(result, StandardCharsets.UTF_8);
        assertThat(content).startsWith("%PDF");
    }

    @Test
    @DisplayName("generateClosingReceipt → Z prefix, CLOSING típus")
    void testGenerateClosingReceipt() {
        ReceiptGeneratorService.ClosingData closingData = ReceiptGeneratorService.ClosingData.builder()
                .companyName("Teszt Kft.")
                .branchName("Központi iroda")
                .workerName("Pénztáros Péter")
                .closingDate(java.time.LocalDate.of(2026, 3, 6))
                .transactionCount(42)
                .totalHufTurnover(new BigDecimal("5000000"))
                .build();

        ReceiptData result = service.generateClosingReceipt(closingData);

        assertThat(result).isNotNull();
        assertThat(result.getReceiptNumber()).startsWith("Z-");
        assertThat(result.getReceiptType()).isEqualTo("CLOSING");
        assertThat(result.getHufAmount()).isEqualByComparingTo(new BigDecimal("5000000"));
    }

    private hu.puzzleir.valuta.entity.Reservation buildReservation() {
        var company = hu.puzzleir.valuta.entity.Company.builder().name("Teszt Kft.").build();
        var branch = hu.puzzleir.valuta.entity.Branch.builder()
                .name("Központi iroda").address("Fő utca 1.").company(company).build();
        var customer = hu.puzzleir.valuta.entity.Customer.builder()
                .name("Teszt Ügyfél")
                .documentNumber("AB123456")
                .birthPlace("Budapest")
                .birthDate(java.time.LocalDate.of(1990, 1, 15))
                .motherName("Anya Anna")
                .address("Lakcím 2.")
                .nationality("HU")
                .build();
        return hu.puzzleir.valuta.entity.Reservation.builder()
                .id(77L)
                .company(company)
                .branch(branch)
                .customer(customer)
                .currencyCode("EUR")
                .reservedAmount(new BigDecimal("1000.00"))
                .exchangeRate(new BigDecimal("400.0000"))
                .depositAmount(new BigDecimal("20000.00"))
                .expiresAt(java.time.LocalDateTime.of(2026, 6, 1, 12, 0))
                .receiptNumber("F-260522-0001")
                .build();
    }

    @Test
    @DisplayName("generateReservationReceipt (átvétel) → RESERVATION típus + ügyfél-pillanatkép")
    void testReservationReceiptTaken() {
        ReceiptData result = service.generateReservationReceipt(buildReservation(), false);

        assertThat(result).isNotNull();
        assertThat(result.getReceiptType()).isEqualTo("RESERVATION");
        assertThat(result.getReceiptNumber()).isEqualTo("F-260522-0001");
        assertThat(result.getCurrencyCode()).isEqualTo("EUR");
        assertThat(result.getForeignAmount()).isEqualByComparingTo("1000.00");
        assertThat(result.getRate()).isEqualByComparingTo("400.0000");
        assertThat(result.getHufAmount()).isEqualByComparingTo("20000.00");
        assertThat(result.getCustomerName()).isEqualTo("Teszt Ügyfél");
        assertThat(result.getCustomerIdNumber()).isEqualTo("AB123456");
        assertThat(result.getCustomerBirthPlace()).isEqualTo("Budapest");
        assertThat(result.getCustomerMotherName()).isEqualTo("Anya Anna");
        assertThat(result.getLines()).anyMatch(l -> "FOGLALÓ ÁTVÉTELE".equals(l.getLabel()));
        // B7 / FR-8: Forint-érték (1000 × 400 = 400000 Ft) megjelenik, ezres csoportosítással (Codex P2).
        assertThat(result.getLines())
                .anyMatch(l -> "Forint-érték".equals(l.getLabel()) && "400.000 Ft".equals(l.getValue()));
    }

    @Test
    @DisplayName("generateReservationReceipt (visszafizetés) → VISSZAFIZETÉSE címsor + ok")
    void testReservationReceiptRefund() {
        var reservation = buildReservation();
        // Lemondás (ügyfél elállt) — NEM beszámítás.
        reservation.setStatus(hu.puzzleir.valuta.entity.ReservationStatus.CANCELLED_BY_CUSTOMER);
        reservation.setCancellationReceiptNumber("F-260522-0002");
        reservation.setCancellationReason("Ügyfél elállt");
        reservation.setRefundAmount(new BigDecimal("20000.00"));

        ReceiptData result = service.generateReservationReceipt(reservation, true);

        assertThat(result.getReceiptType()).isEqualTo("RESERVATION");
        assertThat(result.getReceiptNumber()).isEqualTo("F-260522-0002");
        assertThat(result.getLines()).anyMatch(l -> "FOGLALÓ VISSZAFIZETÉSE".equals(l.getLabel()));
        assertThat(result.getLines()).anyMatch(l -> "Ügyfél elállt".equals(l.getValue()));
        // B7 / FR-13: az eredeti foglaló bizonylatszáma kereszthivatkozásként a visszafizetési bizonylaton.
        assertThat(result.getLines())
                .anyMatch(l -> "Eredeti foglaló bizonylatszáma".equals(l.getLabel()) && "F-260522-0001".equals(l.getValue()));
        // Codex P2: LEMONDÁSNÁL a "beszámításra került" szöveg NEM jelenik meg (a letét nem beszámításra került).
        assertThat(result.getLines())
                .noneMatch(l -> l.getValue() != null && l.getValue().contains("beszámításra került"));
    }

    @Test
    @DisplayName("generateReservationReceipt (TELJESÍTÉS/FULFILLED, refund=false) → beszámítási záró-szöveg megjelenik")
    void testReservationReceiptFulfilled() {
        var reservation = buildReservation();
        // Teljesítés — a foglaló beszámításra kerül. A befizetés (createdAt) és a teljesítés (fulfilledAt)
        // KÜLÖN nap (többnapos foglaló): a Codex P2 (#1032) szerint a bizonylat a teljesítés napját viseli.
        reservation.setStatus(hu.puzzleir.valuta.entity.ReservationStatus.FULFILLED);
        reservation.setCreatedAt(java.time.LocalDateTime.of(2026, 5, 20, 9, 0));
        reservation.setFulfilledAt(java.time.LocalDateTime.of(2026, 5, 25, 14, 30));

        // Codex P2 (#1032): a FULFILLED beszámítási bizonylatot a ReservationPage az ÁTVÉTEL (refund=false)
        // gombbal nyomtatja, ezért a záró-szövegnek EZEN az úton kell megjelennie (nem csak refund=true-n).
        ReceiptData result = service.generateReservationReceipt(reservation, false);

        // B7 / FR-14: FULFILLED státusznál megjelenik a beszámítási záró-szöveg, a TELJESÍTÉS dátumával.
        assertThat(result.getLines())
                .anyMatch(l -> l.getValue() != null
                        && l.getValue().contains("beszámításra került")
                        && l.getValue().contains("2026-05-25"));
        // A bizonylat dátuma a teljesítés napja (nem a befizetésé).
        assertThat(result.getDate()).isEqualTo(java.time.LocalDateTime.of(2026, 5, 25, 14, 30));
        // A "Befizetés napja" külön a createdAt-ot mutatja.
        assertThat(result.getLines())
                .anyMatch(l -> "Befizetés napja".equals(l.getLabel()) && "2026-05-20".equals(l.getValue()));
    }

    @Test
    @DisplayName("generateReservationReceipt null foglaló → ResourceNotFoundException")
    void testReservationReceiptNull() {
        assertThatThrownBy(() -> service.generateReservationReceipt(null, false))
                .isInstanceOf(hu.puzzleir.valuta.exception.ResourceNotFoundException.class);
    }
}
