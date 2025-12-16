package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.entity.WorkerRole;
import org.springframework.data.jpa.repository.JpaRepository;
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
    
    /**
     * Keresés code alapján (company-n belül egyedi)
     */
    Optional<Worker> findByCompanyIdAndCode(UUID companyId, String code);
    
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
     * Supervisor és felsőbb jogosultságú dolgozók
     */
    @Query("SELECT w FROM Worker w WHERE w.company.id = :companyId AND w.role IN ('SUPERVISOR', 'MANAGER', 'ADMIN') AND w.active = true")
    List<Worker> findSupervisorsAndAbove(@Param("companyId") UUID companyId);
    
    /**
     * OTP enabled dolgozók
     */
    @Query("SELECT w FROM Worker w WHERE w.company.id = :companyId AND w.otpEnabled = true AND w.active = true")
    List<Worker> findOtpEnabledWorkers(@Param("companyId") UUID companyId);
}
