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

    private static final DateTimeFormatter DT_FORMAT = DateTimeFormatter.ofPattern("yyyy.MM.dd HH:mm:ss");
    private static final DateTimeFormatter DATE_FORMAT = DateTimeFormatter.ofPattern("yyyy.MM.dd");

    // ============ BIZONYLAT TÍPUSOK ============

    /**
     * Vételi számla nyomtatás.
     * Legacy: VetelSzamlaNyomtatas — ügyfél elad nekünk valutát, mi fizetünk HUF-ot.
     */
    public byte[] generateBuyReceipt(ReceiptData data) {
        EscPosBuilder b = new EscPosBuilder();
        b.init();
        printReceiptHeader(b, data, "VÉTELI BIZONYLAT");
        printTransactionBody(b, data);
        printCustomerSection(b, data);
        printReceiptFooter(b, data);
        return b.build();
    }

    /**
     * Eladási számla nyomtatás.
     * Legacy: EladasSzamlaNyomtatas — mi eladunk valutát az ügyfélnek, ő fizet HUF-ot.
     */
    public byte[] generateSellReceipt(ReceiptData data) {
        EscPosBuilder b = new EscPosBuilder();
        b.init();
        printReceiptHeader(b, data, "ELADÁSI BIZONYLAT");
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
        printReceiptHeader(b, data, "ÁTADÁSI BIZONYLAT");
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
        printReceiptHeader(b, data, "ÁTVÉTELI BIZONYLAT");
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
        printReceiptHeader(b, data, "*** SZTORNÓ ***");
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
        printReceiptHeader(b, data, "KONVERZIÓS BIZONYLAT");
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
        printReceiptHeader(b, data, "KEZELÉSI DÍJAK BIZONYLATA");
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
        printReceiptHeader(b, data, "PÉNZTÁR ÁLLÁS");
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
        printReceiptHeader(b, data, "ÉRTÉKTÁRI ZÁRÁS");
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
        printReceiptHeader(b, data, "KKTG ÁTADÁS-ÁTVÉTEL");
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

    private void printReceiptHeader(EscPosBuilder b, ReceiptData data, String title) {
        b.center();
        b.wideOn();
        b.line(data.getCompanyFullName() != null ? data.getCompanyFullName()
                : (data.getCompanyName() != null ? data.getCompanyName() : ""));
        b.wideOff();
        if (data.getBranchName() != null && !data.getBranchName().isBlank()) {
            b.line(data.getBranchName());
        }
        if (data.getBranchAddress() != null && !data.getBranchAddress().isBlank()) {
            b.line(data.getBranchAddress());
        }
        if (data.getBranchPhone() != null && !data.getBranchPhone().isBlank()) {
            b.line("Tel: " + data.getBranchPhone());
        } else if (data.getCompanyPhone() != null && !data.getCompanyPhone().isBlank()) {
            b.line("Tel: " + data.getCompanyPhone());
        }
        if (data.getCompanyTaxNumber() != null && !data.getCompanyTaxNumber().isBlank()) {
            b.line("Adószám: " + data.getCompanyTaxNumber());
        }
        if (data.getBranchCode() != null && !data.getBranchCode().isBlank()) {
            b.line("Pénztár: " + data.getBranchCode());
        }
        b.separator();
        b.boldLine(title);
        b.separator();
    }

    private void printTransactionBody(EscPosBuilder b, ReceiptData data) {
        b.left();
        b.line("Bizonylat: " + data.getReceiptNumber());
        b.line("Dátum:     " + (data.getDate() != null ? data.getDate().format(DT_FORMAT) : ""));
        b.line("Pénztáros: " + (data.getWorkerName() != null ? data.getWorkerName() : ""));
        b.separator();

        if (data.getCurrencyCode() != null) {
            b.line("Valuta:    " + data.getCurrencyCode());
            b.line("Összeg:    " + (data.getForeignAmount() != null ? data.getForeignAmount().toPlainString() : ""));
            b.line("Árfolyam:  " + (data.getRate() != null ? data.getRate().toPlainString() : ""));
            b.boldLine("HUF:       " + (data.getHufAmount() != null ? data.getHufAmount().toPlainString() : "") + " Ft");
        }

        // Kerekítés és fizetendő összeg
        if (data.getRoundedHufAmount() != null && data.getRoundingDiff() != null
                && data.getRoundingDiff().compareTo(BigDecimal.ZERO) != 0) {
            b.line("Kerekítés: " + data.getRoundingDiff().toPlainString() + " Ft");
            b.boldLine("FIZETENDŐ: " + data.getRoundedHufAmount().toPlainString() + " Ft");
        }

        if (data.getHandlingFee() != null && data.getHandlingFee().compareTo(BigDecimal.ZERO) > 0) {
            b.line("Kez. díj:  " + data.getHandlingFee().toPlainString() + " Ft");
        }
        b.separator();
    }

    private void printCustomerSection(EscPosBuilder b, ReceiptData data) {
        if (data.getCustomerName() != null && !data.getCustomerName().isBlank()) {
            b.left();
            b.boldLine("ÜGYFÉL ADATOK:");
            b.line("Név:        " + data.getCustomerName());
            if (data.getCustomerBirthPlace() != null && !data.getCustomerBirthPlace().isBlank()) {
                b.line("Szül.hely:  " + data.getCustomerBirthPlace());
            }
            if (data.getCustomerBirthDate() != null && !data.getCustomerBirthDate().isBlank()) {
                b.line("Szül.idő:   " + data.getCustomerBirthDate());
            }
            if (data.getCustomerMotherName() != null && !data.getCustomerMotherName().isBlank()) {
                b.line("Anyja neve: " + data.getCustomerMotherName());
            }
            if (data.getCustomerAddress() != null && !data.getCustomerAddress().isBlank()) {
                b.line("Lakcím:     " + data.getCustomerAddress());
            }
            if (data.getCustomerDocType() != null && !data.getCustomerDocType().isBlank()) {
                b.line("Okmány:     " + data.getCustomerDocType());
            }
            if (data.getCustomerIdNumber() != null && !data.getCustomerIdNumber().isBlank()) {
                b.line("Okmányszám: " + data.getCustomerIdNumber());
            }
            if (data.getCustomerNationality() != null && !data.getCustomerNationality().isBlank()) {
                b.line("Államp.:    " + data.getCustomerNationality());
            }
            b.separator();
        }
    }

    private void printReceiptFooter(EscPosBuilder b, ReceiptData data) {
        // ÁFA-mentességi szöveg (törvényi kötelező)
        if (data.getVatExemptionText() != null && !data.getVatExemptionText().isBlank()) {
            b.left();
            b.emptyLine();
            // Szj szám és törvényi hivatkozás külön sorban a 40 karakter/sor limit miatt
            String vat = data.getVatExemptionText();
            int dashIdx = vat.indexOf(" — ");
            if (dashIdx > 0) {
                b.line(vat.substring(0, dashIdx));
                b.line(vat.substring(dashIdx + 3));
            } else {
                b.line(vat);
            }
        }
        b.separator();

        // PEP (közszereplő) nyilatkozat — 300k+ Ft tranzakciónál kötelező
        // Legacy: BLOKNYOM/KozszerepNyilatkozat
        if (Boolean.TRUE.equals(data.getRequiresPepDeclaration())) {
            b.emptyLine();
            b.left();
            b.boldLine("KÖZSZEREPLŐI NYILATKOZAT");
            b.line(data.getPepStatusText() != null
                ? data.getPepStatusText()
                : "Nem közszereplő");
            b.emptyLine();
        }

        // Jogcím nyilatkozat — 300k+ Ft tranzakciónál kötelező
        // Legacy: BLOKNYOM/Jogcimnyilatkozat
        if (Boolean.TRUE.equals(data.getRequiresSourceDeclaration())) {
            b.emptyLine();
            b.left();
            b.boldLine("JOGCÍM NYILATKOZAT");
            b.line("Büntetőjogi felelősségem tudatá-");
            b.line("ban nyilatkozom, hogy a fenti");
            b.line("tranzakciót");
            if (Boolean.TRUE.equals(data.getIsLegalEntityCustomer())
                    && data.getLegalEntityName() != null) {
                b.line(data.getLegalEntityName());
                b.line("nevében bonyolítom,");
            } else {
                b.line("saját nevemben bonyolítom,");
            }
            if (data.getSourceOfFunds() != null && !data.getSourceOfFunds().isBlank()) {
                b.line("Pénzeszközöm forrása:");
                // Word-wrap sourceOfFunds to LINE_WIDTH - 2 (indent)
                String src = data.getSourceOfFunds().trim();
                int maxLen = LINE_WIDTH - 2;
                for (int i = 0; i < src.length(); i += maxLen) {
                    b.line("  " + src.substring(i, Math.min(i + maxLen, src.length())));
                }
            }
            b.emptyLine();
        }

        // Két aláírás sor: pénztáros (bal) + ügyfél (jobb)
        b.emptyLine();
        b.left();
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
        b.line("Köszönjük, hogy minket választott!");
        b.emptyLine();
        b.left();
        String footerNote = "A bizonylat a pénzmosás elleni";
        b.line(footerNote);
        b.line("törvény alapján nem helyettesíti");
        b.line("a számlát.");
        b.feedAndCut();
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
