package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.VatSupplyStock;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface VatSupplyStockRepository extends JpaRepository<VatSupplyStock, UUID> {

    Optional<VatSupplyStock> findByCompanyIdAndVaultTerritoryId(UUID companyId, Integer vaultTerritoryId);
}
