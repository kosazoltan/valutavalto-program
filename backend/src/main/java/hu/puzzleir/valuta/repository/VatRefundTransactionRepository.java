package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.VatRefundTransaction;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
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

    /** Pessimistic lock a sztornóhoz (dupla-sztornó race elleni védelem). */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT v FROM VatRefundTransaction v WHERE v.id = :id")
    Optional<VatRefundTransaction> findByIdForUpdate(@Param("id") Long id);

    /**
     * Cégszintű, DB-alapú sorszám-generáláshoz: a {@code TÍPUS-YYYYMMDD-%} mintára illeszkedő
     * sorszámok numerikus szuffixének maximuma a cégen belül. A {@code -DUP} (V300 dedup) és a
     * {@code SZTORNO-} prefixű serialokat kizárjuk, hogy a CAST ne hibázzon és ne torzítsa a maximumot.
     *
     * @param startPos a numerikus szuffix kezdő pozíciója (1-indexelt SUBSTRING), pl. "AK-20260607-" → 13
     */
    @Query("SELECT COALESCE(MAX(CAST(SUBSTRING(v.serialNumber, :startPos) AS long)), 0) " +
           "FROM VatRefundTransaction v WHERE v.companyId = :companyId " +
           "AND v.serialNumber LIKE :likePattern AND v.serialNumber NOT LIKE '%-DUP%'")
    long findMaxVatSerialForCompany(@Param("companyId") UUID companyId,
                                    @Param("likePattern") String likePattern,
                                    @Param("startPos") int startPos);
}
