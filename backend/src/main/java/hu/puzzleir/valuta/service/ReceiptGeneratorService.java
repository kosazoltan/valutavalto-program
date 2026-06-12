package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.dto.receipt.ReceiptData;
import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.entity.Transfer;
import hu.puzzleir.valuta.entity.TransactionType;
import hu.puzzleir.valuta.entity.WuTransaction;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
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
import java.util.UUID;
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
    // V325 (Batch3-C): tenyleges tulajdonosok betoltese a bizonylat-blokkhoz
    private final hu.puzzleir.valuta.repository.TransactionBeneficialOwnerRepository transactionBeneficialOwnerRepository;

    /** 300.000 Ft — jogszabályi küszöb PEP és Jogcím nyilatkozathoz */
    private static final BigDecimal HIGH_VALUE_THRESHOLD = new BigDecimal("300000");
    private static final DateTimeFormatter RECEIPT_DATE_FORMAT = DateTimeFormatter.ofPattern("yyMMdd");
    /** Megjelenítendő dátum/időpont formátum a bizonylatokon (Sourcery #783 konzisztencia). */
    private static final DateTimeFormatter DISPLAY_DATE = DateTimeFormatter.ofPattern("yyyy-MM-dd");
    private static final DateTimeFormatter DISPLAY_DATETIME = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm");

    /**
     * HUF-összeg formázása a bizonylatra: ezres csoportosítással, ponttal (magyar konvenció:
     * {@code 400.000 Ft}) — Codex P2. A PDF/ESC-POS renderer a sor-értékeket nyersen nyomtatja, ezért a
     * csoportosítást itt kell elvégezni. {@code null} → {@code "—"} (Sourcery #783: nem félrevezető "0 Ft").
     * A HUF egész forint (5 Ft-os kerekítés), ezért a tizedesjegyeket nem jelenítjük meg.
     */
    private static String hufFt(BigDecimal value) {
        if (value == null) {
            return "—";
        }
        java.text.DecimalFormatSymbols sym = new java.text.DecimalFormatSymbols();
        sym.setGroupingSeparator('.');
        return new java.text.DecimalFormat("#,##0", sym).format(value) + " Ft";
    }
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
     * G14 (EXCMD b4-foglalo FR-6..14): Foglaló-bizonylat generálása.
     *
     * <p>Két eset: FOGLALÓ ÁTVÉTELE (a foglaló létrehozásakor/befizetésekor,
     * {@code isRefund=false}) és FOGLALÓ VISSZAFIZETÉSE (lemondás/visszatérítés
     * esetén, {@code isRefund=true}). Mindkét bizonylat tartalmazza az ügyfél
     * pillanatkép-adatait (név, okmány, szül.hely/idő, anyja neve, cím,
     * állampolgárság) — a foglaló-szerződés azonosíthatóságához.</p>
     *
     * <p>Prefix: F (foglaló).</p>
     */
    /**
     * FR-10 (b4-foglalo): a foglaló-átvételi bizonylat kötelező jogi tájékoztató blokkja —
     * VERBATIM átirat a legacy program nyomtatott bizonylatáról (forrás:
     * "Felmérés/.../Bizonylatok/Foglaló bizonylatok.jpg", FOGLALO ATVETELE szelvény, OCR 2026-06-10).
     * A legacy nyomtató ékezet nélkül nyomtatott; a szöveg tartalma változatlan, a magyar
     * helyesírás (ékezetek) helyreállítva. Változatlan formában nyomtatandó.
     */
    static final String[] RESERVATION_LEGAL_NOTICE = {
        "A fent megjelölt ügyfél (továbbiakban: Ügyfél) a jelen bizonylat aláírásával "
            + "egyidejűleg megfizeti az Exclusive Change (továbbiakban: Megbízott) részére "
            + "a fent megjelölt ellenérték összegének öt százalékának (5 %) megfelelő összeget "
            + "foglalóként, mely összeg átvételét a Megbízott a jelen bizonylat aláírásával "
            + "nyugtáz és elismer.",
        "Ügyfél és Megbízott kijelentik, hogy a foglaló jogi természetével tisztában vannak, "
            + "azt magukra nézve kötelezőnek ismerik el. Tudomással bírnak azon körülményről, "
            + "hogy amennyiben a pénzváltási megbízási szerződés teljesülése a szerződés "
            + "megkötése után Megbízott felelősségébe tartozó okból hiúsulna meg, a foglaló "
            + "kétszeres összege Ügyfél részére visszajár. Abban az esetben, ha a szerződés "
            + "teljesülése a szerződés megkötése után az Ügyfél felelősségében felmerült okból "
            + "hiúsulna meg, akkor az általa átadott összeget végleg elveszti. Az átadott "
            + "foglaló az Ügyfél által fizetendő összegbe beszámításra kerül. Tájékoztatjuk "
            + "ügyfeleinket, hogy a feltüntetett árfolyam tájékoztató jellegű. Az aktuális "
            + "árfolyam a kifizetés napján kerül meghatározásra.",
    };

    @Transactional(readOnly = true)
    public ReceiptData generateReservationReceipt(hu.puzzleir.valuta.entity.Reservation reservation, boolean isRefund) {
        if (reservation == null) {
            throw new ResourceNotFoundException("A foglaló nem található a bizonylathoz.");
        }

        // A meglévő foglaló-bizonylatszámot használjuk, ha van; különben generálunk.
        String existing = isRefund
            ? reservation.getCancellationReceiptNumber()
            : reservation.getReceiptNumber();
        String receiptNumber = (existing != null && !existing.isBlank())
            ? existing
            : generateReceiptNumber("F");

        var customer = reservation.getCustomer();
        var branch = reservation.getBranch();

        // Sourcery #783: a bizonylat dátuma a tényleges domain-eseményből (létrehozás / teljesítés /
        // lemondás), nem nyers now() — auditálható, konzisztens.
        // Codex P2 (#1032): a FULFILLED beszámítási bizonylat (refund=false) a TELJESÍTÉS napját viseli
        // (fulfilledAt), NEM a befizetés napját (createdAt) — többnapos foglalónál a "beszámításra került"
        // záradék a tényleges teljesítés-dátummal konzisztens. A "Befizetés napja" sor külön mutatja a createdAt-ot.
        boolean fulfilled = reservation.getStatus() == hu.puzzleir.valuta.entity.ReservationStatus.FULFILLED;
        LocalDateTime fulfilledOrNow = reservation.getFulfilledAt() != null
            ? reservation.getFulfilledAt() : LocalDateTime.now();
        LocalDateTime receiptDate = isRefund
            ? (reservation.getCancelledAt() != null ? reservation.getCancelledAt() : LocalDateTime.now())
            : (fulfilled ? fulfilledOrNow
                         : (reservation.getCreatedAt() != null ? reservation.getCreatedAt() : LocalDateTime.now()));

        List<ReceiptData.ReceiptLineData> lines = new ArrayList<>();
        // Codex P2 (#1032): a FULFILLED foglaló külön RENDEZÉSI/BESZÁMÍTÁSI dokumentum (saját cím), NEM az
        // "ÁTVÉTELE" intake-bizonylat — a teljesítéskor nem letétet veszünk át, hanem a foglalót beszámítjuk.
        String headerTitle = isRefund ? "FOGLALÓ VISSZAFIZETÉSE"
                : (fulfilled ? "FOGLALÓ BESZÁMÍTÁSA" : "FOGLALÓ ÁTVÉTELE");
        lines.add(ReceiptData.ReceiptLineData.builder()
                .label(headerTitle)
                .value(receiptNumber).build());
        lines.add(ReceiptData.ReceiptLineData.builder()
                .label("Foglalt valuta").value(reservation.getCurrencyCode()).build());
        lines.add(ReceiptData.ReceiptLineData.builder()
                .label("Foglalt összeg")
                .value(reservation.getReservedAmount() != null ? reservation.getReservedAmount().toPlainString() : "—").build());
        lines.add(ReceiptData.ReceiptLineData.builder()
                .label("Lekötött árfolyam")
                .value(reservation.getExchangeRate() != null ? reservation.getExchangeRate().toPlainString() : "—").build());
        // FR-8 (b4-foglalo): a rendelt deviza-összeg FORINT-ÉRTÉKE (mért összeg × lekötött árfolyam),
        // egész forintra kerekítve (a doc: "ennek ft. erteke: 254.000 HUF"). A megjelenítés a nyomtató-
        // rétegben formázódik ezres csoportosítással.
        if (reservation.getReservedAmount() != null && reservation.getExchangeRate() != null) {
            // Codex P2: a tényleges KÉSZPÉNZ-értékhez igazítva 5 Ft-ra kerekítjük — egyezően a
            // ReservationService.fulfillReservation fullPrice-számításával (roundToFive), hogy a foglaló-
            // bizonylaton mutatott Ft-érték ne térjen el a beszedett összegtől.
            java.math.BigDecimal ftValue = reservation.getReservedAmount()
                    .multiply(reservation.getExchangeRate())
                    .divide(java.math.BigDecimal.valueOf(5), 0, java.math.RoundingMode.HALF_UP)
                    .multiply(java.math.BigDecimal.valueOf(5));
            lines.add(ReceiptData.ReceiptLineData.builder()
                    .label("Forint-érték").value(hufFt(ftValue)).build());
        }
        lines.add(ReceiptData.ReceiptLineData.builder()
                .label("Letét (foglaló)")
                .value(hufFt(reservation.getDepositAmount())).build());
        // FR-8: a foglaló BEFIZETÉSÉNEK napja (a doc: "Foglalo befizetve: 2024.10.21") — a foglalás
        // létrehozásának dátuma. (Refund-bizonylaton lentebb az eredeti átvétel napjaként jelenik meg.)
        if (!isRefund && reservation.getCreatedAt() != null) {
            lines.add(ReceiptData.ReceiptLineData.builder()
                    .label("Befizetés napja").value(reservation.getCreatedAt().format(DISPLAY_DATE)).build());
        }
        if (reservation.getExpiresAt() != null) {
            lines.add(ReceiptData.ReceiptLineData.builder()
                    .label(isRefund ? "Ügylet határideje volt" : "Ügylet határideje")
                    .value(reservation.getExpiresAt().format(DISPLAY_DATETIME)).build());
        }
        if (isRefund) {
            // FR-13 (b4-foglalo): a visszafizetési bizonylaton az EREDETI foglaló bizonylatszáma + az
            // eredeti foglaló-átvétel napja (kereszthivatkozás a "Kifizetes bizonylata" ÉS a
            // "Foglalo bizonylatszama" / "Foglalo atvetel napja" mezőkhöz).
            if (reservation.getReceiptNumber() != null && !reservation.getReceiptNumber().isBlank()) {
                lines.add(ReceiptData.ReceiptLineData.builder()
                        .label("Eredeti foglaló bizonylatszáma").value(reservation.getReceiptNumber()).build());
            }
            if (reservation.getCreatedAt() != null) {
                lines.add(ReceiptData.ReceiptLineData.builder()
                        .label("Foglaló átvétel napja").value(reservation.getCreatedAt().format(DISPLAY_DATE)).build());
            }
            lines.add(ReceiptData.ReceiptLineData.builder()
                    .label("Átvett foglaló összege")
                    .value(hufFt(reservation.getDepositAmount())).build());
            lines.add(ReceiptData.ReceiptLineData.builder()
                    .label("Visszafizetett összeg")
                    // Sourcery #783: null → "—" (ismeretlen), nem félrevezető "0 Ft".
                    .value(hufFt(reservation.getRefundAmount())).build());
            if (reservation.getCancellationReason() != null && !reservation.getCancellationReason().isBlank()) {
                lines.add(ReceiptData.ReceiptLineData.builder()
                        .label("Lemondás oka").value(reservation.getCancellationReason()).build());
            }
        }

        // FR-10 (b4-foglalo): a kötelező jogi tájékoztató blokk KIZÁRÓLAG az ÁTVÉTELI bizonylaton
        // (a forrás-képen a FOGLALO ATVETELE szelvényen szerepel; a visszafizetési/beszámítási
        // szelvényeken nem). A bekezdéseket üres label-lel fűzzük be — a PDF-réteg az üres label-t
        // folytatósorként, tördelt szövegként rendereli.
        if (!isRefund && !fulfilled) {
            lines.add(ReceiptData.ReceiptLineData.builder()
                    .label("Jogi tájékoztató").value("").build());
            for (String paragraph : RESERVATION_LEGAL_NOTICE) {
                lines.add(ReceiptData.ReceiptLineData.builder()
                        .label("").value(paragraph).build());
            }
        }

        // FR-14 (b4-foglalo): záró tájékoztató — CSAK ha a foglaló TÉNYLEGESEN beszámításra került (FULFILLED).
        // Codex P2 (#1032): a jegyzet az isRefund-ágon KÍVÜL, a közös szakaszban van, mert a FULFILLED foglaló
        // beszámítási bizonylatát a ReservationPage az ÁTVÉTEL (refund=false) gombbal nyomtatja — a refund=true
        // gomb csak a lemondott/lejárt sorokon jelenik meg. Így a "beszámításra került" szöveg a ténylegesen
        // használt nyomtatási úton is megjelenik. Lemondásnál (CANCELLED_*) NEM jelenik meg (nem beszámítás).
        if (fulfilled) {
            // Codex P2 (#1032): a BESZÁMÍTÁSI bizonylat settlement-specifikus mezői — a beszámítás (teljesítés)
            // napja külön sorként, hogy a befizetés-napi (createdAt) adatok mellett egyértelmű legyen a rendezés
            // dátuma (többnapos foglaló). A receiptDate (fejléc dátum) is a fulfilledAt-et viseli.
            if (reservation.getFulfilledAt() != null) {
                lines.add(ReceiptData.ReceiptLineData.builder()
                        .label("Beszámítás napja").value(reservation.getFulfilledAt().format(DISPLAY_DATE)).build());
            }
            // FR-14: a teljesítés TÉNYLEGES dátuma a záró-szövegben (nem "a mai napon").
            String fulfilledDay = reservation.getFulfilledAt() != null
                    ? reservation.getFulfilledAt().format(DISPLAY_DATE) : "a teljesítés napján";
            lines.add(ReceiptData.ReceiptLineData.builder()
                    .label("Megjegyzés")
                    .value("A foglaló " + fulfilledDay
                            + " napon végrehajtott ügylet ellenértékébe beszámításra került.").build());
        }

        return ReceiptData.builder()
                .receiptNumber(receiptNumber)
                .receiptType("RESERVATION")
                .companyName(branch != null && branch.getCompany() != null ? branch.getCompany().getName() : "")
                .branchName(branch != null ? branch.getName() : "")
                .branchAddress(branch != null ? branch.getAddress() : "")
                .workerName(reservation.getWorker() != null ? reservation.getWorker().getName() : "")
                .date(receiptDate)
                .currencyCode(reservation.getCurrencyCode())
                .foreignAmount(reservation.getReservedAmount())
                .rate(reservation.getExchangeRate())
                .hufAmount(reservation.getDepositAmount())
                // Ügyfél-pillanatkép (FR-6..14)
                .customerName(customer != null ? customer.getName() : null)
                .customerIdNumber(customer != null ? customer.getDocumentNumber() : null)
                .customerDocType(customer != null && customer.getDocumentType() != null
                        ? customer.getDocumentType().name() : null)
                .customerAddress(customer != null ? customer.getAddress() : null)
                .customerMotherName(customer != null ? customer.getMotherName() : null)
                .customerBirthPlace(customer != null ? customer.getBirthPlace() : null)
                .customerBirthDate(customer != null && customer.getBirthDate() != null
                        ? customer.getBirthDate().format(DISPLAY_DATE) : null)
                .customerNationality(customer != null ? customer.getNationality() : null)
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
     * Tranzakciót betölti és multi-tenant ellenőrzést végez.
     *
     * Audit (2026-05-27, architect-mode IDOR): a receipt-PDF/ESC-POS végpontok nyers Long
     * transactionId-vel, companyId-ellenőrzés NÉLKÜL töltöttek → bármely CASHIER letölthette
     * más cég bizonylatát (ügyfél-PII + összegek) az id iterálásával (IDOR). A tenant-idegen
     * találatot 404-gyel (ResourceNotFoundException) utasítjuk el — nem 403, hogy az id-létezés
     * se szivárogjon ki. Mintaforrás: ReceiptService.getById / ReceiptSearchService.getDetail.
     */
    private Transaction loadOwnedTransaction(Long transactionId) {
        Transaction tx = transactionRepository.findById(transactionId)
                .orElseThrow(() -> new ResourceNotFoundException("Tranzakció nem található: " + transactionId));
        UUID currentCompanyId = SecurityUtils.getCurrentCompanyId();
        if (tx.getCompany() == null || !tx.getCompany().getId().equals(currentCompanyId)) {
            // Tenant-idegen → ugyanaz a válasz, mint a nem-létezőre (id-enumeráció ellen).
            throw new ResourceNotFoundException("Tranzakció nem található: " + transactionId);
        }
        return tx;
    }

    /**
     * Tranzakció ID alapján PDF bizonylat generálása
     */
    @Transactional(readOnly = true)
    public byte[] generatePdfForTransaction(Long transactionId) {
        Transaction tx = loadOwnedTransaction(transactionId);

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
        Transaction tx = loadOwnedTransaction(transactionId);

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

        // HIBA 2026-05-26 (#4): konverziónál a cél-összeg lefelé módosításából adódó
        // visszajáró forintot fel kell tüntetni a bizonylaton.
        if (tx.getReturnedHuf() != null && tx.getReturnedHuf().compareTo(BigDecimal.ZERO) > 0) {
            lines.add(ReceiptData.ReceiptLineData.builder()
                    .label("Visszajáró forint").value(tx.getReturnedHuf().toPlainString() + " Ft").build());
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
        // V229 (2026-05-15 HIBA #5+#7+#8): customer snapshot mezok mar leteznek a Transaction entity-n
        builder.customerAddress(tx.getCustomerAddress())
               .customerNationality(tx.getCustomerNationality())
               .customerMotherName(tx.getCustomerMotherName())
               .customerBirthPlace(tx.getCustomerBirthPlace())
               .customerBirthDate(tx.getCustomerBirthDate() != null
                       ? tx.getCustomerBirthDate().format(java.time.format.DateTimeFormatter.ofPattern("yyyy.MM.dd."))
                       : null)
               .customerDocType(tx.getCustomerDocumentType())
               .customerOnOwnBehalf(tx.getCustomerOnOwnBehalf())
               .customerActorName(tx.getCustomerActorName())
               // V235 (HIBA #17): actor teljes azonositasa, ha mas neveben jar el
               .customerActorBirthPlace(tx.getCustomerActorBirthPlace())
               .customerActorBirthDate(tx.getCustomerActorBirthDate() != null
                       ? tx.getCustomerActorBirthDate().format(java.time.format.DateTimeFormatter.ofPattern("yyyy.MM.dd."))
                       : null)
               .customerActorMotherName(tx.getCustomerActorMotherName())
               .customerActorNationality(tx.getCustomerActorNationality())
               .customerActorDocumentType(tx.getCustomerActorDocumentType())
               .customerActorDocumentNumber(tx.getCustomerActorDocumentNumber())
               .customerActorAddress(tx.getCustomerActorAddress());

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
        // V325 (Batch3-C): jogi személy + tényleges tulajdonosok blokk (legacy
        // BLOKNYOM Ugyfelnyomtatas jogi ág) — a megbízott/képviselő a customer*
        // mezőkben, a státusza a PEP-blokkban.
        applyLegalEntityBlockIfNeeded(builder, tx);
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
            String pepStatusText = isPep
                ? buildPepStatusText(tx.getCustomerPepKind())
                : "Nem közszereplő";
            builder.requiresPepDeclaration(true)
                   .pepStatusText(pepStatusText)
                   // Batch2-D (2026-06-12): strukturált PEP-adat az első személyű
                   // nyilatkozathoz (legacy KozszerepNyilatkozat) — a minőség már
                   // emberi szövegként megy a bizonylat-rétegnek.
                   .customerIsPep(isPep)
                   .customerPepKind(isPep ? pepKindFirstPersonText(tx.getCustomerPepKind()) : null);
            log.debug("PEP nyilatkozat blokk aktiválva, isPep={}, pepKind={}", isPep, tx.getCustomerPepKind());
        }
    }

    /**
     * V235 (2026-05-19 HIBA #15): a PEP minoseg szovege a bizonylatra.
     * Ha customerIsPep=TRUE de a pepKind null (regi tranzakcio, vagy a
     * frontend nem kuldte at), generikus "kiemelt kozszereplo" string.
     */
    private static String buildPepStatusText(String pepKind) {
        if (pepKind == null || pepKind.isBlank()) {
            return "Az ügyfél kiemelt közszereplő";
        }
        return switch (pepKind) {
            case "CSALADTAG"        -> "Az ügyfél kiemelt közszereplő családtagja";
            case "KOZELI_MUNKATARS" -> "Az ügyfél kiemelt közszereplő közeli munkatársa";
            case "KORMANYFO"        -> "Az ügyfél kiemelt közszereplő — kormányfő / miniszter / államtitkár";
            case "PARLAMENTI"       -> "Az ügyfél kiemelt közszereplő — országgyűlési / önkormányzati képviselő";
            case "NAV_VEZETO"       -> "Az ügyfél kiemelt közszereplő — NAV / állami vállalat felsővezetés";
            case "EGYEB"            -> "Az ügyfél kiemelt közszereplő — egyéb minőségben";
            default                 -> "Az ügyfél kiemelt közszereplő";
        };
    }

    /**
     * Batch2-D (2026-06-12): a PEP-minőség ELSŐ SZEMÉLYŰ alakja a jogcím-blokk
     * "Kiemelt közszereplő (vagyok), mint: ..." sorához (legacy BLOKNYOM
     * KozszerepNyilatkozat) — a kliens-printer pepKindReceiptText tükre.
     */
    private static String pepKindFirstPersonText(String pepKind) {
        if (pepKind == null || pepKind.isBlank()) {
            return null;
        }
        return switch (pepKind) {
            case "CSALADTAG"        -> "kiemelt közszereplő családtagja";
            case "KOZELI_MUNKATARS" -> "kiemelt közszereplő közeli munkatársa";
            case "KORMANYFO"        -> "kormányfő / miniszter / államtitkár";
            case "PARLAMENTI"       -> "országgyűlési / önkormányzati képviselő";
            case "NAV_VEZETO"       -> "NAV / állami vállalat felsővezetés";
            case "EGYEB"            -> "egyéb kiemelt közszereplő";
            default                 -> pepKind;
        };
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
     * V325 (Batch3-C): jogi személy blokk a tranzakció V325-ös mezőiből + a
     * tényleges tulajdonosok betöltése az altáblából (legacy UJTULAJOK).
     * A megbízott/képviselő neve a customer mezőből (a pultnál álló személy).
     */
    public void applyLegalEntityBlockIfNeeded(ReceiptData.ReceiptDataBuilder builder, Transaction tx) {
        if (!Boolean.TRUE.equals(tx.getIsLegalEntityCustomer())) {
            return;
        }
        builder.requiresLegalEntityBlock(true)
                .isLegalEntityCustomer(true)
                .legalEntityName(tx.getLegalEntityName())
                .legalEntitySeat(tx.getLegalEntitySeat())
                .legalEntityTaxNumber(tx.getLegalEntityTaxNumber())
                .legalDeedNumber(tx.getLegalDeedNumber())
                .legalRepresentativeName(tx.getCustomerName());
        if (tx.getId() != null && tx.getCompany() != null) {
            var owners = transactionBeneficialOwnerRepository
                    .findByCompanyIdAndTransactionIdOrderByOwnerNo(tx.getCompany().getId(), tx.getId());
            builder.beneficialOwners(owners.stream()
                    .map(o -> hu.puzzleir.valuta.dto.transaction.BeneficialOwnerDto.builder()
                            .name(o.getOwnerName())
                            .address(o.getOwnerAddress())
                            .birthPlace(o.getOwnerBirthPlace())
                            .birthDate(o.getOwnerBirthDate())
                            .nationality(o.getOwnerNationality())
                            .residenceAbroad(o.getOwnerResidenceAbroad())
                            .interestNature(o.getOwnerInterestNature())
                            .interestExtent(o.getOwnerInterestExtent())
                            .isPep(o.getOwnerIsPep())
                            .build())
                    .toList());
        }
        log.debug("V325: jogi személy blokk aktiválva: {}", tx.getLegalEntityName());
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
