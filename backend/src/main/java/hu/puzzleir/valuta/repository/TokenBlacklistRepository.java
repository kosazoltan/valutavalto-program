package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.TokenBlacklist;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;

@Repository
public interface TokenBlacklistRepository extends JpaRepository<TokenBlacklist, Long> {

    boolean existsByTokenId(String tokenId);

    /**
     * Lejárt blacklist bejegyzések törlése — @Scheduled cleanup-hoz.
     * A JWT 24 órás, tehát a lejárt tokeneket már nem kell nyilvántartani.
     */
    @Modifying
    @Query("DELETE FROM TokenBlacklist t WHERE t.expiresAt < :now")
    int deleteExpiredEntries(LocalDateTime now);
}
