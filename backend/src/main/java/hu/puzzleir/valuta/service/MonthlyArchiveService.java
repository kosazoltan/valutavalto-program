package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.config.FinancialRetentionProperties;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.entity.ArchivedTransaction;
import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.entity.TransactionStatus;
import hu.puzzleir.valuta.repository.ArchivedTransactionRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.YearMonth;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.UUID;

/**
 * Havi archiválási szolgáltatás.
 * 
 * A Delphi rendszer havonta archiválta a tranzakciókat (CopyTables):
 * - BLOKKFEJ → BFéévhh
 * - BLOKKTETEL → BTéévhh
 * - DELETE az eredeti táblákból
 * 
 * Modern verzió:
 * - Batch INSERT az archived_transactions-be
 * - Soft delete (STATUS = ARCHIVED) az eredeti táblában
 * - NEM töröl fizikailag (modern DB-ben nem kell)
 * 
 * Legacy: NAPZAR.DLL - CopyTables eljárás
 */
@Service
@RequiredArgsConstructor
@Transactional
@Slf4j
public class MonthlyArchiveService {

    private final TransactionRepository transactionRepository;
    private final ArchivedTransactionRepository archivedTransactionRepository;
    private final AuditLogService auditLogService;
    private final FinancialRetentionProperties financialRetentionProperties;

    private static final DateTimeFormatter MONTH_FORMAT = DateTimeFormatter.ofPattern("yyyy-MM");

    /**
     * Havi archiválás végrehajtása.
     * 
     * @param branchId Iroda ID
     * @param yearMonth Hónap (pl. 2026-03)
     * @return Archivált tranzakciók száma
     */
    public int archiveMonth(UUID branchId, YearMonth yearMonth) {
        String archiveMonth = yearMonth.format(MONTH_FORMAT);
        
        log.info("Havi archiválás kezdése: branchId={}, month={}, retentionYears={}, hardDeleteEnabled={}",
            branchId,
            archiveMonth,
            financialRetentionProperties.getYears(),
            financialRetentionProperties.isHardDeleteEnabled());

        // 1. Ellenőrzés: már archivált-e ez a hónap
        long existingCount = archivedTransactionRepository.countByMonthAndBranch(archiveMonth, branchId);
        if (existingCount > 0) {
            throw new ValidationException(
                String.format("A %s hónap már archivált! (%d tranzakció)", archiveMonth, existingCount)
            );
        }

        // 2. Lekérdezés: az adott hónap COMPLETED státuszú tranzakciói
        LocalDate startDate = yearMonth.atDay(1);
        LocalDate endDate = yearMonth.atEndOfMonth();

        List<Transaction> transactions = transactionRepository.findByBranchAndMonth(
            branchId, startDate, endDate
        );

        if (transactions.isEmpty()) {
            log.warn("Nincs archiválandó tranzakció: branchId={}, month={}", branchId, archiveMonth);
            return 0;
        }

        log.info("Archivláandó tranzakciók száma: {}", transactions.size());

        // 3. Batch INSERT az archived_transactions-be
        int archivedCount = 0;
        for (Transaction tx : transactions) {
            ArchivedTransaction archived = ArchivedTransaction.builder()
                .archiveMonth(archiveMonth)
                .originalId(tx.getId())
                .receiptNumber(tx.getReceiptNumber())
                .transactionType(tx.getTransactionType().name())
                .currencyCode(tx.getCurrency() != null ? tx.getCurrency().getCode() : null)
                .amount((tx.getCurrencyAmount() != null ? tx.getCurrencyAmount() : java.math.BigDecimal.ZERO))
                .exchangeRate((tx.getExchangeRate() != null ? tx.getExchangeRate() : java.math.BigDecimal.ZERO))
                .hufAmount(tx.getHufAmount())
                .handlingFee(tx.getHandlingFee())
                .roundingAmount(java.math.BigDecimal.ZERO)
                .originalDate(tx.getCreatedAt())
                .branchId(tx.getBranch().getId())
                .workerId(tx.getWorker().getId())
                .customerName("")
                .customerId(null)
                .documentNumber("")
                .archivedBy(SecurityUtils.getCurrentWorkerCode())
                .company(null)
                .archiveStatus("ARCHIVED")
                .build();

            archivedTransactionRepository.save(archived);
            archivedCount++;
        }

        // 4. Soft delete: STATUS = ARCHIVED (NEM töröl fizikailag!)
        for (Transaction tx : transactions) {
            tx.setStatus(TransactionStatus.ARCHIVED);
            transactionRepository.save(tx);
        }

        // 5. Audit log
        auditLogService.log(
            "MONTHLY_ARCHIVE",
            String.format("Havi archiválás: %s - %d tranzakció archivált, retention=%d év, hardDelete=%s",
                    archiveMonth,
                    archivedCount,
                    financialRetentionProperties.getYears(),
                    financialRetentionProperties.isHardDeleteEnabled()),
            branchId.toString()
        );

        log.info("Havi archiválás sikeres: branchId={}, month={}, count={}", branchId, archiveMonth, archivedCount);
        return archivedCount;
    }

    /**
     * Napi tranzakciók archiválása (napzárás részeként).
     * Legacy: NAPZAR.DLL — CopyTables napi szintű változata.
     *
     * @param branchId    Iroda ID
     * @param closingDate A zárt nap dátuma
     * @return Archivált tranzakciók száma (duplikátumokat kihagyva)
     */
    public int archiveDailyTransactions(UUID branchId, LocalDate closingDate) {
        String archiveMonth = YearMonth.from(closingDate).format(MONTH_FORMAT);

        log.info("Napi archiválás: branchId={}, date={}, archiveMonth={}, retentionYears={}, hardDeleteEnabled={}",
            branchId,
            closingDate,
            archiveMonth,
            financialRetentionProperties.getYears(),
            financialRetentionProperties.isHardDeleteEnabled());

        List<Transaction> transactions = transactionRepository.findByBranchAndMonth(
            branchId, closingDate, closingDate
        );

        if (transactions.isEmpty()) {
            log.info("Napi archiválás: nincs archiválandó tranzakció: branchId={}, date={}", branchId, closingDate);
            return 0;
        }

        int archivedCount = 0;
        for (Transaction tx : transactions) {
            // Duplikáció ellenőrzés bizonylat szám alapján
            if (tx.getReceiptNumber() != null
                    && archivedTransactionRepository.existsByReceiptNumberAndArchiveMonth(
                        tx.getReceiptNumber(), archiveMonth)) {
                log.debug("Napi archiválás: már archivált bizonylat kihagyva: {}", tx.getReceiptNumber());
                continue;
            }
            // Eredeti ID alapú duplikáció ellenőrzés
            if (tx.getId() != null && archivedTransactionRepository.existsByOriginalId(tx.getId())) {
                log.debug("Napi archiválás: már archivált tranzakció kihagyva (id={})", tx.getId());
                continue;
            }

            ArchivedTransaction archived = ArchivedTransaction.builder()
                .archiveMonth(archiveMonth)
                .originalId(tx.getId())
                .receiptNumber(tx.getReceiptNumber())
                .transactionType(tx.getTransactionType().name())
                .currencyCode(tx.getCurrency() != null ? tx.getCurrency().getCode() : null)
                .amount(tx.getCurrencyAmount() != null ? tx.getCurrencyAmount() : java.math.BigDecimal.ZERO)
                .exchangeRate(tx.getExchangeRate() != null ? tx.getExchangeRate() : java.math.BigDecimal.ZERO)
                .hufAmount(tx.getHufAmount())
                .handlingFee(tx.getHandlingFee())
                .roundingAmount(java.math.BigDecimal.ZERO)
                .originalDate(tx.getCreatedAt())
                .branchId(tx.getBranch().getId())
                .workerId(tx.getWorker().getId())
                .customerName("")
                .customerId(null)
                .documentNumber("")
                .archivedBy(SecurityUtils.getCurrentWorkerCode())
                .company(null)
                .archiveStatus("ARCHIVED")
                .build();

            archivedTransactionRepository.save(archived);
            archivedCount++;
        }

        log.info("Napi archiválás kész: branchId={}, date={}, count={}", branchId, closingDate, archivedCount);
        return archivedCount;
    }

    /**
     * Archivált tranzakciók lekérdezése.
     */
    @Transactional(readOnly = true)
    public List<ArchivedTransaction> getArchivedTransactions(UUID branchId, YearMonth yearMonth) {
        String archiveMonth = yearMonth.format(MONTH_FORMAT);
        return archivedTransactionRepository.findByBranchIdAndArchiveMonth(branchId, archiveMonth);
    }

    /**
     * Ellenőrzés: archivált-e már a hónap.
     */
    @Transactional(readOnly = true)
    public boolean isMonthArchived(UUID branchId, YearMonth yearMonth) {
        String archiveMonth = yearMonth.format(MONTH_FORMAT);
        return archivedTransactionRepository.countByMonthAndBranch(archiveMonth, branchId) > 0;
    }
}
