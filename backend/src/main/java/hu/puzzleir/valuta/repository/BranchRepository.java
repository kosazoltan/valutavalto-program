package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.Branch;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface BranchRepository extends JpaRepository<Branch, UUID> {

    /**
     * Keresés kód alapján (GLOBALIS - minden ceg).
     *
     * <p><b>FIGYELEM: multi-tenant kontextusban NE hasznald!</b>
     * Cross-tenant adat leak veszelye. Hasznald a {@link #findByCompanyIdAndCode(UUID, String)}-t.
     *
     * <p>Ez a metodus CSAK pre-login wizard / public endpoint kontextusban hasznalhato,
     * ahol nincs bejelentkezett felhasznalo es a branch-code ceg-globalis unique.</p>
     */
    @Deprecated(since = "2026-04-21", forRemoval = false)
    Optional<Branch> findByCode(String code);

    /**
     * Ellenőrzi, hogy létezik-e adott kóddal fiók (GLOBALIS - minden ceg).
     *
     * <p><b>FIGYELEM: multi-tenant kontextusban NE hasznald!</b>
     * Hasznald a {@link #existsByCompanyIdAndCode(UUID, String)}-t.</p>
     */
    @Deprecated(since = "2026-04-21", forRemoval = false)
    boolean existsByCode(String code);

    /**
     * Ellenőrzi, hogy létezik-e adott kóddal fiók CEG-en BELUL.
     * Multi-tenant-safe validalashoz.
     */
    boolean existsByCompanyIdAndCode(UUID companyId, String code);

    /**
     * Összes aktív fiók lekérdezése (GLOBALIS - minden ceg).
     *
     * <p><b>FIGYELEM:</b> multi-tenant kontextusban NE hasznald!
     * Hasznald a {@link #findByCompanyIdAndIsActiveTrue(UUID)}-t.</p>
     */
    @Deprecated(since = "2026-04-21", forRemoval = false)
    List<Branch> findByIsActiveTrue();

    /**
     * Fiókok típus szerint (GLOBALIS).
     *
     * <p><b>FIGYELEM:</b> multi-tenant kontextusban NE hasznald!
     * Hasznald a {@link #findByCompanyIdAndBranchTypeCode(UUID, String)}-t.</p>
     */
    @Deprecated(since = "2026-04-21", forRemoval = false)
    @Query("SELECT b FROM Branch b WHERE b.branchType.code = :typeCode")
    List<Branch> findByBranchTypeCode(@Param("typeCode") String typeCode);

    /**
     * Fiókok típus szerint CEG-en BELUL. Multi-tenant-safe.
     */
    @Query("SELECT b FROM Branch b WHERE b.company.id = :companyId AND b.branchType.code = :typeCode")
    List<Branch> findByCompanyIdAndBranchTypeCode(
        @Param("companyId") UUID companyId,
        @Param("typeCode") String typeCode
    );

    /**
     * Fiókok státusz szerint (GLOBALIS).
     *
     * <p><b>FIGYELEM:</b> multi-tenant kontextusban NE hasznald!</p>
     */
    @Deprecated(since = "2026-04-21", forRemoval = false)
    @Query("SELECT b FROM Branch b WHERE b.branchStatus.code = :statusCode")
    List<Branch> findByBranchStatusCode(@Param("statusCode") String statusCode);

    /** PP-05: SQL-szintű, cég-szűrt státusz-lekérdezés (a memóriabeli post-filter helyett). */
    @Query("SELECT b FROM Branch b WHERE b.company.id = :companyId AND b.branchStatus.code = :statusCode")
    List<Branch> findByCompanyIdAndBranchStatusCode(
            @Param("companyId") UUID companyId, @Param("statusCode") String statusCode);

    /**
     * Szülő alatti fiókok (közvetlen gyermekek)
     */
    @Query("SELECT b FROM Branch b WHERE b.parentBranch.id = :parentId")
    List<Branch> findByParentBranchId(@Param("parentId") UUID parentId);

    /**
     * Gyökér fiókok (nincs szülő) — GLOBALIS.
     *
     * <p><b>FIGYELEM:</b> multi-tenant kontextusban NE hasznald!
     * Hasznald a {@link #findRootBranchesByCompanyId(UUID)}-t.</p>
     */
    @Deprecated(since = "2026-04-21", forRemoval = false)
    @Query("SELECT b FROM Branch b WHERE b.parentBranch IS NULL")
    List<Branch> findRootBranches();

    /**
     * Gyökér fiókok CEG-en BELUL. Multi-tenant-safe.
     */
    @Query("SELECT b FROM Branch b WHERE b.company.id = :companyId AND b.parentBranch IS NULL")
    List<Branch> findRootBranchesByCompanyId(@Param("companyId") UUID companyId);

    /**
     * Keresés név vagy kód szerint (partial match) — GLOBALIS.
     *
     * <p><b>FIGYELEM:</b> multi-tenant kontextusban NE hasznald!
     * Hasznald a {@link #searchByCompanyIdAndNameOrCode(UUID, String)}-t.</p>
     */
    @Deprecated(since = "2026-04-21", forRemoval = false)
    @Query("SELECT b FROM Branch b WHERE " +
           "LOWER(b.name) LIKE LOWER(CONCAT('%', :search, '%')) OR " +
           "LOWER(b.code) LIKE LOWER(CONCAT('%', :search, '%'))")
    List<Branch> searchByNameOrCode(@Param("search") String search);

    /**
     * Keresés név vagy kód szerint CEG-en BELUL. Multi-tenant-safe.
     */
    @Query("SELECT b FROM Branch b WHERE b.company.id = :companyId AND (" +
           "LOWER(b.name) LIKE LOWER(CONCAT('%', :search, '%')) OR " +
           "LOWER(b.code) LIKE LOWER(CONCAT('%', :search, '%')))")
    List<Branch> searchByCompanyIdAndNameOrCode(
        @Param("companyId") UUID companyId,
        @Param("search") String search
    );

    /**
     * Fiókok város szerint (GLOBALIS).
     *
     * <p><b>FIGYELEM:</b> multi-tenant kontextusban NE hasznald!
     * Hasznald a {@link #findByCompanyIdAndCity(UUID, String)}-t.</p>
     */
    @Deprecated(since = "2026-04-21", forRemoval = false)
    List<Branch> findByCity(String city);

    /**
     * Fiókok város szerint CEG-en BELUL. Multi-tenant-safe.
     */
    List<Branch> findByCompanyIdAndCity(UUID companyId, String city);

    /**
     * Fiókok cégen belül
     */
    @Query("SELECT b FROM Branch b WHERE b.company.id = :companyId")
    List<Branch> findByCompanyId(@Param("companyId") UUID companyId);

    /**
     * Aktív fiókok cégen belül (árfolyam munkacsoport kezeléshez)
     */
    @Query("SELECT b FROM Branch b WHERE b.company.id = :companyId AND b.isActive = true ORDER BY b.name")
    List<Branch> findByCompanyIdAndIsActiveTrue(@Param("companyId") UUID companyId);

    /**
     * Fiók keresése cégen belül kód alapján (Értéktár modul)
     */
    @Query("SELECT b FROM Branch b WHERE b.company.id = :companyId AND b.code = :code")
    Optional<Branch> findByCompanyIdAndCode(@Param("companyId") UUID companyId, @Param("code") String code);

    /**
     * Megosztott fiok-email setup azonositasahoz. Csak aktiv branch-eket ad vissza,
     * mert a first-run wizard nem kothet gepet lezart irodahoz.
     */
    @Query("""
        SELECT b FROM Branch b
        WHERE b.company.id = :companyId
          AND b.isActive = true
          AND b.email IS NOT NULL
          AND LOWER(b.email) = LOWER(:email)
    """)
    List<Branch> findActiveByCompanyIdAndEmailIgnoreCase(
            @Param("companyId") UUID companyId,
            @Param("email") String email);

    /**
     * Rekurzív lekérdezés: összes leszármazott
     * PostgreSQL WITH RECURSIVE használata
     */
    @Query(value = """
        WITH RECURSIVE branch_tree AS (
            SELECT id, code, name, parent_branch_id, 1 as level,
                   ARRAY[id] as path
            FROM branch
            WHERE id = :branchId
            
            UNION ALL
            
            SELECT b.id, b.code, b.name, b.parent_branch_id, bt.level + 1,
                   bt.path || b.id
            FROM branch b
            INNER JOIN branch_tree bt ON b.parent_branch_id = bt.id
        )
        SELECT * FROM branch WHERE id IN (SELECT id FROM branch_tree)
        """, nativeQuery = true)
    List<Branch> findAllDescendants(@Param("branchId") UUID branchId);

    /**
     * Fiókok értéktári terület szerint — GLOBALIS.
     *
     * <p><b>FIGYELEM:</b> multi-tenant kontextusban NE hasznald!
     * Hasznald a {@link #findByCompanyIdAndVaultTerritoryId(UUID, Integer)}-t.</p>
     */
    @Deprecated(since = "2026-04-21", forRemoval = false)
    List<Branch> findByVaultTerritoryId(Integer vaultTerritoryId);

    /**
     * Fiókok értéktári terület szerint CEG-en BELUL. Multi-tenant-safe.
     */
    List<Branch> findByCompanyIdAndVaultTerritoryId(UUID companyId, Integer vaultTerritoryId);

    /**
     * v2.5.1-C B6: Csak ÉRTÉKTÁRI (is_vault=TRUE) fiókok adott cégen belül.
     * A SetupWizard értéktár módú telepítéshez használt.
     */
    List<Branch> findByCompanyIdAndIsVaultTrue(UUID companyId);

    /**
     * v2.5.1-C B6: Aktív értéktári fiókok adott cégen belül.
     */
    List<Branch> findByCompanyIdAndIsVaultTrueAndIsActiveTrue(UUID companyId);

    /**
     * Rekurzív lekérdezés: teljes útvonal a gyökérig
     */
    @Query(value = """
        WITH RECURSIVE branch_path AS (
            SELECT id, code, name, parent_branch_id, 1 as level
            FROM branch
            WHERE id = :branchId
            
            UNION ALL
            
            SELECT b.id, b.code, b.name, b.parent_branch_id, bp.level + 1
            FROM branch b
            INNER JOIN branch_path bp ON bp.parent_branch_id = b.id
        )
        SELECT * FROM branch WHERE id IN (SELECT id FROM branch_path)
        ORDER BY level DESC
        """, nativeQuery = true)
    List<Branch> findPathToRoot(@Param("branchId") UUID branchId);

    /**
     * Aktív irodák körzet kód és cég szerint (KESZLEX készlet export).
     */
    @Query("SELECT b FROM Branch b WHERE b.company.id = :companyId " +
           "AND b.regionCode = :regionCode AND b.isActive = true " +
           "ORDER BY b.code")
    List<Branch> findActiveByCompanyIdAndRegionCode(
            @Param("companyId") UUID companyId,
            @Param("regionCode") String regionCode);

    /**
     * Aktív irodák cég szerint, körzet kóddal rendelkezők (KESZLEX).
     */
    @Query("SELECT b FROM Branch b WHERE b.company.id = :companyId " +
           "AND b.regionCode IS NOT NULL AND b.isActive = true " +
           "ORDER BY b.regionCode, b.code")
    List<Branch> findActiveWithRegionByCompanyId(@Param("companyId") UUID companyId);
}
