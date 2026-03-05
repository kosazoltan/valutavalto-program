package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.InitialFeeConfig;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface InitialFeeConfigRepository extends JpaRepository<InitialFeeConfig, Long> {

    Optional<InitialFeeConfig> findByCompanyIdAndActive(UUID companyId, Boolean active);
}
