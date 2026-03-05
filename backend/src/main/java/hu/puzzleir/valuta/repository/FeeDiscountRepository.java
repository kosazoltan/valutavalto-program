package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.FeeDiscount;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public interface FeeDiscountRepository extends JpaRepository<FeeDiscount, UUID> {
}
