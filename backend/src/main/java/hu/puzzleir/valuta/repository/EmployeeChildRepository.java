package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.EmployeeChild;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface EmployeeChildRepository extends JpaRepository<EmployeeChild, Long> {
    List<EmployeeChild> findByEmployeeIdOrderByBirthDateAsc(Long employeeId);
}
