package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.Employee;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Employee repository — dolgozói HR törzsadatok.
 */
@Repository
public interface EmployeeRepository extends JpaRepository<Employee, Long> {

    /** Cég összes dolgozója */
    List<Employee> findByCompanyId(UUID companyId);

    /** Cég dolgozói — aktív szűréssel */
    List<Employee> findByCompanyIdAndActive(UUID companyId, Boolean active);

    /** Szervezeti egység szerint */
    List<Employee> findByCompanyIdAndOrganizationUnit(UUID companyId, String organizationUnit);

    /** Adóazonosító alapján keresés */
    Optional<Employee> findByCompanyIdAndTaxId(UUID companyId, String taxId);

    /** TAJ-szám alapján keresés */
    Optional<Employee> findByCompanyIdAndSocialSecurityNumber(UUID companyId, String socialSecurityNumber);

    /** Név alapján keresés (részleges, case-insensitive) */
    @Query("SELECT e FROM Employee e WHERE e.company.id = :companyId " +
           "AND (LOWER(e.lastName) LIKE LOWER(CONCAT('%', :name, '%')) " +
           "OR LOWER(e.firstName) LIKE LOWER(CONCAT('%', :name, '%')))")
    List<Employee> searchByName(@Param("companyId") UUID companyId, @Param("name") String name);

    /** Munkakör szerint */
    List<Employee> findByCompanyIdAndJobTitleContainingIgnoreCase(UUID companyId, String jobTitle);

    /** Szervezeti egység + aktív szűréssel */
    List<Employee> findByCompanyIdAndOrganizationUnitAndActive(UUID companyId, String organizationUnit, Boolean active);
}
