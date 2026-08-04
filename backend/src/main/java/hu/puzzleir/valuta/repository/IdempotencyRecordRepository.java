package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.IdempotencyRecord;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface IdempotencyRecordRepository extends JpaRepository<IdempotencyRecord, Long> {

    /** Multi-tenant scope-pal: company + endpoint + idempotency_key UNIQUE lookup. */
    Optional<IdempotencyRecord> findByCompanyIdAndEndpointAndIdempotencyKey(
            UUID companyId, String endpoint, String idempotencyKey);

    /**
     * FKH-028 7. kör: a beragadt (régóta PROCESSING) dedup-rekordok monitorozásához —
     * a TransferDedupStuckRecordWarningJob riasztó lekérdezése (read-only, lock nélkül).
     */
    java.util.List<IdempotencyRecord> findByEndpointAndStatusAndCreatedAtBefore(
            String endpoint, IdempotencyRecord.Status status, java.time.Instant createdBefore);

    /**
     * Codex P1 PR #358 follow-up: pesszimista row-level lock a FAILED -> PROCESSING
     * atmenethez. Ket konkurens retry kozul csak EGY tudja olvasni FAILED-kent
     * es uj PROCESSING-re allitani — a masik a `SELECT FOR UPDATE` blokkjaban
     * varakozik, majd a frissitett (PROCESSING) statust olvassa.
     */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT r FROM IdempotencyRecord r " +
           "WHERE r.companyId = :companyId " +
           "AND r.endpoint = :endpoint " +
           "AND r.idempotencyKey = :idempotencyKey")
    Optional<IdempotencyRecord> findByCompanyIdAndEndpointAndIdempotencyKeyForUpdate(
            @Param("companyId") UUID companyId,
            @Param("endpoint") String endpoint,
            @Param("idempotencyKey") String idempotencyKey);

    /**
     * TTL cleanup: lejart entry-k torlese.
     *
     * @return torolt rekordok szama
     */
    @Modifying
    @Query("DELETE FROM IdempotencyRecord r WHERE r.expiresAt < :now")
    int deleteByExpiresAtBefore(@Param("now") Instant now);
}
