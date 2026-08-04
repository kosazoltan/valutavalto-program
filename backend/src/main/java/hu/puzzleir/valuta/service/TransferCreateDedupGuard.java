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
    /** A dedup-rekordok endpoint-scope-ja az idempotency_record táblában. */
    static final String ENDPOINT = "TRANSFER_CREATE_DEDUP";
    /** Rövid TTL a cleanup-jobnak — a dedup-rekord percek után már irreleváns. */
    private static final Duration TTL = Duration.ofHours(1);

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
        Optional<IdempotencyRecord> existing =
                repository.findByCompanyIdAndEndpointAndIdempotencyKey(companyId, ENDPOINT, dedupKey);
        if (existing.isPresent()) {
            IdempotencyRecord rec = existing.get();
            if (rec.getStatus() == IdempotencyRecord.Status.PROCESSING) {
                throw duplicateRejected("az előző azonos beküldés még feldolgozás alatt áll");
            }
            if (rec.getStatus() == IdempotencyRecord.Status.COMPLETED
                    && rec.getCompletedAt() != null
                    && Duration.between(rec.getCompletedAt(), now).toMillis() <= RECENT_COMPLETED_WINDOW_MS) {
                throw duplicateRejected("ugyanez az átadás az elmúlt "
                        + (RECENT_COMPLETED_WINDOW_MS / 1000) + " másodpercben már rögzítésre került");
            }
            // FAILED vagy régi COMPLETED: átvesszük a kulcsot.
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
        } catch (DataIntegrityViolationException race) {
            // Két tényleg párhuzamos azonos kérés — a UNIQUE constraint dönt, a vesztes 409.
            log.warn("Transfer-dedup insert-race — a konkurens azonos kérés elutasítva");
            throw duplicateRejected("az előző azonos beküldés még feldolgozás alatt áll");
        }
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
