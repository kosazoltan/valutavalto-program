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

    List<VaultTerritory> findByCompanyIdAndActiveTrue(UUID companyId);

    List<VaultTerritory> findByCompanyId(UUID companyId);

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
    @Query("SELECT COUNT(vt) > 0 FROM VaultTerritory vt WHERE vt.company.id = :companyId AND LOWER(vt.name) = LOWER(:name)")
    boolean existsByCompanyIdAndNameIgnoreCase(@Param("companyId") UUID companyId, @Param("name") String name);
}