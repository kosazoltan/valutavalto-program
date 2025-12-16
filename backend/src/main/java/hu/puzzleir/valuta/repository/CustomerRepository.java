package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.Customer;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Customer repository.
 */
@Repository
public interface CustomerRepository extends JpaRepository<Customer, Long> {

    /**
     * Ügyfél keresése dokumentum szám alapján
     */
    Optional<Customer> findByDocumentNumberAndCompanyId(String documentNumber, UUID companyId);

    /**
     * Ügyfél keresése ügyfélkód alapján
     */
    Optional<Customer> findByCustomerCodeAndCompanyId(String customerCode, UUID companyId);

    /**
     * Ügyfelek keresése név alapján
     */
    @Query("SELECT c FROM Customer c " +
           "WHERE c.company.id = :companyId " +
           "AND LOWER(c.name) LIKE LOWER(CONCAT('%', :name, '%'))")
    List<Customer> searchByName(
        @Param("companyId") UUID companyId,
        @Param("name") String name
    );

    /**
     * VIP ügyfelek
     */
    @Query("SELECT c FROM Customer c " +
           "WHERE c.company.id = :companyId " +
           "AND c.isVip = true " +
           "AND c.active = true")
    List<Customer> findVipCustomers(@Param("companyId") UUID companyId);

    /**
     * Aktív ügyfelek
     */
    List<Customer> findByCompanyIdAndActiveTrue(UUID companyId);
}
