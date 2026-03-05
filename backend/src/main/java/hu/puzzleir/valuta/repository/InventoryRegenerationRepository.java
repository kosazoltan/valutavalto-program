package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.InventoryRegeneration;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface InventoryRegenerationRepository extends JpaRepository<InventoryRegeneration, Long> {

    Optional<InventoryRegeneration> findTopByBranchIdOrderByRegeneratedAtDesc(UUID branchId);
}
