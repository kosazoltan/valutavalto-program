package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.SanctionEntry;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface SanctionEntryRepository extends JpaRepository<SanctionEntry, UUID> {

    List<SanctionEntry> findByFullNameContainingIgnoreCase(String name);

    List<SanctionEntry> findByAliasesContainingIgnoreCase(String alias);

    List<SanctionEntry> findByDocumentNumber(String docNumber);

    List<SanctionEntry> findByActiveTrue();

    long countByActiveTrue();

    @Query("SELECT MAX(se.lastUpdated) FROM SanctionEntry se WHERE se.active = true")
    Optional<LocalDate> findLastUpdateDate();

    @Query("SELECT se FROM SanctionEntry se WHERE se.active = true AND " +
           "(LOWER(se.fullName) LIKE LOWER(CONCAT('%', :name, '%')) OR " +
           "LOWER(se.aliases) LIKE LOWER(CONCAT('%', :name, '%')))")
    List<SanctionEntry> searchByNameOrAlias(@Param("name") String name);
}
