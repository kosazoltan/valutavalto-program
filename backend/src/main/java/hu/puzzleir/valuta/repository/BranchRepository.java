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
     * Fiók-tulajdonos cég ellenőrzése ID alapján (multi-tenant cross-tenant IDOR védelemhez).
     */
    boolean existsByIdAndCompanyId(UUID id, UUID companyId);

    /**
     * Fiók betöltése cég-scope-pal, ha a hívónak magát az entitást kell használnia.
     */
    Optional<Branch> findByIdAndCompanyId(UUID id, UUID companyId);

    /**
     * FKH-022 FR-K12 (Security Gate tenant-guard hardening): partner-fiókok BATCH
     * betöltése cég-scope-pal. A HUF naplókönyv partner-kód feloldása ezen keresztül
     * fut, hogy korrupt/legacy cross-tenant branch-referencia esetén se töltődjön be
     * idegen tenant Branch-rekordja.
     */
    List<Branch> findByIdInAndCompanyId(java.util.Collection<UUID> ids, UUID companyId);

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
    List<Branch> findByParentBranchId(UUID parentId);

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
     * System-szintu napzaras monitorozas: aktiv, valodi irodak minden cegbol.
     *
     * <p>Schedulerben nincs SecurityContext, ezert ez tudatosan globalis query. A banki/spec
     * VAULT_COUNTERPARTY partnerek nem napi zarasra kotelezett irodak, ezert kizartak.</p>
     */
    @Query("SELECT b FROM Branch b LEFT JOIN b.branchType bt "
        + "WHERE b.isActive = true AND (bt IS NULL OR bt.code <> 'VAULT_COUNTERPARTY') ORDER BY b.company.id, b.code")
    List<Branch> findActiveClosingMonitoredBranches();

    /**
     * FK-014 backend-szűrés (2026-06-01): aktív, VALÓDI irodák (pénztár + értéktár) cégen belül —
     * a VAULT_COUNTERPARTY típusú banki/speciális partnerek (PRB/UPT/TRB/ERB/FRB/RB/JRB/MNB/TH/FOP1,
     * V277 seed) KIZÁRVA. A felügyeleti modulok (Zárás beérkezés, Napi ellenőrzési lista) csak napi
     * zárást végző egységeket mutatnak; a partnerek sosem zárnak. LEFT JOIN: a (jelenleg nem létező,
     * de defenzíven kezelt) null-branchType sorok is bennmaradnak.
     */
    @Query("SELECT b FROM Branch b LEFT JOIN b.branchType bt "
        + "WHERE b.company.id = :companyId AND b.isActive = true "
        + "AND (bt IS NULL OR bt.code <> 'VAULT_COUNTERPARTY') ORDER BY b.name")
    List<Branch> findByCompanyIdAndIsActiveTrueExcludingCounterparties(@Param("companyId") UUID companyId);

    /**
     * FK-098 FR-8: the handling-fee admin page data source — active, real cashier branches
     * within the company. Extends {@link #findByCompanyIdAndIsActiveTrueExcludingCounterparties(UUID)}
     * with a vault exclusion (b.isVault): a vault has no buy/sell turnover, therefore no
     * handling fee. The older method is intentionally left untouched (8 live consumers).
     * LEFT JOIN + IS NULL guards keep defensively-null branchType / isVault rows visible.
     */
    @Query("SELECT b FROM Branch b LEFT JOIN b.branchType bt "
        + "WHERE b.company.id = :companyId AND b.isActive = true "
        + "AND (bt IS NULL OR bt.code <> 'VAULT_COUNTERPARTY') "
        + "AND (b.isVault IS NULL OR b.isVault = false) ORDER BY b.name")
    List<Branch> findByCompanyIdAndIsActiveTrueExcludingCounterpartiesAndVaults(
        @Param("companyId") UUID companyId);

    /**
     * FK02-C (2026-06-01): Árfolyamkészítő munkacsoporthoz választható irodák — KIZÁRÓLAG aktív,
     * cégen belüli, lakossági PÉNZTÁR típusú egységek (branchType.code = 'PENZTAR'). Az értéktár
     * (isVault = true) és a VAULT_COUNTERPARTY banki/speciális partnerek kizárva. Az „Irodák kezelése"
     * lista (FR-1) és a keresés (FR-3) erre a backend-szűrt halmazra épül (NFR-1: nem frontend-elrejtés).
     * Szigorúbb, mint a {@link #findByCompanyIdAndIsActiveTrueExcludingCounterparties(UUID)} (az csak a
     * VAULT_COUNTERPARTY-t zárja ki, az ERTEKTAR-t nem). INNER JOIN: branchType nélküli sor nem pénztár.
     */
    @Query("SELECT b FROM Branch b JOIN b.branchType bt "
        + "WHERE b.company.id = :companyId AND b.isActive = true "
        + "AND bt.code = 'PENZTAR' AND (b.isVault IS NULL OR b.isVault = false) ORDER BY b.name")
    List<Branch> findRateCreationAssignableCashierBranches(@Param("companyId") UUID companyId);

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
        -- FK-038 fix: a 'level' oszlop a branch_path CTE-ben letezik, NEM a branch
        -- tablaban. A korabbi 'SELECT * FROM branch ... ORDER BY level DESC' ezert
        -- 'column "level" does not exist' hibat dobott -> 500 a GET /branches/{id}/path
        -- hivason (a BranchEditPage betoltesekor "Belso szerverhiba"). A path-elemeket
        -- a CTE-vel JOIN-oljuk, igy az ORDER BY a CTE bp.level oszlopara hivatkozhat.
        SELECT b.* FROM branch b
        INNER JOIN branch_path bp ON bp.id = b.id
        ORDER BY bp.level DESC
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

    /**
     * FK (2026-06-01): aktív irodák cég + RÉGIÓ (region, NEM region_code) szerint.
     * A területi értéktár↔pénztár kapcsolat a `region` oszlopon van feltöltve (V145: pénztárak,
     * V254: értéktárak — pl. 'SZEGED'); a `region_code` (KESZLEX körzet) a pénztáraknál NULL (V250),
     * ezért a korábbi region_code-alapú scope üres listát adott. Ez a region-alapú változat a
     * helyes a vault-régió-scope-hoz.
     */
    @Query("SELECT b FROM Branch b WHERE b.company.id = :companyId " +
           "AND b.region = :region AND b.isActive = true " +
           "ORDER BY b.code")
    List<Branch> findActiveByCompanyIdAndRegion(@Param("companyId") UUID companyId,
                                                @Param("region") String region);
}
