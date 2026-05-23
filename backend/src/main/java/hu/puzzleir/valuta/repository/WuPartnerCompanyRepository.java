package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.WuPartnerCompany;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface WuPartnerCompanyRepository extends JpaRepository<WuPartnerCompany, UUID> {

    List<WuPartnerCompany> findByCompanyIdAndActiveTrueOrderByNameAsc(UUID companyId);

    @Query("""
            SELECT w FROM WuPartnerCompany w
            WHERE w.company.id = :companyId AND w.active = true
              AND LOWER(w.name) LIKE LOWER(CONCAT('%', :q, '%'))
            ORDER BY w.name ASC
            """)
    List<WuPartnerCompany> searchByName(@Param("companyId") UUID companyId, @Param("q") String q);

    Optional<WuPartnerCompany> findByCompanyIdAndNameIgnoreCase(UUID companyId, String name);
}
