package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.CollectedInventory;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

/**
 * Összegyűjtött készlet repository.
 */
@Repository
public interface CollectedInventoryRepository extends JpaRepository<CollectedInventory, UUID> {

    List<CollectedInventory> findByDataCollectionId(UUID dataCollectionId);
}
