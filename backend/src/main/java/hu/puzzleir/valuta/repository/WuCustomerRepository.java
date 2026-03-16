package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.WuCustomer;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface WuCustomerRepository extends JpaRepository<WuCustomer, UUID> {

    Optional<WuCustomer> findByIdNumber(String idNumber);

    /**
     * Deduplikáció: azonos vezéknév + keresztnév + dokumentumszám kombinációra keres.
     * Segít elkerülni a duplikált WuCustomer rekordokat.
     * @deprecated Nem multi-tenant safe! Használd a companyId-s változatot.
     */
    @Deprecated
    Optional<WuCustomer> findByLastNameAndFirstNameAndIdNumber(
            String lastName, String firstName, String idNumber);

    /**
     * Multi-tenant safe deduplikáció: cégszintű egyediség ellenőrzés.
     */
    Optional<WuCustomer> findByCompanyIdAndLastNameAndFirstNameAndIdNumber(
            UUID companyId, String lastName, String firstName, String idNumber);
}
