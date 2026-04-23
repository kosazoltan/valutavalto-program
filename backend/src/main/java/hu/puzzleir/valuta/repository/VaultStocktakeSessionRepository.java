package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.VaultStocktakeSession;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface VaultStocktakeSessionRepository extends JpaRepository<VaultStocktakeSession, UUID> {

    @Query("SELECT s FROM VaultStocktakeSession s WHERE s.company.id = :companyId ORDER BY s.startedAt DESC")
    List<VaultStocktakeSession> findByCompanyIdOrderByStartedAtDesc(UUID companyId);

    /**
     * Sourcery PR #128 fix: parameter-based enum compare JPQL standard.
     * Hivas: findOpenByCompanyId(companyId, VaultStocktakeSession.Status.OPEN)
     */
    @Query("SELECT s FROM VaultStocktakeSession s WHERE s.company.id = :companyId AND s.status = :status")
    List<VaultStocktakeSession> findByCompanyIdAndStatus(UUID companyId, hu.puzzleir.valuta.entity.VaultStocktakeSession.Status status);

    @Query("SELECT s FROM VaultStocktakeSession s LEFT JOIN FETCH s.items WHERE s.id = :id")
    java.util.Optional<VaultStocktakeSession> findByIdWithItems(UUID id);
}
