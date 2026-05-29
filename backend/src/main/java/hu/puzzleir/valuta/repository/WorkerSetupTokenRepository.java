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

    /**
     * ATOMI felhasználás (Copilot review fix): csak akkor jelöli usedAt-tal, ha még
     * fel nem használt. A visszaadott sorszám 1, ha EZ a hívás nyerte a versenyt;
     * 0, ha közben más felhasználta — így két párhuzamos kérés nem tudja kétszer
     * felhasználni ugyanazt a tokent.
     */
    @Modifying(clearAutomatically = true)
    @Query("UPDATE WorkerSetupToken t SET t.usedAt = :now WHERE t.id = :id AND t.usedAt IS NULL")
    int markUsedIfUnused(@Param("id") Long id, @Param("now") Instant now);

    @Modifying
    @Query("DELETE FROM WorkerSetupToken t WHERE t.expiresAt < :cutoff OR t.usedAt IS NOT NULL")
    int deleteExpiredOrUsed(@Param("cutoff") Instant cutoff);
}
