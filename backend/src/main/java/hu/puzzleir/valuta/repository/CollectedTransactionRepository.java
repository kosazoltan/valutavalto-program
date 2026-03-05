package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.CollectedTransaction;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

/**
 * Összegyűjtött tranzakció repository.
 */
@Repository
public interface CollectedTransactionRepository extends JpaRepository<CollectedTransaction, UUID> {

    List<CollectedTransaction> findByDataCollectionId(UUID dataCollectionId);
}
