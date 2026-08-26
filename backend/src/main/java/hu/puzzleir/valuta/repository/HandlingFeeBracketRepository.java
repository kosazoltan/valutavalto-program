package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.FeeConfigStatus;
import hu.puzzleir.valuta.entity.HandlingFeeBracket;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface HandlingFeeBracketRepository extends JpaRepository<HandlingFeeBracket, Long> {

    List<HandlingFeeBracket> findByCompanyIdAndActiveOrderByBracketOrder(UUID companyId, Boolean active);

    /**
     * FK-096/FR-6 + D16/W6: status-szűrt kereső. A legacy GET /handling-fee-config
     * kizárólag LIVE sávokat adhat vissza — egy DRAFT sáv megjelenése nélkül a
     * status-szűrés nélküli finder kevert LIVE+DRAFT listát adna.
     */
    List<HandlingFeeBracket> findByCompanyIdAndStatusAndActiveOrderByBracketOrder(
            UUID companyId, FeeConfigStatus status, Boolean active);

    /**
     * FK-096/D8: a közös sáv-készlet publikálása SOROS írási út — a publish use case
     * PESSIMISTIC_WRITE zárral veszi a cég sáv-sorait a tranzakción belül.
     */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT b FROM HandlingFeeBracket b WHERE b.company.id = :companyId ORDER BY b.bracketOrder")
    List<HandlingFeeBracket> lockAllForCompany(@Param("companyId") UUID companyId);
}
