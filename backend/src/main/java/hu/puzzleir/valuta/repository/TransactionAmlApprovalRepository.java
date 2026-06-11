package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.TransactionAmlApproval;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

/**
 * AML felsővezetői jóváhagyás audit-rekordok repository (Pmt. 14/A. § (4), MNB 14/2025 V.2.6).
 * Insert-only audit — csak mentés + olvasás; nincs update/delete kontraktus.
 */
public interface TransactionAmlApprovalRepository extends JpaRepository<TransactionAmlApproval, UUID> {

    List<TransactionAmlApproval> findByCompanyIdOrderByApprovedAtDesc(UUID companyId);

    /**
     * V312 / FR-BSZUR-05: a bizonylat-lista ENGEDÉLYEZŐ-dúsításának batch-lookupja —
     * cég-szűrt, session-kulcsok szerint (N+1 elkerülése, a lista egy query-ből tölt).
     */
    List<TransactionAmlApproval> findByCompanyIdAndApprovalSessionIdIn(
            UUID companyId, java.util.Collection<String> approvalSessionIds);
}
