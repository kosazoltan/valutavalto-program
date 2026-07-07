package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.DocumentViewGrant;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Repository
public interface DocumentViewGrantRepository extends JpaRepository<DocumentViewGrant, Long> {

    /**
     * A (company, requester, documentId) hármasra tartozó, le nem járt grantok.
     * A hívó ebből választja ki az első felhasználhatót (atomikus decrement).
     */
    @Query("""
            SELECT g FROM DocumentViewGrant g
            WHERE g.companyId = :companyId
              AND g.requesterWorkerId = :requesterWorkerId
              AND g.documentId = :documentId
              AND g.expiresAt > :now
            ORDER BY g.createdAt ASC
            """)
    List<DocumentViewGrant> findActiveForDocument(@Param("companyId") UUID companyId,
            @Param("requesterWorkerId") Long requesterWorkerId,
            @Param("documentId") UUID documentId, @Param("now") LocalDateTime now);

    /**
     * Egyetlen grant atomikus elhasználása: {@code uses_remaining--} CSAK ha még &gt;0.
     * A feltétel a WHERE-ben van, ezért párhuzamos hívásoknál sem fogyhat 0 alá.
     *
     * @return 1 ha sikerült (a grant a hívóé lett), 0 ha közben kimerült.
     */
    @Modifying
    @Query("UPDATE DocumentViewGrant g SET g.usesRemaining = g.usesRemaining - 1 "
            + "WHERE g.id = :id AND g.companyId = :companyId "
            + "AND g.requesterWorkerId = :requesterWorkerId AND g.usesRemaining > 0")
    int decrementIfAvailable(@Param("id") Long id, @Param("companyId") UUID companyId,
            @Param("requesterWorkerId") Long requesterWorkerId);
}
