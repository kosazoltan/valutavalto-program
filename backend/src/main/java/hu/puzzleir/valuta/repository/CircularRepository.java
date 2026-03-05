package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.Circular;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface CircularRepository extends JpaRepository<Circular, Long> {

    @Query("SELECT c FROM Circular c WHERE c.acknowledged = false ORDER BY c.urgent DESC, c.createdAt DESC")
    List<Circular> findUnacknowledged();

    @Query("SELECT c FROM Circular c ORDER BY c.createdAt DESC")
    List<Circular> findAllOrderByCreatedAtDesc();
}
