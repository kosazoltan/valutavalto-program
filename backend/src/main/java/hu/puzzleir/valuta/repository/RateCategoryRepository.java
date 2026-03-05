package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.RateCategory;
import hu.puzzleir.valuta.entity.RateCategory.RateCategoryType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface RateCategoryRepository extends JpaRepository<RateCategory, UUID> {

    List<RateCategory> findByBranchIdAndCurrencyCode(UUID branchId, String currencyCode);

    Optional<RateCategory> findByBranchIdAndCurrencyCodeAndCategory(
        UUID branchId, String currencyCode, RateCategoryType category);

    List<RateCategory> findByBranchId(UUID branchId);
}
