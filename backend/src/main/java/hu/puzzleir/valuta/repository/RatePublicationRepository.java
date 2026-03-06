package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.RatePublication;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.UUID;

@Repository
public interface RatePublicationRepository extends JpaRepository<RatePublication, UUID> {
    List<RatePublication> findByWorkgroupIdOrderByPublishedAtDesc(UUID workgroupId);
    List<RatePublication> findTop20ByOrderByPublishedAtDesc();
}
