package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.RefreshToken;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

@Repository
public interface RefreshTokenRepository extends JpaRepository<RefreshToken, Long> {

    Optional<RefreshToken> findByTokenHash(String tokenHash);

    /** Audit P0.3 (2026-05-03): selector lookup — O(1) DB index, NEM N×BCrypt. */
    Optional<RefreshToken> findBySelector(String selector);

    List<RefreshToken> findByWorkerIdAndRevokedAtIsNull(Long workerId);

    @Modifying
    @Query("UPDATE RefreshToken rt SET rt.revokedAt = :now WHERE rt.workerId = :workerId AND rt.revokedAt IS NULL")
    int revokeAllForWorker(@Param("workerId") Long workerId, @Param("now") Instant now);

    @Modifying
    @Query("DELETE FROM RefreshToken rt WHERE rt.expiresAt < :cutoff")
    int deleteExpired(@Param("cutoff") Instant cutoff);
}
