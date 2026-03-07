package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.VaultTerritory;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface VaultTerritoryRepository extends JpaRepository<VaultTerritory, Integer> {

    List<VaultTerritory> findByCompanyIdAndActiveTrue(UUID companyId);

    List<VaultTerritory> findByCompanyId(UUID companyId);
}
