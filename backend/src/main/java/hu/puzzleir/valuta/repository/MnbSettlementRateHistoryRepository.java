package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.MnbSettlementRateHistory;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface MnbSettlementRateHistoryRepository extends JpaRepository<MnbSettlementRateHistory, UUID> {

    List<MnbSettlementRateHistory> findByCompanyIdOrderByRecordedAtDesc(UUID companyId);

    long countByCompanyId(UUID companyId);

    /**
     * FKH-063: newest usable settlement-rate snapshot of one company + currency, recorded strictly
     * before {@code asOfExclusive}.
     *
     * <p>{@code minRate} is passed as ZERO by the caller: V353 seeds {@code official_rate = 0} as
     * the "never recorded" marker (FR-8) and {@code MnbSettlementRateService.validateRequest}
     * (line 200) rejects {@code signum() <= 0} on write, so a zero snapshot means ABSENT, never a
     * real rate. Filtering in the query keeps a zero from ever reaching a valuation multiply.</p>
     */
    Optional<MnbSettlementRateHistory>
    findFirstByCompanyIdAndCurrencyCodeAndOfficialRateGreaterThanAndRecordedAtLessThanOrderByRecordedAtDesc(
            UUID companyId, String currencyCode, BigDecimal minRate, Instant asOfExclusive);
}
