package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.MnbSettlementRate;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface MnbSettlementRateRepository extends JpaRepository<MnbSettlementRate, UUID> {

    List<MnbSettlementRate> findByCompanyId(UUID companyId);

    Optional<MnbSettlementRate> findByCompanyIdAndCurrencyCode(UUID companyId, String currencyCode);
}
