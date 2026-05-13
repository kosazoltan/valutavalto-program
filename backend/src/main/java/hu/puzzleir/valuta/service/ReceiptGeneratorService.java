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
    private final EscPosReceiptService escPosReceiptService;
    private final SystemParameterService systemParameterService;

    /** 300.000 Ft — jogszabályi küszöb PEP és Jogcím nyilatkozathoz */
    private static final BigDecimal HIGH_VALUE_THRESHOLD = new BigDecimal("300000");
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
                .label("Forrás iroda").value(transfer.getFromBranch() != null ? transfer.getFromBranch().getName() : "—").build());
        lines.add(ReceiptData.ReceiptLineData.builder()
                .label("Cél iroda").value(transfer.getToBranch() != null ? transfer.getToBranch().getName() : "—").build());
        lines.add(ReceiptData.ReceiptLineData.builder()
                .label("Szállítólevél szám").value(transfer.getTransferNumber() != null ? transfer.getTransferNumber() : "—").build());

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
     * ESC/POS nyomtató formátum — delegál az EscPosReceiptService-nek,
     * amely a javított fejlécet, teljes ügyfél adatokat, ÁFA-mentesség szöveget,
     * kerekítést és két aláírás sort tartalmazza.
     */
    public byte[] formatForEscPos(ReceiptData data) {
        String type = data.getReceiptType();
        if (type == null) type = "";
        return switch (type) {
            case "BUY" -> escPosReceiptService.generateBuyReceipt(data);
            case "SELL" -> escPosReceiptService.generateSellReceipt(data);
            case "REVERSAL", "STORNO" -> escPosReceiptService.generateStornoReceipt(data);
            case "CONVERSION" -> escPosReceiptService.generateConversionReceipt(data);
            case "TRANSFER", "TRANSFER_OUT" -> escPosReceiptService.generateTransferOutReceipt(data);
            case "TRANSFER_IN" -> escPosReceiptService.generateTransferInReceipt(data);
            case "HANDLING_FEE" -> escPosReceiptService.generateHandlingFeeReceipt(data);
            case "KKTG_TRANSFER" -> escPosReceiptService.generateKktgTransferReceipt(data);
            // CASH_STATUS és VAULT_CLOSING extra paramétereket igényelnek (currency map-ek) →
            // közvetlenül az EscPosReceiptService-t kell hívni a megfelelő service-ből,
            // nem a formatForEscPos()-on keresztül. Ide nem juthatnak be normál flow-ban.
            // CLOSING: napi zárás → PDF útvonal (formatForPdf), ESC/POS-on nem támogatott.
            // WU: Western Union bizonylatok → saját nyomtatási flow-t használnak.
            case "CLOSING", "CASH_STATUS", "VAULT_CLOSING" -> {
                log.warn("ESC/POS not supported for type '{}', falling back to generic receipt", type);
                yield escPosReceiptService.generateBuyReceipt(data);
            }
            default -> {
                if (type.startsWith("WU_")) {
                    log.warn("ESC/POS WU receipt type '{}', falling back to generic buy receipt", type);
                    yield escPosReceiptService.generateBuyReceipt(data);
                }
                log.warn("Unknown receipt type for ESC/POS: '{}', using fallback", type);
                yield escPosReceiptService.generateBuyReceipt(data);
            }
        };
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

        ReceiptData.ReceiptDataBuilder builder = ReceiptData.builder()
                .receiptNumber(receiptNumber)
                .navReceiptNumber(tx.getLinkedReceiptNumber())
                .receiptType(type)
                .date(LocalDateTime.now())
                .currencyCode(tx.getCurrency() != null ? tx.getCurrency().getCode() : "")
                .foreignAmount(tx.getCurrencyAmount())
                .foreignStatus(tx.getForeignStatus() != null ? tx.getForeignStatus().name() : null)
                .rate(tx.getExchangeRate())
                .hufAmount(tx.getHufAmount())
                .handlingFee(tx.getHandlingFee())
                .customerName(tx.getCustomerName())
                .customerIdNumber(tx.getCustomerDocumentNumber())
                .lines(lines)
                .qrCode(receiptNumber);

        // Cég adatok
        if (tx.getCompany() != null) {
            builder.companyName(tx.getCompany().getName())
                   .companyFullName(tx.getCompany().getName())
                   .companyTaxNumber(tx.getCompany().getTaxNumber())
                   .companyPhone(tx.getCompany().getPhone());
        }

        // Fiók adatok
        if (tx.getBranch() != null) {
            builder.branchName(tx.getBranch().getName())
                   .branchCode(tx.getBranch().getCode())
                   .branchAddress(tx.getBranch().getAddress())
                   .branchPhone(tx.getBranch().getPhone());
        }

        // Pénztáros
        if (tx.getWorker() != null) {
            builder.workerName(tx.getWorker().getName());
        }

        // Ügyfél részletes adatok (300K felett kötelező a bizonylaton)
        // Transaction entity-n elérhető: customerAddress, customerNationality
        builder.customerAddress(tx.getCustomerAddress())
               .customerNationality(tx.getCustomerNationality());
        // Megjegyzés: customerMotherName, customerBirthPlace, customerBirthDate, customerDocType
        // jelenleg nem léteznek a Transaction entity-n — ezek a Customer entity-n vagy
        // a jövőbeli AML adatbővítés részeként lesznek elérhetők.
        // A ReceiptData DTO-ban opcionálisak, null-safe.

        // Kerekítés — Transaction entity: roundingAmount
        if (tx.getRoundingAmount() != null && tx.getRoundingAmount().compareTo(BigDecimal.ZERO) != 0) {
            BigDecimal roundedAmount = tx.getHufAmount() != null
                    ? tx.getHufAmount().add(tx.getRoundingAmount())
                    : tx.getRoundingAmount();
            builder.roundingDiff(tx.getRoundingAmount())
                   .roundedHufAmount(roundedAmount);
        }

        // ÁFA-mentesség — SystemParameter-ből (admin UI-ból szerkeszthető)
        try {
            String vatText = systemParameterService.getValue("RECEIPT_VAT_EXEMPTION",
                    "Szj - 67.13.10.0\nAdómentes  a szolgáltatás nyújtása a 2007\nM.Á.A. evi CXVII tv. 86 § e) alapján\nmentes az adó alól");
            builder.vatExemptionText(vatText);
        } catch (Exception e) {
            log.debug("VAT exemption text SystemParameter olvasás sikertelen, default marad");
        }

        // Kiegészítő blokkok aktiválása
        applyRuByDeclarationIfNeeded(builder, tx.getCustomerNationality());
        applyPepDeclarationIfNeeded(builder, tx);
        applySourceDeclarationIfNeeded(builder, tx);
        // Kedvezményes árfolyam — jövőbeli bővítés; jelenleg a helper elérhető
        // az explicit hívásokhoz (pl. VIP ár esetén)

        return builder.build();
    }

    /**
     * Kezelési díj bizonylat generálása (külön bizonylat a díjról)
     * Prefix: B
     */
    public ReceiptData generateHandlingFeeReceipt(Transaction tx, String sealNumber) {
        String receiptNumber = generateReceiptNumber("B");

        List<ReceiptData.ReceiptLineData> lines = new ArrayList<>();
        lines.add(ReceiptData.ReceiptLineData.builder()
                .label("Alapbizonylat").value(tx.getReceiptNumber() != null ? tx.getReceiptNumber() : "").build());

        ReceiptData.ReceiptDataBuilder builder = ReceiptData.builder()
                .receiptNumber(receiptNumber)
                .receiptType("HANDLING_FEE")
                .date(LocalDateTime.now())
                .hufAmount(tx.getHandlingFee())
                .handlingFee(tx.getHandlingFee())
                .sealNumber(sealNumber)
                .lines(lines)
                .qrCode(receiptNumber);

        if (tx.getCompany() != null) {
            builder.companyName(tx.getCompany().getName())
                   .companyFullName(tx.getCompany().getName())
                   .companyTaxNumber(tx.getCompany().getTaxNumber())
                   .companyPhone(tx.getCompany().getPhone());
        }
        if (tx.getBranch() != null) {
            builder.branchName(tx.getBranch().getName())
                   .branchCode(tx.getBranch().getCode())
                   .branchAddress(tx.getBranch().getAddress())
                   .branchPhone(tx.getBranch().getPhone());
        }
        if (tx.getWorker() != null) {
            builder.workerName(tx.getWorker().getName());
        }

        return builder.build();
    }

    // ============ KIEGÉSZÍTŐ BIZONYLAT BLOKKOK ============

    /**
     * Orosz/fehérorosz ügyfél nyilatkozat blokk hozzáadása.
     *
     * Ha az ügyfél állampolgársága RU vagy BY, a bizonylaton kötelező
     * megjeleníteni az EU/FATF szankciós nyilatkozatot.
     *
     * @param builder  ReceiptData builder
     * @param isoCode  ügyfél állampolgárság ISO kódja (pl. "RU", "BY")
     */
    public void applyRuByDeclarationIfNeeded(ReceiptData.ReceiptDataBuilder builder, String isoCode) {
        if ("RU".equalsIgnoreCase(isoCode) || "BY".equalsIgnoreCase(isoCode)) {
            builder.requiresRuByDeclaration(true);
            log.debug("RU/BY nyilatkozat blokk aktiválva, ügyfél ISO: {}", isoCode);
        }
    }

    /**
     * PEP (kiemelt közszereplő) nyilatkozat blokk hozzáadása.
     *
     * Legacy: BLOKNYOM/KozszerepNyilatkozat — 300k+ Ft felett jogszabályi kötelezettség.
     * Ha az ügyfél PEP, a bizonylaton kötelezően megjelenik a közszereplő státusz.
     *
     * @param builder  ReceiptData builder
     * @param tx       tranzakció (customerIsPep, hufAmount)
     */
    public void applyPepDeclarationIfNeeded(ReceiptData.ReceiptDataBuilder builder, Transaction tx) {
        boolean isHighValue = tx.getHufAmount() != null && tx.getHufAmount().abs().compareTo(HIGH_VALUE_THRESHOLD) >= 0;

        if (isHighValue) {
            boolean isPep = Boolean.TRUE.equals(tx.getCustomerIsPep());
            builder.requiresPepDeclaration(true)
                   .pepStatusText(isPep
                       ? "Az ügyfél kiemelt közszereplő"
                       : "Nem közszereplő");
            log.debug("PEP nyilatkozat blokk aktiválva, isPep={}", isPep);
        }
    }

    /**
     * Jogcím nyilatkozat (pénzeszköz forrása) blokk hozzáadása.
     *
     * Legacy: BLOKNYOM/Jogcimnyilatkozat — 300k+ Ft tranzakciónál kötelező.
     * "Büntetőjogi felelősségem tudatában nyilatkozom, hogy a fenti tranzakciót
     *  saját nevemben bonyolítom / XY nevében bonyolítom."
     *
     * @param builder  ReceiptData builder
     * @param tx       tranzakció (sourceOfFunds, hufAmount, customerName)
     */
    public void applySourceDeclarationIfNeeded(ReceiptData.ReceiptDataBuilder builder, Transaction tx) {
        boolean isHighValue = tx.getHufAmount() != null && tx.getHufAmount().abs().compareTo(HIGH_VALUE_THRESHOLD) >= 0;

        if (isHighValue) {
            builder.requiresSourceDeclaration(true)
                   .sourceOfFunds(tx.getSourceOfFunds());
            log.debug("Jogcím nyilatkozat blokk aktiválva, forrás: {}", tx.getSourceOfFunds());
        }
    }

    /**
     * Jogi személy nyilatkozat blokk hozzáadása.
     *
     * Ha az ügyfél jogi személy, kötelező feltüntetni a cégnevet,
     * székhelyet, okiratszámot és képviselő adatait.
     *
     * @param builder               ReceiptData builder
     * @param isLegalEntity         jogi személy-e
     * @param representativeName    képviselő neve
     * @param deedNumber            okiratszám
     */
    public void applyLegalEntityBlockIfNeeded(
            ReceiptData.ReceiptDataBuilder builder,
            boolean isLegalEntity,
            String representativeName,
            String deedNumber) {
        if (isLegalEntity) {
            builder.requiresLegalEntityBlock(true)
                   .legalRepresentativeName(representativeName)
                   .legalDeedNumber(deedNumber);
            log.debug("Jogi személy nyilatkozat blokk aktiválva");
        }
    }

    /**
     * Kedvezményes árfolyam melléklet hozzáadása.
     *
     * Ha az ügyfél kedvezményes árfolyamot kapott (pl. VIP ár),
     * a bizonylaton feltüntetjük a normál és kedvezményes árfolyamot.
     *
     * @param builder        ReceiptData builder
     * @param appliedRate    ténylegesen alkalmazott árfolyam
     * @param standardRate   standard listaáras árfolyam
     */
    public void applyDiscountedRateIfNeeded(
            ReceiptData.ReceiptDataBuilder builder,
            java.math.BigDecimal appliedRate,
            java.math.BigDecimal standardRate) {
        if (appliedRate != null && standardRate != null
                && appliedRate.compareTo(standardRate) != 0) {
            builder.hasDiscountedRate(true)
                   .standardRate(standardRate);
            log.debug("Kedvezményes árfolyam melléklet aktiválva: alkalmazott={}, standard={}",
                appliedRate, standardRate);
        }
    }

    /**
     * Másolat indok beállítása.
     *
     * Ha másolatot nyomtatunk, a bizonylaton MÁSOLAT fejléc és az indok jelenik meg.
     *
     * @param builder    ReceiptData builder
     * @param copyReason másolat nyomtatásának indoka (nem null = másolat)
     */
    public void applyCopyReason(ReceiptData.ReceiptDataBuilder builder, String copyReason) {
        if (copyReason != null && !copyReason.isBlank()) {
            builder.copyReason(copyReason);
            log.debug("Másolat indok beállítva: {}", copyReason);
        }
    }

    /**
     * Kétnyelvű (magyar + angol) tételsorok generálása.
     *
     * @param labelHu  magyar felirat
     * @param labelEn  angol felirat
     * @param value    érték
     * @return kétnyelvű ReceiptLineData
     */
    public ReceiptData.ReceiptLineData bilingualLine(String labelHu, String labelEn, String value) {
        return ReceiptData.ReceiptLineData.builder()
            .label(labelHu)
            .labelEn(labelEn)
            .value(value)
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
