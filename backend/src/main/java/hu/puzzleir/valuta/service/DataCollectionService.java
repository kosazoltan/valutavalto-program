package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.repository.CashBalanceRepository;
import hu.puzzleir.valuta.repository.DataCollectionRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * Adatgyűjtő szerver szolgáltatás — a rendszer gerince.
 *
 * Ez a modul gyűjti össze az irodák napi adatait a központi DB-be.
 *
 * Legacy: Adatgyűjtő DLL (adatgyujto/unit2.pas)
 * - Irodánként összegyűjti a tranzakciókat
 * - Készlet állapotot rögzít
 * - Hibakezelés és újrapróbálkozás
 */
@Service
@RequiredArgsConstructor
@Transactional(rollbackFor = Exception.class)
@Slf4j
public class DataCollectionService {

    private final DataCollectionRepository dataCollectionRepository;
    private final TransactionRepository transactionRepository;
    private final CashBalanceRepository cashBalanceRepository;
    private final BranchRepository branchRepository;

    /**
     * Egy iroda adatainak összegyűjtése az adott napra.
     *
     * 1. Tranzakciók lekérése az adott irodából
     * 2. Készlet állapot rögzítése (CashBalance-ból)
     * 3. Státusz frissítése
     */
    /**
     * User-facing belépő az egy-iroda gyűjtéshez — a /collect REST végpont EGYETLEN user-úti hívása.
     *
     * <p>IDOR guard (FINDING): a branchId user-kontrollált request-body mező, ezért a hívó cégének
     * tulajdonát ELLENŐRIZZÜK, mielőtt a közös feldolgozó futna. Cross-tenant → ResourceNotFoundException.
     * A guard KIZÁRÓLAG ezen a user-úton van: az auth-kontextus NÉLKÜLI belső hívók
     * ({@link #collectAllBranchesForAllCompanies} ütemezett cron-job + {@link #retryFailedCollections})
     * a guard-mentes {@link #collectBranchDataInternal}-t használják, így a getCurrentCompanyId() nem
     * hasal el rajtuk.</p>
     */
    public DataCollection collectBranchData(UUID branchId, LocalDate date) {
        if (!branchRepository.existsByIdAndCompanyId(branchId, SecurityUtils.getCurrentCompanyId())) {
            throw new ResourceNotFoundException("Iroda nem található: " + branchId);
        }
        return collectBranchDataInternal(branchId, date);
    }

    /**
     * Belső (auth-kontextus nélküli) gyűjtés-feldolgozó. KÖZVETLENÜL csak a rendszer-job és a
     * retry-hurok hívhatja; user-úton mindig a guardolt {@link #collectBranchData}-n keresztül.
     */
    DataCollection collectBranchDataInternal(UUID branchId, LocalDate date) {
        log.info("Adatgyűjtés indítása: branchId={}, date={}", branchId, date);

        Branch branch = branchRepository.findById(branchId)
            .orElseThrow(() -> new ResourceNotFoundException("Iroda nem található: " + branchId));

        // Ha már van ezen a napon gyűjtés, visszaadjuk
        DataCollection existing = dataCollectionRepository
            .findByBranchIdAndCollectionDate(branchId, date)
            .orElse(null);

        if (existing != null && existing.getStatus() == DataCollectionStatus.COMPLETED) {
            log.info("Adatgyűjtés már kész: branchId={}, date={}", branchId, date);
            return existing;
        }

        // Új vagy sikertelen gyűjtés újraindítása
        DataCollection collection;
        if (existing != null) {
            collection = existing;
            // Tiszta újrakezdés
            collection.getCollectedTransactions().clear();
            collection.getCollectedInventories().clear();
        } else {
            collection = DataCollection.builder()
                .branch(branch)
                .collectionDate(date)
                .status(DataCollectionStatus.PENDING)
                .collectionType(DataCollectionType.DAILY)
                .build();
        }

        collection.setStatus(DataCollectionStatus.COLLECTING);
        collection.setStartedAt(LocalDateTime.now());
        collection.setErrorMessage(null);

        try {
            // 1. Tranzakciók összegyűjtése riport-celre.
            // User-direktiva 2026-05-03: aggregalt totalBuyHuf/totalSellHuf — a parent CONVERSION
            // sorok (csak metadata) NEM duplazhatjak. `findFinanciallyEffectiveByBranchAndDate` szuri.
            List<Transaction> transactions = transactionRepository
                .findFinanciallyEffectiveByBranchAndDate(branchId, date);

            BigDecimal totalBuyHuf = BigDecimal.ZERO;
            BigDecimal totalSellHuf = BigDecimal.ZERO;

            for (Transaction tx : transactions) {
                CollectedTransaction ct = CollectedTransaction.builder()
                    .originalTransactionId(tx.getId())
                    .transactionType(tx.getTransactionType())
                    .currencyCode(tx.getCurrency() != null ? tx.getCurrency().getCode() : "???")
                    .foreignAmount(tx.getCurrencyAmount())
                    .hufAmount(tx.getHufAmount())
                    .rate(tx.getExchangeRate())
                    .receiptNumber(tx.getReceiptNumber())
                    .customerName(tx.getCustomerName())
                    .transactionTimestamp(tx.getTransactionDate().atTime(tx.getTransactionTime()))
                    .build();

                collection.addCollectedTransaction(ct);

                if (tx.getTransactionType().isBuyType()) {
                    totalBuyHuf = totalBuyHuf.add(tx.getHufAmount());
                } else if (tx.getTransactionType().isSellType()) {
                    totalSellHuf = totalSellHuf.add(tx.getHufAmount());
                }
            }

            // 2. Készlet állapot rögzítése
            List<CashBalance> balances = cashBalanceRepository.findByBranchId(branchId);
            for (CashBalance cb : balances) {
                if (cb.getCurrency() == null) continue;

                CollectedInventory ci = CollectedInventory.builder()
                    .currencyCode(cb.getCurrency().getCode())
                    .amount(cb.getCurrentBalance())
                    .hufValue(BigDecimal.ZERO) // HUF érték számítás későbbi
                    .build();

                collection.addCollectedInventory(ci);
            }

            // 3. Összesítés és státusz frissítés
            collection.setTransactionCount(transactions.size());
            collection.setTotalBuyHuf(totalBuyHuf);
            collection.setTotalSellHuf(totalSellHuf);
            collection.setStatus(DataCollectionStatus.COMPLETED);
            collection.setCompletedAt(LocalDateTime.now());

            log.info("Adatgyűjtés SIKERES: branchId={}, date={}, tx={}, buyHuf={}, sellHuf={}",
                branchId, date, transactions.size(), totalBuyHuf, totalSellHuf);

        } catch (Exception e) {
            log.error("Adatgyűjtés SIKERTELEN: branchId={}, date={}, hiba={}",
                branchId, date, e.getMessage(), e);

            collection.setStatus(DataCollectionStatus.FAILED);
            collection.setErrorMessage(e.getMessage());
            collection.setCompletedAt(LocalDateTime.now());
        }

        return dataCollectionRepository.save(collection);
    }

    /**
     * Összes aktív iroda adatgyűjtése az adott napra — CSAK a hívó cégének irodáira.
     *
     * IDOR védelem (FINDING #9): korábban a globális {@code findByIsActiveTrue()} MINDEN tenant
     * aktív irodáin operált (cross-tenant). A /collect-all REST végpont request-kontextusban fut
     * (ADMIN-gated), így a hívó cégének aktív irodáira szűrünk.
     */
    public List<DataCollection> collectAllBranches(LocalDate date) {
        log.info("Összes iroda adatgyűjtés indítása: date={}", date);

        UUID companyId = SecurityUtils.getCurrentCompanyId();
        List<Branch> activeBranches = branchRepository.findByCompanyIdAndIsActiveTrue(companyId);
        List<DataCollection> results = new ArrayList<>();

        for (Branch branch : activeBranches) {
            try {
                // activeBranches már companyId-szűrt (findByCompanyIdAndIsActiveTrue), ezért a
                // guard-mentes belső feldolgozót hívjuk — nem kell branch-enként újra-ellenőrizni.
                DataCollection result = collectBranchDataInternal(branch.getId(), date);
                results.add(result);
            } catch (Exception e) {
                log.error("Adatgyűjtés hiba irodánál: branchId={}, hiba={}",
                    branch.getId(), e.getMessage(), e);
                // Folytatjuk a következő irodával
            }
        }

        long completed = results.stream()
            .filter(dc -> dc.getStatus() == DataCollectionStatus.COMPLETED)
            .count();
        long failed = results.stream()
            .filter(dc -> dc.getStatus() == DataCollectionStatus.FAILED)
            .count();

        log.info("Összes iroda adatgyűjtés kész: date={}, összesen={}, sikeres={}, sikertelen={}",
            date, results.size(), completed, failed);

        return results;
    }

    /**
     * RENDSZER-SZINTŰ (ütemezett) napi adatgyűjtés — MINDEN cég összes aktív irodájára.
     *
     * Ezt KIZÁRÓLAG a {@code DataCollectionScheduler} (auth-kontextus NÉLKÜLI cron-szál) hívja, ezért
     * NEM használ {@link SecurityUtils#getCurrentCompanyId()}-t (az "Nincs bejelentkezett felhasználó"-val
     * elhasalna — ez volt a 2026-06-15 IDOR-fix regressziója). A user-facing {@link #collectAllBranches}
     * ezzel szemben a hívó cégére szűr (request-kontextus, ADMIN-gated).
     */
    public List<DataCollection> collectAllBranchesForAllCompanies(LocalDate date) {
        log.info("Rendszer-szintű (ütemezett) napi adatgyűjtés indítása: date={}", date);
        List<Branch> activeBranches = branchRepository.findByIsActiveTrue(); // GLOBÁLIS — szándékos rendszer-job
        List<DataCollection> results = new ArrayList<>();
        for (Branch branch : activeBranches) {
            try {
                results.add(collectBranchDataInternal(branch.getId(), date));
            } catch (Exception e) {
                log.error("Ütemezett adatgyűjtés hiba irodánál: branchId={}, hiba={}",
                    branch.getId(), e.getMessage(), e);
            }
        }
        log.info("Rendszer-szintű adatgyűjtés kész: date={}, összesen={} iroda", date, results.size());
        return results;
    }

    /**
     * Gyűjtés státusz lekérdezése.
     */
    @Transactional(readOnly = true)
    public DataCollection getCollectionStatus(UUID branchId, LocalDate date) {
        // IDOR védelem (FINDING #9): csak a hívó cégének irodájára szóló gyűjtés kérdezhető le.
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return dataCollectionRepository
            .findByBranchIdAndCollectionDateAndBranchCompanyId(branchId, date, companyId)
            .orElseThrow(() -> new ResourceNotFoundException(
                "Adatgyűjtés nem található: branchId=" + branchId + ", date=" + date));
    }

    /**
     * Összesítő: adott nap összes irodájának gyűjtési állapota.
     * Param nélküli /status hívás esetén kerül meghívásra.
     */
    @Transactional(readOnly = true)
    public List<hu.puzzleir.valuta.dto.datacollection.DataCollectionDto> getSummary(LocalDate date) {
        // IDOR védelem (FINDING #9): csak a hívó cégének irodáira szóló rekordok (globális leak ellen).
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return dataCollectionRepository
            .findByCollectionDateAndBranchCompanyIdOrderByBranchIdAsc(date, companyId)
            .stream()
            .map(dc -> hu.puzzleir.valuta.dto.datacollection.DataCollectionDto.builder()
                .id(dc.getId())
                .branchId(dc.getBranch() != null ? dc.getBranch().getId() : null)
                .collectionDate(dc.getCollectionDate())
                .status(dc.getStatus().name())
                .collectionType(dc.getCollectionType().name())
                .transactionCount(dc.getTransactionCount())
                .totalBuyHuf(dc.getTotalBuyHuf())
                .totalSellHuf(dc.getTotalSellHuf())
                .startedAt(dc.getStartedAt())
                .completedAt(dc.getCompletedAt())
                .errorMessage(dc.getErrorMessage())
                .createdAt(dc.getCreatedAt())
                .build())
            .collect(java.util.stream.Collectors.toList());
    }

    /**
     * Sikertelen gyűjtések újrapróbálása.
     *
     * @return újrapróbált gyűjtések száma
     */
    public int retryFailedCollections() {
        LocalDate sinceDate = LocalDate.now().minusDays(7); // max 7 napra visszamenőleg
        List<DataCollection> failed = dataCollectionRepository.findFailedSince(sinceDate);

        log.info("Sikertelen gyűjtések újrapróbálása: {} db", failed.size());

        int retried = 0;
        for (DataCollection dc : failed) {
            try {
                // retryFailedCollections cron-úton (auth-kontextus nélkül) is futhat → guard-mentes belső hívás.
                collectBranchDataInternal(dc.getBranch().getId(), dc.getCollectionDate());
                retried++;
            } catch (Exception e) {
                log.error("Újrapróbálás sikertelen: branchId={}, date={}, hiba={}",
                    dc.getBranch().getId(), dc.getCollectionDate(), e.getMessage());
            }
        }

        log.info("Sikertelen gyűjtések újrapróbálva: {}/{}", retried, failed.size());
        return retried;
    }
}
