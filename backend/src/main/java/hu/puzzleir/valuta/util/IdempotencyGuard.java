package hu.puzzleir.valuta.util;

import tools.jackson.core.JacksonException;
import tools.jackson.databind.JavaType;
import tools.jackson.databind.ObjectMapper;
import hu.puzzleir.valuta.entity.IdempotencyRecord;
import hu.puzzleir.valuta.exception.ConflictException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.IdempotencyRecordRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.service.AuditLogService;
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
 * Audit P0.5 (2026-05-03) — perzisztens idempotencia vedelem.
 *
 * <p>A korabbi in-memory `ConcurrentHashMap`-alapu implementacio
 * (memory-leak, restart-vesztes, multi-instance hibak, payload-binding hianya)
 * helyett DB-perzisztens, payload-hash binding-os, multi-tenant scope-pal.</p>
 *
 * <p>Hasznalati minta a controllerekben:</p>
 * <pre>{@code
 * String key = request.getHeader("Idempotency-Key");
 * String endpoint = "POST /api/v1/transactions/buy";
 * IdempotencyGuard.Acquired<TransactionDto> acquired =
 *     idempotencyGuard.tryAcquire(key, endpoint, requestBody, TransactionDto.class);
 * if (acquired.cachedResult() != null) {
 *     return ResponseEntity.status(201).body(acquired.cachedResult());
 * }
 * try {
 *     TransactionDto result = ...;
 *     idempotencyGuard.complete(acquired, result);
 *     return ResponseEntity.status(201).body(result);
 * } catch (Exception e) {
 *     idempotencyGuard.fail(acquired);
 *     throw e;
 * }
 * }</pre>
 *
 * <p>Garanciak:</p>
 * <ul>
 *   <li>multi-instance: DB-szintű unique constraint a `(company_id, endpoint, idempotency_key)`-en.</li>
 *   <li>restart-bizots: DB-perzisztens, nem in-memory.</li>
 *   <li>payload binding: SHA-256 a request body-ra; `key + payload-mismatch -> 409 Conflict`.</li>
 *   <li>kulcs-validacio: max 255 karakter, nyomtathato ASCII; ervenytelen kulcs -> 400 (IDEM-KEYLEN).</li>
 *   <li>replay-audit: cache-elt COMPLETED valasz kiszolgalasa IDEMPOTENCY_CACHE_HIT audit-esemenyt ir (IDEM-CACHEHIT-AUDIT).</li>
 *   <li>TTL cleanup: `IdempotencyCleanupJob` orankent torli a lejart entry-ket.</li>
 * </ul>
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class IdempotencyGuard {

    private static final Duration DEFAULT_TTL = Duration.ofHours(24);
    /** A DB-oszlop limitje: idempotency_record.idempotency_key VARCHAR(255) (IdempotencyRecord.java:50). */
    private static final int MAX_KEY_LENGTH = 255;

    private final IdempotencyRecordRepository repository;
    private final ObjectMapper objectMapper;
    private final AuditLogService auditLogService;

    /**
     * Sikeres lookup vagy ujonnan acquire-olt rekord.
     * - `cachedResult` != null: korabbi COMPLETED entry, atadhato a kliensnek.
     * - `cachedResult` == null + `record` != null: most foglaltunk PROCESSING-et,
     *   a hivo elvegezheti a tenyleges muveletet, majd `complete(acquired, result)`-tel zar.
     */
    public record Acquired<T>(IdempotencyRecord record, T cachedResult, Class<T> resultType) {
    }

    /**
     * Try-acquire egy idempotency key-re payload-binding-gel.
     *
     * @param idempotencyKey kliens-altal generalt UUID (Idempotency-Key header)
     * @param endpoint endpoint azonositoja (pl. "POST /api/v1/transactions/buy")
     * @param requestBody serializalando request DTO; null = "no payload" hash
     * @param resultType a varhato response DTO tipusa (deserializalashoz)
     * @param <T> response DTO tipus
     * @return korabbi cached result vagy uj PROCESSING rekord (acquired.cachedResult() == null)
     * @throws ConflictException ha ugyanaz a key-en mas payload erkezett (cache poisoning vedelem)
     * @throws ConflictException ha a kulcs jelenleg PROCESSING (parhuzamos dupla kerelem)
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public <T> Acquired<T> tryAcquire(
            String idempotencyKey,
            String endpoint,
            Object requestBody,
            Class<T> resultType) {
        if (idempotencyKey == null || idempotencyKey.isBlank()) {
            // Backward compat: no key -> no protection
            return new Acquired<>(null, null, resultType);
        }
        validateKey(idempotencyKey);
        if (endpoint == null || endpoint.isBlank()) {
            throw new IllegalArgumentException("endpoint kotelezo");
        }
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        String requestHash = computeRequestHash(requestBody);

        Optional<IdempotencyRecord> existing = repository
                .findByCompanyIdAndEndpointAndIdempotencyKey(companyId, endpoint, idempotencyKey);

        if (existing.isPresent()) {
            IdempotencyRecord rec = existing.get();
            if (!requestHash.equals(rec.getRequestHash())) {
                // Payload-mismatch: cache poisoning attempt vagy kliens-bug.
                log.warn("Idempotency key reuse with different payload — endpoint={} keyHash={}",
                        endpoint, hashKeyForLog(idempotencyKey));
                throw new ConflictException(
                        "Idempotency-Key reuse with different request payload");
            }
            return switch (rec.getStatus()) {
                case COMPLETED -> {
                    T cached = deserializeResponse(rec.getResponseJson(), resultType);
                    log.info("Idempotency hit: endpoint={} keyHash={} (cached COMPLETED)",
                            endpoint, hashKeyForLog(idempotencyKey));
                    auditCacheHit(endpoint, idempotencyKey);
                    yield new Acquired<>(rec, cached, resultType);
                }
                case PROCESSING -> {
                    log.warn("Idempotency PROCESSING in-flight — endpoint={} keyHash={}",
                            endpoint, hashKeyForLog(idempotencyKey));
                    throw new ConflictException(
                            "A keres feldolgozas alatt all. Kerjuk ne kuldje el ujra!");
                }
                case FAILED -> {
                    // Codex P1 PR #358 follow-up: ket konkurens retry FAILED branch race condition.
                    // Atomic FAILED -> PROCESSING atmenet pesszimista lock-kal:
                    // 1. SELECT ... FOR UPDATE — a masik retry blokkolva varakozik a lock-ra.
                    // 2. Double-check: meg mindig FAILED? Ha igen -> mi update-eljuk PROCESSING-re.
                    //    Ha NEM (mar PROCESSING/COMPLETED a masik altal): re-evaluate.
                    IdempotencyRecord locked = repository
                            .findByCompanyIdAndEndpointAndIdempotencyKeyForUpdate(
                                    companyId, endpoint, idempotencyKey)
                            .orElseThrow(() ->
                                new IllegalStateException("Idempotency record disappeared during lock"));
                    if (locked.getStatus() == IdempotencyRecord.Status.PROCESSING) {
                        // Masik retry mar PROCESSING-re allitotta — mi blokkoljuk magunkat.
                        log.warn("Idempotency PROCESSING in-flight (FAILED-retry race) endpoint={} keyHash={}",
                                endpoint, hashKeyForLog(idempotencyKey));
                        throw new ConflictException(
                                "A keres feldolgozas alatt all. Kerjuk ne kuldje el ujra!");
                    }
                    if (locked.getStatus() == IdempotencyRecord.Status.COMPLETED) {
                        // Masik retry mar COMPLETED — payload check + cache hit.
                        if (!requestHash.equals(locked.getRequestHash())) {
                            throw new ConflictException(
                                    "Idempotency-Key reuse with different request payload");
                        }
                        T cached = deserializeResponse(locked.getResponseJson(), resultType);
                        auditCacheHit(endpoint, idempotencyKey);
                        yield new Acquired<>(locked, cached, resultType);
                    }
                    // Status == FAILED, mi nyertuk a lock-ot. Atallitjuk PROCESSING-re.
                    locked.setStatus(IdempotencyRecord.Status.PROCESSING);
                    locked.setRequestHash(requestHash);
                    locked.setResponseJson(null);
                    locked.setCompletedAt(null);
                    locked.setExpiresAt(Instant.now().plus(DEFAULT_TTL));
                    repository.save(locked);
                    yield new Acquired<>(locked, null, resultType);
                }
            };
        }

        // Uj rekord PROCESSING statusszal — race-mentes a UNIQUE constraint-tel.
        IdempotencyRecord fresh = IdempotencyRecord.builder()
                .companyId(companyId)
                .endpoint(endpoint)
                .idempotencyKey(idempotencyKey)
                .requestHash(requestHash)
                .status(IdempotencyRecord.Status.PROCESSING)
                .createdAt(Instant.now())
                .expiresAt(Instant.now().plus(DEFAULT_TTL))
                .build();
        try {
            IdempotencyRecord saved = repository.save(fresh);
            return new Acquired<>(saved, null, resultType);
        } catch (DataIntegrityViolationException race) {
            // Konkurens insert ugyanazon kulcsra — read-back a masik rekord.
            // (UNIQUE constraint elinditja a violation-t a transaction commit-jenel.)
            log.warn("Idempotency race detected — re-reading concurrent record");
            IdempotencyRecord rec = repository
                    .findByCompanyIdAndEndpointAndIdempotencyKey(companyId, endpoint, idempotencyKey)
                    .orElseThrow(() -> race);
            if (rec.getStatus() == IdempotencyRecord.Status.PROCESSING) {
                throw new ConflictException(
                        "A keres feldolgozas alatt all. Kerjuk ne kuldje el ujra!");
            }
            T cached = null;
            if (rec.getStatus() == IdempotencyRecord.Status.COMPLETED) {
                cached = deserializeResponse(rec.getResponseJson(), resultType);
                auditCacheHit(endpoint, idempotencyKey);
            }
            return new Acquired<>(rec, cached, resultType);
        }
    }

    /** Sikeres feldolgozas rogzitese. */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public <T> void complete(Acquired<T> acquired, T result) {
        if (acquired == null || acquired.record() == null) return;
        IdempotencyRecord rec = acquired.record();
        rec.setStatus(IdempotencyRecord.Status.COMPLETED);
        rec.setResponseJson(serializeResponse(result));
        rec.setCompletedAt(Instant.now());
        repository.save(rec);
    }

    /** Sikertelen feldolgozas — engedjuk a kesobbi ujraprobalkozast. */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public <T> void fail(Acquired<T> acquired) {
        if (acquired == null || acquired.record() == null) return;
        IdempotencyRecord rec = acquired.record();
        rec.setStatus(IdempotencyRecord.Status.FAILED);
        rec.setCompletedAt(Instant.now());
        repository.save(rec);
    }

    /**
     * Aspect-advisory IDEM-KEYLEN (2026-07-06): hossz- es charset-validacio.
     * Fail-closed: ervenytelen kulcs = 400, NEM csendes no-protection (a csendes eldobas
     * dupla-submitnal a vedelem elveszteset jelentene). A nyers kulcs a hibauzenetbe
     * SOHA nem kerul be (klienskontrollalt, akar tobb KB, log-injection vektor).
     */
    private static void validateKey(String key) {
        if (key.length() > MAX_KEY_LENGTH) {
            throw new ValidationException(
                    "Ervenytelen Idempotency-Key: legfeljebb " + MAX_KEY_LENGTH + " karakter lehet");
        }
        for (int i = 0; i < key.length(); i++) {
            char c = key.charAt(i);
            if (c < 0x20 || c > 0x7E) {
                throw new ValidationException(
                        "Ervenytelen Idempotency-Key: csak nyomtathato ASCII karakterek engedelyezettek");
            }
        }
    }

    private String computeRequestHash(Object requestBody) {
        try {
            String body = requestBody == null ? "" : objectMapper.writeValueAsString(requestBody);
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            byte[] digest = md.digest(body.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(digest);
        } catch (JacksonException | NoSuchAlgorithmException e) {
            throw new IllegalStateException("Idempotency request hash compute failed", e);
        }
    }

    private <T> T deserializeResponse(String json, Class<T> resultType) {
        if (json == null) return null;
        try {
            JavaType type = objectMapper.getTypeFactory().constructType(resultType);
            return objectMapper.readValue(json, type);
        } catch (JacksonException e) {
            throw new IllegalStateException("Idempotency response deserialize failed", e);
        }
    }

    private String serializeResponse(Object result) {
        try {
            return objectMapper.writeValueAsString(result);
        } catch (JacksonException e) {
            throw new IllegalStateException("Idempotency response serialize failed", e);
        }
    }

    /**
     * Aspect-advisory IDEM-CACHEHIT-AUDIT (2026-07-06): replay-esemeny audit-nyomvonala.
     * MINDEN cache-elt COMPLETED valasz kiszolgalasakor hivodik (fo COMPLETED ag,
     * FAILED-lock utani double-check, konkurens-insert race read-back). Sima REQUIRED
     * propagacio: a tryAcquire REQUIRES_NEW tranzakciojaval egyutt commitol (a cache-hit
     * agon nincs penzmozgas-rollback-kockazat). A nyers kulcs nem kerul audit-mezobe.
     */
    private void auditCacheHit(String endpoint, String idempotencyKey) {
        String keyHash = hashKeyForLog(idempotencyKey);
        auditLogService.log(
                "IDEMPOTENCY_CACHE_HIT",
                "IDEMPOTENCY",
                keyHash,
                resolveWorkerCode(),
                null, null, null,
                "Idempotencia cache-hit (replay): endpoint=" + endpoint + " keyHash=" + keyHash,
                null, null);
    }

    /**
     * Defenziv: a cache-hit idejen mar van auth-kontextus (getCurrentCompanyId korabban
     * lefutott), de a principal-cast/hianyzo details eseten inkabb null userId, mint 500.
     */
    private static String resolveWorkerCode() {
        try {
            return SecurityUtils.getCurrentWorkerCode();
        } catch (Exception e) {
            return null;
        }
    }

    /** Defenziv: nyers kulcs helyett rovid hex hash a logoknak. */
    private String hashKeyForLog(String key) {
        return Integer.toHexString(key.hashCode());
    }
}
