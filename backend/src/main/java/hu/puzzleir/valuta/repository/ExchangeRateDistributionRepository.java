package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.ExchangeRateDistribution;
import hu.puzzleir.valuta.entity.ExchangeRateDistribution.DistributionStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

/**
 * Árfolyam elosztás repository.
 */
@Repository
public interface ExchangeRateDistributionRepository extends JpaRepository<ExchangeRateDistribution, UUID> {

    List<ExchangeRateDistribution> findByMasterRateId(UUID masterRateId);

    List<ExchangeRateDistribution> findByBranchIdAndStatus(UUID branchId, DistributionStatus status);

    List<ExchangeRateDistribution> findByMasterRateIdAndStatus(UUID masterRateId, DistributionStatus status);

    long countByMasterRateIdAndStatus(UUID masterRateId, DistributionStatus status);
}
