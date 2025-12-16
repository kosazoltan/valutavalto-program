package hu.puzzleir.valuta.repository;

import com.puzzleir.backend.entity.Company;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

/**
 * Company repository.
 */
@Repository
public interface CompanyRepository extends JpaRepository<Company, UUID> {
    
    /**
     * Keresés code alapján
     */
    Optional<Company> findByCode(String code);
    
    /**
     * Code létezik-e
     */
    boolean existsByCode(String code);
}
