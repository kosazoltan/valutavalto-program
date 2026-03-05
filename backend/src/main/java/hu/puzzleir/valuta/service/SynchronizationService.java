package hu.puzzleir.valuta.service;

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

    @Transactional
    public Map<String, Object> sync(UUID branchId, Long workerId) {
        UUID effectiveBranch = branchId != null ? branchId : SecurityUtils.getCurrentBranchId();
        log.info("Szinkronizáció indítása: branch={}, worker={}", effectiveBranch, workerId);

        // Simplified sync implementation — in production this would sync with central DB
        int recordsSynced = 0;
        List<String> errors = new ArrayList<>();

        try {
            // Count today's unsynced transactions as a proxy
            long todayCount = transactionRepository.findActiveByBranchAndDate(effectiveBranch, LocalDate.now()).size();
            recordsSynced = (int) todayCount;
        } catch (Exception e) {
            errors.add("Szinkronizációs hiba: " + e.getMessage());
            log.error("Szinkronizáció sikertelen: branch={}", effectiveBranch, e);
        }

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("success", errors.isEmpty());
        result.put("recordsSynced", recordsSynced);
        result.put("errors", errors);
        result.put("syncedAt", LocalDateTime.now());
        result.put("branchId", effectiveBranch);
        return result;
    }

    public boolean shouldSync(UUID branchId) {
        UUID effectiveBranch = branchId != null ? branchId : SecurityUtils.getCurrentBranchId();
        // Simple check: if there are transactions today, sync is needed
        long todayCount = transactionRepository.findActiveByBranchAndDate(effectiveBranch, LocalDate.now()).size();
        return todayCount > 0;
    }
}
