package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.VaultDistribution;
import hu.puzzleir.valuta.entity.VaultOperationStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface VaultDistributionRepository extends JpaRepository<VaultDistribution, Long> {

    /**
     * v2.2.2 hotfix: LEFT JOIN FETCH d.lines - a GET list az items-et is
     * visszaadja eager-loadolva, nem lazy-n (lazy eseten items=0 jonnek vissza JSON-ban).
     */
    @Query("SELECT DISTINCT d FROM VaultDistribution d LEFT JOIN FETCH d.lines " +
           "WHERE d.companyId = :companyId ORDER BY d.createdAt DESC")
    List<VaultDistribution> findByCompanyIdOrderByCreatedAtDesc(@Param("companyId") UUID companyId);

    @Query("SELECT DISTINCT d FROM VaultDistribution d LEFT JOIN FETCH d.lines " +
           "WHERE d.companyId = :companyId AND d.status = :status ORDER BY d.createdAt DESC")
    List<VaultDistribution> findByCompanyIdAndStatusOrderByCreatedAtDesc(
            @Param("companyId") UUID companyId,
            @Param("status") VaultOperationStatus status);
}