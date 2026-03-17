package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.RateWorkgroup;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface RateWorkgroupRepository extends JpaRepository<RateWorkgroup, UUID> {
    Optional<RateWorkgroup> findByCode(String code);
    List<RateWorkgroup> findByActiveTrue();
    List<RateWorkgroup> findByCompanyIdAndActiveTrue(UUID companyId);
    List<RateWorkgroup> findByCompanyId(UUID companyId);
}
