package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.VaultTransfer;
import hu.puzzleir.valuta.entity.VaultOperationStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface VaultTransferRepository extends JpaRepository<VaultTransfer, Long> {
    List<VaultTransfer> findByCompanyIdOrderByCreatedAtDesc(UUID companyId);
    List<VaultTransfer> findByCompanyIdAndStatusOrderByCreatedAtDesc(UUID companyId, VaultOperationStatus status);

    @Query("SELECT vt FROM VaultTransfer vt WHERE vt.companyId = :companyId AND vt.transferNumber = :transferNumber")
    Optional<VaultTransfer> findByCompanyIdAndTransferNumber(
            @Param("companyId") UUID companyId,
            @Param("transferNumber") String transferNumber);

    @Query(value = "SELECT nextval('vault_transfer_seq')", nativeQuery = true)
    Long getNextTransferNumber();
}
