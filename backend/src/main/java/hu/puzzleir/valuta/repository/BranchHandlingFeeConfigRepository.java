package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.BranchHandlingFeeConfig;
import hu.puzzleir.valuta.entity.FeeConfigStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * FK-096: iroda-szintű kezelési díj konfiguráció repository.
 * MINDEN lekérdezés companyId-szűrt (multi-tenant invariáns).
 */
@Repository
public interface BranchHandlingFeeConfigRepository extends JpaRepository<BranchHandlingFeeConfig, UUID> {

    Optional<BranchHandlingFeeConfig> findByCompanyIdAndBranchIdAndStatusAndActiveTrue(
            UUID companyId, UUID branchId, FeeConfigStatus status);

    List<BranchHandlingFeeConfig> findByCompanyIdAndActiveTrue(UUID companyId);
}
