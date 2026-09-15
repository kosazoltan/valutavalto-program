package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.HandlingFeeBalance;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface HandlingFeeBalanceRepository extends JpaRepository<HandlingFeeBalance, UUID> {

    Optional<HandlingFeeBalance> findByBranchIdAndCompanyId(UUID branchId, UUID companyId);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT h FROM HandlingFeeBalance h WHERE h.branchId = :branchId AND h.companyId = :companyId")
    Optional<HandlingFeeBalance> findByBranchIdAndCompanyIdForUpdate(
            @Param("branchId") UUID branchId, @Param("companyId") UUID companyId);

    @Modifying
    @Query(value = """
            INSERT INTO handling_fee_balance
                (company_id, branch_id, current_balance, version, updated_at)
            VALUES (:companyId, :branchId, 0, 0, NOW())
            ON CONFLICT (company_id, branch_id) DO NOTHING
            """, nativeQuery = true)
    int insertIfAbsent(@Param("companyId") UUID companyId, @Param("branchId") UUID branchId);
}
