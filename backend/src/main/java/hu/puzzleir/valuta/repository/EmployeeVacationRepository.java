package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.EmployeeVacation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface EmployeeVacationRepository extends JpaRepository<EmployeeVacation, Long> {
    List<EmployeeVacation> findByEmployeeIdOrderByYearDesc(Long employeeId);
}
