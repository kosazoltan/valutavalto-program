package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.CashRegisterEvent;
import hu.puzzleir.valuta.entity.CashRegisterEventType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface CashRegisterEventRepository extends JpaRepository<CashRegisterEvent, UUID> {

    List<CashRegisterEvent> findByBranchIdAndEventTimestampBetweenOrderByEventTimestampDesc(
            UUID branchId, LocalDateTime from, LocalDateTime to);

    Optional<CashRegisterEvent> findByIdAndBranchId(UUID id, UUID branchId);

    @Query("SELECT e FROM CashRegisterEvent e WHERE e.branch.id = :branchId " +
           "AND e.eventType = :eventType ORDER BY e.eventTimestamp DESC LIMIT 1")
    CashRegisterEvent findLastByBranchAndType(
            @Param("branchId") UUID branchId,
            @Param("eventType") CashRegisterEventType eventType);
}
