package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.AmlApprovalGrant;
import org.springframework.data.domain.Limit;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Repository
public interface AmlApprovalGrantRepository extends JpaRepository<AmlApprovalGrant, Long> {

    /**
     * Fel nem használt, le nem járt grant(ek) a (company, pénztáros, engedélyező) hármasra, a
     * legrégebbi elöl. A hívó az elsőt fogyasztja el (single-use). Több párhuzamos jóváhagyás
     * (ugyanaz az engedélyező, ugyanaz a pénztáros, több tranzakció) több grantot jelent.
     */
    @Query("""
            SELECT g FROM AmlApprovalGrant g
            WHERE g.companyId = :companyId
              AND g.cashierWorkerId = :cashierWorkerId
              AND g.approverWorkerId = :approverWorkerId
              AND g.usedAt IS NULL
              AND g.expiresAt > :now
            ORDER BY g.createdAt ASC
            """)
    List<AmlApprovalGrant> findConsumable(@Param("companyId") UUID companyId,
                                          @Param("cashierWorkerId") Long cashierWorkerId,
                                          @Param("approverWorkerId") Long approverWorkerId,
                                          @Param("now") LocalDateTime now,
                                          Limit limit);
}
