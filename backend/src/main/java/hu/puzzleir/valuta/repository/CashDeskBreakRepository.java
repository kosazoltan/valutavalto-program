package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.CashDeskBreak;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Pénztár szünet repository.
 *
 * <p>v2.3.2 multi-tenant audit: a {@code findAllByOrderByBreakStartDesc()} eltavolitva.
 * Minden listazas company-scope-os {@link #findByCompanyIdOrderByBreakStartDesc(UUID)}-en
 * keresztul, a CashDesk.companyId join-nal.</p>
 */
@Repository
public interface CashDeskBreakRepository extends JpaRepository<CashDeskBreak, UUID> {

    /**
     * Pénztárgép összes szünete (a CashDesk maga company-scope-os, igy ez biztonsagos)
     */
    List<CashDeskBreak> findByCashDeskIdOrderByBreakStartDesc(UUID cashDeskId);

    /**
     * Aktív szünet keresése pénztárgéphez
     */
    Optional<CashDeskBreak> findByCashDeskIdAndIsActiveTrue(UUID cashDeskId);

    /**
     * v2.3.2 multi-tenant boundary: az adott company osszes pénztárgép-szünete (legújabb elöl).
     * Native subquery-vel a CashDesk.companyId-n at; a tenant-elszigeteles igy garantalt.
     */
    @Query("""
        SELECT b FROM CashDeskBreak b
        WHERE b.cashDeskId IN (
            SELECT cd.id FROM CashDesk cd WHERE cd.companyId = :companyId
        )
        ORDER BY b.breakStart DESC
    """)
    List<CashDeskBreak> findByCompanyIdOrderByBreakStartDesc(@Param("companyId") UUID companyId);
}
