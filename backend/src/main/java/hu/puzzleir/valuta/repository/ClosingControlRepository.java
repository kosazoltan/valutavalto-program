package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.ClosingControl;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ClosingControlRepository extends JpaRepository<ClosingControl, UUID> {

    List<ClosingControl> findByControlDate(LocalDate controlDate);

    List<ClosingControl> findByCompanyIdAndControlDate(UUID companyId, LocalDate controlDate);

    Optional<ClosingControl> findByBranchIdAndControlDate(UUID branchId, LocalDate controlDate);

    Optional<ClosingControl> findByCompanyIdAndBranchIdAndControlDate(UUID companyId, UUID branchId, LocalDate controlDate);

    /**
     * FK-114 FR-2: evening-closed (branch, date) pairs in a range. Vault missing-day
     * detection uses {@code evening_closing_done}, never {@code daily_closing_done}.
     *
     * <p>Tuple: [0]=branchId (UUID), [1]=controlDate (LocalDate).</p>
     */
    @Query("SELECT cc.branchId, cc.controlDate FROM ClosingControl cc "
            + "WHERE cc.companyId = :companyId "
            + "AND cc.branchId IN :branchIds "
            + "AND cc.controlDate BETWEEN :from AND :to "
            + "AND cc.eveningClosingDone = true")
    List<Object[]> findEveningClosedBranchDates(
            @Param("companyId") UUID companyId,
            @Param("branchIds") List<UUID> branchIds,
            @Param("from") LocalDate from,
            @Param("to") LocalDate to);
}
