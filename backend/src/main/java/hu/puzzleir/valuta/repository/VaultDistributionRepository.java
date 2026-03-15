package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.VaultDistribution;
import hu.puzzleir.valuta.entity.VaultOperationStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface VaultDistributionRepository extends JpaRepository<VaultDistribution, Long> {
    List<VaultDistribution> findByCompanyIdOrderByCreatedAtDesc(UUID companyId);
    List<VaultDistribution> findByCompanyIdAndStatusOrderByCreatedAtDesc(UUID companyId, VaultOperationStatus status);
}
