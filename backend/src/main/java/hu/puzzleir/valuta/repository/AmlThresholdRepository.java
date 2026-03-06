package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.AmlThreshold;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface AmlThresholdRepository extends JpaRepository<AmlThreshold, UUID> {

    Optional<AmlThreshold> findByThresholdType(String thresholdType);

    List<AmlThreshold> findByIsActiveTrue();
}
