package hu.puzzleir.valuta.config;

import hu.puzzleir.valuta.repository.IdempotencyRecordRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;

/**
 * Audit P0.5 (2026-05-03) — TTL cleanup a `idempotency_record` tablahoz.
 *
 * <p>Orankent torli a lejart entry-ket. A lejarat 24h (default a `IdempotencyGuard`-ban),
 * igy normal mukodes mellett max ~25h-ig latszhat egy record cleanup elott.</p>
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class IdempotencyCleanupJob {

    private final IdempotencyRecordRepository repository;

    /** Cron: minden ora 0. perc 30. masodperc. */
    @Scheduled(cron = "30 0 * * * *")
    @Transactional
    public void cleanupExpired() {
        int deleted = repository.deleteByExpiresAtBefore(Instant.now());
        if (deleted > 0) {
            log.info("Idempotency cleanup: {} lejart rekord torolve", deleted);
        }
    }
}
