package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.VaultCollection;
import hu.puzzleir.valuta.entity.VaultOperationStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface VaultCollectionRepository extends JpaRepository<VaultCollection, Long> {
    List<VaultCollection> findByCompanyIdOrderByRequestedAtDesc(UUID companyId);
    List<VaultCollection> findByCompanyIdAndStatusOrderByRequestedAtDesc(UUID companyId, VaultOperationStatus status);
    List<VaultCollection> findByCompanyIdAndSourceBranchCodeOrderByRequestedAtDesc(UUID companyId, String sourceBranchCode);
}
