package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.CurrencyGroup;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface CurrencyGroupRepository extends JpaRepository<CurrencyGroup, UUID> {

    List<CurrencyGroup> findByIsActiveTrueOrderByNameAsc();
}
