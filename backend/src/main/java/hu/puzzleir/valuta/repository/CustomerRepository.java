package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.Customer;
import hu.puzzleir.valuta.entity.ReviewStatus;
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
     * Ügyfél keresése személyi ig. szám alapján
     */
    Optional<Customer> findByIdCardNumberAndCompanyId(String idCardNumber, UUID companyId);

    /**
     * Ügyfél keresése útlevél szám alapján
     */
    Optional<Customer> findByPassportNumberAndCompanyId(String passportNumber, UUID companyId);

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
     * Ügyfelek keresése név vagy okmányszám alapján.
     */
    @Query("SELECT c FROM Customer c " +
           "WHERE c.company.id = :companyId " +
           "AND (" +
           "LOWER(c.name) LIKE LOWER(CONCAT('%', :query, '%')) " +
           "OR LOWER(c.documentNumber) LIKE LOWER(CONCAT('%', :query, '%')) " +
           "OR LOWER(c.idCardNumber) LIKE LOWER(CONCAT('%', :query, '%')) " +
           "OR LOWER(c.passportNumber) LIKE LOWER(CONCAT('%', :query, '%'))" +
           ")")
    List<Customer> searchByNameOrDocument(
        @Param("companyId") UUID companyId,
        @Param("query") String query
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

    /** FS-3 (D2): átnézésre váró ügyfelek — companyId-szűrt (invariáns #1). */
    List<Customer> findByCompanyIdAndReviewStatusOrderByUpdatedAtDesc(UUID companyId, ReviewStatus reviewStatus);

    /**
     * Keresés név alapján (rendőrségi adatkéréshez) — company szűréssel
     */
    List<Customer> findByCompanyIdAndNameContainingIgnoreCase(UUID companyId, String name);

    /**
     * Keresés okmányszám alapján (rendőrségi adatkéréshez) — company szűréssel
     */
    List<Customer> findByCompanyIdAndDocumentNumberContainingIgnoreCase(UUID companyId, String documentNumber);

    /**
     * IDOR-fix (F-2): cég-szűrt ügyfél-létezés ellenőrzés. A ScannedDocument csak
     * customerId-t hordoz, a tenancy a szülő Customer-en van — a dokumentum-lekérés
     * előtt ezzel validáljuk, hogy az ügyfél a hívó cégéhez tartozik-e.
     */
    boolean existsByIdAndCompany_Id(Long id, UUID companyId);
}
