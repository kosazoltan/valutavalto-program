package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.ClosingWizard;
import hu.puzzleir.valuta.entity.WizardStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.time.LocalDateTime;
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

    /**
     * FK-065: globális (cross-tenant) lekérdezés az auto-lejárathoz — adott státuszú,
     * a cutoff előtt indított varázslók. A foglaló findByStatusAndExpiresAtBefore
     * mintája; a tenant-izolációt itt szándékosan NEM a query adja: a scheduler minden
     * cég beragadt sorát kezeli, az audit a wizard saját company-jából szkópolódik.
     */
    @Query("SELECT cw FROM ClosingWizard cw " +
           "WHERE cw.wizardStatus = :status " +
           "AND cw.startedAt < :startedBefore")
    List<ClosingWizard> findByWizardStatusAndStartedAtBefore(
        @Param("status") WizardStatus status,
        @Param("startedBefore") LocalDateTime startedBefore
    );

    /**
     * FK-065 Security Gate HIGH-fix: feltételes, atomikus státuszváltás az
     * auto-lejárathoz (az AmlApprovalGrant {@code decrementIfAvailable} minta).
     * A SELECT és az írás közti konkurens cancel()/finalize ellen a WHERE-feltétel
     * véd: csak akkor ír, ha a sor MÉG MINDIG a várt státuszban van és a cutoff
     * előtt indult. Visszatérés: érintett sorok száma (0 = közben más állapotba
     * került — ilyenkor a hívó nem auditolhat EXPIRED-váltást).
     */
    @Modifying
    @Query("UPDATE ClosingWizard cw SET cw.wizardStatus = :newStatus " +
           "WHERE cw.id = :id " +
           "AND cw.wizardStatus = :expectedStatus " +
           "AND cw.startedAt < :startedBefore")
    int transitionIfStale(
        @Param("id") UUID id,
        @Param("expectedStatus") WizardStatus expectedStatus,
        @Param("newStatus") WizardStatus newStatus,
        @Param("startedBefore") LocalDateTime startedBefore
    );
}
