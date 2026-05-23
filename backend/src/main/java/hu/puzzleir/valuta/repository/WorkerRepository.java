package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.entity.WorkerRole;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Worker repository multi-tenant supporttal.
 * 
 * Minden query automatikusan szűr company_id alapján.
 */
@Repository
public interface WorkerRepository extends JpaRepository<Worker, Long> {

    /** PP-06: pesszimista zár a pénztáros sorára — egyedi-árfolyam napi kvóta TOCTOU ellen. */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT w FROM Worker w WHERE w.id = :id")
    Optional<Worker> findByIdForUpdate(@Param("id") Long id);


    /**
     * Keresés code alapján (company-n belül egyedi)
     */
    Optional<Worker> findByCompanyIdAndCode(UUID companyId, String code);
    Optional<Worker> findByCompanyIdAndCodeIgnoreCase(UUID companyId, String code);
    
    /**
     * Összes dolgozó egy céghez
     */
    List<Worker> findByCompanyId(UUID companyId);
    
    /**
     * Aktív dolgozók egy céghez
     */
    List<Worker> findByCompanyIdAndActiveTrue(UUID companyId);
    
    /**
     * Dolgozók egy irodában
     */
    List<Worker> findByBranchId(UUID branchId);
    
    /**
     * Aktív dolgozók egy irodában
     */
    @Query("SELECT w FROM Worker w WHERE w.branch.id = :branchId AND w.active = true")
    List<Worker> findActiveWorkersByBranch(@Param("branchId") UUID branchId);
    
    /**
     * Dolgozók company és role alapján
     */
    List<Worker> findByCompanyIdAndRole(UUID companyId, WorkerRole role);
    
    /**
     * Dolgozók név alapján (search)
     */
    @Query("SELECT w FROM Worker w WHERE w.company.id = :companyId AND LOWER(w.name) LIKE LOWER(CONCAT('%', :name, '%'))")
    List<Worker> searchByName(@Param("companyId") UUID companyId, @Param("name") String name);
    
    /**
     * Worker keresés ID + company (multi-tenant IDOR védelem)
     */
    Optional<Worker> findByIdAndCompanyId(Long id, UUID companyId);

    /**
     * Worker törlés ID + company alapján (multi-tenant IDOR védelem)
     */
    void deleteByIdAndCompanyId(Long id, UUID companyId);

    /**
     * Code létezik-e már (company-n belül)
     */
    boolean existsByCompanyIdAndCode(UUID companyId, String code);
    
    /**
     * Aktív dolgozók száma company-ban
     */
    @Query("SELECT COUNT(w) FROM Worker w WHERE w.company.id = :companyId AND w.active = true")
    long countActiveWorkersByCompany(@Param("companyId") UUID companyId);
    
    /**
     * Aktív dolgozók száma irodában
     */
    @Query("SELECT COUNT(w) FROM Worker w WHERE w.branch.id = :branchId AND w.active = true")
    long countActiveWorkersByBranch(@Param("branchId") UUID branchId);
    
    /**
     * Worker keresés email alapján
     */
    Optional<Worker> findByEmail(String email);

    // ============ GOOGLE OAUTH WHITELIST (V178, 2026-05-03) ============

    /**
     * Google `sub` claim alapjan keres workert. A `google_subject` partial unique
     * index garantalja az egyediseget — egy Google fiok max EGY worker-hez kotheto.
     */
    Optional<Worker> findByGoogleSubject(String googleSubject);

    /**
     * Google login candidate-ek lekerese case-insensitive email + whitelist flag-szuressel.
     * Tobb worker is lehet azonos email-lel kulonbozo company-ban (multi-tenant); a hivo
     * ellenorzi a konfiguracios hibat.
     *
     * <p>A `WHERE google_login_enabled = true` szuro a partial index-et (`idx_worker_google_email_lower`)
     * hasznalja, igy O(log n) lookup.</p>
     */
    @Query("""
        SELECT w FROM Worker w
        WHERE w.googleLoginEnabled = true
          AND LOWER(w.email) = LOWER(:email)
    """)
    List<Worker> findGoogleLoginCandidatesByEmail(@Param("email") String email);

    /**
     * Company-szurt Google setup/login lookup. A first-run wizard mindig tud companyCode-ot,
     * ezert itt nem engedunk cross-company disambiguationt.
     */
    @Query("""
        SELECT w FROM Worker w
        WHERE w.company.id = :companyId
          AND w.googleLoginEnabled = true
          AND LOWER(w.email) = LOWER(:email)
    """)
    List<Worker> findGoogleLoginCandidatesByCompanyIdAndEmail(
            @Param("companyId") UUID companyId,
            @Param("email") String email);
    
    /**
     * Supervisor és felsőbb jogosultságú dolgozók
     */
    @Query("SELECT w FROM Worker w WHERE w.company.id = :companyId AND w.role IN ('SUPERVISOR', 'MANAGER', 'ADMIN') AND w.active = true")
    List<Worker> findSupervisorsAndAbove(@Param("companyId") UUID companyId);
    
    /**
     * Osszes aktiv supervisor/manager/admin — system-szintu kereseshez (pl. scheduler).
     */
    @Query("SELECT w FROM Worker w WHERE w.role IN ('SUPERVISOR', 'MANAGER', 'ADMIN') AND w.active = true")
    List<Worker> findAllSupervisorsAndAbove();

    /**
     * Worker betöltése company + branch eager fetch-csel (LAZY proxy-k nélkül).
     * Az auth flow-kban (login, select-role, refresh, first-time-setup) használandó,
     * ahol open-in-view=false miatt a session bezárul a repository hívás után.
     */
    @Query("SELECT w FROM Worker w JOIN FETCH w.company JOIN FETCH w.branch WHERE w.id = :id")
    Optional<Worker> findByIdWithCompanyAndBranch(@Param("id") Long id);

    /**
     * OTP enabled dolgozók
     */
    @Query("SELECT w FROM Worker w WHERE w.company.id = :companyId AND w.otpEnabled = true AND w.active = true")
    List<Worker> findOtpEnabledWorkers(@Param("companyId") UUID companyId);

    /**
     * All active workers for a given company and region.
     * Used by the login-prefill public endpoint - any cashier in the region
     * can log in from any branch of that region.
     */
    List<Worker> findByCompanyIdAndRegionAndActiveTrue(UUID companyId, String region);

}
