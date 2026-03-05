package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.Workstation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface WorkstationRepository extends JpaRepository<Workstation, UUID> {
    List<Workstation> findByIsActiveTrue();
}
