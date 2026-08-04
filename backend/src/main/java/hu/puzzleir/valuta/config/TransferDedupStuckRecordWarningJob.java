package hu.puzzleir.valuta.config;

import hu.puzzleir.valuta.repository.IdempotencyRecordRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/**
 * FKH-028 7. kör: a beragadt (régóta PROCESSING állapotú) Transfer-dedup rekordok
 * FIGYELMEZTETŐ monitorozása — az IdempotencyCleanupJob mintájára.
 *
 * <p>Háttér (Codex BLOCKING a 6. kör automatikus stale-átvételére): nincs garancia,
 * hogy egy legitim kérés adott időn belül lefut, és a release nem tulajdonos-alapú —
 * ezért az automatikus átvétel kivezetésre került. Ez a job KIZÁRÓLAG riaszt
 * (log.warn), SEMMIT nem módosít és nem töröl; a beragadt rekord feloldása manuális
 * admin-eljárás: {@code docs/ops/idempotency-stuck-record-recovery.md}.</p>
 *
 * <p>Megjegyzés: a dedup-kulcs SHA-256 hash (a worker/cél/valuta/összeg tuple szándékosan
 * nem visszafejthető belőle), ezért a riasztás a rekord-azonosítót, a korát és a
 * kulcs-hash-t tartalmazza — a konkrét átadás a szerver-log időbeli korrelációjával
 * azonosítható (ld. az ops-dokumentum 2. lépését).</p>
 */
@Component
@Slf4j
public class TransferDedupStuckRecordWarningJob {

    private final IdempotencyRecordRepository repository;
    /** Konfigurálható küszöb (perc): ennél régebbi PROCESSING rekord számít beragadtnak. */
    private final long stuckWarnMinutes;

    public TransferDedupStuckRecordWarningJob(
            IdempotencyRecordRepository repository,
            @Value("${app.transfer-dedup.stuck-warn-minutes:15}") long stuckWarnMinutes) {
        this.repository = repository;
        this.stuckWarnMinutes = stuckWarnMinutes;
    }

    /** 5 percenként fut; csak riaszt, nem avatkozik be. */
    @Scheduled(fixedDelayString = "${app.transfer-dedup.stuck-warn-check-ms:300000}")
    public void warnStuckRecords() {
        java.time.Instant threshold = java.time.Instant.now()
                .minus(java.time.Duration.ofMinutes(stuckWarnMinutes));
        for (hu.puzzleir.valuta.entity.IdempotencyRecord rec :
                repository.findByEndpointAndStatusAndCreatedAtBefore(
                        hu.puzzleir.valuta.service.TransferCreateDedupGuard.ENDPOINT,
                        hu.puzzleir.valuta.entity.IdempotencyRecord.Status.PROCESSING,
                        threshold)) {
            long ageMinutes = rec.getCreatedAt() != null
                    ? java.time.Duration.between(rec.getCreatedAt(), java.time.Instant.now()).toMinutes()
                    : -1;
            log.warn("BERAGADT Transfer-dedup rekord: id={}, kulcs-hash={}, {} perce PROCESSING "
                            + "(létrejött: {}). A rekord feloldása MANUÁLIS admin-eljárás — "
                            + "ld. docs/ops/idempotency-stuck-record-recovery.md; a konkrét átadás "
                            + "a szerver-log időbeli korrelációjával azonosítható.",
                    rec.getId(), rec.getIdempotencyKey(), ageMinutes, rec.getCreatedAt());
        }
    }
}
