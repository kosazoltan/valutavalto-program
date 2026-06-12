package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.TransactionBeneficialOwner;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

/** V325 (Batch3-C): tényleges tulajdonosok — tranzakciónként, tenant-szűréssel. */
@Repository
public interface TransactionBeneficialOwnerRepository extends JpaRepository<TransactionBeneficialOwner, Long> {

    List<TransactionBeneficialOwner> findByCompanyIdAndTransactionIdOrderByOwnerNo(UUID companyId, Long transactionId);
}
