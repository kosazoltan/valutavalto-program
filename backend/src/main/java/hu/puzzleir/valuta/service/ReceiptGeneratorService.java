package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.dto.receipt.ReceiptData;
import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.entity.Transfer;
import hu.puzzleir.valuta.entity.TransactionType;
import hu.puzzleir.valuta.entity.WuTransaction;
import hu.puzzleir.valuta.repository.TransactionRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.atomic.AtomicLong;

/**
 * Bizonylat generátor szolgáltatás.
 *
 * Bizonylat típusok:
 * - E-YYMMDD-XXXX: Eladási bizonylat (valuta eladás)
 * - V-YYMMDD-XXXX: Vételi bizonylat (valuta vétel)
 * - A-YYMMDD-XXXX: Átvezetési bizonylat (irodák közti)
 * - S-YYMMDD-XXXX: Sztornó bizonylat
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class ReceiptGeneratorService {

    private final TransactionRepository transactionRepository;
    private final ReceiptPdfService receiptPdfService;

    private static final DateTimeFormatter RECEIPT_DATE_FORMAT = DateTimeFormatter.ofPattern("yyMMdd");
    /**
     * Bizonylat sorszám — a nap + milliszekundum + AtomicLong kombináció biztosítja
     * az egyediséget újraindítás után is: System.currentTimeMillis() % 10000 az alap,
     * az AtomicLong pedig a tranzakción belüli szekvenciát tartja.
     */
    private static final AtomicLong SEQUENCE = new AtomicLong(
        (System.currentTimeMillis() / 1000) % 100000  // 5 digits, changes every second — minimizes restart collision
    );

    /**
     * Eladási bizonylat generálása (ügyfélnek eladunk valutát)
     * Prefix: E
     */
    @Transactional(readOnly = true)
    public ReceiptData generateSellReceipt(Transaction tx) {
        return generateTransactionReceipt(tx, "E", "SELL");
    }

    /**
     * Vételi bizonylat generálása (ügyféltől veszünk valutát)
     * Prefix: V
     */
    @Transactional(readOnly = true)
    public ReceiptData generateBuyReceipt(Transaction tx) {
        return generateTransactionReceipt(tx, "V", "BUY");
    }

    /**
     * Átvezetési bizonylat generálása (irodák közti szállítás)
     * Prefix: A
     */
    public ReceiptData generateTransferReceipt(Transfer transfer) {
        String receiptNumber = generateReceiptNumber("A");

        List<ReceiptData.ReceiptLineData> lines = new ArrayList<>();
        lines.add(ReceiptData.ReceiptLineData.builder()
                .label("Forrás iroda").value(transfer.getFromBranch().getName()).build());
        lines.add(ReceiptData.ReceiptLineData.builder()
                .label("Cél iroda").value(transfer.getToBranch().getName()).build());
        lines.add(ReceiptData.ReceiptLineData.builder()
                .label("Szállítólevél szám").value(transfer.getTransferNumber()).build());

        return ReceiptData.builder()
                .receiptNumber(receiptNumber)
                .receiptType("TRANSFER")
                .companyName(transfer.getFromBranch() != null && transfer.getFromBranch().getCompany() != null
                        ? transfer.getFromBranch().getCompany().getName() : "")
                .branchName(transfer.getFromBranch() != null ? transfer.getFromBranch().getName() : "")
                .workerName(transfer.getFromWorker() != null ? transfer.getFromWorker().getName() : "")
                .date(LocalDateTime.now())
                .currencyCode(transfer.getCurrency() != null ? transfer.getCurrency().getCode() : "")
                .foreignAmount(transfer.getAmount())
                .rate(BigDecimal.ZERO)
                .hufAmount(transfer.getHufValue() != null ? transfer.getHufValue() : BigDecimal.ZERO)
                .lines(lines)
                .qrCode(receiptNumber)
                .build();
    }

    /**
     * Sztornó bizonylat generálása
     * Prefix: S
     */
    @Transactional(readOnly = true)
    public ReceiptData generateStornoReceipt(Transaction stornoTx) {
        String receiptNumber = generateReceiptNumber("S");

        List<ReceiptData.ReceiptLineData> lines = new ArrayList<>();
        lines.add(ReceiptData.ReceiptLineData.builder()
                .label("Sztornó bizonylat szám").value(receiptNumber).build());
        if (stornoTx.getOriginalTransaction() != null) {
            lines.add(ReceiptData.ReceiptLineData.builder()
                    .label("Eredeti bizonylat").value(stornoTx.getOriginalTransaction().getReceiptNumber()).build());
        }
        lines.add(ReceiptData.ReceiptLineData.builder()
                .label("Sztornó ok").value(stornoTx.getReversalReason() != null ? stornoTx.getReversalReason() : "").build());

        return ReceiptData.builder()
                .receiptNumber(receiptNumber)
                .receiptType("STORNO")
                .companyName(stornoTx.getCompany() != null ? stornoTx.getCompany().getName() : "")
                .branchName(stornoTx.getBranch() != null ? stornoTx.getBranch().getName() : "")
                .workerName(stornoTx.getWorker() != null ? stornoTx.getWorker().getName() : "")
                .date(LocalDateTime.now())
                .currencyCode(stornoTx.getCurrency() != null ? stornoTx.getCurrency().getCode() : "")
                .foreignAmount(stornoTx.getCurrencyAmount())
                .rate(stornoTx.getExchangeRate())
                .hufAmount(stornoTx.getHufAmount())
                .customerName(stornoTx.getCustomerName())
                .customerIdNumber(stornoTx.getCustomerDocumentNumber())
                .lines(lines)
                .qrCode(receiptNumber)
                .build();
    }

    /**
     * Zárási bizonylat generálása
     */
    public ReceiptData generateClosingReceipt(ClosingData data) {
        String receiptNumber = generateReceiptNumber("Z");

        List<ReceiptData.ReceiptLineData> lines = new ArrayList<>();
        lines.add(ReceiptData.ReceiptLineData.builder()
                .label("Zárás dátuma").value(data.getClosingDate().toString()).build());
        lines.add(ReceiptData.ReceiptLineData.builder()
                .label("Tranzakciók száma").value(String.valueOf(data.getTransactionCount())).build());
        lines.add(ReceiptData.ReceiptLineData.builder()
                .label("Napi forgalom (HUF)").value(data.getTotalHufTurnover().toPlainString()).build());

        return ReceiptData.builder()
                .receiptNumber(receiptNumber)
                .receiptType("CLOSING")
                .companyName(data.getCompanyName())
                .branchName(data.getBranchName())
                .workerName(data.getWorkerName())
                .date(LocalDateTime.now())
                .hufAmount(data.getTotalHufTurnover())
                .lines(lines)
                .qrCode(receiptNumber)
                .build();
    }

    /**
     * ESC/POS nyomtató formátum
     */
    public byte[] formatForEscPos(ReceiptData data) {
        StringBuilder sb = new StringBuilder();

        // ESC/POS init
        sb.append("\u001B@"); // Initialize printer
        sb.append("\u001Ba\u0001"); // Center alignment

        // Fejléc
        sb.append("\u001B!\u0010"); // Double-height
        sb.append(data.getCompanyName() != null ? data.getCompanyName() : "").append("\n");
        sb.append("\u001B!\u0000"); // Normal
        sb.append(data.getBranchName() != null ? data.getBranchName() : "").append("\n");
        sb.append("================================\n");

        sb.append("\u001Ba\u0000"); // Left alignment

        // Bizonylat adatok
        sb.append("Bizonylat: ").append(data.getReceiptNumber()).append("\n");
        sb.append("Típus:     ").append(data.getReceiptType()).append("\n");
        sb.append("Dátum:     ").append(data.getDate() != null ?
                data.getDate().format(DateTimeFormatter.ofPattern("yyyy.MM.dd HH:mm")) : "").append("\n");
        sb.append("Pénztáros: ").append(data.getWorkerName() != null ? data.getWorkerName() : "").append("\n");
        sb.append("--------------------------------\n");

        // Valuta adatok
        if (data.getCurrencyCode() != null) {
            sb.append("Valuta:    ").append(data.getCurrencyCode()).append("\n");
            sb.append("Összeg:    ").append(data.getForeignAmount() != null ? data.getForeignAmount().toPlainString() : "").append("\n");
            sb.append("Árfolyam:  ").append(data.getRate() != null ? data.getRate().toPlainString() : "").append("\n");
            sb.append("HUF:       ").append(data.getHufAmount() != null ? data.getHufAmount().toPlainString() : "").append(" Ft\n");
        }

        if (data.getHandlingFee() != null && data.getHandlingFee().compareTo(BigDecimal.ZERO) > 0) {
            sb.append("Kezelési díj: ").append(data.getHandlingFee().toPlainString()).append(" Ft\n");
        }

        sb.append("--------------------------------\n");

        // Ügyfél
        if (data.getCustomerName() != null && !data.getCustomerName().isBlank()) {
            sb.append("Ügyfél:    ").append(data.getCustomerName()).append("\n");
        }
        if (data.getCustomerIdNumber() != null && !data.getCustomerIdNumber().isBlank()) {
            sb.append("Okmány:    ").append(data.getCustomerIdNumber()).append("\n");
        }

        // Extra sorok
        if (data.getLines() != null) {
            for (ReceiptData.ReceiptLineData line : data.getLines()) {
                sb.append(line.getLabel()).append(": ").append(line.getValue()).append("\n");
            }
        }

        sb.append("================================\n");
        sb.append(data.getSignatureLine() != null ? data.getSignatureLine() : "Aláírás: ____________________")
                .append("\n\n\n");

        // Paper cut
        sb.append("\u001DVA\u0003"); // Partial cut

        return sb.toString().getBytes(StandardCharsets.UTF_8);
    }

    /**
     * PDF formátum generálása — Apache PDFBox alapú valódi PDF.
     */
    public byte[] formatForPdf(ReceiptData data) {
        return receiptPdfService.generatePdf(data);
    }

    /**
     * Western Union bizonylat generálása
     * Prefix: W
     */
    public ReceiptData generateWuReceipt(WuTransaction wuTx) {
        String receiptNumber = generateReceiptNumber("W");

        List<ReceiptData.ReceiptLineData> lines = new ArrayList<>();
        if (wuTx.getMtcn() != null) {
            lines.add(ReceiptData.ReceiptLineData.builder()
                    .label("MTCN").value(wuTx.getMtcn()).build());
        }
        if (wuTx.getTransactionType() != null) {
            lines.add(ReceiptData.ReceiptLineData.builder()
                    .label("Tipus").value(wuTx.getTransactionType()).build());
        }
        if (wuTx.getSenderName() != null) {
            lines.add(ReceiptData.ReceiptLineData.builder()
                    .label("Kuldo").value(wuTx.getSenderName()).build());
        }
        if (wuTx.getReceiverName() != null) {
            lines.add(ReceiptData.ReceiptLineData.builder()
                    .label("Cimzett").value(wuTx.getReceiverName()).build());
        }
        if (wuTx.getDestinationCountry() != null) {
            lines.add(ReceiptData.ReceiptLineData.builder()
                    .label("Cel orszag").value(wuTx.getDestinationCountry()).build());
        }
        if (wuTx.getFeeAmount() != null) {
            lines.add(ReceiptData.ReceiptLineData.builder()
                    .label("WU dij").value(wuTx.getFeeAmount().toPlainString() + " USD").build());
        }

        return ReceiptData.builder()
                .receiptNumber(receiptNumber)
                .receiptType("WU_" + (wuTx.getTransactionType() != null ? wuTx.getTransactionType() : "UNKNOWN"))
                .companyName(wuTx.getCompany() != null ? wuTx.getCompany().getName() : "")
                .branchName(wuTx.getBranch() != null ? wuTx.getBranch().getName() : "")
                .workerName(wuTx.getWorker() != null ? wuTx.getWorker().getName() : "")
                .date(wuTx.getTransactionDate() != null ? wuTx.getTransactionDate() : LocalDateTime.now())
                .currencyCode("USD")
                .foreignAmount(wuTx.getAmountUsd())
                .rate(wuTx.getExchangeRate())
                .hufAmount(wuTx.getAmountHuf())
                .lines(lines)
                .qrCode(receiptNumber)
                .build();
    }

    // ============ Tranzakció ID → Receipt ============

    /**
     * Tranzakció ID alapján PDF bizonylat generálása
     */
    @Transactional(readOnly = true)
    public byte[] generatePdfForTransaction(Long transactionId) {
        Transaction tx = transactionRepository.findById(transactionId)
                .orElseThrow(() -> new ResourceNotFoundException("Tranzakció nem található: " + transactionId));

        ReceiptData data;
        if (tx.isReversal()) {
            data = generateStornoReceipt(tx);
        } else if (tx.getTransactionType() == TransactionType.SELL) {
            data = generateSellReceipt(tx);
        } else {
            data = generateBuyReceipt(tx);
        }

        return formatForPdf(data);
    }

    /**
     * Tranzakció ID alapján ESC/POS bizonylat generálása
     */
    @Transactional(readOnly = true)
    public byte[] generateEscPosForTransaction(Long transactionId) {
        Transaction tx = transactionRepository.findById(transactionId)
                .orElseThrow(() -> new ResourceNotFoundException("Tranzakció nem található: " + transactionId));

        ReceiptData data;
        if (tx.isReversal()) {
            data = generateStornoReceipt(tx);
        } else if (tx.getTransactionType() == TransactionType.SELL) {
            data = generateSellReceipt(tx);
        } else {
            data = generateBuyReceipt(tx);
        }

        return formatForEscPos(data);
    }

    // ============ HELPERS ============

    private ReceiptData generateTransactionReceipt(Transaction tx, String prefix, String type) {
        String receiptNumber = generateReceiptNumber(prefix);

        List<ReceiptData.ReceiptLineData> lines = new ArrayList<>();
        lines.add(ReceiptData.ReceiptLineData.builder()
                .label("Eredeti bizonylat szám").value(tx.getReceiptNumber()).build());

        if (tx.getHandlingFee() != null && tx.getHandlingFee().compareTo(BigDecimal.ZERO) > 0) {
            lines.add(ReceiptData.ReceiptLineData.builder()
                    .label("Kezelési díj").value(tx.getHandlingFee().toPlainString() + " Ft").build());
        }

        return ReceiptData.builder()
                .receiptNumber(receiptNumber)
                .receiptType(type)
                .companyName(tx.getCompany() != null ? tx.getCompany().getName() : "")
                .branchName(tx.getBranch() != null ? tx.getBranch().getName() : "")
                .workerName(tx.getWorker() != null ? tx.getWorker().getName() : "")
                .date(LocalDateTime.now())
                .currencyCode(tx.getCurrency() != null ? tx.getCurrency().getCode() : "")
                .foreignAmount(tx.getCurrencyAmount())
                .rate(tx.getExchangeRate())
                .hufAmount(tx.getHufAmount())
                .handlingFee(tx.getHandlingFee())
                .customerName(tx.getCustomerName())
                .customerIdNumber(tx.getCustomerDocumentNumber())
                .lines(lines)
                .qrCode(receiptNumber)
                .build();
    }

    /**
     * Bizonylat szám generálása: PREFIX-YYMMDD-XXXX
     */
    private String generateReceiptNumber(String prefix) {
        String datePart = LocalDate.now().format(RECEIPT_DATE_FORMAT);
        long seq = SEQUENCE.getAndIncrement();
        return String.format("%s-%s-%05d", prefix, datePart, seq);
    }

    /**
     * Zárási adat DTO (belső)
     */
    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class ClosingData {
        private String companyName;
        private String branchName;
        private String workerName;
        private LocalDate closingDate;
        private int transactionCount;
        private BigDecimal totalHufTurnover;
    }
}
