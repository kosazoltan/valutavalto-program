package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.VaultTerritory;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface VaultTerritoryRepository extends JpaRepository<VaultTerritory, Integer> {

    /**
     * PRODUCTION HOTFIX v2.2.1: a PR #126 Sourcery `getCompanyIdForJson -> getCompanyId` rename
     * konfliktusba kerult a Spring Data JPA derived query parser-rel. A parser azt hitte, hogy
     * `VaultTerritory.companyId` persistent mezo kene, de az csak @Transient getter volt
     * (csak JSON-hez a Company proxy lazy-init elkerulese miatt).
     * 
     * Eredmeny: Hibernate `PathElementException: Could not resolve attribute 'companyId'` 
     * startup-kor -> valuta-backend.service exit 1 -> Hetzner 502 Bad Gateway.
     * 
     * Fix: explicit @Query, amely NEM tol a Spring Data parser-re. A `company.id` JPQL
     * path egyertelmu (ManyToOne association).
     */
    @Query("SELECT vt FROM VaultTerritory vt WHERE vt.company.id = :companyId AND vt.active = true")
    List<VaultTerritory> findByCompanyIdAndActiveTrue(@Param("companyId") UUID companyId);

    @Query("SELECT vt FROM VaultTerritory vt WHERE vt.company.id = :companyId")
    List<VaultTerritory> findByCompanyId(@Param("companyId") UUID companyId);

    /**
     * Codex AI review #125 P1: multi-tenant safe lookup by id + companyId kombinacio.
     * CLAUDE.md "Every query MUST filter by companyId - NEVER skip company filtering!"
     * Ezzel a metodussal cross-tenant leak nem fordulhat elo, mert
     * mas ceg teruletet soha nem tolti be.
     */
    @Query("SELECT vt FROM VaultTerritory vt WHERE vt.id = :id AND vt.company.id = :companyId")
    Optional<VaultTerritory> findByIdAndCompanyId(@Param("id") Integer id, @Param("companyId") UUID companyId);

    /**
     * Sourcery AI review #125 performance: DB-szintu name uniqueness check.
     * Nem tolti be az osszes teruletet memoriaba (skalazhatossag + race condition
     * csokkentes, a unique constraint a vegsp biztositek).
     */
    @Query("SELECT CASE WHEN COUNT(vt) > 0 THEN true ELSE false END FROM VaultTerritory vt WHERE vt.company.id = :companyId AND LOWER(vt.name) = LOWER(:name)")
    boolean existsByCompanyIdAndNameIgnoreCase(@Param("companyId") UUID companyId, @Param("name") String name);
}