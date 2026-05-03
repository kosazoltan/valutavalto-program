package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.IdempotencyRecord;
import org.springframework.data.jpa.repository.JpaRepository;
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
     * TTL cleanup: lejart entry-k torlese.
     *
     * @return torolt rekordok szama
     */
    @Modifying
    @Query("DELETE FROM IdempotencyRecord r WHERE r.expiresAt < :now")
    int deleteByExpiresAtBefore(@Param("now") Instant now);
}
