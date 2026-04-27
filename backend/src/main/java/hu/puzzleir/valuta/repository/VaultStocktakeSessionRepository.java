package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.VaultStocktakeSession;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface VaultStocktakeSessionRepository extends JpaRepository<VaultStocktakeSession, UUID> {

    @Query("SELECT s FROM VaultStocktakeSession s WHERE s.company.id = :companyId ORDER BY s.startedAt DESC")
    List<VaultStocktakeSession> findByCompanyIdOrderByStartedAtDesc(UUID companyId);

    /**
     * Sourcery PR #128 fix: parameter-based enum compare JPQL standard.
     * Hivas: findOpenByCompanyId(companyId, VaultStocktakeSession.Status.OPEN)
     */
    @Query("SELECT s FROM VaultStocktakeSession s WHERE s.company.id = :companyId AND s.status = :status")
    List<VaultStocktakeSession> findByCompanyIdAndStatus(UUID companyId, hu.puzzleir.valuta.entity.VaultStocktakeSession.Status status);

    /**
     * @deprecated Multi-tenant leak veszelye! Helyette {@link #findByIdAndCompanyIdWithItems(UUID, UUID)}.
     * Csak akkor hasznald, ha a hivo kod kifejezetten tenant-fuggetlen kontextusban dolgozik (pl. system migration).
     */
    @Deprecated
    @Query("SELECT s FROM VaultStocktakeSession s LEFT JOIN FETCH s.items WHERE s.id = :id")
    java.util.Optional<VaultStocktakeSession> findByIdWithItems(UUID id);

    /**
     * Tenant-scoped fetch: csak az adott company-hoz tartozo session olvashato.
     * Ezt hasznald minden user-context (controller -> service) folyamatban,
     * hogy ne legyen IDOR (Insecure Direct Object Reference) szivargas.
     *
     * @param id stocktake session UUID
     * @param companyId aktualis tenant
     * @return session ha letezik ES a tenanthez tartozik, kulonben empty
     */
    @Query("SELECT s FROM VaultStocktakeSession s LEFT JOIN FETCH s.items "
            + "WHERE s.id = :id AND s.company.id = :companyId")
    java.util.Optional<VaultStocktakeSession> findByIdAndCompanyIdWithItems(UUID id, UUID companyId);

    /**
     * Tenant-scoped fetch items nelkul (pl. cancel kornyek, ahol nem kell session.items).
     */
    @Query("SELECT s FROM VaultStocktakeSession s WHERE s.id = :id AND s.company.id = :companyId")
    java.util.Optional<VaultStocktakeSession> findByIdAndCompanyId(UUID id, UUID companyId);
}
