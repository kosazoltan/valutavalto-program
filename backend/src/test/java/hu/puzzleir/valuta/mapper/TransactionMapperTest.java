package hu.puzzleir.valuta.mapper;

import hu.puzzleir.valuta.dto.transaction.TransactionDto;
import hu.puzzleir.valuta.dto.transaction.TransactionLineDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.ForeignStatus;
import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.entity.TransactionLine;
import hu.puzzleir.valuta.entity.TransactionStatus;
import hu.puzzleir.valuta.entity.TransactionType;
import hu.puzzleir.valuta.entity.Worker;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.Collections;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

class TransactionMapperTest {

    private final TransactionMapper mapper = new TransactionMapper();

    @Test
    @DisplayName("null entity és null line → null DTO")
    void mapsNullInputs() {
        assertThat(mapper.toDto(null)).isNull();
        assertThat(mapper.toLineDto(null)).isNull();
    }

    @Test
    @DisplayName("Tranzakció pénzügyi mezők, kapcsolatok, devizastátusz és eredeti bizonylat átkerül")
    void mapsFinancialReferenceAndReversalFields() {
        UUID branchId = UUID.fromString("44444444-5555-6666-7777-888888888888");
        LocalDate transactionDate = LocalDate.of(2026, 7, 6);
        LocalTime transactionTime = LocalTime.of(11, 30);
        LocalDateTime createdAt = LocalDateTime.of(2026, 7, 6, 11, 31);
        Transaction original = Transaction.builder()
                .id(99L)
                .receiptNumber("V00099")
                .build();
        Transaction entity = Transaction.builder()
                .id(1L)
                .receiptNumber("S00001")
                .transactionType(TransactionType.REVERSAL)
                .status(TransactionStatus.COMPLETED)
                .transactionDate(transactionDate)
                .transactionTime(transactionTime)
                .currency(Currency.builder().id(2L).code("EUR").name("Euro").build())
                .currencyAmount(new BigDecimal("500.00"))
                .exchangeRate(new BigDecimal("390.0000"))
                .hufAmount(new BigDecimal("195000.00"))
                .handlingFee(new BigDecimal("1500.00"))
                .discountAmount(new BigDecimal("500.00"))
                .discountPercent(new BigDecimal("1.25"))
                .customerId("C-001")
                .customerName("Tranzakció Ügyfél")
                .customerAddress("Teszt utca 1.")
                .customerDocumentNumber("AB123456")
                .customerNationality("Magyar")
                .worker(Worker.builder().id(10L).code("P001").name("Pénztáros").build())
                .branch(Branch.builder().id(branchId).name("Szeged").build())
                .originalTransaction(original)
                .reversalReason("téves rögzítés")
                .approvedBy("Supervisor")
                .notes("megjegyzés")
                .foreignStatus(ForeignStatus.FOREIGN)
                .printed(true)
                .mtcn("MTCN-1")
                .referenceNumber("REF-1")
                .createdAt(createdAt)
                .multiLine(false)
                .lineCount(1)
                .build();

        TransactionDto dto = mapper.toDto(entity);

        assertThat(dto.getId()).isEqualTo(1L);
        assertThat(dto.getReceiptNumber()).isEqualTo("S00001");
        assertThat(dto.getTransactionType()).isEqualTo(TransactionType.REVERSAL);
        assertThat(dto.getStatus()).isEqualTo(TransactionStatus.COMPLETED);
        assertThat(dto.getTransactionDate()).isEqualTo(transactionDate);
        assertThat(dto.getTransactionTime()).isEqualTo(transactionTime);
        assertThat(dto.getCurrencyId()).isEqualTo(2L);
        assertThat(dto.getCurrencyCode()).isEqualTo("EUR");
        assertThat(dto.getCurrencyName()).isEqualTo("Euro");
        assertThat(dto.getCurrencyAmount()).isEqualByComparingTo("500.00");
        assertThat(dto.getExchangeRate()).isEqualByComparingTo("390.0000");
        assertThat(dto.getHufAmount()).isEqualByComparingTo("195000.00");
        assertThat(dto.getHandlingFee()).isEqualByComparingTo("1500.00");
        assertThat(dto.getDiscountAmount()).isEqualByComparingTo("500.00");
        assertThat(dto.getDiscountPercent()).isEqualByComparingTo("1.25");
        assertThat(dto.getCustomerId()).isEqualTo("C-001");
        assertThat(dto.getCustomerName()).isEqualTo("Tranzakció Ügyfél");
        assertThat(dto.getCustomerAddress()).isEqualTo("Teszt utca 1.");
        assertThat(dto.getCustomerDocumentNumber()).isEqualTo("AB123456");
        assertThat(dto.getCustomerNationality()).isEqualTo("Magyar");
        assertThat(dto.getWorkerId()).isEqualTo(10L);
        assertThat(dto.getWorkerCode()).isEqualTo("P001");
        assertThat(dto.getWorkerName()).isEqualTo("Pénztáros");
        assertThat(dto.getBranchId()).isEqualTo(branchId.toString());
        assertThat(dto.getBranchName()).isEqualTo("Szeged");
        assertThat(dto.getOriginalTransactionId()).isEqualTo(99L);
        assertThat(dto.getOriginalReceiptNumber()).isEqualTo("V00099");
        assertThat(dto.getReversalReason()).isEqualTo("téves rögzítés");
        assertThat(dto.getApprovedBy()).isEqualTo("Supervisor");
        assertThat(dto.getNotes()).isEqualTo("megjegyzés");
        assertThat(dto.getForeignStatus()).isEqualTo("FOREIGN");
        assertThat(dto.getPrinted()).isTrue();
        assertThat(dto.getMtcn()).isEqualTo("MTCN-1");
        assertThat(dto.getReferenceNumber()).isEqualTo("REF-1");
        assertThat(dto.getCreatedAt()).isEqualTo(createdAt);
        assertThat(dto.getMultiLine()).isFalse();
        assertThat(dto.getLineCount()).isEqualTo(1);
        assertThat(dto.getLines()).isNull();
    }

    @Test
    @DisplayName("multiLine=true és nem üres lines → line DTO-k képződnek")
    void mapsMultiLineTransactionLines() {
        TransactionLine line = TransactionLine.builder()
                .id(10L)
                .lineNumber(1)
                .currency(Currency.builder().id(2L).code("EUR").name("Euro").build())
                .appliedRate(new BigDecimal("390.0000"))
                .originalRate(new BigDecimal("392.0000"))
                .banknoteCount(new BigDecimal("500.00"))
                .hufValue(new BigDecimal("195000"))
                .lineDiscount(new BigDecimal("1000"))
                .discountType(4)
                .foreignStatus(ForeignStatus.DOMESTIC)
                .build();
        Transaction entity = Transaction.builder()
                .id(1L)
                .receiptNumber("V00001")
                .multiLine(true)
                .lineCount(1)
                .lines(List.of(line))
                .currency(Currency.builder().id(2L).code("EUR").name("Euro").build())
                .currencyAmount(new BigDecimal("500.00"))
                .hufAmount(new BigDecimal("195000"))
                .exchangeRate(new BigDecimal("390.0000"))
                .handlingFee(new BigDecimal("0"))
                .build();

        TransactionDto dto = mapper.toDto(entity);

        assertThat(dto.getLines()).hasSize(1);
        assertThat(dto.getLines().getFirst().getId()).isEqualTo(10L);
        assertThat(dto.getLines().getFirst().getLineNumber()).isEqualTo(1);
        assertThat(dto.getLines().getFirst().getCurrencyId()).isEqualTo(2L);
        assertThat(dto.getLines().getFirst().getCurrencyCode()).isEqualTo("EUR");
        assertThat(dto.getLines().getFirst().getCurrencyName()).isEqualTo("Euro");
        assertThat(dto.getLines().getFirst().getAppliedRate()).isEqualByComparingTo("390.0000");
        assertThat(dto.getLines().getFirst().getOriginalRate()).isEqualByComparingTo("392.0000");
        assertThat(dto.getLines().getFirst().getBanknoteCount()).isEqualByComparingTo("500.00");
        assertThat(dto.getLines().getFirst().getHufValue()).isEqualByComparingTo("195000");
        assertThat(dto.getLines().getFirst().getLineDiscount()).isEqualByComparingTo("1000");
        assertThat(dto.getLines().getFirst().getDiscountType()).isEqualTo(4);
        assertThat(dto.getLines().getFirst().getForeignStatus()).isEqualTo("DOMESTIC");
        assertThat(dto.getHufAmount()).isEqualByComparingTo("195000");
    }

    @Test
    @DisplayName("multiLine false/null vagy üres lines → lines null")
    void mapsLinesOnlyWhenMultiLineTrueAndNonEmpty() {
        TransactionLine line = TransactionLine.builder().id(1L).lineNumber(1).build();
        Transaction multiLineFalse = Transaction.builder()
                .multiLine(false)
                .lines(List.of(line))
                .build();
        Transaction multiLineNull = Transaction.builder()
                .multiLine(null)
                .lines(List.of(line))
                .build();
        Transaction emptyLines = Transaction.builder()
                .multiLine(true)
                .lines(Collections.emptyList())
                .build();

        assertThat(mapper.toDto(multiLineFalse).getLines()).isNull();
        assertThat(mapper.toDto(multiLineNull).getLines()).isNull();
        assertThat(mapper.toDto(emptyLines).getLines()).isNull();
    }

    @Test
    @DisplayName("Hiányzó currency/worker/branch/originalTx/foreignStatus → null mezők NPE nélkül")
    void mapsNullReferencesSafely() {
        Transaction entity = Transaction.builder()
                .currency(null)
                .worker(null)
                .branch(null)
                .originalTransaction(null)
                .foreignStatus(null)
                .multiLine(false)
                .build();

        TransactionDto dto = mapper.toDto(entity);

        assertThat(dto.getCurrencyId()).isNull();
        assertThat(dto.getCurrencyCode()).isNull();
        assertThat(dto.getCurrencyName()).isNull();
        assertThat(dto.getWorkerId()).isNull();
        assertThat(dto.getWorkerCode()).isNull();
        assertThat(dto.getWorkerName()).isNull();
        assertThat(dto.getBranchId()).isNull();
        assertThat(dto.getBranchName()).isNull();
        assertThat(dto.getOriginalTransactionId()).isNull();
        assertThat(dto.getOriginalReceiptNumber()).isNull();
        assertThat(dto.getForeignStatus()).isNull();
    }

    @Test
    @DisplayName("toLineDto: null currency és null foreignStatus NPE nélkül null mezők")
    void mapsLineNullCurrencyAndForeignStatusSafely() {
        TransactionLine line = TransactionLine.builder()
                .id(10L)
                .lineNumber(2)
                .currency(null)
                .appliedRate(new BigDecimal("1.2500"))
                .banknoteCount(new BigDecimal("100.00"))
                .hufValue(new BigDecimal("125"))
                .foreignStatus(null)
                .build();

        TransactionLineDto dto = mapper.toLineDto(line);

        assertThat(dto.getCurrencyId()).isNull();
        assertThat(dto.getCurrencyCode()).isNull();
        assertThat(dto.getCurrencyName()).isNull();
        assertThat(dto.getForeignStatus()).isNull();
        assertThat(dto.getAppliedRate()).isEqualByComparingTo("1.2500");
        assertThat(dto.getBanknoteCount()).isEqualByComparingTo("100.00");
        assertThat(dto.getHufValue()).isEqualByComparingTo("125");
    }
}
