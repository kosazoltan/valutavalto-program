package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.transfer.CreateTransferDto;
import hu.puzzleir.valuta.entity.IdempotencyRecord;
import hu.puzzleir.valuta.exception.ConflictException;
import hu.puzzleir.valuta.repository.IdempotencyRecordRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.Duration;
import java.time.Instant;
import java.util.HexFormat;
import java.util.Optional;
import java.util.UUID;

/**
 * FKH-028 (5. kör, Codex HIGH-2/MEDIUM): DB-perzisztens, ÁLLAPOT-alapú duplikátum-védelem
 * a Transfer create-hez — a korábbi in-memory ConcurrentHashMap + időalapú removeIf helyett.
 *
 * <p>A meglévő {@link IdempotencyRecord} entitást és repository-t használja (Audit P0.5
 * minta: DB-perzisztens, multi-instance-biztos, {@code (company_id, endpoint, key)} UNIQUE,
 * TTL-cleanup az IdempotencyCleanupJob-bal). A teljes {@code IdempotencyGuard} viszont
 * SZÁNDÉKOSAN nincs ráerőltetve erre a use-case-re (Fázis 0 döntés): az kliens-generált
 * Idempotency-Key headerre és COMPLETED-válasz REPLAY-re épül — a Transfer-dedup kulcsa
 * viszont SZERVER-oldalon származtatott a paraméterekből, és egy későbbi, azonos paraméterű
 * legitim átadásnak ÚJ bizonylatot kell kapnia, nem a régi cache-elt választ.</p>
 *
 * <p>Szemantika:
 * <ul>
 *   <li><b>PROCESSING</b> (folyamatban lévő azonos kérés): elutasítás — IDŐKORLÁT NÉLKÜL
 *       (a 3 mp-nél lassabb feldolgozás alatt érkező retry is elutasítva — HIGH-2 fix).</li>
 *   <li><b>COMPLETED az elmúlt {@value #RECENT_COMPLETED_WINDOW_MS} ms-en belül</b>:
 *       elutasítás (a frissen lezárt duplikátum-ablak, az eredeti FK 2-3 mp-es irányszáma).</li>
 *   <li><b>FAILED vagy régebbi COMPLETED</b>: a kulcs átvehető, a kérés átmegy.</li>
 * </ul>
 * A feloldást a hívó a tranzakció TÉNYLEGES befejezésekor végzi
 * (TransactionSynchronization.afterCompletion — commit/flush-bukásnál is), nem időzítővel.</p>
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class TransferCreateDedupGuard {

    /** A frissen COMPLETED kulcs még ennyi ideig számít duplikátumnak (az FK 2-3 mp irányszáma). */
    static final long RECENT_COMPLETED_WINDOW_MS = 3000;
    /** A dedup-rekordok endpoint-scope-ja az idempotency_record táblában (a monitor-job is használja). */
    public static final String ENDPOINT = "TRANSFER_CREATE_DEDUP";
    /** Rövid TTL a cleanup-jobnak — a dedup-rekord percek után már irreleváns. */
    private static final Duration TTL = Duration.ofHours(1);
    /**
     * FKH-028 6. kör (MEDIUM-kompenzáció): ha a release() minden retry-jal együtt elbukott
     * (vagy a folyamat összeomlott), a PROCESSING kulcs beragadna — az ennél régebbi
     * PROCESSING rekordot az acquire a zár alatt ÁTVESZI. Egy create sosem tart percekig,
     * így a false-conflict ablak a korábbi ~2 órás TTL/cleanup helyett legfeljebb ennyi.
     */
    static final long STALE_PROCESSING_TAKEOVER_MS = Duration.ofMinutes(10).toMillis();
    /** A V175-ös unique index neve — a duplikátum-detekció KIZÁRÓLAG erre szűkített. */
    static final String DEDUP_UNIQUE_INDEX = "idempotency_record_unique_idx";

    private final IdempotencyRecordRepository repository;

    /** Szerver-oldalon származtatott dedup-kulcs (SHA-256 hex, 64 karakter). */
    public static String buildKey(Long workerId, CreateTransferDto dto) {
        String tuple = workerId + "|" + dto.getToBranchId() + "|" + dto.getCurrencyId()
                + "|" + (dto.getAmount() != null ? dto.getAmount().stripTrailingZeros().toPlainString() : "null")
                + "|" + dto.getDirection() + "|" + dto.getTransferType();
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            return HexFormat.of().formatHex(md.digest(tuple.getBytes(StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("Dedup-kulcs hash számítás sikertelen", e);
        }
    }

    /**
     * Kulcs-foglalás REQUIRES_NEW tranzakcióban — a PROCESSING sor AZONNAL commitolódik,
     * így a párhuzamos kérések számára is látható (a create() saját tranzakciójától
     * függetlenül). Ütközésnél ConflictException (409).
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void acquire(UUID companyId, String dedupKey) {
        Instant now = Instant.now();
        // FKH-028 6. kör (Codex HIGH): a meglévő rekordot PESSZIMISTA ZÁRRAL (SELECT ...
        // FOR UPDATE, az IdempotencyGuard FAILED-retry mintája) töltjük be — a
        // FAILED / lejárt-COMPLETED újrafoglalás státusz-döntése és átírása a zár alatt
        // történik, két konkurens kérésből a második a záron várakozik, majd a friss
        // (PROCESSING) állapotot látja és konfliktust kap.
        Optional<IdempotencyRecord> locked =
                repository.findByCompanyIdAndEndpointAndIdempotencyKeyForUpdate(companyId, ENDPOINT, dedupKey);
        if (locked.isPresent()) {
            IdempotencyRecord rec = locked.get();
            if (rec.getStatus() == IdempotencyRecord.Status.PROCESSING) {
                long ageMs = rec.getCreatedAt() != null
                        ? Duration.between(rec.getCreatedAt(), now).toMillis()
                        : Long.MAX_VALUE;
                if (ageMs <= STALE_PROCESSING_TAKEOVER_MS) {
                    throw duplicateRejected("az előző azonos beküldés még feldolgozás alatt áll");
                }
                // MEDIUM-kompenzáció: beragadt PROCESSING (release-hiba / folyamat-crash) —
                // a küszöbnél régebbi kulcsot a zár alatt átvesszük, nem várunk a cleanupra.
                log.warn("Beragadt PROCESSING dedup-kulcs átvétele (kora: {} ms) — "
                        + "release-hiba/crash kompenzáció", ageMs);
            } else if (rec.getStatus() == IdempotencyRecord.Status.COMPLETED
                    && rec.getCompletedAt() != null
                    && Duration.between(rec.getCompletedAt(), now).toMillis() <= RECENT_COMPLETED_WINDOW_MS) {
                throw duplicateRejected("ugyanez az átadás az elmúlt "
                        + (RECENT_COMPLETED_WINDOW_MS / 1000) + " másodpercben már rögzítésre került");
            }
            // FAILED, régi COMPLETED vagy beragadt PROCESSING: átvesszük a kulcsot (a zár alatt).
            rec.setStatus(IdempotencyRecord.Status.PROCESSING);
            rec.setCreatedAt(now);
            rec.setCompletedAt(null);
            rec.setResponseJson(null);
            rec.setExpiresAt(now.plus(TTL));
            repository.save(rec);
            return;
        }
        IdempotencyRecord fresh = IdempotencyRecord.builder()
                .companyId(companyId)
                .endpoint(ENDPOINT)
                .idempotencyKey(dedupKey)
                .requestHash(dedupKey)
                .status(IdempotencyRecord.Status.PROCESSING)
                .createdAt(now)
                .expiresAt(now.plus(TTL))
                .build();
        try {
            repository.save(fresh);
        } catch (DataIntegrityViolationException violation) {
            // FKH-028 6. kör (Codex MEDIUM): CSAK a dedup-unique-index tényleges ütközése
            // minősül duplikátumnak — bármilyen más integritási hiba a normál hibaútra megy.
            if (!isDedupUniqueViolation(violation)) {
                throw violation;
            }
            log.warn("Transfer-dedup insert-race — a konkurens azonos kérés elutasítva");
            throw duplicateRejected("az előző azonos beküldés még feldolgozás alatt áll");
        }
    }

    /** A kiváltó ok constraint-neve alapján dönt: tényleg a dedup unique indexe ütközött-e. */
    private static boolean isDedupUniqueViolation(DataIntegrityViolationException violation) {
        Throwable cur = violation;
        while (cur != null) {
            if (cur instanceof org.hibernate.exception.ConstraintViolationException cve) {
                String name = cve.getConstraintName();
                return name != null && name.contains(DEDUP_UNIQUE_INDEX);
            }
            cur = cur.getCause();
        }
        return false;
    }

    /**
     * Kulcs-feloldás a tranzakció TÉNYLEGES befejezésekor (afterCompletion / teszt-fallback).
     * Siker → COMPLETED (innen indul a {@value #RECENT_COMPLETED_WINDOW_MS} ms-es
     * frissen-lezárt ablak); bukás (rollback, commit/flush-hiba is) → FAILED, a kulcs
     * azonnal újrahasználható — nincs hamis konfliktus (MEDIUM fix).
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void release(UUID companyId, String dedupKey, boolean committed) {
        repository.findByCompanyIdAndEndpointAndIdempotencyKey(companyId, ENDPOINT, dedupKey)
                .ifPresent(rec -> {
                    rec.setStatus(committed
                            ? IdempotencyRecord.Status.COMPLETED
                            : IdempotencyRecord.Status.FAILED);
                    rec.setCompletedAt(Instant.now());
                    repository.save(rec);
                });
    }

    private static ConflictException duplicateRejected(String reason) {
        return new ConflictException("Valószínű duplikált beküldés: " + reason
                + ". Ellenőrizze az átadás-listát, mielőtt újra próbálja!");
    }
}
