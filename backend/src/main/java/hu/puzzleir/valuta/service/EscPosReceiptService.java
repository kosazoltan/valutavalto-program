package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.receipt.ReceiptData;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.entity.TransactionType;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.nio.charset.Charset;
import java.nio.charset.StandardCharsets;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Map;

/**
 * EPSON TM-T88V ESC/POS nyomtató motor.
 *
 * Legacy: BLOKNYOM.DLL — byte-szintű ESC/POS parancsok,
 * 5 bizonylattípus, címlet nyomtatás, jogi nyilatkozatok.
 *
 * ESC/POS parancs referencia:
 * - #27#64       → ESC @ — nyomtató inicializálás (reset)
 * - #14 / #20    → SO / DC4 — széles karakter on/off
 * - #27#97#n     → ESC a n — igazítás (0=bal, 1=közép, 2=jobb)
 * - #27#33#n     → ESC ! n — betűstílus (bit0=bold, bit4=dupla magasság, bit5=dupla szélesség)
 * - #29#86#65#3  → GS V A 3 — részleges vágás 3 sor előtolással
 * - #27#100#n    → ESC d n — n sor előtolás
 * - #27#74#n     → ESC J n — n pont előtolás
 *
 * EPSON TM-T88V specifikáció:
 * - 40 karakter/sor (normál mód)
 * - 20 karakter/sor (széles mód)
 * - Nyomtató port: LPT1 (PRINTER=0) vagy USB/Driver (PRINTER=1)
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class EscPosReceiptService {

    private final SystemParameterService systemParameterService;

    private static final int LINE_WIDTH = 40;
    private static final int WIDE_LINE_WIDTH = 20;
    private static final Charset CHARSET = Charset.forName("Cp852"); // Magyar karakterek

    // ESC/POS parancsok — EPSON TM-T88V
    private static final byte[] CMD_INIT     = {0x1B, 0x40};                    // ESC @ — reset
    private static final byte[] CMD_CENTER   = {0x1B, 0x61, 0x01};              // ESC a 1 — közép
    private static final byte[] CMD_LEFT     = {0x1B, 0x61, 0x00};              // ESC a 0 — bal
    private static final byte[] CMD_RIGHT    = {0x1B, 0x61, 0x02};              // ESC a 2 — jobb
    private static final byte[] CMD_BOLD_ON  = {0x1B, 0x45, 0x01};              // ESC E 1 — bold on
    private static final byte[] CMD_BOLD_OFF = {0x1B, 0x45, 0x00};              // ESC E 0 — bold off
    private static final byte[] CMD_WIDE_ON  = {0x0E};                          // SO — széles on
    private static final byte[] CMD_WIDE_OFF = {0x14};                          // DC4 — széles off
    private static final byte[] CMD_DOUBLE_H = {0x1B, 0x21, 0x10};              // ESC ! 16 — dupla magasság
    private static final byte[] CMD_NORMAL   = {0x1B, 0x21, 0x00};              // ESC ! 0 — normál
    private static final byte[] CMD_FEED_CUT = {0x1B, 0x64, 0x05, 0x1D, 0x56, 0x41, 0x03}; // 5 sor feed + vágás
    private static final byte[] CMD_FEED_3   = {0x1B, 0x64, 0x03};              // 3 sor feed
    private static final byte[] CMD_LF       = {0x0A};                          // Új sor

    private static final BigDecimal MEDIUM_THRESHOLD = new BigDecimal("100000");
    private static final BigDecimal HIGH_THRESHOLD = new BigDecimal("300000");

    private static final DateTimeFormatter DT_FORMAT = DateTimeFormatter.ofPattern("yyyy.MM.dd HH:mm:ss");
    private static final DateTimeFormatter DATE_FORMAT = DateTimeFormatter.ofPattern("yyyy.MM.dd");
    private static final DateTimeFormatter TIME_FORMAT = DateTimeFormatter.ofPattern("HH:mm:ss");

    // ============ BIZONYLAT TÍPUSOK ============

    /**
     * Vételi nyugta nyomtatás.
     * Legacy: VetelSzamlaNyomtatas — ügyfél elad nekünk valutát, mi fizetünk HUF-ot.
     */
    public byte[] generateBuyReceipt(ReceiptData data) {
        EscPosBuilder b = new EscPosBuilder();
        b.init();
        printReceiptHeader(b, data, "Valuta vétel", "EXCHANGE (PURCHASE)");
        printTransactionBody(b, data);
        printCustomerSection(b, data);
        printReceiptFooter(b, data);
        return b.build();
    }

    /**
     * Eladási nyugta nyomtatás.
     * Legacy: EladasSzamlaNyomtatas — mi eladunk valutát az ügyfélnek, ő fizet HUF-ot.
     */
    public byte[] generateSellReceipt(ReceiptData data) {
        EscPosBuilder b = new EscPosBuilder();
        b.init();
        printReceiptHeader(b, data, "Valuta eladás", "EXCHANGE (SELLING)");
        printTransactionBody(b, data);
        printCustomerSection(b, data);
        printReceiptFooter(b, data);
        return b.build();
    }

    /**
     * Átadási blokk nyomtatás.
     * Legacy: AtadBlokkNyomtatas — valuta átadás másik irodának.
     */
    public byte[] generateTransferOutReceipt(ReceiptData data) {
        EscPosBuilder b = new EscPosBuilder();
        b.init();
        printReceiptHeader(b, data, "Átadási bizonylat", "TRANSFER OUT");
        printTransactionBody(b, data);
        b.left();
        b.line("Cél pénztár: " + getLineValue(data, "Cél iroda"));
        b.separator();
        printReceiptFooter(b, data);
        return b.build();
    }

    /**
     * Átvételi blokk nyomtatás.
     * Legacy: AtveszBlokkNyomtatas — valuta átvétel másik irodától.
     */
    public byte[] generateTransferInReceipt(ReceiptData data) {
        EscPosBuilder b = new EscPosBuilder();
        b.init();
        printReceiptHeader(b, data, "Átvételi bizonylat", "TRANSFER IN");
        printTransactionBody(b, data);
        b.left();
        b.line("Forrás pénztár: " + getLineValue(data, "Forrás iroda"));
        b.separator();
        printReceiptFooter(b, data);
        return b.build();
    }

    /**
     * Sztornó blokk nyomtatás.
     * Legacy: StornoBlokknyomtatas — sztornó bizonylat.
     */
    public byte[] generateStornoReceipt(ReceiptData data) {
        EscPosBuilder b = new EscPosBuilder();
        b.init();
        printReceiptHeader(b, data, "*** Sztornó ***", "*** REVERSAL ***");
        printTransactionBody(b, data);
        b.left();
        b.line("Eredeti bizonylat: " + getLineValue(data, "Eredeti bizonylat"));
        String reason = getLineValue(data, "Sztornó ok");
        if (!reason.isEmpty()) {
            b.line("Sztornó ok: " + reason);
        }
        b.separator();
        printCustomerSection(b, data);
        printReceiptFooter(b, data);
        return b.build();
    }

    /**
     * Konverziós bizonylat nyomtatás.
     * Legacy: KonverzioBlokkNyomtatas — deviza→deviza átváltás bizonylat.
     */
    public byte[] generateConversionReceipt(ReceiptData data) {
        EscPosBuilder b = new EscPosBuilder();
        b.init();
        printReceiptHeader(b, data, "Konverziós bizonylat", "CONVERSION");
        printTransactionBody(b, data);
        // Konverzió-specifikus extra sorok (forrás/cél valuta)
        if (data.getLines() != null) {
            for (ReceiptData.ReceiptLineData line : data.getLines()) {
                b.line(line.getLabel() + ": " + line.getValue());
            }
        }
        b.separator();
        printCustomerSection(b, data);
        printReceiptFooter(b, data);
        return b.build();
    }

    // ============ NYILATKOZATOK ============

    /**
     * Jogcím nyilatkozat nyomtatása.
     * Legacy: Jogcimnyilatkozat — jogi nyilatkozat a deviza eredetéről.
     */
    public byte[] generateLegalDeclaration(ReceiptData data) {
        EscPosBuilder b = new EscPosBuilder();
        b.init();
        b.center();
        b.boldLine("JOGCÍM NYILATKOZAT");
        b.separator();
        b.left();
        b.line("Alulírott kijelentem, hogy az");
        b.line("általam átváltásra felajánlott");
        b.line("valuta jogszerűen van a");
        b.line("birtokomban.");
        b.emptyLine();
        b.line("Dátum: " + LocalDateTime.now().format(DATE_FORMAT));
        b.emptyLine();
        b.line(pad("", 30, '.'));
        b.center();
        b.line("aláírás");
        b.feedAndCut();
        return b.build();
    }

    /**
     * Deviza státusz nyomtatás.
     * Legacy: DevizsStatuszNyomtatas — a nagy tranzakcióknál kötelező.
     */
    public byte[] generateCurrencyStatusDeclaration(ReceiptData data) {
        EscPosBuilder b = new EscPosBuilder();
        b.init();
        b.center();
        b.boldLine("DEVIZA STÁTUSZ NYILATKOZAT");
        b.separator();
        b.left();
        b.line("Ügyfél: " + (data.getCustomerName() != null ? data.getCustomerName() : ""));
        b.line("Okmány: " + (data.getCustomerIdNumber() != null ? data.getCustomerIdNumber() : ""));
        b.emptyLine();
        b.line("Nyilatkozom, hogy magyarországi");
        b.line("tartózkodási státuszom:");
        b.line("  [ ] Belföldi");
        b.line("  [ ] Külföldi");
        b.emptyLine();
        b.line("Dátum: " + LocalDateTime.now().format(DATE_FORMAT));
        b.line(pad("", 30, '.'));
        b.center();
        b.line("aláírás");
        b.feedAndCut();
        return b.build();
    }

    /**
     * Közszereplő nyilatkozat nyomtatás.
     * Legacy: KozszerepNyilatkozat — PEP (Politically Exposed Person) nyilatkozat.
     */
    public byte[] generatePepDeclaration(ReceiptData data) {
        EscPosBuilder b = new EscPosBuilder();
        b.init();
        b.center();
        b.boldLine("KIEMELT KÖZSZEREPLŐ");
        b.boldLine("NYILATKOZAT");
        b.separator();
        b.left();
        b.line("Ügyfél: " + (data.getCustomerName() != null ? data.getCustomerName() : ""));
        b.emptyLine();
        b.line("Nyilatkozom, hogy");
        b.line("  [ ] NEM vagyok kiemelt");
        b.line("      közszereplő");
        b.line("  [ ] Kiemelt közszereplő");
        b.line("      VAGYOK");
        b.emptyLine();
        b.line("Dátum: " + LocalDateTime.now().format(DATE_FORMAT));
        b.line(pad("", 30, '.'));
        b.center();
        b.line("aláírás");
        b.feedAndCut();
        return b.build();
    }

    // ============ KEZELÉSI DÍJ BIZONYLAT ============

    /**
     * Kezelési díj bizonylat nyomtatás.
     * Legacy: KezKoltsegBlokkNyomtatas — külön bizonylat a kezelési díjról.
     * B-prefix, plombaszámmal.
     */
    public byte[] generateHandlingFeeReceipt(ReceiptData data) {
        EscPosBuilder b = new EscPosBuilder();
        b.init();
        printReceiptHeader(b, data, "Kezelési díjak bizonylata", "HANDLING FEE RECEIPT");
        b.left();
        b.line("Bizonylat: " + data.getReceiptNumber());
        b.line("Dátum:     " + (data.getDate() != null ? data.getDate().format(DT_FORMAT) : ""));
        b.line("Pénztáros: " + (data.getWorkerName() != null ? data.getWorkerName() : ""));
        b.separator();
        if (data.getHandlingFee() != null && data.getHandlingFee().compareTo(BigDecimal.ZERO) > 0) {
            b.boldLine("Kezelési díj: " + data.getHandlingFee().toPlainString() + " Ft");
        }
        if (data.getSealNumber() != null && !data.getSealNumber().isBlank()) {
            b.line("Plombaszám: " + data.getSealNumber());
        }
        b.separator();
        // Átadó-átvevő aláírás sorok
        b.emptyLine();
        b.line(padRight("...............", 20) + padRight("...............", 20));
        b.line(padRight("   Átadó", 20) + padRight("   Átvevő", 20));
        b.feedAndCut();
        return b.build();
    }

    // ============ PÉNZTÁR ÁLLÁS BIZONYLAT ============

    /**
     * Pillanatnyi pénztár állás nyomtatás.
     * Legacy: PenztarAllasNyomtatas — valutánkénti készlet kimutatás.
     *
     * @param data alap bizonylat adatok (cég, iroda, pénztáros)
     * @param currencyBalances valutanem → összeg map
     * @param currencyHufValues valutanem → Ft érték map
     */
    public byte[] generateCashStatusReceipt(ReceiptData data,
                                             Map<String, BigDecimal> currencyBalances,
                                             Map<String, BigDecimal> currencyHufValues) {
        EscPosBuilder b = new EscPosBuilder();
        b.init();
        printReceiptHeader(b, data, "Pénztár állás", "CASH STATUS");
        b.left();
        b.line("Dátum: " + (data.getDate() != null ? data.getDate().format(DT_FORMAT) : ""));
        b.line("Pénztáros: " + (data.getWorkerName() != null ? data.getWorkerName() : ""));
        b.separator();
        b.boldLine(padRight("Valuta", 8) + padLeft("Összeg", 14) + padLeft("Ft érték", 14));
        b.separator();
        BigDecimal totalHuf = BigDecimal.ZERO;
        for (Map.Entry<String, BigDecimal> entry : currencyBalances.entrySet()) {
            String currency = entry.getKey();
            BigDecimal amount = entry.getValue();
            BigDecimal hufValue = currencyHufValues.getOrDefault(currency, BigDecimal.ZERO);
            totalHuf = totalHuf.add(hufValue);
            b.line(padRight(currency, 8) + padLeft(amount.toPlainString(), 14) + padLeft(hufValue.toPlainString(), 14));
        }
        b.separator();
        b.boldLine(padRight("Összesen:", 22) + padLeft(totalHuf.toPlainString() + " Ft", 14));
        b.separator();
        b.emptyLine();
        b.line(padRight("...............", 20) + padRight("...............", 20));
        b.line(padRight("  Pénztáros", 20) + padRight("  Ellenőr", 20));
        b.feedAndCut();
        return b.build();
    }

    // ============ ÉRTÉKTÁRI ZÁRÁS BIZONYLAT ============

    /**
     * Értéktári zárás bizonylat nyomtatás.
     * Legacy: ErtektarZarasNyomtatas — checklista + készlet kimutatás.
     *
     * @param data alap bizonylat adatok
     * @param checklistItems checklista tételek [cím, státusz] párok
     * @param currencyBalances valutanem → összeg map
     */
    public byte[] generateVaultClosingReceipt(ReceiptData data,
                                               List<String[]> checklistItems,
                                               Map<String, BigDecimal> currencyBalances) {
        EscPosBuilder b = new EscPosBuilder();
        b.init();
        printReceiptHeader(b, data, "Értéktári zárás", "VAULT CLOSING");
        b.left();
        b.line("Dátum:     " + (data.getDate() != null ? data.getDate().format(DT_FORMAT) : ""));
        b.line("Értéktáros:" + (data.getWorkerName() != null ? data.getWorkerName() : ""));
        b.separator();

        // Checklista
        if (checklistItems != null && !checklistItems.isEmpty()) {
            b.boldLine("ELLENŐRZŐ CHECKLISTA:");
            for (int i = 0; i < checklistItems.size(); i++) {
                String[] item = checklistItems.get(i);
                String status = item.length > 1 ? item[1] : "[ ]";
                b.line(padRight((i + 1) + ". " + item[0], 34) + padLeft(status, 6));
            }
            b.separator();
        }

        // Készlet kimutatás
        if (currencyBalances != null && !currencyBalances.isEmpty()) {
            b.boldLine("KÉSZLET KIMUTATÁS:");
            for (Map.Entry<String, BigDecimal> entry : currencyBalances.entrySet()) {
                b.line(padRight(entry.getKey(), 8) + padLeft(entry.getValue().toPlainString(), 20));
            }
            b.separator();
        }

        if (data.getSealNumber() != null && !data.getSealNumber().isBlank()) {
            b.line("Plombaszám: " + data.getSealNumber());
        }

        b.emptyLine();
        b.line(padRight("...............", 20) + padRight("...............", 20));
        b.line(padRight("  Értéktáros", 20) + padRight("  Ellenőr", 20));
        b.feedAndCut();
        return b.build();
    }

    // ============ KKTG ÁTADÁS-ÁTVÉTELI BIZONYLAT ============

    /**
     * KKTG (kezelési költség) átadás-átvétel bizonylat.
     * Legacy: KktgAtadasBlokkNyomtatas — plombaszámos belső átadás.
     */
    public byte[] generateKktgTransferReceipt(ReceiptData data) {
        EscPosBuilder b = new EscPosBuilder();
        b.init();
        printReceiptHeader(b, data, "KKTG átadás-átvétel", "KKTG TRANSFER");
        b.left();
        b.line("Bizonylat: " + data.getReceiptNumber());
        b.line("Dátum:     " + (data.getDate() != null ? data.getDate().format(DT_FORMAT) : ""));
        b.separator();
        if (data.getHufAmount() != null) {
            b.boldLine("Összeg: " + data.getHufAmount().toPlainString() + " Ft");
        }
        if (data.getSealNumber() != null && !data.getSealNumber().isBlank()) {
            b.line("Plombaszám: " + data.getSealNumber());
        }
        b.separator();

        // Extra sorok (forrás/cél iroda stb.)
        if (data.getLines() != null) {
            for (ReceiptData.ReceiptLineData line : data.getLines()) {
                b.line(line.getLabel() + ": " + line.getValue());
            }
        }

        b.emptyLine();
        b.line(padRight("...............", 20) + padRight("...............", 20));
        b.line(padRight("   Átadó", 20) + padRight("   Átvevő", 20));
        b.emptyLine();
        b.line("Szállító: ..............................");
        b.feedAndCut();
        return b.build();
    }

    // ============ ÁRFOLYAM MÓDOSÍTÁS BLOKK ============

    /**
     * Árfolyam módosítás nyomtatás.
     * Legacy: ArfModNyomtatas — ha kedvezményes árfolyamot alkalmaztak.
     */
    public byte[] generateRateModificationReceipt(ReceiptData data, BigDecimal originalRate, BigDecimal modifiedRate) {
        EscPosBuilder b = new EscPosBuilder();
        b.init();
        b.center();
        b.boldLine("ÁRFOLYAM MÓDOSÍTÁS");
        b.separator();
        b.left();
        b.line("Bizonylat: " + data.getReceiptNumber());
        b.line("Valuta:    " + data.getCurrencyCode());
        b.line("Eredeti:   " + originalRate.toPlainString());
        b.line("Módosított:" + modifiedRate.toPlainString());
        b.separator();
        b.line("Dátum: " + LocalDateTime.now().format(DT_FORMAT));
        b.feedAndCut();
        return b.build();
    }

    // ============ CÍMLET NYOMTATÁS ============

    /**
     * Címlet nyomtatás.
     * Legacy: CimletNyomtatas — napi címletleltár nyomtatás a blokk nyomtatóra.
     *
     * @param branchName iroda neve
     * @param date dátum
     * @param denominations címlet → darabszám map
     * @param totals valuta → összeg map
     */
    public byte[] generateDenominationPrint(String branchName, String date,
                                             Map<String, Map<String, Integer>> denominations,
                                             Map<String, BigDecimal> totals) {
        EscPosBuilder b = new EscPosBuilder();
        b.init();
        b.center();
        b.boldLine("CÍMLETLELTÁR");
        b.line(branchName);
        b.line(date);
        b.separator();

        for (Map.Entry<String, Map<String, Integer>> currEntry : denominations.entrySet()) {
            String currency = currEntry.getKey();
            Map<String, Integer> denoms = currEntry.getValue();

            b.left();
            b.boldLine(currency + ":");
            for (Map.Entry<String, Integer> denom : denoms.entrySet()) {
                String denomName = denom.getKey();
                int count = denom.getValue();
                if (count > 0) {
                    b.line(padRight(denomName, 20) + padLeft(String.valueOf(count), 6) + " db");
                }
            }
            BigDecimal total = totals.getOrDefault(currency, BigDecimal.ZERO);
            b.line(padRight("Összesen:", 20) + padLeft(total.toPlainString(), 10));
            b.separator();
        }

        b.feedAndCut();
        return b.build();
    }

    // ============ DEKÁD NYOMTATÁS ============

    /**
     * Dekád zárás nyomtatás.
     * Legacy: DekadNyomtatas — dekád forgalom összesítő blokk.
     */
    public byte[] generateDecadeClosingPrint(String branchCode, String branchName,
                                              String branchAddress, int year, int month,
                                              int decade, String periodStart, String periodEnd,
                                              List<String[]> transactionRows,
                                              long totalRevenue, long totalExpense,
                                              long openingBalance, long closingBalance) {
        EscPosBuilder b = new EscPosBuilder();
        b.init();
        b.center();
        b.line(branchCode + ". PÉNZTÁR");
        b.line(branchName);
        b.line(branchAddress);
        b.separator();

        String title = year + " " + getMonthName(month) + " HAVI " + decade + ". DEKÁDZÁRÁS";
        b.center();
        b.boldLine(title);
        b.line(periodStart + " - " + periodEnd);
        b.separator();

        b.left();
        b.line("Sor Np   Bizony.  Ft.átvétel   Ft.átadás");
        b.separator();

        for (String[] row : transactionRows) {
            b.line(row[0]); // pre-formatted row
        }

        b.separator();
        b.line("Dekád forgalom:  " + formatHuf(totalRevenue) + " " + formatHuf(totalExpense));
        b.line("  Nyitó forint:  " + formatHuf(openingBalance) + " ###########");
        b.line("   Záró forint:  ########### " + formatHuf(closingBalance));

        long total = totalRevenue + openingBalance;
        b.line(" Összes forint:  " + formatHuf(total) + " " + formatHuf(total));
        b.separator();

        b.emptyLine();
        b.line(LocalDateTime.now().format(DATE_FORMAT) + "     " + pad("", 24, '.'));
        b.line(pad("", 25, ' ') + "pénztáros");
        b.feedAndCut();

        return b.build();
    }

    // ============ SEGÉD METÓDUSOK ============

    private void printReceiptHeader(EscPosBuilder b, ReceiptData data, String subtitleHu, String subtitleEn) {
        b.center();
        b.wideOn();
        b.boldLine("NYUGTA");
        b.wideOff();
        b.line(data.getCompanyFullName() != null ? data.getCompanyFullName()
                : (data.getCompanyName() != null ? data.getCompanyName() : ""));
        if (data.getBranchName() != null && !data.getBranchName().isBlank()) {
            b.line(data.getBranchName());
        }
        if (data.getBranchAddress() != null && !data.getBranchAddress().isBlank()) {
            b.line(data.getBranchAddress());
        }
        String phone = data.getBranchPhone() != null && !data.getBranchPhone().isBlank()
                ? data.getBranchPhone()
                : data.getCompanyPhone();
        if (phone != null && !phone.isBlank()) {
            b.line("Telefon: " + phone);
        }
        if (data.getCompanyTaxNumber() != null && !data.getCompanyTaxNumber().isBlank()) {
            b.line("Adószám: " + data.getCompanyTaxNumber());
        }
        b.boldLine(subtitleHu);
        b.line(subtitleEn);
        b.separator();
    }

    private void printTransactionBody(EscPosBuilder b, ReceiptData data) {
        b.left();
        b.line(padRight("Sorszám (INVOICE NR)", 22) + ": " + data.getReceiptNumber());
        if (data.getDate() != null) {
            b.line(padRight("Dátum   (DATE)", 22) + ": " + data.getDate().format(DATE_FORMAT));
            b.line(padRight("Idő     (TIME)", 22) + ": " + data.getDate().format(TIME_FORMAT));
        }
        if (data.getNavReceiptNumber() != null && !data.getNavReceiptNumber().isBlank()) {
            b.line("(Nyugtaszám: " + data.getNavReceiptNumber() + ")");
        }
        b.separator();

        // ÁFA-mentességi szöveg (a PDF mintákon a valutatáblázat ELŐTT van)
        if (data.getVatExemptionText() != null && !data.getVatExemptionText().isBlank()) {
            for (String vatLine : data.getVatExemptionText().split("\n")) {
                b.line(vatLine);
            }
        }
        b.separator();

        // Valutatáblázat fejléc
        if (data.getCurrencyCode() != null) {
            b.line(padRight("V.nem", 7) + padRight("Árfolyam", 10) + padRight("B.jegy", 10) + padLeft("Forint", 10));
            b.line(padRight("CURR.", 7) + padRight("RATE", 10) + padRight("CASH", 10) + padLeft("VALUE", 10));
            b.separator();

            String curr = data.getCurrencyCode() != null ? data.getCurrencyCode() : "";
            String rate = data.getRate() != null ? data.getRate().toPlainString() : "";
            String amount = data.getForeignAmount() != null ? data.getForeignAmount().toPlainString() : "";
            String huf = data.getHufAmount() != null ? data.getHufAmount().toPlainString() : "";
            b.line(padRight(curr, 7) + padRight(rate, 10) + padRight(amount, 10) + padLeft(huf, 10));
            b.separator();
        }

        // Kerekítés + Nettó + Kezelési költség + Kifizetve
        BigDecimal roundingDiff = data.getRoundingDiff();
        String roundingStr = roundingDiff != null ? roundingDiff.toPlainString() : "0";
        b.line(padRight("Kerekítés (ROUNDING)", 25) + ": " + padLeft(roundingStr, 10));

        BigDecimal netTotal = data.getRoundedHufAmount() != null ? data.getRoundedHufAmount()
                : (data.getHufAmount() != null ? data.getHufAmount() : BigDecimal.ZERO);
        b.line(padRight("Nettó Ft  (SUM TOTAL)", 25) + ": " + padLeft(netTotal.toPlainString(), 10));

        BigDecimal fee = data.getHandlingFee() != null ? data.getHandlingFee() : BigDecimal.ZERO;
        b.line(padRight("Kez. kltsg (HANDLING FEE)", 25) + ": " + padLeft(fee.toPlainString(), 10));

        BigDecimal paid = netTotal.add(fee);
        b.boldLine(padRight("Kifizetve:(PAID):", 25) + "  " + padLeft(paid.toPlainString(), 10));
        b.separator();
    }

    private void printCustomerSection(EscPosBuilder b, ReceiptData data) {
        BigDecimal absHuf = data.getHufAmount() != null ? data.getHufAmount().abs() : BigDecimal.ZERO;

        b.left();
        b.center();
        b.line("--- ügyfél adatai ---");
        b.left();

        if (absHuf.compareTo(MEDIUM_THRESHOLD) >= 0) {
            // 100k+ : alap ügyfél adatok
            if (data.getCustomerName() != null && !data.getCustomerName().isBlank()) {
                b.line("Neve: " + data.getCustomerName());
            }
            if (data.getCustomerMotherName() != null && !data.getCustomerMotherName().isBlank()) {
                b.line("Anyja neve: " + data.getCustomerMotherName());
            }
            if (data.getCustomerBirthPlace() != null && !data.getCustomerBirthPlace().isBlank()) {
                b.line("Szül-i hely: " + data.getCustomerBirthPlace());
            }
            if (data.getCustomerBirthDate() != null && !data.getCustomerBirthDate().isBlank()) {
                b.line("Szül-i idő: " + data.getCustomerBirthDate());
            }

            if (absHuf.compareTo(HIGH_THRESHOLD) >= 0) {
                // 300k+ : teljes ügyfél adatok
                if (data.getCustomerAddress() != null && !data.getCustomerAddress().isBlank()) {
                    b.line("Lakcím(ADDRESS): " + data.getCustomerAddress());
                }
                if (data.getCustomerDocType() != null && !data.getCustomerDocType().isBlank()) {
                    b.line("DOC TYPE: " + data.getCustomerDocType());
                }
                if (data.getCustomerIdNumber() != null && !data.getCustomerIdNumber().isBlank()) {
                    b.line("NR.: " + data.getCustomerIdNumber());
                }
                // PEP státusz
                if (Boolean.TRUE.equals(data.getRequiresPepDeclaration())) {
                    b.line(data.getPepStatusText() != null ? data.getPepStatusText() : "Az ügyfél nem közszereplő");
                }
            }
        }
        // < 100k: nincs ügyfél adat, csak a fejléc

        b.emptyLine();
        b.line("Az ügyletet készpénzben teljesítjük");
        // Devizastátusz megjelenítés: NULL → "—" (ismeretlen, régi adatokra), FOREIGN/DOMESTIC explicit
        String statusText;
        if (data.getForeignStatus() == null) {
            statusText = "—";
        } else if ("FOREIGN".equalsIgnoreCase(data.getForeignStatus())) {
            statusText = "Külföldi";
        } else {
            statusText = "Belföldi";
        }
        b.line("Deviza-státusz: " + statusText);
        b.separator();
    }

    /**
     * Batch2-D: orosz EUR-vásárlási nyilatkozat triggere — a legacy EzoroszUgyfel
     * (BLOKNYOM Unit2.pas:1929-1938) tükre: EUR eladás (az ügyfél EUR-t VESZ)
     * + orosz állampolgár. (A 300k-s küszöböt a hívó ellenőrzi.)
     * A kliens-printer isRussianEurPurchase párja.
     */
    static boolean isRussianEurPurchase(ReceiptData data) {
        if (!"SELL".equalsIgnoreCase(data.getReceiptType())) {
            return false;
        }
        if (!"EUR".equalsIgnoreCase(data.getCurrencyCode())) {
            return false;
        }
        String nat = data.getCustomerNationality() != null
                ? data.getCustomerNationality().trim().toLowerCase() : "";
        return nat.equals("ru") || nat.equals("rus")
                || nat.contains("orosz") || nat.contains("russia");
    }

    private void printReceiptFooter(EscPosBuilder b, ReceiptData data) {
        BigDecimal absHuf = data.getHufAmount() != null ? data.getHufAmount().abs() : BigDecimal.ZERO;
        boolean isHighValue = absHuf.compareTo(HIGH_THRESHOLD) >= 0;

        // 300k+ felett: bankpartner + marketing szöveg (SystemParameter-ből)
        if (isHighValue) {
            String bankName = getReceiptText("RECEIPT_BANK_PARTNER_NAME", "Raiffeisen Bank Zrt.");
            String bankSub = getReceiptText("RECEIPT_BANK_PARTNER_SUBTITLE", "KIEMELT KÖZVETÍTŐJE");
            b.center();
            b.line(bankName);
            b.line(bankSub);
            b.separator();
            String marketingTitle = getReceiptText("RECEIPT_MARKETING_TITLE", "EXCLUSIVE CHANGE");
            String marketingSlogan = getReceiptText("RECEIPT_MARKETING_SLOGAN", "KEDVEZŐBB,\nGYORSABB,\nBIZTONSÁGOSABB");
            b.center();
            b.boldLine(marketingTitle);
            for (String sloganLine : marketingSlogan.split("\\n")) {
                b.line(sloganLine.trim());
            }
            b.separator();
        }

        // Jogcím nyilatkozat — 300k+ Ft tranzakciónál kötelező
        if (isHighValue && Boolean.TRUE.equals(data.getRequiresSourceDeclaration())) {
            b.left();
            b.boldLine("JOGCÍM NYILATKOZAT");
            b.line("Büntetőjogi felelősségem tudatá-");
            b.line("ban nyilatkozom, hogy a fenti");
            b.line("tranzakciót");
            // V229 (HIBA #8): elsobbseg a customerOnOwnBehalf flag-en (uj rendszer)
            // Fallback a regi isLegalEntityCustomer + legalEntityName-re.
            boolean isOnOwnBehalfSet = data.getCustomerOnOwnBehalf() != null;
            if (isOnOwnBehalfSet && Boolean.FALSE.equals(data.getCustomerOnOwnBehalf())
                    && data.getCustomerActorName() != null && !data.getCustomerActorName().isBlank()) {
                b.line(data.getCustomerActorName());
                b.line("nevében bonyolítom,");
                // V235 (Codex P2 PR #695): Pmt. tv. 6.§ (2) — a kepviselt felre is
                // teljes azonositast kell vegezni. A bizonylatra az actor szul.helyet,
                // szul.idejet, anyja nevet, okmany szamat es lakcimet is ki kell irni.
                b.line("Kepviselt fel adatai:");
                if (data.getCustomerActorBirthPlace() != null && !data.getCustomerActorBirthPlace().isBlank()) {
                    b.line("  szul.hely: " + data.getCustomerActorBirthPlace());
                }
                if (data.getCustomerActorBirthDate() != null && !data.getCustomerActorBirthDate().isBlank()) {
                    b.line("  szul.ido: " + data.getCustomerActorBirthDate());
                }
                if (data.getCustomerActorMotherName() != null && !data.getCustomerActorMotherName().isBlank()) {
                    b.line("  anyja: " + data.getCustomerActorMotherName());
                }
                if (data.getCustomerActorNationality() != null && !data.getCustomerActorNationality().isBlank()) {
                    b.line("  allampolg.: " + data.getCustomerActorNationality());
                }
                if (data.getCustomerActorDocumentNumber() != null && !data.getCustomerActorDocumentNumber().isBlank()) {
                    String docType = data.getCustomerActorDocumentType() != null
                            ? data.getCustomerActorDocumentType() : "okmany";
                    b.line("  " + docType + ": " + data.getCustomerActorDocumentNumber());
                }
                if (data.getCustomerActorAddress() != null && !data.getCustomerActorAddress().isBlank()) {
                    b.line("  lakcim: " + data.getCustomerActorAddress());
                }
            } else if (isOnOwnBehalfSet && Boolean.TRUE.equals(data.getCustomerOnOwnBehalf())) {
                b.line("saját nevemben bonyolítom,");
            } else if (Boolean.TRUE.equals(data.getIsLegalEntityCustomer())
                    && data.getLegalEntityName() != null) {
                b.line(data.getLegalEntityName());
                b.line("nevében bonyolítom,");
            } else {
                b.line("saját nevemben bonyolítom,");
            }
            // Batch2-D (2026-06-12): a legacy Jogcimnyilatkozat (BLOKNYOM Unit2.pas:
            // 1437-1493) kötelező elemei a saját neves/képviselt ág UTÁN — első
            // személyű PEP-nyilatkozat, 5 munkanapos adatváltozás-klauzula, forrás,
            // dedikált ügyfél-aláírás. A kliens-printer buildSourceDeclarationLines
            // tükre (sorrend és szöveg azonos).
            b.emptyLine();
            if (data.getCustomerIsPep() != null) {
                if (Boolean.TRUE.equals(data.getCustomerIsPep())) {
                    b.line("Kiemelt közszereplő (vagyok),");
                    if (data.getCustomerPepKind() != null && !data.getCustomerPepKind().isBlank()) {
                        b.line("mint: " + data.getCustomerPepKind().trim());
                    }
                } else {
                    b.line("Nem (vagyok) kiemelt közszereplő.");
                }
                b.emptyLine();
            }
            b.line("Tudomásom van arról, hogy 5 (öt)");
            b.line("munkanapon belül köteles vagyok");
            b.line("bejelenteni a szolgáltatónak a fenti");
            b.line("adatokban, vagy a saját adataimban");
            b.line("bekövetkező esetleges változásokat,");
            b.line("és e kötelezettség elmulasztásából");
            b.line("eredő kár engem terhel.");
            if (data.getSourceOfFunds() != null && !data.getSourceOfFunds().isBlank()) {
                b.emptyLine();
                b.line("Pénzeszközöm forrása:");
                String src = data.getSourceOfFunds().trim();
                int maxLen = LINE_WIDTH - 2;
                for (int i = 0; i < src.length(); i += maxLen) {
                    b.line("  " + src.substring(i, Math.min(i + maxLen, src.length())));
                }
            }
            b.emptyLine();
            b.line(".....................................");
            b.line("          ügyfél aláírása");
            b.separator();
        }

        // Batch2-D: orosz állampolgár EUR-vásárlása 300k+ felett → kétnyelvű
        // személyes-használat nyilatkozat (legacy OroszNyilatkozat, BLOKNYOM
        // Unit2.pas:1929-1963 tükre; trigger: SELL + EUR + orosz + 300k+).
        if (isHighValue && isRussianEurPurchase(data)) {
            b.left();
            b.line("----------------------------------------");
            b.center();
            b.line("NYILATKOZAT/DECLARATION");
            b.left();
            b.line("----------------------------------------");
            b.emptyLine();
            String name = data.getCustomerName() != null ? data.getCustomerName().trim() : "";
            b.line("Alulírott " + name.substring(0, Math.min(30, name.length())));
            b.line("kijelentem, hogy az általam vásárolt EUR");
            b.line("valutát személyes használatra váltottam.");
            b.emptyLine();
            b.line("/I declare that the just purchased");
            b.line("EUR currency is for my personal usage.");
            b.emptyLine();
            b.line(".....................................");
            b.line("  ügyfél aláírása/signature of buyer");
            b.separator();
        }

        // Pénztáros + aláírás sorok
        b.left();
        if (data.getWorkerName() != null && !data.getWorkerName().isBlank()) {
            b.line("Pénztáros: " + data.getWorkerName());
        }
        b.emptyLine();
        b.line(padRight("...............", 20) + padRight("...............", 20));
        b.line(padRight("  Pénztáros", 20) + padRight("    Ügyfél", 20));
        b.emptyLine();

        // QR kód
        if (data.getQrCode() != null && !data.getQrCode().isBlank()) {
            b.left();
            b.line("QR: " + data.getQrCode());
        }

        b.emptyLine();
        b.center();
        String footerThanks = getReceiptText("RECEIPT_FOOTER_THANKS", "Köszönjük, hogy minket választott!");
        b.line(footerThanks);
        b.emptyLine();
        b.left();
        String footerLegal = getReceiptText("RECEIPT_FOOTER_LEGAL",
                "A bizonylat a pénzmosás elleni törvény alapján nem helyettesíti a számlát.");
        for (String legalLine : wrapText(footerLegal, LINE_WIDTH)) {
            b.line(legalLine);
        }
        b.feedAndCut();
    }

    private String getReceiptText(String key, String defaultValue) {
        try {
            return systemParameterService.getValue(key, defaultValue);
        } catch (Exception e) {
            return defaultValue;
        }
    }

    private List<String> wrapText(String text, int maxWidth) {
        List<String> lines = new java.util.ArrayList<>();
        for (String paragraph : text.split("\\n")) {
            String remaining = paragraph.trim();
            while (remaining.length() > maxWidth) {
                int breakAt = remaining.lastIndexOf(' ', maxWidth);
                if (breakAt <= 0) breakAt = maxWidth;
                lines.add(remaining.substring(0, breakAt));
                remaining = remaining.substring(breakAt).trim();
            }
            if (!remaining.isEmpty()) lines.add(remaining);
        }
        return lines;
    }

    private String getLineValue(ReceiptData data, String label) {
        if (data.getLines() == null) return "";
        return data.getLines().stream()
            .filter(l -> label.equals(l.getLabel()))
            .map(ReceiptData.ReceiptLineData::getValue)
            .findFirst().orElse("");
    }

    /**
     * HUF összeg formázás — 1.234.567 Ft formátum.
     * Legacy: Form11() / FtFormalo()
     */
    private String formatHuf(long amount) {
        if (amount == 0) return "     -     ";
        String s = String.valueOf(Math.abs(amount));
        StringBuilder formatted = new StringBuilder();
        int len = s.length();
        for (int i = 0; i < len; i++) {
            if (i > 0 && (len - i) % 3 == 0) formatted.append('.');
            formatted.append(s.charAt(i));
        }
        if (amount < 0) formatted.insert(0, '-');
        String result = formatted.toString();
        while (result.length() < 11) result = " " + result;
        return result;
    }

    private String getMonthName(int month) {
        String[] names = {"JANUÁR", "FEBRUÁR", "MÁRCIUS", "ÁPRILIS", "MÁJUS", "JÚNIUS",
            "JÚLIUS", "AUGUSZTUS", "SZEPTEMBER", "OKTÓBER", "NOVEMBER", "DECEMBER"};
        return (month >= 1 && month <= 12) ? names[month - 1] : "???";
    }

    private String pad(String s, int width, char c) {
        StringBuilder sb = new StringBuilder(s);
        while (sb.length() < width) sb.append(c);
        return sb.toString();
    }

    private String padLeft(String s, int width) {
        while (s.length() < width) s = " " + s;
        return s;
    }

    private String padRight(String s, int width) {
        StringBuilder sb = new StringBuilder(s);
        while (sb.length() < width) sb.append(' ');
        return sb.toString();
    }

    // ============ ESC/POS BUILDER ============

    /**
     * Belső ESC/POS byte-stream builder.
     * A BLOKNYOM.DLL logikáját tükrözi: parancsok + szöveg byte-sorozatba.
     */
    public static class EscPosBuilder {
        private final java.io.ByteArrayOutputStream stream = new java.io.ByteArrayOutputStream(4096);

        public void init() {
            write(CMD_INIT);
        }

        public void center() { write(CMD_CENTER); }
        public void left() { write(CMD_LEFT); }
        public void right() { write(CMD_RIGHT); }
        public void wideOn() { write(CMD_WIDE_ON); }
        public void wideOff() { write(CMD_WIDE_OFF); }

        public void line(String text) {
            write(text.getBytes(Charset.forName("Cp852")));
            write(CMD_LF);
        }

        public void boldLine(String text) {
            write(CMD_BOLD_ON);
            line(text);
            write(CMD_BOLD_OFF);
        }

        public void separator() {
            line("----------------------------------------");
        }

        public void emptyLine() {
            write(CMD_LF);
        }

        public void feedAndCut() {
            write(CMD_FEED_CUT);
        }

        public void feed(int lines) {
            for (int i = 0; i < lines; i++) write(CMD_LF);
        }

        private void write(byte[] data) {
            stream.write(data, 0, data.length);
        }

        public byte[] build() {
            return stream.toByteArray();
        }
    }
}
