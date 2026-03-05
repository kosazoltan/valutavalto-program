package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.WuBalance;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface WuBalanceRepository extends JpaRepository<WuBalance, UUID> {

    Optional<WuBalance> findByBranchId(UUID branchId);

    List<WuBalance> findAllByBranchId(UUID branchId);
}
