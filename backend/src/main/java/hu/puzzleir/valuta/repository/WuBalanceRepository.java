package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.WuBalance;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface WuBalanceRepository extends JpaRepository<WuBalance, UUID> {

    Optional<WuBalance> findByBranchId(UUID branchId);

    List<WuBalance> findAllByBranchId(UUID branchId);

    /**
     * Több iroda WU egyenlege egyben (KESZLEX batch lekérdezés).
     */
    @Query("SELECT wb FROM WuBalance wb WHERE wb.branch.id IN :branchIds")
    List<WuBalance> findByBranchIds(@Param("branchIds") List<UUID> branchIds);

    /**
     * Pesszimista írási zárolással tölti be az egyenleget — konkurens pénztáros műveletek ellen.
     */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT wb FROM WuBalance wb WHERE wb.branch.id = :branchId")
    Optional<WuBalance> findByBranchIdForUpdate(@Param("branchId") UUID branchId);
}
