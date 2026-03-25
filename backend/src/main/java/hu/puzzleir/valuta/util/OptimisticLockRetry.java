package hu.puzzleir.valuta.util;

import hu.puzzleir.valuta.exception.BusinessException;

import jakarta.persistence.OptimisticLockException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.orm.ObjectOptimisticLockingFailureException;

import java.util.function.Supplier;

/**
 * Optimistic lock retry segédosztály.
 * Pénzügyi műveleteknél max 3 próbálkozás, köztük rövid várakozással.
 */
@Slf4j
public final class OptimisticLockRetry {

    private static final int MAX_RETRIES = 3;
    private static final long RETRY_DELAY_MS = 50;

    private OptimisticLockRetry() {}

    /**
     * Végrehajtja a műveletet, OptimisticLockException esetén újrapróbálja.
     *
     * @param operation a végrehajtandó művelet (friss entity-t KELL olvasnia!)
     * @param operationName log üzenethez
     * @return a művelet eredménye
     */
    public static <T> T execute(Supplier<T> operation, String operationName) {
        for (int attempt = 1; attempt <= MAX_RETRIES; attempt++) {
            try {
                return operation.get();
            } catch (OptimisticLockException | ObjectOptimisticLockingFailureException e) {
                if (attempt == MAX_RETRIES) {
                    log.error("OptimisticLock FAILED after {} attempts: {}", MAX_RETRIES, operationName);
                    throw e;
                }
                log.warn("OptimisticLock conflict (attempt {}/{}): {} — retrying...",
                        attempt, MAX_RETRIES, operationName);
                try {
                    Thread.sleep(RETRY_DELAY_MS * attempt);
                } catch (InterruptedException ie) {
                    Thread.currentThread().interrupt();
                    throw new BusinessException("Retry interrupted", "RETRY_INTERRUPTED");
                }
            }
        }
        // Unreachable
        throw new IllegalStateException("Retry loop exited unexpectedly");
    }

    /**
     * Void művelet retry-ja.
     */
    public static void executeVoid(Runnable operation, String operationName) {
        execute(() -> { operation.run(); return null; }, operationName);
    }
}
