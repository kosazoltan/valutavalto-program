package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.ClosingWizard;
import hu.puzzleir.valuta.entity.WizardStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Zárási varázsló repository.
 */
@Repository
public interface ClosingWizardRepository extends JpaRepository<ClosingWizard, UUID> {

    /**
     * Aktív (folyamatban lévő) varázsló keresése iroda és pénztárgép alapján
     */
    @Query("SELECT cw FROM ClosingWizard cw " +
           "WHERE cw.branch.id = :branchId " +
           "AND cw.wizardStatus = :status")
    List<ClosingWizard> findByBranchIdAndStatus(
        @Param("branchId") UUID branchId,
        @Param("status") WizardStatus status
    );

    @Query("SELECT cw FROM ClosingWizard cw " +
           "WHERE cw.branch.id = :branchId " +
           "AND cw.wizardStatus = :status " +
           "AND cw.closingDate = :closingDate")
    List<ClosingWizard> findByBranchIdAndStatusAndClosingDate(
        @Param("branchId") UUID branchId,
        @Param("status") WizardStatus status,
        @Param("closingDate") LocalDate closingDate
    );

    /**
     * Varázsló lekérése lépésekkel együtt
     */
    @Query("SELECT cw FROM ClosingWizard cw LEFT JOIN FETCH cw.steps WHERE cw.id = :id")
    Optional<ClosingWizard> findByIdWithSteps(@Param("id") UUID id);
}
