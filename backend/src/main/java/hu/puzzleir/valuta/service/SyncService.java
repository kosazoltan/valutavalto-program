package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.config.IntegrationTransportProperties;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.logging.VVLogger;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CashBalanceRepository;
import hu.puzzleir.valuta.repository.DailySessionRepository;
import hu.puzzleir.valuta.dto.sync.SyncLogDto;
import hu.puzzleir.valuta.dto.sync.SyncStatusDto;
import hu.puzzleir.valuta.entity.SyncLog;
import hu.puzzleir.valuta.repository.ExchangeRateRepository;
import hu.puzzleir.valuta.repository.SyncLogRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.file.Paths;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

/**
 * Szinkronizációs szolgáltatás — fiókok közötti adatszinkronizáció.
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
@Slf4j
public class SyncService {

    // V234 belso log+audit modul - strukturalt error code log
    private static final VVLogger VV_LOG = VVLogger.of(SyncService.class);

    private final SyncLogRepository syncLogRepository;
    private final BranchRepository branchRepository;
    private final ExchangeRateRepository exchangeRateRepository;
    private final TransactionRepository transactionRepository;
    private final CashBalanceRepository cashBalanceRepository;
    private final DailySessionRepository dailySessionRepository;
    private final IntegrationTransportProperties integrationTransportProperties;
    private final FileTransportService fileTransportService;

    @Transactional(rollbackFor = Exception.class)
    public SyncLogDto syncRatesDown(UUID branchId) {
        return performSync(branchId, SyncLog.SyncType.RATES, SyncLog.SyncDirection.DOWN);
    }

    @Transactional(rollbackFor = Exception.class)
    public SyncLogDto syncTransactionsUp(UUID branchId) {
        return performSync(branchId, SyncLog.SyncType.TRANSACTIONS, SyncLog.SyncDirection.UP);
    }

    @Transactional(rollbackFor = Exception.class)
    public SyncLogDto syncInventoryUp(UUID branchId) {
        return performSync(branchId, SyncLog.SyncType.INVENTORY, SyncLog.SyncDirection.UP);
    }

    @Transactional(rollbackFor = Exception.class)
    public SyncLogDto syncAll(UUID branchId) {
        return performSync(branchId, SyncLog.SyncType.FULL, SyncLog.SyncDirection.DOWN);
    }

    public SyncStatusDto getSyncStatus(UUID branchId) {
        UUID effectiveBranch = resolveBranch(branchId);
        List<SyncLog> completedLogs = syncLogRepository.findLastCompletedByBranch(effectiveBranch);

        Map<String, LocalDateTime> lastSyncTimes = new LinkedHashMap<>();
        for (SyncLog.SyncType type : SyncLog.SyncType.values()) {
            completedLogs.stream()
                    .filter(s -> s.getSyncType() == type)
                    .findFirst()
                    .ifPresent(s -> lastSyncTimes.put(type.name(), s.getCompletedAt()));
        }

        return SyncStatusDto.builder()
                .branchId(effectiveBranch)
                .lastSyncTimes(lastSyncTimes)
                .build();
    }

    public Page<SyncLogDto> getSyncHistory(UUID branchId, Pageable pageable) {
        UUID effectiveBranch = resolveBranch(branchId);
        return syncLogRepository.findByBranchIdOrderByStartedAtDesc(effectiveBranch, pageable)
                .map(this::toDto);
    }

    private SyncLogDto performSync(UUID branchId, SyncLog.SyncType syncType, SyncLog.SyncDirection direction) {
        UUID effectiveBranch = resolveBranch(branchId);
        Branch branch = findBranchInCurrentCompany(effectiveBranch);

        SyncLog syncLog = SyncLog.builder()
                .branch(branch)
                .syncType(syncType)
                .direction(direction)
                .status(SyncLog.SyncStatus.RUNNING)
                .startedAt(LocalDateTime.now())
                .build();
        syncLog = syncLogRepository.save(syncLog);

        try {
            int recordCount = executeSync(syncType, effectiveBranch, branch.getCode(), direction);

            syncLog.setStatus(SyncLog.SyncStatus.COMPLETED);
            syncLog.setCompletedAt(LocalDateTime.now());
            syncLog.setRecordCount(recordCount);
            log.info("Szinkronizáció sikeres: branch={}, type={}, direction={}, records={}",
                    branch.getCode(), syncType, direction, recordCount);
        } catch (Exception e) {
            syncLog.setStatus(SyncLog.SyncStatus.FAILED);
            syncLog.setCompletedAt(LocalDateTime.now());
            syncLog.setErrorMessage(e.getMessage());
            VV_LOG.error("VV-SYNC-004", "branch.sync_failed", e,
                    java.util.Map.of("branch_code", branch.getCode(),
                            "sync_type", syncType,
                            "branch_id", branch.getId()));
        }

        syncLog = syncLogRepository.save(syncLog);
        return toDto(syncLog);
    }

    private int executeSync(SyncLog.SyncType syncType, UUID branchId, String branchCode, SyncLog.SyncDirection direction) {
        UUID companyId = findBranchInCurrentCompany(branchId).getCompany().getId();
        int rates = countCurrentRates(branchId);
        int transactions = transactionRepository.findActiveByBranchAndDate(branchId, LocalDate.now()).size();
        int inventory = cashBalanceRepository.findByBranchIdAndCompanyId(branchId, companyId).size();
        int closing = dailySessionRepository.findOpenSessionsByBranch(companyId, branchId).size();

        String safeBranchCode = fileTransportService.sanitizePathSegment(branchCode, "branchCode");
        String safeSyncDir = fileTransportService.sanitizePathSegment(
                integrationTransportProperties.getSync().getDir(), "sync.dir");

        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("branchId", branchId);
        payload.put("branchCode", safeBranchCode);
        payload.put("syncType", syncType.name());
        payload.put("direction", direction.name());
        payload.put("generatedAt", LocalDateTime.now().toString());
        payload.put("rates", rates);
        payload.put("transactions", transactions);
        payload.put("inventory", inventory);
        payload.put("openClosings", closing);

        try {
            fileTransportService.writeJson(Paths.get(
                            safeSyncDir,
                            safeBranchCode,
                            fileTransportService.sanitizePathSegment(syncType.name().toLowerCase(), "syncType"))
                    .toString(),
                    "sync", payload);
        } catch (Exception e) {
            throw new IllegalStateException("Szinkron artifact írás sikertelen", e);
        }

        return switch (syncType) {
            case RATES -> rates;
            case TRANSACTIONS -> transactions;
            case INVENTORY -> inventory;
            case CLOSING -> closing;
            case FULL -> rates + transactions + inventory + closing;
        };
    }

    private int countCurrentRates(UUID branchId) {
        Branch branch = findBranchInCurrentCompany(branchId);

        return exchangeRateRepository.findAllActiveRates(branch.getCompany().getId(), branchId)
            .stream()
            .collect(Collectors.toMap(
                r -> r.getCurrency().getId(),
                r -> r,
                (first, second) -> first,
                LinkedHashMap::new))
            .size();
    }

    private Branch findBranchInCurrentCompany(UUID branchId) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return branchRepository.findByIdAndCompanyId(branchId, companyId)
                .orElseThrow(() -> new ResourceNotFoundException("Iroda nem található: " + branchId));
    }

    private UUID resolveBranch(UUID branchId) {
        UUID effectiveBranch = branchId != null ? branchId : SecurityUtils.getCurrentBranchId();
        // Multi-tenant cross-tenant IDOR vedelem: az ADMIN ebben a rendszerben CEG-scoped, nem
        // globalis super-admin. A megadott branchId-t a hivo cegere validaljuk, hogy idegen ceg
        // branch-enek sync-naplojat/adatait ne lehessen elerni. Idegen (vagy nem letezo) branch ->
        // ResourceNotFoundException.
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        if (!branchRepository.existsByIdAndCompanyId(effectiveBranch, companyId)) {
            throw new ResourceNotFoundException("Iroda nem található: " + effectiveBranch);
        }
        return effectiveBranch;
    }

    private SyncLogDto toDto(SyncLog s) {
        return SyncLogDto.builder()
                .id(s.getId())
                .branchId(s.getBranch().getId())
                .syncType(s.getSyncType().name())
                .direction(s.getDirection().name())
                .status(s.getStatus().name())
                .startedAt(s.getStartedAt())
                .completedAt(s.getCompletedAt())
                .recordCount(s.getRecordCount())
                .errorMessage(s.getErrorMessage())
                .build();
    }
}
