package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.VaultStocktakeItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface VaultStocktakeItemRepository extends JpaRepository<VaultStocktakeItem, UUID> {

    List<VaultStocktakeItem> findBySessionId(UUID sessionId);
}
