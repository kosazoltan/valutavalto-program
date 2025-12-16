package hu.puzzleir.valuta.repository;

import com.puzzleir.backend.entity.Branch;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Branch repository.
 */
@Repository
public interface BranchRepository extends JpaRepository<Branch, UUID> {
    
    /**
     * Keresés kód alapján
     */
    Optional<Branch> findByCode(String code);
    
    /**
     * Ellenőrzi, hogy létezik-e adott kóddal fiók
     */
    boolean existsByCode(String code);
    
    /**
     * Összes aktív fiók lekérdezése
     */
    List<Branch> findByIsActiveTrue();
    
    /**
     * Fiókok cégen belül
     */
    @Query("SELECT b FROM Branch b WHERE b.company.id = :companyId")
    List<Branch> findByCompanyId(@Param("companyId") UUID companyId);
    
    /**
     * Gyökér fiókok (nincs szülő)
     */
    @Query("SELECT b FROM Branch b WHERE b.parentBranch IS NULL")
    List<Branch> findRootBranches();
    
    /**
     * Szülő alatti fiókok (közvetlen gyermekek)
     */
    @Query("SELECT b FROM Branch b WHERE b.parentBranch.id = :parentId")
    List<Branch> findByParentBranchId(@Param("parentId") UUID parentId);
}
