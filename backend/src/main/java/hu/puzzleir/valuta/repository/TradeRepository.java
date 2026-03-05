package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.Trade;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Repository
public interface TradeRepository extends JpaRepository<Trade, UUID> {

    @Query("SELECT t FROM Trade t WHERE (t.fromBranch.id = :branchId OR t.toBranch.id = :branchId) " +
           "AND t.status = 'PROPOSED' ORDER BY t.proposedAt DESC")
    List<Trade> findPendingByBranch(@Param("branchId") UUID branchId);

    @Query("SELECT t FROM Trade t WHERE (t.fromBranch.id = :branchId OR t.toBranch.id = :branchId) " +
           "AND t.proposedAt BETWEEN :from AND :to ORDER BY t.proposedAt DESC")
    Page<Trade> findHistoryByBranch(@Param("branchId") UUID branchId,
                                     @Param("from") LocalDateTime from,
                                     @Param("to") LocalDateTime to,
                                     Pageable pageable);
}
