package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.MaterialReceipt;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface MaterialReceiptRepository extends JpaRepository<MaterialReceipt, Long> {
    List<MaterialReceipt> findByCompanyIdOrderByCreatedAtDesc(UUID companyId);
    List<MaterialReceipt> findByCompanyIdAndReceiptTypeOrderByCreatedAtDesc(UUID companyId, String receiptType);

    @Query(value = "SELECT nextval('material_receipt_seq')", nativeQuery = true)
    Long getNextReceiptNumber();
}
