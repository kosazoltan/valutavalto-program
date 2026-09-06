package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

/**
 * Napi zárás archiváló service (Delphi: HaviGyujtokbeMasolas).
 *
 * <p>A Delphi rendszerben a napzár 10 copy-lépést hajtott végre, amelyek a napi
 * munkatáblákat (BLOKKFEJ, BLOKKTETEL, CIMINI, ARFOLYAM, EKERDATA, KEZDIJDATA,
 * WUAFAFORG, WZARO, EKERESKEDELEM, KEZDIJ) átmásolták havi archívum táblákba
 * (BF, BT, CIMT, NARF, EDAT, KDAT, WUNI, WZAR, EKER, KEZD) majd törölték az
 * eredeti táblák tartalmát.</p>
 *
 * <p>A modern rendszerben a tranzakciók perzisztensek (nem törlődnek naponta),
 * ezért a copy-lépések snapshot-jellegű archiválásként működnek:</p>
 *
 * <ul>
 *   <li>Tranzakció archiválás (BfCopy + BtCopy) → {@code MonthlyArchiveService.archiveDailyTransactions()}</li>
 *   <li>Árfolyam snapshot (NarfCopy) → {@code DailyClosingService.snapshotDailyRates()}</li>
 *   <li>Címletezés snapshot (CimtCopy) → {@link #snapshotDenominations(UUID, LocalDate)}</li>
 *   <li>E-kereskedelem zárás (EdatCopy) → {@link #snapshotSubledger(UUID, LocalDate, String, String)}</li>
 *   <li>Kezelési díj zárás (KdatCopy) → {@link #snapshotSubledger(UUID, LocalDate, String, String)}</li>
 *   <li>WU/ÁFA forgalom (WuniCopy) → {@link #snapshotWuAfaTransactions(UUID, LocalDate)}</li>
 *   <li>WU/ÁFA zárás (WzarCopy) → {@link #snapshotWuAfaSubledgers(UUID, LocalDate)}</li>
 *   <li>E-ker forgalom (EkerCopy) + Kez.díj forgalom (KezdijCopy) → tranzakció táblában marad</li>
 * </ul>
 */
@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class DailyClosingArchiveService {

    private final DailyDenominationSnapshotRepository denominationSnapshotRepo;
    private final DailySubledgerSnapshotRepository subledgerSnapshotRepo;
    private final DailyWuAfaTransactionRepository wuAfaTransactionRepo;
    private final DenominationBalanceRepository denominationBalanceRepo;
    private final TransactionRepository transactionRepository;

    /**
     * Teljes napi archiválás végrehajtása (Delphi: HaviGyujtokbeMasolas).
     *
     * @return archiválási összesítő szöveg
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public String executeFullDailyArchive(UUID branchId, LocalDate closingDate) {
        log.info("S1-02 napi archiválás indítása: branchId={}, date={}", branchId, closingDate);
        StringBuilder summary = new StringBuilder();

        // 1. Címletezés snapshot (CimtCopy)
        int denomCount = snapshotDenominations(branchId, closingDate);
        summary.append("Címletezés: ").append(denomCount).append(" snapshot. ");

        // 2. E-kereskedelem zárás (EdatCopy)
        snapshotSubledger(branchId, closingDate, "ECOMMERCE", "HUF");
        summary.append("E-kereskedelem zárás: OK. ");

        // 3. Kezelési díj zárás (KdatCopy)
        snapshotSubledger(branchId, closingDate, "HANDLING_FEE", "HUF");
        summary.append("Kezelési díj zárás: OK. ");

        // 4. WU/ÁFA forgalom snapshot (WuniCopy)
        int wuTxCount = snapshotWuAfaTransactions(branchId, closingDate);
        summary.append("WU/ÁFA forgalom: ").append(wuTxCount).append(" tétel. ");

        // 5. WU/ÁFA zárás (WzarCopy)
        snapshotWuAfaSubledgers(branchId, closingDate);
        summary.append("WU/ÁFA zárás: OK.");

        log.info("S1-02 napi archiválás kész: branchId={}, date={}, summary={}",
                branchId, closingDate, summary);
        return summary.toString();
    }

    /**
     * Címletezés snapshot (Delphi: CimtCopy).
     *
     * Snapshots DenominationBalance rows of {@code closingDate} only.
     * Duplicate-day skip: if a snapshot already exists for the date, no-op.
     *
     * <p>FKH-054: never {@code findByCashDeskId} — V387 date-keyed rows from earlier
     * submission dates collide on {@code uq_denom_snap} (branch, date, currency, type, face)
     * and mark the outer closing transaction rollback-only.</p>
     */
    public int snapshotDenominations(UUID branchId, LocalDate closingDate) {
        if (denominationSnapshotRepo.existsByBranchIdAndSnapshotDate(branchId, closingDate)) {
            log.info("Címletezés snapshot már létezik: branchId={}, date={} — SKIP", branchId, closingDate);
            return 0;
        }

        List<DenominationBalance> balances = denominationBalanceRepo.findByBranchIdAndDate(branchId, closingDate);

        int count = 0;
        for (DenominationBalance bal : balances) {
            if (bal.getQuantity() == null || bal.getQuantity() == 0) {
                continue; // 0 darabot nem mentünk
            }
            Denomination denom = bal.getDenomination();
            if (denom == null) continue;

            DailyDenominationSnapshot snapshot = DailyDenominationSnapshot.builder()
                    .branchId(branchId)
                    .snapshotDate(closingDate)
                    .currencyCode(denom.getCurrency() != null ? denom.getCurrency().getCode() : "HUF")
                    .denominationType(denom.getDenominationType() != null ? denom.getDenominationType().name() : "BANKNOTE")
                    .faceValue(denom.getFaceValue() != null ? denom.getFaceValue() : BigDecimal.ZERO)
                    .quantity(bal.getQuantity())
                    .totalValue(bal.getTotalValue() != null ? bal.getTotalValue() : BigDecimal.ZERO)
                    .closingType(bal.getDenominationCategory() != null
                            ? bal.getDenominationCategory().getLegacyCimletSorszam() : 1)
                    .build();
            denominationSnapshotRepo.save(snapshot);
            count++;
        }

        log.info("Címletezés snapshot kész: branchId={}, date={}, count={}", branchId, closingDate, count);
        return count;
    }

    /**
     * Al-pénztár zárás snapshot (Delphi: EdatCopy, KdatCopy).
     *
     * A napi forgalmat a Transaction táblából aggregáljuk típus szerint.
     */
    public void snapshotSubledger(UUID branchId, LocalDate closingDate,
                                   String subledgerType, String currencyCode) {
        if (subledgerSnapshotRepo.existsByBranchIdAndSnapshotDateAndSubledgerType(
                branchId, closingDate, subledgerType)) {
            log.info("Al-pénztár snapshot már létezik: branchId={}, date={}, type={} — SKIP",
                    branchId, closingDate, subledgerType);
            return;
        }

        // Az előző napi záró = mai nyitó (ha van)
        LocalDate previousDate = closingDate.minusDays(1);
        BigDecimal opening = subledgerSnapshotRepo
                .findByBranchIdAndSnapshotDateAndSubledgerTypeAndCurrencyCode(
                        branchId, previousDate, subledgerType, currencyCode)
                .map(DailySubledgerSnapshot::getClosingBalance)
                .orElse(BigDecimal.ZERO);

        // Napi forgalom aggregálás — tranzakciókból
        BigDecimal income = BigDecimal.ZERO;
        BigDecimal expense = BigDecimal.ZERO;

        // User-direktiva 2026-05-03: napi-zarasi archiv-snapshot szandekosan TELJES KEPET
        // archival (parent CONVERSION sor IS), audit/forensikai celokra. NEM hasznaljuk a
        // `findFinanciallyEffectiveBy*` scope-olt variant-ot — az audit teljesseg az elsodleges.
        List<Transaction> dayTx = transactionRepository.findActiveByBranchAndDate(
                branchId, closingDate);

        for (Transaction tx : dayTx) {
            TransactionType txType = tx.getTransactionType();
            BigDecimal amt = tx.getHufAmount() != null ? tx.getHufAmount().abs() : BigDecimal.ZERO;

            switch (subledgerType) {
                case "ECOMMERCE" -> {
                    if (txType == TransactionType.OTHER) {
                        income = income.add(amt);
                    }
                }
                case "HANDLING_FEE" -> {
                    if (tx.getHandlingFee() != null && tx.getHandlingFee().compareTo(BigDecimal.ZERO) > 0) {
                        income = income.add(tx.getHandlingFee());
                    }
                }
                case "WU_USD" -> {
                    boolean isWu = txType == TransactionType.WESTERN_UNION_SEND
                            || txType == TransactionType.WESTERN_UNION_RECEIVE;
                    if (isWu && tx.getCurrency() != null && "USD".equals(tx.getCurrency().getCode())) {
                        BigDecimal currAmt = tx.getCurrencyAmount() != null ? tx.getCurrencyAmount().abs() : BigDecimal.ZERO;
                        if (txType == TransactionType.WESTERN_UNION_RECEIVE) {
                            income = income.add(currAmt);
                        } else {
                            expense = expense.add(currAmt);
                        }
                    }
                }
                case "WU_HUF" -> {
                    boolean isWu = txType == TransactionType.WESTERN_UNION_SEND
                            || txType == TransactionType.WESTERN_UNION_RECEIVE;
                    if (isWu) {
                        if (txType == TransactionType.WESTERN_UNION_RECEIVE) {
                            income = income.add(amt); // HUF bevétel
                        } else {
                            expense = expense.add(amt); // HUF kiadás
                        }
                    }
                }
                case "WU_VAT" -> {
                    // ÁFA: WU tranzakciók után számított ÁFA
                    boolean isWu = txType == TransactionType.WESTERN_UNION_SEND
                            || txType == TransactionType.WESTERN_UNION_RECEIVE;
                    if (isWu && tx.getHandlingFee() != null && tx.getHandlingFee().compareTo(BigDecimal.ZERO) > 0) {
                        // WU kezelési díj ÁFA tartalom (27%)
                        BigDecimal vatAmount = tx.getHandlingFee()
                                .multiply(BigDecimal.valueOf(27))
                                .divide(BigDecimal.valueOf(127), 2, java.math.RoundingMode.HALF_UP);
                        income = income.add(vatAmount);
                    }
                }
                default -> { /* nem illeszkedik */ }
            }
        }

        BigDecimal closing = opening.add(income).subtract(expense);

        DailySubledgerSnapshot snapshot = DailySubledgerSnapshot.builder()
                .branchId(branchId)
                .snapshotDate(closingDate)
                .subledgerType(subledgerType)
                .currencyCode(currencyCode)
                .openingBalance(opening)
                .income(income)
                .expense(expense)
                .closingBalance(closing)
                .build();
        subledgerSnapshotRepo.save(snapshot);

        log.info("Al-pénztár snapshot kész: branchId={}, date={}, type={}, closing={}",
                branchId, closingDate, subledgerType, closing);
    }

    /**
     * WU/ÁFA forgalmi tételek snapshot (Delphi: WuniCopy).
     *
     * A WU és ÁFA típusú tranzakciókat snapshot-olja.
     */
    public int snapshotWuAfaTransactions(UUID branchId, LocalDate closingDate) {
        if (wuAfaTransactionRepo.existsByBranchIdAndTransactionDate(branchId, closingDate)) {
            log.info("WU/ÁFA forgalom snapshot már létezik: branchId={}, date={} — SKIP",
                    branchId, closingDate);
            return 0;
        }

        List<Transaction> dayTx = transactionRepository.findActiveByBranchAndDate(
                branchId, closingDate);

        int count = 0;
        for (Transaction tx : dayTx) {
            TransactionType type = tx.getTransactionType();
            boolean isWu = type == TransactionType.WESTERN_UNION_SEND
                    || type == TransactionType.WESTERN_UNION_RECEIVE;
            boolean isMg = type == TransactionType.MONEYGRAM_SEND
                    || type == TransactionType.MONEYGRAM_RECEIVE;

            if (!isWu && !isMg) continue;

            String sign = (type == TransactionType.WESTERN_UNION_RECEIVE
                    || type == TransactionType.MONEYGRAM_RECEIVE) ? "+" : "-";
            String receiptType = isWu ? "WU" : "MG";

            DailyWuAfaTransaction wuTx = DailyWuAfaTransaction.builder()
                    .branchId(branchId)
                    .transactionDate(closingDate)
                    .receiptNumber(tx.getReceiptNumber() != null ? tx.getReceiptNumber() : "")
                    .currencyCode(tx.getCurrency() != null ? tx.getCurrency().getCode() : "USD")
                    .sign(sign)
                    .amount(tx.getCurrencyAmount() != null ? tx.getCurrencyAmount() : BigDecimal.ZERO)
                    .receiptType(receiptType)
                    .registerCode(null)
                    .storno(0)
                    .build();
            wuAfaTransactionRepo.save(wuTx);
            count++;
        }

        log.info("WU/ÁFA forgalom snapshot kész: branchId={}, date={}, count={}", branchId, closingDate, count);
        return count;
    }

    /**
     * WU/ÁFA al-pénztárak napi zárás (Delphi: WzarCopy).
     *
     * 3 al-pénztár: WU_USD, WU_HUF, WU_VAT.
     */
    public void snapshotWuAfaSubledgers(UUID branchId, LocalDate closingDate) {
        snapshotSubledger(branchId, closingDate, "WU_USD", "USD");
        snapshotSubledger(branchId, closingDate, "WU_HUF", "HUF");
        snapshotSubledger(branchId, closingDate, "WU_VAT", "HUF");
    }

    /**
     * Régi évek napi zárásainak archiválása/törlése (év-nyitó workflow, tenant-izolált).
     * Legacy: DROP TABLE ARFE1812, BF1812 stb. (evnyito/unit1.pas)
     * Modern: Régi snapshot rekordok törlése az archív táblákból.
     *
     * @param branchIds A céghez tartozó irodák ID-i (tenant-izolálás)
     * @param beforeYear Az évet megelőző rekordok törlése (pl. 2025 → 2024 és régebbi törlése)
     * @return Törölt rekordok száma
     */
    public int archiveBeforeYear(List<UUID> branchIds, int beforeYear) {
        LocalDate cutoffDate = LocalDate.of(beforeYear + 1, 1, 1);
        int deleted = 0;

        // Denomination snapshots (tenant-izolált)
        int denomDeleted = denominationSnapshotRepo.deleteByBranchIdsAndSnapshotDateBefore(branchIds, cutoffDate);
        deleted += denomDeleted;

        // Subledger snapshots (tenant-izolált)
        int subledgerDeleted = subledgerSnapshotRepo.deleteByBranchIdsAndSnapshotDateBefore(branchIds, cutoffDate);
        deleted += subledgerDeleted;

        log.info("Év-nyitó archiválás: branchCount={}, beforeYear={}, cutoff={}, denomDeleted={}, subledgerDeleted={}",
            branchIds.size(), beforeYear, cutoffDate, denomDeleted, subledgerDeleted);

        return deleted;
    }
}
