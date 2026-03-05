package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.CommissionRate;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface CommissionRateRepository extends JpaRepository<CommissionRate, UUID> {

    List<CommissionRate> findByIsActiveTrueOrderByValidFromDesc();

    List<CommissionRate> findByEntityTypeAndIsActiveTrueOrderByValidFromDesc(String entityType);
}
