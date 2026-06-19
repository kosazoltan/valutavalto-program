package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.PosTerminal;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface PosTerminalRepository extends JpaRepository<PosTerminal, UUID> {

    List<PosTerminal> findByBranchIdAndIsActiveTrueOrderByTerminalNameAsc(UUID branchId);

    Optional<PosTerminal> findByIdAndBranchId(UUID id, UUID branchId);

    Optional<PosTerminal> findByTerminalId(String terminalId);

    List<PosTerminal> findByIsActiveTrueOrderByTerminalNameAsc();
}
