package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.WuCustomer;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface WuCustomerRepository extends JpaRepository<WuCustomer, UUID> {

    Optional<WuCustomer> findByIdNumber(String idNumber);
}
