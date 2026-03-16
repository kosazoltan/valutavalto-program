package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.StockCorrection;
import hu.puzzleir.valuta.entity.VaultOperationStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface StockCorrectionRepository extends JpaRepository<StockCorrection, Long> {
    List<StockCorrection> findByCompanyIdOrderByCreatedAtDesc(UUID companyId);
    List<StockCorrection> findByCompanyIdAndStatusOrderByCreatedAtDesc(UUID companyId, VaultOperationStatus status);
    List<StockCorrection> findByCompanyIdAndEntityTypeAndEntityIdOrderByCreatedAtDesc(
            UUID companyId, String entityType, String entityId);
}
