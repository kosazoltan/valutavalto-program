package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.WuTransaction;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface WuTransactionRepository extends JpaRepository<WuTransaction, UUID> {

    @Query("SELECT t FROM WuTransaction t WHERE t.branch.id = :branchId " +
           "AND t.branch.company.id = :companyId " +
           "AND (:from IS NULL OR t.transactionDate >= :from) " +
           "AND (:to IS NULL OR t.transactionDate <= :to) " +
           "ORDER BY t.transactionDate DESC")
    Page<WuTransaction> findByBranchAndDateRange(
            @Param("branchId") UUID branchId,
            @Param("companyId") UUID companyId,
            @Param("from") LocalDateTime from,
            @Param("to") LocalDateTime to,
            Pageable pageable);

    @Query("SELECT t FROM WuTransaction t WHERE t.branch.id = :branchId " +
           "AND t.branch.company.id = :companyId " +
           "AND t.transactionDate >= :from AND t.transactionDate <= :to")
    List<WuTransaction> findAllByBranchAndDateRange(
            @Param("branchId") UUID branchId,
            @Param("companyId") UUID companyId,
            @Param("from") LocalDateTime from,
            @Param("to") LocalDateTime to);

    Optional<WuTransaction> findFirstByMtcnAndCompanyIdOrderByTransactionDateDesc(String mtcn, UUID companyId);

    /**
     * SOF 10M/7nap kumulált trigger (EBC szabályzat V.2.8 A.1): az ügyfél (WuCustomer)
     * lezárt SEND/RECEIVE forgalma az ablakban. Company-szűrt (multi-tenant).
     */
    @Query("SELECT t FROM WuTransaction t WHERE t.company.id = :companyId " +
           "AND t.wuCustomer.id = :wuCustomerId " +
           "AND t.transactionType IN ('SEND','RECEIVE') " +
           "AND t.status = hu.puzzleir.valuta.entity.WuTransactionStatus.COMPLETED " +
           "AND t.transactionDate >= :since")
    List<WuTransaction> findRecentSendReceiveByCustomer(
            @Param("companyId") UUID companyId,
            @Param("wuCustomerId") UUID wuCustomerId,
            @Param("since") LocalDateTime since);

    /**
     * SOF 10M/7nap trigger név-alapú fallbackje, ha a tranzakcióhoz nincs WuCustomer kötve:
     * az „ugyanazon ügyfél" a SEND-nél a küldő, a RECEIVE-nél a fogadó neve (kisbetű-érzéketlen).
     */
    @Query("SELECT t FROM WuTransaction t WHERE t.company.id = :companyId " +
           "AND ((t.transactionType = 'SEND' AND UPPER(t.senderName) = :nameUpper) " +
           "  OR (t.transactionType = 'RECEIVE' AND UPPER(t.receiverName) = :nameUpper)) " +
           "AND t.status = hu.puzzleir.valuta.entity.WuTransactionStatus.COMPLETED " +
           "AND t.transactionDate >= :since")
    List<WuTransaction> findRecentSendReceiveByCustomerName(
            @Param("companyId") UUID companyId,
            @Param("nameUpper") String nameUpper,
            @Param("since") LocalDateTime since);
}
