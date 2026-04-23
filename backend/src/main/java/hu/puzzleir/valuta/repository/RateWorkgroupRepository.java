package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.RateWorkgroup;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface RateWorkgroupRepository extends JpaRepository<RateWorkgroup, UUID> {
    Optional<RateWorkgroup> findByCode(String code);
    List<RateWorkgroup> findByActiveTrue();

    /**
     * Fix #148 regression: a @Transient getCompanyId() getter (Jackson LazyInit bypass)
     * conflict-ot okoz a Spring Data JPA derived query-vel ("Could not resolve attribute
     * 'companyId'"). Explicit @Query query-vel elkerultjuk a path-resolving-et.
     * (Ugyanaz a minta, mint PR #132-ben a VaultTerritory-nal.)
     */
    @Query("SELECT r FROM RateWorkgroup r WHERE r.company.id = :companyId AND r.active = true")
    List<RateWorkgroup> findByCompanyIdAndActiveTrue(@Param("companyId") UUID companyId);

    @Query("SELECT r FROM RateWorkgroup r WHERE r.company.id = :companyId")
    List<RateWorkgroup> findByCompanyId(@Param("companyId") UUID companyId);
}