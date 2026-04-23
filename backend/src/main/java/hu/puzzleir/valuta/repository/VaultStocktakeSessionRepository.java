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

    @Query("SELECT s FROM VaultStocktakeSession s WHERE s.company.id = :companyId AND s.status = hu.puzzleir.valuta.entity.VaultStocktakeSession$Status.OPEN")
    List<VaultStocktakeSession> findOpenByCompanyId(UUID companyId);

    @Query("SELECT s FROM VaultStocktakeSession s LEFT JOIN FETCH s.items WHERE s.id = :id")
    java.util.Optional<VaultStocktakeSession> findByIdWithItems(UUID id);
}
