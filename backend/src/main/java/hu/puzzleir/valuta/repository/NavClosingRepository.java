package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.NavClosing;
import hu.puzzleir.valuta.entity.NavClosingStatus;
import hu.puzzleir.valuta.entity.NavClosingType;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * NAV zárás repository.
 */
@Repository
public interface NavClosingRepository extends JpaRepository<NavClosing, UUID> {

    /**
     * Napi zárás keresése iroda és dátum alapján
     */
    Optional<NavClosing> findByBranchIdAndClosingDateAndClosingType(
        UUID branchId, LocalDate closingDate, NavClosingType closingType);

    /**
     * Zárások státusz alapján (GLOBALIS - minden ceg).
     *
     * <p><b>FIGYELEM:</b> multi-tenant kontextusban NE hasznald! Cross-tenant leak.
     * Hasznald a {@link #findByBranchCompanyIdAndStatus(UUID, NavClosingStatus)}-t.</p>
     */
    @Deprecated(since = "2026-04-21", forRemoval = false)
    List<NavClosing> findByStatus(NavClosingStatus status);

    /**
     * Zárások státusz alapján CEG-en BELUL. Multi-tenant-safe.
     */
    @Query("SELECT nc FROM NavClosing nc " +
           "WHERE nc.branch.company.id = :companyId " +
           "AND nc.status = :status")
    List<NavClosing> findByBranchCompanyIdAndStatus(
        @Param("companyId") UUID companyId,
        @Param("status") NavClosingStatus status
    );

    /**
     * Zárások iroda és időszak szerint
     */
    List<NavClosing> findByBranchIdAndClosingDateBetween(UUID branchId, LocalDate from, LocalDate to);

    /**
     * Zárások szűrése lapozással — multi-tenant-safe (companyId kotelezo).
     */
    @Query("SELECT nc FROM NavClosing nc " +
           "WHERE nc.branch.company.id = :companyId " +
           "AND (:branchId IS NULL OR nc.branch.id = :branchId) " +
           "AND (:closingType IS NULL OR nc.closingType = :closingType) " +
           "AND (:status IS NULL OR nc.status = :status) " +
           "AND (:dateFrom IS NULL OR nc.closingDate >= :dateFrom) " +
           "AND (:dateTo IS NULL OR nc.closingDate <= :dateTo) " +
           "ORDER BY nc.closingDate DESC")
    Page<NavClosing> findWithFilters(
        @Param("companyId") UUID companyId,
        @Param("branchId") UUID branchId,
        @Param("closingType") NavClosingType closingType,
        @Param("status") NavClosingStatus status,
        @Param("dateFrom") LocalDate dateFrom,
        @Param("dateTo") LocalDate dateTo,
        Pageable pageable
    );
}
