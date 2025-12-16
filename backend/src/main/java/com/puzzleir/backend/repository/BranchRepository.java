package com.puzzleir.backend.repository;

import com.puzzleir.backend.entity.Branch;
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
     * Fiókok típus szerint
     */
    @Query("SELECT b FROM Branch b WHERE b.branchType.code = :typeCode")
    List<Branch> findByBranchTypeCode(@Param("typeCode") String typeCode);

    /**
     * Fiókok státusz szerint
     */
    @Query("SELECT b FROM Branch b WHERE b.branchStatus.code = :statusCode")
    List<Branch> findByBranchStatusCode(@Param("statusCode") String statusCode);

    /**
     * Szülő alatti fiókok (közvetlen gyermekek)
     */
    @Query("SELECT b FROM Branch b WHERE b.parentBranch.id = :parentId")
    List<Branch> findByParentBranchId(@Param("parentId") UUID parentId);

    /**
     * Gyökér fiókok (nincs szülő)
     */
    @Query("SELECT b FROM Branch b WHERE b.parentBranch IS NULL")
    List<Branch> findRootBranches();

    /**
     * Keresés név vagy kód szerint (partial match)
     */
    @Query("SELECT b FROM Branch b WHERE " +
           "LOWER(b.name) LIKE LOWER(CONCAT('%', :search, '%')) OR " +
           "LOWER(b.code) LIKE LOWER(CONCAT('%', :search, '%'))")
    List<Branch> searchByNameOrCode(@Param("search") String search);

    /**
     * Fiókok város szerint
     */
    List<Branch> findByCity(String city);

    /**
     * Fiókok cégen belül
     */
    @Query("SELECT b FROM Branch b WHERE b.company.id = :companyId")
    List<Branch> findByCompanyId(@Param("companyId") UUID companyId);

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
}
