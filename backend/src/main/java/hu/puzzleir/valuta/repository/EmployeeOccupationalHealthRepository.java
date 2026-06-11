package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.EmployeeOccupationalHealth;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface EmployeeOccupationalHealthRepository extends JpaRepository<EmployeeOccupationalHealth, Long> {
    List<EmployeeOccupationalHealth> findByEmployeeIdOrderByExamDateDesc(Long employeeId);

    /** Cégszintű export: az adott cég összes dolgozójának üzemorvosi rekordjai (NFR-03). */
    @Query("SELECT o FROM EmployeeOccupationalHealth o " +
           "JOIN FETCH o.employee " +
           "WHERE o.employee.company.id = :companyId " +
           "ORDER BY o.employee.lastName, o.employee.firstName, o.examDate DESC")
    List<EmployeeOccupationalHealth> findAllByCompanyId(@Param("companyId") UUID companyId);
}
