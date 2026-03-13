package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.ClosingControl;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ClosingControlRepository extends JpaRepository<ClosingControl, UUID> {

    List<ClosingControl> findByControlDate(LocalDate controlDate);

    Optional<ClosingControl> findByBranchIdAndControlDate(UUID branchId, LocalDate controlDate);
}
