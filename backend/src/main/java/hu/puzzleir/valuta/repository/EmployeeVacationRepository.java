package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.EmployeeVacation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface EmployeeVacationRepository extends JpaRepository<EmployeeVacation, Long> {
    List<EmployeeVacation> findByEmployeeIdOrderByYearDesc(Long employeeId);

    boolean existsByEmployeeIdAndYear(Long employeeId, Integer year);

    /** Cégszintű export: az adott cég összes dolgozójának szabadság-sorai (NFR-03). */
    @Query("SELECT v FROM EmployeeVacation v " +
           "WHERE v.employee.company.id = :companyId " +
           "ORDER BY v.employee.lastName, v.employee.firstName, v.year DESC")
    List<EmployeeVacation> findAllByCompanyId(@Param("companyId") UUID companyId);
}
