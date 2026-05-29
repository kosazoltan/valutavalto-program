package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.WorkerSetupToken;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.Optional;

@Repository
public interface WorkerSetupTokenRepository extends JpaRepository<WorkerSetupToken, Long> {

    /** Aktív (fel nem használt) token a hash alapján. */
    Optional<WorkerSetupToken> findByTokenHashAndUsedAtIsNull(String tokenHash);

    @Modifying
    @Query("DELETE FROM WorkerSetupToken t WHERE t.expiresAt < :cutoff OR t.usedAt IS NOT NULL")
    int deleteExpiredOrUsed(@Param("cutoff") Instant cutoff);
}
