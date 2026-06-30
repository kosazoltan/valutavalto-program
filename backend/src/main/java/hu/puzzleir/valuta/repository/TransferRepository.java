package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.Transfer;
import jakarta.persistence.LockModeType;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface TransferRepository extends JpaRepository<Transfer, Long> {

    Optional<Transfer> findByTransferNumber(String transferNumber);

    /** Pessimistic lock a sztornóhoz: a konkurens dupla-sztornó (kétszeres készlet-visszafordítás) ellen. */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT t FROM Transfer t WHERE t.id = :id")
    Optional<Transfer> findByIdForUpdate(@Param("id") Long id);

    List<Transfer> findByStatus(Transfer.TransferStatus status);

    @Query("SELECT t FROM Transfer t WHERE " +
           "(t.fromBranch.company.id = :companyId OR t.toBranch.company.id = :companyId) " +
           "AND t.status = :status")
    List<Transfer> findByCompanyAndStatus(@Param("companyId") UUID companyId, @Param("status") Transfer.TransferStatus status);

    /**
     * Az adott fiókhoz tartozó (bejövő VAGY kimenő) PENDING átadások, cég-szűrve.
     * A szűrés DB-oldalon történik (nem a teljes cég pending halmazát húzza le + Java-szűr),
     * és JOIN FETCH-csel betölti a {@code toDto}-hoz szükséges lazy asszociációkat
     * (from/to branch + currency), így nincs N+1 lazy-load query.
     */
    @Query("SELECT DISTINCT t FROM Transfer t " +
           "JOIN FETCH t.fromBranch fb " +
           "JOIN FETCH t.toBranch tb " +
           "JOIN FETCH t.currency " +
           "WHERE (fb.company.id = :companyId OR tb.company.id = :companyId) " +
           "AND t.status = :status " +
           "AND (fb.id = :branchId OR tb.id = :branchId)")
    List<Transfer> findPendingForBranch(@Param("companyId") UUID companyId,
                                        @Param("branchId") UUID branchId,
                                        @Param("status") Transfer.TransferStatus status);

    @Query("SELECT t FROM Transfer t WHERE t.fromBranch.id = :branchId AND t.status IN ('PENDING', 'IN_TRANSIT')")
    List<Transfer> findOutgoingByBranch(@Param("branchId") UUID branchId);

    @Query("SELECT t FROM Transfer t WHERE t.toBranch.id = :branchId AND t.status IN ('PENDING', 'IN_TRANSIT')")
    List<Transfer> findIncomingByBranch(@Param("branchId") UUID branchId);

    @Query("SELECT t FROM Transfer t WHERE " +
           "(:branchId IS NULL OR t.fromBranch.id = :branchId OR t.toBranch.id = :branchId) " +
           "AND (:startDate IS NULL OR t.transferDate >= :startDate) " +
           "AND (:endDate IS NULL OR t.transferDate <= :endDate) " +
           "AND (:status IS NULL OR t.status = :status) " +
           "AND (:type IS NULL OR t.transferType = :type)")
    Page<Transfer> search(
            @Param("branchId") UUID branchId,
            @Param("startDate") LocalDate startDate,
            @Param("endDate") LocalDate endDate,
            @Param("status") Transfer.TransferStatus status,
            @Param("type") Transfer.TransferType type,
            Pageable pageable);

    @Query("SELECT COUNT(t) FROM Transfer t WHERE t.toBranch.id = :branchId AND t.status IN ('PENDING', 'IN_TRANSIT')")
    long countPendingByBranch(@Param("branchId") UUID branchId);

    /**
     * FK-003: Pénztárak/értéktárak közötti pénzmozgások egyeztetéshez — cég-szűrt, intervallumra.
     * A CANCELLED/REJECTED tételek nem valós pénzmozgások, ezért kizárva. A {@code lines}
     * lazy módon töltődik a hívó @Transactional metóduson belül.
     */
    @Query("SELECT DISTINCT t FROM Transfer t " +
           "JOIN FETCH t.fromBranch fb " +
           "JOIN FETCH t.toBranch tb " +
           "JOIN FETCH t.currency " +
           "LEFT JOIN FETCH t.lines l " +
           "LEFT JOIN FETCH l.currency " +
           "WHERE (fb.company.id = :companyId OR tb.company.id = :companyId) " +
           "AND t.transferDate BETWEEN :startDate AND :endDate " +
           "AND t.status NOT IN (hu.puzzleir.valuta.entity.Transfer$TransferStatus.CANCELLED, " +
           "hu.puzzleir.valuta.entity.Transfer$TransferStatus.REJECTED) " +
           "ORDER BY t.transferDate, t.transferNumber")
    List<Transfer> findForReconciliation(@Param("companyId") UUID companyId,
                                         @Param("startDate") LocalDate startDate,
                                         @Param("endDate") LocalDate endDate);

    /**
     * Értéktár→pénztár átvett (RECEIVED) lehívások az adott pénztárakra, időszakra.
     * Az átértékelés-allokáció „lehívott forgalom" hajtóereje (legacy puffer→pénztár átadás).
     */
    @Query("SELECT t FROM Transfer t WHERE (t.fromBranch.company.id = :companyId OR t.toBranch.company.id = :companyId) " +
           "AND t.toBranch.id IN :toBranchIds " +
           "AND t.fromBranch.isVault = true AND t.status = hu.puzzleir.valuta.entity.Transfer$TransferStatus.RECEIVED " +
           "AND t.transferDate BETWEEN :from AND :to")
    List<Transfer> findVaultDrawsToCashiers(@Param("companyId") UUID companyId,
                                            @Param("toBranchIds") List<UUID> toBranchIds,
                                            @Param("from") LocalDate from, @Param("to") LocalDate to);

    /**
     * FK-005/B2+B3: az átadólap-sorszám gap-mentes szekvenciájához. A megadott teljes
     * prefix (pl. "F020" / "UF020") utáni numerikus szuffix maximuma.
     *
     * @param fullPrefix a teljes prefix (irány-prefix + 3-jegyű branch-szám, pl. "FF020")
     * @param startPos a numerikus szuffix kezdő pozíciója (1-indexelt SUBSTRING) =
     *                 {@code fullPrefix.length() + 1}
     */
    @Query("SELECT COALESCE(MAX(CAST(SUBSTRING(t.transferNumber, :startPos) AS long)), 0) "
            + "FROM Transfer t WHERE t.transferNumber LIKE CONCAT(:fullPrefix, '%')")
    long findMaxSlipSequence(@Param("fullPrefix") String fullPrefix, @Param("startPos") int startPos);

    /**
     * Értéktári átadás-átvétel CÉGSZINTŰ folyamatos sorszámához (AT/AV/FF/UF-NNNNNN).
     * A megadott prefix-minta (pl. "AT-%") utáni 6-jegyű numerikus szuffix maximuma a cégen belül.
     * A sztornó bizonylatokat (`...-SZ`) kizárjuk, hogy a CAST ne hibázzon és ne torzítsa a maximumot.
     *
     * @param companyId  a cég (tenant) azonosítója — a sorszám cégszinten folyamatos
     * @param likePattern prefix-minta, pl. {@code "AT-%"}
     * @param startPos    a numerikus szuffix kezdő pozíciója (1-indexelt SUBSTRING) = prefix + '-' után, pl. 4
     */
    @Query("SELECT COALESCE(MAX(CAST(SUBSTRING(t.transferNumber, :startPos) AS long)), 0) "
            + "FROM Transfer t WHERE (t.fromBranch.company.id = :companyId OR t.toBranch.company.id = :companyId) "
            + "AND t.transferNumber LIKE :likePattern AND t.transferNumber NOT LIKE '%-SZ'")
    long findMaxTransferSerialForCompany(@Param("companyId") UUID companyId,
                                         @Param("likePattern") String likePattern,
                                         @Param("startPos") int startPos);

    // ===== FK-046: napi mérleg — Többlet-Hiány (TH) elszámolási pénztár szétválasztása =====
    // Minden lekérdezés tenant-szűrt (companyId) — §6.b cross-tenant követelmény (GLM-review #1).
    // A korábbi H-3 sumTransfersIn/sumTransfersOut (TH-kizárás és tenant-szűrés nélkül) törölve:
    // holt kód volt (nincs hívó), és a TH-tételeket tévesen beleszámolta volna (GLM-review #4/TBD#2).

    /**
     * FK-046 FR-3: NORMÁL pénztárközi ÁTVÉTEL napi összege, a TH (Többlet-Hiány elszámolási
     * pénztár, kód: 'TH') felőli tételek KIZÁRVA — ezek külön Többlet/Hiány-ként számolódnak.
     * Kétoldali tenant-szűrés (mindkét branch a hívó cégéhez kötött) — konzisztens a surplus/shortage
     * lekérdezésekkel, cross-tenant adathiba ellen (GLM-review #7).
     */
    @Query("SELECT COALESCE(SUM(t.amount), 0) FROM Transfer t WHERE t.toBranch.id = :branchId " +
           "AND t.toBranch.company.id = :companyId " +
           "AND t.transferDate = :date AND t.currency.code = :currencyCode AND t.status = 'COMPLETED' " +
           "AND (t.fromBranch IS NULL OR (t.fromBranch.company.id = :companyId AND t.fromBranch.code <> 'TH'))")
    BigDecimal sumTransfersInExcludingTh(@Param("branchId") UUID branchId, @Param("companyId") UUID companyId, @Param("date") LocalDate date, @Param("currencyCode") String currencyCode);

    /**
     * FK-046 FR-3: NORMÁL pénztárközi ÁTADÁS napi összege, a TH felé irányuló tételek KIZÁRVA.
     * Kétoldali tenant-szűrés (GLM-review #7).
     */
    @Query("SELECT COALESCE(SUM(t.amount), 0) FROM Transfer t WHERE t.fromBranch.id = :branchId " +
           "AND t.fromBranch.company.id = :companyId " +
           "AND t.transferDate = :date AND t.currency.code = :currencyCode AND t.status = 'COMPLETED' " +
           "AND (t.toBranch IS NULL OR (t.toBranch.company.id = :companyId AND t.toBranch.code <> 'TH'))")
    BigDecimal sumTransfersOutExcludingTh(@Param("branchId") UUID branchId, @Param("companyId") UUID companyId, @Param("date") LocalDate date, @Param("currencyCode") String currencyCode);

    /**
     * FK-046 FR-4/FR-6: TÖBBLET — a pénztár a TH elszámolási pénztártól ÁTVETT (TH a forrás),
     * teljesített (COMPLETED) tételek napi összege valutánként. Mindkét oldal a hívó cégéhez kötött.
     */
    @Query("SELECT COALESCE(SUM(t.amount), 0) FROM Transfer t WHERE t.toBranch.id = :branchId " +
           "AND t.toBranch.company.id = :companyId AND t.fromBranch.company.id = :companyId " +
           "AND t.fromBranch.code = 'TH' AND t.transferDate = :date AND t.currency.code = :currencyCode AND t.status = 'COMPLETED'")
    BigDecimal sumSurplusFromTh(@Param("branchId") UUID branchId, @Param("companyId") UUID companyId, @Param("date") LocalDate date, @Param("currencyCode") String currencyCode);

    /**
     * FK-046 FR-4/FR-6: HIÁNY — a pénztár a TH elszámolási pénztárnak ÁTADOTT (TH a célpont),
     * teljesített (COMPLETED) tételek napi összege valutánként. Mindkét oldal a hívó cégéhez kötött.
     */
    @Query("SELECT COALESCE(SUM(t.amount), 0) FROM Transfer t WHERE t.fromBranch.id = :branchId " +
           "AND t.fromBranch.company.id = :companyId AND t.toBranch.company.id = :companyId " +
           "AND t.toBranch.code = 'TH' AND t.transferDate = :date AND t.currency.code = :currencyCode AND t.status = 'COMPLETED'")
    BigDecimal sumShortageToTh(@Param("branchId") UUID branchId, @Param("companyId") UUID companyId, @Param("date") LocalDate date, @Param("currencyCode") String currencyCode);

    /** Havi aggregalt bejovo transfer osszegek devizanementkent */
    @Query("SELECT t.currency.code, COALESCE(SUM(t.amount), 0) FROM Transfer t " +
           "WHERE t.toBranch.id = :branchId AND t.transferDate BETWEEN :startDate AND :endDate " +
           "AND t.status = 'COMPLETED' GROUP BY t.currency.code")
    List<Object[]> sumTransfersInByPeriod(@Param("branchId") UUID branchId,
                                          @Param("startDate") LocalDate startDate,
                                          @Param("endDate") LocalDate endDate);

    /** Havi aggregalt kimeno transfer osszegek devizanementkent */
    @Query("SELECT t.currency.code, COALESCE(SUM(t.amount), 0) FROM Transfer t " +
           "WHERE t.fromBranch.id = :branchId AND t.transferDate BETWEEN :startDate AND :endDate " +
           "AND t.status = 'COMPLETED' GROUP BY t.currency.code")
    List<Object[]> sumTransfersOutByPeriod(@Param("branchId") UUID branchId,
                                           @Param("startDate") LocalDate startDate,
                                           @Param("endDate") LocalDate endDate);

    /** ReportService â€" kimenĹ' ĂˇtadĂˇsok */
    @Query("SELECT t FROM Transfer t WHERE t.fromBranch.id = :branchId ORDER BY t.createdAt DESC")
    List<Transfer> findByFromBranchIdOrderByCreatedAtDesc(@Param("branchId") UUID branchId);

    /** ReportService â€" bejĂ¶vĹ' ĂˇtadĂˇsok */
    @Query("SELECT t FROM Transfer t WHERE t.toBranch.id = :branchId ORDER BY t.createdAt DESC")
    List<Transfer> findByToBranchIdOrderByCreatedAtDesc(@Param("branchId") UUID branchId);
}
