package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.EmployeeBankAccount;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

/**
 * Employee Bank Account repository — dolgozói bankszámlák.
 */
@Repository
public interface EmployeeBankAccountRepository extends JpaRepository<EmployeeBankAccount, Long> {

    /** Dolgozó összes bankszámlája */
    List<EmployeeBankAccount> findByEmployeeId(Long employeeId);

    /** Dolgozó bankszámláinak törlése */
    void deleteByEmployeeId(Long employeeId);
}
