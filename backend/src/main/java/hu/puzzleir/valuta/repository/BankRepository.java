package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.Bank;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface BankRepository extends JpaRepository<Bank, UUID> {

    List<Bank> findByCompanyIdAndActiveTrueOrderByNameAsc(UUID companyId);

    /**
     * FK-005/C1 területi szűrés: a cég-szintű (region_code IS NULL) ÉS az adott területhez
     * tartozó (region_code = :region) aktív bankok.
     */
    @Query("""
            SELECT b FROM Bank b
            WHERE b.company.id = :companyId AND b.active = true
              AND (b.regionCode IS NULL OR b.regionCode = :region)
            ORDER BY b.name ASC
            """)
    List<Bank> findActiveByCompanyAndRegionOrGlobal(@Param("companyId") UUID companyId,
                                                    @Param("region") String region);

    @Query("""
            SELECT b FROM Bank b
            WHERE b.company.id = :companyId AND b.active = true
              AND LOWER(b.name) LIKE LOWER(CONCAT('%', :q, '%'))
            ORDER BY b.name ASC
            """)
    List<Bank> searchByName(@Param("companyId") UUID companyId, @Param("q") String q);

    Optional<Bank> findByCompanyIdAndNameIgnoreCase(UUID companyId, String name);
}
