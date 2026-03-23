package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.Company;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface CompanyRepository extends JpaRepository<Company, UUID> {

    /**
     * Keresés code alapján
     */
    Optional<Company> findByCode(String code);
    Optional<Company> findByCodeIgnoreCase(String code);

    /**
     * Code létezik-e
     */
    boolean existsByCode(String code);
}
