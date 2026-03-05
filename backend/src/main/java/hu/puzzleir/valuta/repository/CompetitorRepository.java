package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.Competitor;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface CompetitorRepository extends JpaRepository<Competitor, UUID> {

    List<Competitor> findByIsActiveTrueOrderByNameAsc();

    List<Competitor> findByBranchIdAndIsActiveTrueOrderByNameAsc(UUID branchId);
}
