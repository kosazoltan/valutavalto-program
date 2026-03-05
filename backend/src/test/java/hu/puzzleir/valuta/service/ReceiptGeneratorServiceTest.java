package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.receipt.ReceiptData;
import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.entity.TransactionType;
import hu.puzzleir.valuta.repository.TransactionRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;

import static org.assertj.core.api.Assertions.*;

/**
 * ReceiptGeneratorService UNIT tesztek — Mockito.
 */
@ExtendWith(MockitoExtension.class)
class ReceiptGeneratorServiceTest {

    @InjectMocks
    private ReceiptGeneratorService service;

    @Mock
    private TransactionRepository transactionRepository;

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
    @DisplayName("formatForPdf → nem üres byte tömb, tartalmazza az adatokat")
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
        String content = new String(result);
        assertThat(content).contains("V-260306-0002");
        assertThat(content).contains("Vevő Béla");
        assertThat(content).contains("USD");
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
}
