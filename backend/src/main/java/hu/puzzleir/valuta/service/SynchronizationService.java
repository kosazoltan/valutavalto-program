package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.sync.SyncLogDto;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;

/**
 * Szinkronizációs szolgáltatás — adatszinkronizáció fiókok között.
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
@Slf4j
public class SynchronizationService {

    private final TransactionRepository transactionRepository;
    private final SyncService syncService;

    @Transactional
    public Map<String, Object> sync(UUID branchId, Long workerId) {
        UUID effectiveBranch = branchId != null ? branchId : SecurityUtils.getCurrentBranchId();
        log.info("Szinkronizáció indítása: branch={}, worker={}", effectiveBranch, workerId);

        List<String> errors = new ArrayList<>();
        int recordsSynced = 0;
        String syncStatus = "FAILED";
        UUID syncLogId = null;
        LocalDateTime syncedAt = LocalDateTime.now();

        try {
            SyncLogDto syncResult = syncService.syncAll(effectiveBranch);
            recordsSynced = syncResult.getRecordCount() != null ? syncResult.getRecordCount() : 0;
            syncStatus = syncResult.getStatus() != null ? syncResult.getStatus() : "FAILED";
            syncLogId = syncResult.getId();
            syncedAt = syncResult.getCompletedAt() != null ? syncResult.getCompletedAt() : LocalDateTime.now();

            if (!"COMPLETED".equalsIgnoreCase(syncStatus)) {
                String error = syncResult.getErrorMessage();
                errors.add(error != null && !error.isBlank()
                        ? error
                        : "A teljes szinkronizáció nem COMPLETED státusszal zárult.");
            }
        } catch (Exception e) {
            errors.add("Szinkronizációs hiba: " + e.getMessage());
            log.error("Szinkronizáció sikertelen: branch={}", effectiveBranch, e);
        }

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("success", errors.isEmpty());
        result.put("status", syncStatus);
        result.put("recordsSynced", recordsSynced);
        result.put("errors", errors);
        result.put("syncedAt", syncedAt);
        result.put("branchId", effectiveBranch);
        result.put("workerId", workerId);
        result.put("syncLogId", syncLogId);
        return result;
    }

    public boolean shouldSync(UUID branchId) {
        UUID effectiveBranch = branchId != null ? branchId : SecurityUtils.getCurrentBranchId();
        // Simple check: if there are transactions today, sync is needed
        long todayCount = transactionRepository.findActiveByBranchAndDate(effectiveBranch, LocalDate.now()).size();
        return todayCount > 0;
    }
}
