package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.BanknoteInventory;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface BanknoteInventoryRepository extends JpaRepository<BanknoteInventory, Long> {

    List<BanknoteInventory> findByBranchId(UUID branchId);

    List<BanknoteInventory> findByBranchIdAndCurrencyCode(UUID branchId, String currencyCode);

    Optional<BanknoteInventory> findByBranchIdAndCurrencyIdAndFaceValue(UUID branchId, Long currencyId, BigDecimal faceValue);

    @Query("SELECT bi FROM BanknoteInventory bi WHERE bi.branchId = :branchId AND bi.quantity < bi.minQuantity")
    List<BanknoteInventory> findLowStock(@Param("branchId") UUID branchId);

    @Query("SELECT bi FROM BanknoteInventory bi WHERE bi.branchId = :branchId AND bi.quantity > bi.maxQuantity")
    List<BanknoteInventory> findOverStock(@Param("branchId") UUID branchId);
}
