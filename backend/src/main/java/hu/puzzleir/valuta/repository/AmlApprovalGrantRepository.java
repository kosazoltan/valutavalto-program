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
     * A (company, pénztáros, engedélyező, session) hármasra tartozó, le nem járt grantok — a felhasználástól
     * FÜGGETLENÜL (uses_remaining 0 is). A hívó ebből (a) ellenőrzi az ügyfél-kötést (customer_key), és (b)
     * megkülönbözteti a "kimerült de létező" (sibling-sor, jóváhagyás-fedett) esetet a "nincs grant"
     * (forge) esettől. Codex P1: a customer-kötés akadályozza meg a session nem-összefüggő tranzakcióra
     * történő újrahasználatát.
     */
    @Query("""
            SELECT g FROM AmlApprovalGrant g
            WHERE g.companyId = :companyId
              AND g.cashierWorkerId = :cashierWorkerId
              AND g.approverWorkerId = :approverWorkerId
              AND g.sessionId = :sessionId
              AND g.expiresAt > :now
            ORDER BY g.createdAt ASC
            """)
    List<AmlApprovalGrant> findActiveBySessionScope(@Param("companyId") UUID companyId,
                                                    @Param("cashierWorkerId") Long cashierWorkerId,
                                                    @Param("approverWorkerId") Long approverWorkerId,
                                                    @Param("sessionId") String sessionId,
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
