package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.CurrencyStock;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import jakarta.persistence.LockModeType;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface CurrencyStockRepository extends JpaRepository<CurrencyStock, Long> {

    Optional<CurrencyStock> findByCompanyIdAndEntityTypeAndEntityIdAndCurrencyCode(
            UUID companyId, String entityType, String entityId, String currencyCode);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT cs FROM CurrencyStock cs WHERE cs.company.id = :companyId " +
           "AND cs.entityType = :entityType AND cs.entityId = :entityId " +
           "AND cs.currencyCode = :currencyCode")
    Optional<CurrencyStock> findForUpdate(
            @Param("companyId") UUID companyId,
            @Param("entityType") String entityType,
            @Param("entityId") String entityId,
            @Param("currencyCode") String currencyCode);

    List<CurrencyStock> findByEntityTypeAndEntityId(String entityType, String entityId);

    List<CurrencyStock> findByCompanyIdAndEntityType(UUID companyId, String entityType);
}
