package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.VatRefundTransaction;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/**
 * ÁFA visszatérítés tranzakció repository.
 */
@Repository
public interface VatRefundTransactionRepository extends JpaRepository<VatRefundTransaction, Long> {

    List<VatRefundTransaction> findByCompanyIdOrderByTransactionDateDescCreatedAtDesc(UUID companyId);

    List<VatRefundTransaction> findByCompanyIdAndTransactionDateBetweenOrderByTransactionDateDescCreatedAtDesc(
        UUID companyId, LocalDate from, LocalDate to);

    List<VatRefundTransaction> findByCompanyIdAndVoucherTypeOrderByTransactionDateDesc(
        UUID companyId, VatRefundTransaction.VoucherType voucherType);

    @Query("SELECT v FROM VatRefundTransaction v " +
           "WHERE v.companyId = :companyId " +
           "AND v.isReversed = false " +
           "AND v.transactionDate = :date " +
           "ORDER BY v.transactionTime")
    List<VatRefundTransaction> findActiveByCompanyAndDate(
        @Param("companyId") UUID companyId,
        @Param("date") LocalDate date);
}
