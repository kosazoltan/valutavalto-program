package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.EmployeeAddress;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * Employee Address repository — dolgozói címek.
 */
@Repository
public interface EmployeeAddressRepository extends JpaRepository<EmployeeAddress, Long> {

    /** Dolgozó összes címe */
    List<EmployeeAddress> findByEmployeeId(Long employeeId);

    /** Dolgozó címeinek törlése */
    @Transactional(rollbackFor = Exception.class)
    void deleteByEmployeeId(Long employeeId);
}
