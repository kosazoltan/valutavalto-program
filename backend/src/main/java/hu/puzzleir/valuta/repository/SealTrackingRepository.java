package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.SealTracking;
import hu.puzzleir.valuta.entity.SealTransitStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface SealTrackingRepository extends JpaRepository<SealTracking, Long> {
    Optional<SealTracking> findBySealNumber(String sealNumber);
    Optional<SealTracking> findByTransferTypeAndTransferId(String transferType, Long transferId);
    List<SealTracking> findByCompanyIdAndTransitStatusIn(UUID companyId, List<SealTransitStatus> statuses);
    boolean existsBySealNumber(String sealNumber);
    boolean existsByCompanyIdAndSealNumber(UUID companyId, String sealNumber);
}
