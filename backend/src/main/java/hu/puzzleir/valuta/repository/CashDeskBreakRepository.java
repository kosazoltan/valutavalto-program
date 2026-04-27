package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.CashDeskBreak;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Pénztár szünet repository.
 *
 * AUDIT NOTE (audit-NO-GO-iter3 P0 fix, 2026-04-27):
 * All query methods are multi-tenant scoped via companyId.
 * The legacy {@code findByCashDeskId...} and {@code findAll...} queries are removed —
 * callers MUST go through {@code findByCompanyId...} variants. This prevents the
 * cross-tenant data leak previously possible via {@code GET /api/v1/cash-desk-breaks}
 * without a cashDeskId filter.
 */
@Repository
public interface CashDeskBreakRepository extends JpaRepository<CashDeskBreak, UUID> {

    /**
     * Company összes szünete (multi-tenant scoped, legújabb elöl).
     */
    List<CashDeskBreak> findByCompanyIdOrderByBreakStartDesc(UUID companyId);

    /**
     * Pénztárgép szünete adott company-n belül (multi-tenant scoped).
     */
    List<CashDeskBreak> findByCompanyIdAndCashDeskIdOrderByBreakStartDesc(UUID companyId, UUID cashDeskId);

    /**
     * Aktív szünet keresése pénztárgéphez (multi-tenant scoped).
     */
    Optional<CashDeskBreak> findByCompanyIdAndCashDeskIdAndIsActiveTrue(UUID companyId, UUID cashDeskId);
}
