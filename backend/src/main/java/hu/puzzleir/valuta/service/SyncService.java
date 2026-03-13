package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.dto.sync.SyncLogDto;
import hu.puzzleir.valuta.dto.sync.SyncStatusDto;
import hu.puzzleir.valuta.entity.SyncLog;
import hu.puzzleir.valuta.repository.SyncLogRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

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

    private final SyncLogRepository syncLogRepository;
    private final BranchRepository branchRepository;

    @Transactional
    public SyncLogDto syncRatesDown(UUID branchId) {
        return performSync(branchId, SyncLog.SyncType.RATES, SyncLog.SyncDirection.DOWN);
    }

    @Transactional
    public SyncLogDto syncTransactionsUp(UUID branchId) {
        return performSync(branchId, SyncLog.SyncType.TRANSACTIONS, SyncLog.SyncDirection.UP);
    }

    @Transactional
    public SyncLogDto syncInventoryUp(UUID branchId) {
        return performSync(branchId, SyncLog.SyncType.INVENTORY, SyncLog.SyncDirection.UP);
    }

    @Transactional
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
        Branch branch = branchRepository.findById(effectiveBranch)
                .orElseThrow(() -> new ResourceNotFoundException("Iroda nem található: " + effectiveBranch));

        SyncLog syncLog = SyncLog.builder()
                .branch(branch)
                .syncType(syncType)
                .direction(direction)
                .status(SyncLog.SyncStatus.RUNNING)
                .startedAt(LocalDateTime.now())
                .build();
        syncLog = syncLogRepository.save(syncLog);

        try {
            // Simplified sync — production implementation would do actual data transfer
            int recordCount = simulateSync(syncType, effectiveBranch);

            syncLog.setStatus(SyncLog.SyncStatus.COMPLETED);
            syncLog.setCompletedAt(LocalDateTime.now());
            syncLog.setRecordCount(recordCount);
            log.info("Szinkronizáció sikeres: branch={}, type={}, direction={}, records={}",
                    branch.getCode(), syncType, direction, recordCount);
        } catch (Exception e) {
            syncLog.setStatus(SyncLog.SyncStatus.FAILED);
            syncLog.setCompletedAt(LocalDateTime.now());
            syncLog.setErrorMessage(e.getMessage());
            log.error("Szinkronizáció sikertelen: branch={}, type={}", branch.getCode(), syncType, e);
        }

        syncLog = syncLogRepository.save(syncLog);
        return toDto(syncLog);
    }

    private int simulateSync(SyncLog.SyncType syncType, UUID branchId) {
        // Production implementation placeholder
        return switch (syncType) {
            case RATES -> 15;
            case TRANSACTIONS -> 50;
            case INVENTORY -> 20;
            case CLOSING -> 5;
            case FULL -> 90;
        };
    }

    private UUID resolveBranch(UUID branchId) {
        return branchId != null ? branchId : SecurityUtils.getCurrentBranchId();
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
