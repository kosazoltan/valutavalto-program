package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.WuDailyLimit;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface WuDailyLimitRepository extends JpaRepository<WuDailyLimit, UUID> {

    Optional<WuDailyLimit> findByCompanyIdAndBusinessDateAndCurrencyCode(
            UUID companyId,
            LocalDate businessDate,
            String currencyCode);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("""
        SELECT l FROM WuDailyLimit l
        WHERE l.company.id = :companyId
          AND l.businessDate = :businessDate
          AND l.currencyCode = :currencyCode
    """)
    Optional<WuDailyLimit> findByCompanyDateCurrencyForUpdate(
            @Param("companyId") UUID companyId,
            @Param("businessDate") LocalDate businessDate,
            @Param("currencyCode") String currencyCode);
}
