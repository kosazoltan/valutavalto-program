package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.AmlApprovalGrant;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Repository
public interface AmlApprovalGrantRepository extends JpaRepository<AmlApprovalGrant, Long> {

    /**
     * A még felhasználható (uses_remaining&gt;0), le nem járt grantok ID-jai a (company, pénztáros,
     * engedélyező) hármasra, a legrégebbi elöl. A hívó az elsőn próbál atomikus decrementet
     * ({@link #decrementIfAvailable}); ha az 0-t ad (közben elfogyott), a következőt próbálja.
     */
    @Query("""
            SELECT g.id FROM AmlApprovalGrant g
            WHERE g.companyId = :companyId
              AND g.cashierWorkerId = :cashierWorkerId
              AND g.approverWorkerId = :approverWorkerId
              AND g.usesRemaining > 0
              AND g.expiresAt > :now
            ORDER BY g.createdAt ASC
            """)
    List<Long> findConsumableIds(@Param("companyId") UUID companyId,
                                 @Param("cashierWorkerId") Long cashierWorkerId,
                                 @Param("approverWorkerId") Long approverWorkerId,
                                 @Param("now") LocalDateTime now);

    /**
     * Egyetlen grant atomikus elhasználása: {@code uses_remaining--} CSAK ha még &gt;0. A feltétel a
     * WHERE-ben van, ezért párhuzamos sync-nél sem fogyhat 0 alá (single-use garancia, Codex P2).
     *
     * @return 1 ha sikerült (a grant a hívóé lett), 0 ha közben kimerült.
     */
    @Modifying
    @Query("UPDATE AmlApprovalGrant g SET g.usesRemaining = g.usesRemaining - 1 "
            + "WHERE g.id = :id AND g.usesRemaining > 0")
    int decrementIfAvailable(@Param("id") Long id);
}
