package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.RateDiscount;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.UUID;

@Repository
public interface RateDiscountRepository extends JpaRepository<RateDiscount, UUID> {
    List<RateDiscount> findByWorkgroupIdAndActiveTrue(UUID workgroupId);
    List<RateDiscount> findByWorkgroupIdOrderByLevel(UUID workgroupId);
}
