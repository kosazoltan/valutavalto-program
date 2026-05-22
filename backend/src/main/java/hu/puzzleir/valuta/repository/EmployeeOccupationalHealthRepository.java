package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.EmployeeOccupationalHealth;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface EmployeeOccupationalHealthRepository extends JpaRepository<EmployeeOccupationalHealth, Long> {
    List<EmployeeOccupationalHealth> findByEmployeeIdOrderByExamDateDesc(Long employeeId);
}
