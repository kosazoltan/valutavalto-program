package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.DataCollection;
import hu.puzzleir.valuta.entity.DataCollectionStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Adatgyűjtés repository.
 */
@Repository
public interface DataCollectionRepository extends JpaRepository<DataCollection, UUID> {

    /**
     * Gyűjtés keresése iroda és dátum alapján
     */
    Optional<DataCollection> findByBranchIdAndCollectionDate(UUID branchId, LocalDate date);

    /**
     * Gyűjtések státusz szerint
     */
    List<DataCollection> findByStatus(DataCollectionStatus status);

    /**
     * Gyűjtések dátum alapján
     */
    List<DataCollection> findByCollectionDate(LocalDate date);

    /**
     * Sikertelen gyűjtések (újrapróbáláshoz)
     */
    @Query("SELECT dc FROM DataCollection dc " +
           "WHERE dc.status = 'FAILED' " +
           "AND dc.collectionDate >= :sinceDate " +
           "ORDER BY dc.collectionDate DESC")
    List<DataCollection> findFailedSince(@Param("sinceDate") LocalDate sinceDate);

    /**
     * Gyűjtések iroda és időszak szerint
     */
    List<DataCollection> findByBranchIdAndCollectionDateBetween(
        UUID branchId, LocalDate from, LocalDate to);

    /**
     * Összesítő: adott napra az összes iroda utolsó gyűjtési állapota.
     * Ha nincs rekord a napra, üres lista.
     */
    List<DataCollection> findByCollectionDateOrderByBranchIdAsc(LocalDate collectionDate);
}
