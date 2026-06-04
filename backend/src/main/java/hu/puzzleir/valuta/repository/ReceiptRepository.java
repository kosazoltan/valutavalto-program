package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.Receipt;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@Repository
public interface ReceiptRepository extends JpaRepository<Receipt, UUID> {
    List<Receipt> findByTransactionId(UUID transactionId);
    List<Receipt> findAllByCompanyId(UUID companyId);
    List<Receipt> findByCompanyIdAndTransactionId(UUID companyId, UUID transactionId);

    /**
     * EXCMD b5b FR-BSZUR-02 (Codex P2): materializált (real) Receipt-ek OPCIONÁLIS dátum-szűréssel,
     * az {@code issueDate} alapján. Amikor a list-endpoint from/to szűrőt kap, a real receipt-eket is a
     * DB szűri (nem csak a synthesized ágat) — különben a {@code GET /api/v1/receipts?from=&to=} az
     * időszakon kívüli materializált bizonylatokat is visszaadná (és a teljes Receipt-táblát betöltené).
     * A {@code fromDate}/{@code toDate} külön-külön elhagyható (NULL = nyitott vég); mindkettő NULL →
     * a {@link #findAllByCompanyId}-vel azonos (szűretlen).
     */
    @Query("SELECT r FROM Receipt r WHERE r.companyId = :companyId " +
           "AND (:fromDate IS NULL OR r.issueDate >= :fromDate) " +
           "AND (:toDate IS NULL OR r.issueDate <= :toDate)")
    List<Receipt> findByCompanyIdAndIssueDateRange(
        @Param("companyId") UUID companyId,
        @Param("fromDate") LocalDate fromDate,
        @Param("toDate") LocalDate toDate);
}
