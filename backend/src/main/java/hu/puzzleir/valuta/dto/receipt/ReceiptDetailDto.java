package hu.puzzleir.valuta.dto.receipt;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ReceiptDetailDto {
    private Long id;
    private String receiptNumber;
    private LocalDate transactionDate;
    private LocalTime transactionTime;
    private String transactionType;
    private String transactionTypeDisplay;
    private String status;
    // Valuta adatok
    private String currencyCode;
    private BigDecimal currencyAmount;
    private BigDecimal hufAmount;
    private BigDecimal exchangeRate;
    private BigDecimal handlingFee;
    // Ügyfél
    private String customerName;
    private String customerAddress;
    private String customerDocumentNumber;
    // Pénztáros
    private String cashierName;
    private String branchCode;
    // Tételsorok
    private List<ReceiptLineDto> lines;
    // QR kód
    private String qrData;
}
