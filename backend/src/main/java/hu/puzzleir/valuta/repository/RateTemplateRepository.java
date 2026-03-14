package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.RateTemplate;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.UUID;

@Repository
public interface RateTemplateRepository extends JpaRepository<RateTemplate, UUID> {
    List<RateTemplate> findByWorkgroupIdAndStatus(UUID workgroupId, RateTemplate.RateTemplateStatus status);
    List<RateTemplate> findByWorkgroupId(UUID workgroupId);
    List<RateTemplate> findByCurrencyIdAndWorkgroupId(Long currencyId, UUID workgroupId);
    List<RateTemplate> findByStatus(RateTemplate.RateTemplateStatus status);
}
