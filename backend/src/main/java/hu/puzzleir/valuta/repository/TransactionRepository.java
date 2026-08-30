package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.entity.TransactionStatus;
import hu.puzzleir.valuta.entity.TransactionType;
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
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Transaction repository.
 */
@Repository
public interface TransactionRepository extends JpaRepository<Transaction, Long> {

    /** PP-07: pesszimista zár az eredeti tranzakcióra — dupla-sztornó (TOCTOU) ellen. */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT t FROM Transaction t WHERE t.id = :id")
    Optional<Transaction> findByIdForUpdate(@Param("id") Long id);

    /**
     * PP-03 IDOR: cég-szűrt tranzakció-lekérés. A más cég tranzakciója és a nem létező
     * tranzakció ugyanazt az üres eredményt adja — így nincs oldalcsatorna (txId-enumeráció).
     */
    @Query("SELECT t FROM Transaction t WHERE t.id = :id AND t.company.id = :companyId")
    Optional<Transaction> findByIdAndCompanyId(@Param("id") Long id, @Param("companyId") UUID companyId);

    /**
     * Batch, cég-szűrt tranzakció-lekérés id-halmazra (bizonylat-böngésző dúsítás).
     * A company-szűrés a query-ben történik (JPQL t.company.id) — így (1) más cég
     * tranzakciója NEM kerül vissza (multi-tenant), és (2) NEM kell a detached
     * {@code tx.getCompany()} lazy-asszociációt dereferálni (OSIV=off →
     * LazyInitializationException elkerülve). Csak skalár mezőket olvasunk
     * (customerName, hufAmount), amelyek a SELECT t-vel betöltődnek.
     */
    @Query("SELECT t FROM Transaction t WHERE t.id IN :ids AND t.company.id = :companyId")
    List<Transaction> findAllByIdInAndCompanyId(
        @Param("ids") java.util.Collection<Long> ids,
        @Param("companyId") UUID companyId);

    /**
     * Bizonylat keresése szám alapján (JOIN FETCH a lazy proxy hiba elkerüléséhez)
     */
    @Query("SELECT t FROM Transaction t " +
           "JOIN FETCH t.branch " +
           "JOIN FETCH t.company " +
           "LEFT JOIN FETCH t.currency " +
           "LEFT JOIN FETCH t.worker " +
           "LEFT JOIN FETCH t.originalTransaction " +
           "WHERE t.receiptNumber = :receiptNumber AND t.company.id = :companyId")
    Optional<Transaction> findByReceiptNumberAndCompanyId(
        @Param("receiptNumber") String receiptNumber,
        @Param("companyId") UUID companyId);

    /**
     * FK-071 HIGH-D (Codex security review): fiók-szintre szűkített bizonylat-lekérdezés
     * a nem-supervisor (pénztáros) hívókhoz — a cégszintű változat bizonylatszám-
     * tippeléssel más fiók tranzakcióját is kiadta volna. A scope-on kívüli találat
     * üres Optional → 404 (létezés-maszkolás), a cross-tenant F9 konvencióval azonosan.
     */
    @Query("SELECT t FROM Transaction t " +
           "JOIN FETCH t.branch " +
           "JOIN FETCH t.company " +
           "LEFT JOIN FETCH t.currency " +
           "LEFT JOIN FETCH t.worker " +
           "LEFT JOIN FETCH t.originalTransaction " +
           "WHERE t.receiptNumber = :receiptNumber AND t.company.id = :companyId " +
           "AND t.branch.id = :branchId")
    Optional<Transaction> findByReceiptNumberAndCompanyIdAndBranchId(
        @Param("receiptNumber") String receiptNumber,
        @Param("companyId") UUID companyId,
        @Param("branchId") UUID branchId);

    /**
     * Napi tranzakciók egy fiókhoz (JOIN FETCH a lazy proxy hiba elkerüléséhez).
     *
     * <p>MEGJEGYZES: a branch.id uniq garantalva van, es branch->company FK biztositja az
     * implicit tenant-elvalasztast, ezert nincs explicit companyId szures.</p>
     */
    @Query("SELECT t FROM Transaction t " +
           "JOIN FETCH t.branch " +
           "JOIN FETCH t.company " +
           "LEFT JOIN FETCH t.currency " +
           "LEFT JOIN FETCH t.worker " +
           "LEFT JOIN FETCH t.originalTransaction " +
           "WHERE t.branch.id = :branchId " +
           "AND t.transactionDate = :date " +
           "ORDER BY t.transactionTime DESC")
    List<Transaction> findByBranchAndDate(
        @Param("branchId") UUID branchId,
        @Param("date") LocalDate date
    );

    /**
     * Napi tranzakciók egy fiókhoz CEG-en BELUL (explicit multi-tenant szures).
     * Akkor hasznald, amikor a branchId a felhasznalotol jon (IDOR veszely).
     */
    @Query("SELECT t FROM Transaction t " +
           "JOIN FETCH t.branch " +
           "JOIN FETCH t.company " +
           "LEFT JOIN FETCH t.currency " +
           "LEFT JOIN FETCH t.worker " +
           "LEFT JOIN FETCH t.originalTransaction " +
           "WHERE t.company.id = :companyId " +
           "AND t.branch.id = :branchId " +
           "AND t.transactionDate = :date " +
           "ORDER BY t.transactionTime DESC")
    List<Transaction> findByCompanyIdAndBranchAndDate(
        @Param("companyId") UUID companyId,
        @Param("branchId") UUID branchId,
        @Param("date") LocalDate date
    );

    /**
     * Tranzakciók pénztároshoz.
     *
     * 2026-04-29 v2.3.28 (B17 multi-tenancy extend — defenzív hardening):
     * Bevezetjük a `companyId` szűrőt is, hogy a worker.id elméleti collision
     * (cross-company workerId) NE okozzon adatszivárgást. A worker.id BIGINT
     * sequence egyedi a system-en, de defenzív Spring Security best-practice
     * szerint a multi-tenant szűrőt minden lekérdezés-réteg-en alkalmazni kell.
     */
    @Query("SELECT t FROM Transaction t " +
           "WHERE t.company.id = :companyId " +
           "AND t.worker.id = :workerId " +
           "AND t.transactionDate = :date " +
           "ORDER BY t.transactionTime DESC")
    List<Transaction> findByWorkerAndDate(
        @Param("companyId") UUID companyId,
        @Param("workerId") Long workerId,
        @Param("date") LocalDate date
    );

    /**
     * H-7: Pénztáros tranzakciói egy időszakban (N+1 kiváltása)
     */
    @Query("SELECT t FROM Transaction t " +
           "JOIN FETCH t.currency " +
           "WHERE t.company.id = :companyId " +
           "AND t.worker.id = :workerId " +
           "AND t.transactionDate BETWEEN :startDate AND :endDate " +
           "ORDER BY t.transactionDate, t.transactionTime")
    List<Transaction> findByCompanyIdAndWorkerIdAndTransactionDateBetween(
        @Param("companyId") UUID companyId,
        @Param("workerId") Long workerId,
        @Param("startDate") LocalDate startDate,
        @Param("endDate") LocalDate endDate
    );

    /**
     * Tranzakciók típus szerint
     */
    @Query("SELECT t FROM Transaction t " +
           "WHERE t.company.id = :companyId " +
           "AND t.transactionType = :type " +
           "AND t.transactionDate BETWEEN :startDate AND :endDate")
    List<Transaction> findByTypeAndDateRange(
        @Param("companyId") UUID companyId,
        @Param("type") TransactionType type,
        @Param("startDate") LocalDate startDate,
        @Param("endDate") LocalDate endDate
    );

    /**
     * Napi sztornók száma — iroda szinten.
     *
     * 2026-04-29 v2.3.28 (B17 multi-tenancy extend — defenzív hardening):
     * `companyId` szűrő hozzáadva, hogy a branch.id elméleti collision (cross-company
     * branchId — bár UUID egyedi, defenzív szempontból is) NE okozzon szivárgást.
     */
    @Query("SELECT COUNT(t) FROM Transaction t " +
           "WHERE t.company.id = :companyId " +
           "AND t.branch.id = :branchId " +
           "AND t.transactionDate = :date " +
           "AND t.transactionType = 'REVERSAL'")
    long countReversalsByBranchAndDate(
        @Param("companyId") UUID companyId,
        @Param("branchId") UUID branchId,
        @Param("date") LocalDate date
    );

    /**
     * Napi sztornók száma — pénztáros (cashier/worker) szinten.
     * Legacy: a sztornó limit irodánként ÉS pénztárosonként is érvényes.
     *
     * 2026-04-29 v2.3.30 (Sourcery PR #293 consistency align):
     * `companyId` param hozzáadva — consistent multi-tenant query API
     * (countReversalsByBranchAndDate-vel azonos pattern).
     */
    @Query("SELECT COUNT(t) FROM Transaction t " +
           "WHERE t.company.id = :companyId " +
           "AND t.branch.id = :branchId " +
           "AND t.transactionDate = :date " +
           "AND t.worker.id = :workerId " +
           "AND t.transactionType = 'REVERSAL'")
    long countReversalsByBranchAndWorkerAndDate(
        @Param("companyId") UUID companyId,
        @Param("branchId") UUID branchId,
        @Param("workerId") Long workerId,
        @Param("date") LocalDate date
    );

    /**
     * Napi forgalom összeg
     */
    @Query("SELECT COALESCE(SUM(t.hufAmount), 0) FROM Transaction t " +
           "WHERE t.company.id = :companyId " +
           "AND t.branch.id = :branchId " +
           "AND t.transactionDate = :date " +
           "AND t.transactionType = :type " +
           "AND t.status = 'COMPLETED'")
    BigDecimal sumDailyTurnover(
        @Param("companyId") UUID companyId,
        @Param("branchId") UUID branchId,
        @Param("date") LocalDate date,
        @Param("type") TransactionType type
    );

    /**
     * FK-075 FR-5/FR-6 (2026-08-06): élő „Mai statisztika" — a mai napra és az aktuális
     * fiókra szűrt, COMPLETED státuszú tranzakciók darabszáma a megadott típus-halmazra.
     *
     * <p>Tenant-szűrés: azonos a {@link #sumDailyTurnover} mintájával (companyId + branchId
     * + transactionDate). Csak COMPLETED tranzakciók számítanak — a sztornózott (REVERSED)
     * tételek így NEM növelik az élő statisztikát (eltérés a tárolt DailySession-számlálóktól,
     * lásd a service-oldali dokumentációt).</p>
     */
    @Query("SELECT COUNT(t) FROM Transaction t " +
           "WHERE t.company.id = :companyId " +
           "AND t.branch.id = :branchId " +
           "AND t.transactionDate = :date " +
           "AND t.transactionType IN :types " +
           "AND t.status = 'COMPLETED'")
    long countCompletedByBranchAndDateAndTypes(
        @Param("companyId") UUID companyId,
        @Param("branchId") UUID branchId,
        @Param("date") LocalDate date,
        @Param("types") java.util.Collection<TransactionType> types
    );

    /**
     * FK-075 FR-5/FR-6 (2026-08-06): élő „Mai statisztika" — HUF forgalom összegzése.
     *
     * <p>Header-szintű összegzés: a multi-line bizonylatok FEJ-sora (hufAmount = a bizonylat
     * TELJES HUF összege, {@code TransactionMultiLineService}) egyszer számít — tételsorokat
     * NEM adunk hozzá, így nincs dupla-számolás. (A Codex #903 multi-line caveat a
     * valutánkénti currencyAmount-összesítésekre vonatkozik, a HUF header-összegre nem.)</p>
     */
    @Query("SELECT COALESCE(SUM(t.hufAmount), 0) FROM Transaction t " +
           "WHERE t.company.id = :companyId " +
           "AND t.branch.id = :branchId " +
           "AND t.transactionDate = :date " +
           "AND t.transactionType IN :types " +
           "AND t.status = 'COMPLETED'")
    BigDecimal sumCompletedTurnoverByBranchAndDateAndTypes(
        @Param("companyId") UUID companyId,
        @Param("branchId") UUID branchId,
        @Param("date") LocalDate date,
        @Param("types") java.util.Collection<TransactionType> types
    );

    /**
     * FK-075 FR-5/FR-6 (2026-08-06): élő „Mai statisztika" — beszedett kezelési díj összegzése.
     * Header-szintű (multi-line fej sorában a teljes díj szerepel), csak COMPLETED tételek.
     */
    @Query("SELECT COALESCE(SUM(t.handlingFee), 0) FROM Transaction t " +
           "WHERE t.company.id = :companyId " +
           "AND t.branch.id = :branchId " +
           "AND t.transactionDate = :date " +
           "AND t.transactionType IN :types " +
           "AND t.status = 'COMPLETED'")
    BigDecimal sumCompletedHandlingFeeByBranchAndDateAndTypes(
        @Param("companyId") UUID companyId,
        @Param("branchId") UUID branchId,
        @Param("date") LocalDate date,
        @Param("types") java.util.Collection<TransactionType> types
    );

    // A korábbi header-alapú sumDailyTurnoverByCurrency / sumDailyTurnoverHufByCurrency query-k
    // ELTÁVOLÍTVA (Codex #903): multi-valutás (multiLine) bizonylatnál az első valutára számolták a
    // teljes összeget. Helyettük a sumDailySingleLineTurnover* (lent, multi-line kizárva) + a
    // TransactionLineRepository.sumDailyLineTurnover* (tétel-sor szintű) párost kell összegezni.

    /**
     * Napi forgalom (deviza-mennyiség) CSAK az EGY-SOROS (nem multi-line) tranzakciókból
     * (Codex #903 multi-line fix). A multi-line bizonylatoknál a {@code Transaction.currency}
     * az ELSŐ sor valutája és a {@code currencyAmount} csak az első soré, a többi valuta a
     * {@code TransactionLine}-ban él — ezért a multi-line tranzakciókat itt KIZÁRJUK, a
     * sor-szintű összegzés (TransactionLineRepository.sumDailyLineTurnoverByCurrency) adja hozzá.
     */
    @Query("SELECT COALESCE(SUM(t.currencyAmount), 0) FROM Transaction t " +
           "WHERE t.branch.id = :branchId AND t.transactionDate = :date " +
           "AND t.transactionType = :type AND t.currency.code = :currencyCode " +
           "AND t.status = 'COMPLETED' AND (t.multiLine IS NULL OR t.multiLine = false)")
    BigDecimal sumDailySingleLineTurnoverByCurrency(
        @Param("branchId") UUID branchId,
        @Param("date") LocalDate date,
        @Param("type") TransactionType type,
        @Param("currencyCode") String currencyCode
    );

    /** Napi forgalom FORINTOSÍTOTT összege CSAK az egy-soros tranzakciókból (Codex #903 multi-line fix). */
    @Query("SELECT COALESCE(SUM(t.hufAmount), 0) FROM Transaction t " +
           "WHERE t.branch.id = :branchId AND t.transactionDate = :date " +
           "AND t.transactionType = :type AND t.currency.code = :currencyCode " +
           "AND t.status = 'COMPLETED' AND (t.multiLine IS NULL OR t.multiLine = false)")
    BigDecimal sumDailySingleLineTurnoverHufByCurrency(
        @Param("branchId") UUID branchId,
        @Param("date") LocalDate date,
        @Param("type") TransactionType type,
        @Param("currencyCode") String currencyCode
    );

    /**
     * Következő bizonylat szám generálásához
     */
    @Query("SELECT MAX(t.receiptNumber) FROM Transaction t " +
           "WHERE t.branch.id = :branchId " +
           "AND t.transactionDate = :date " +
           "AND t.receiptNumber LIKE :prefix%")
    Optional<String> findMaxReceiptNumber(
        @Param("branchId") UUID branchId,
        @Param("date") LocalDate date,
        @Param("prefix") String prefix
    );

    /**
     * Tranzakciók lapozással (JOIN FETCH a lazy proxy hiba elkerüléséhez).
     *
     * 2026-04-29 v2.3.25 (B17 multi-tenant hardening):
     * KÖTELEZŐ `companyId` ÉS `branchId` szűrő — defenzív IDOR-megelőzés.
     * Korábbi `(:branchId IS NULL OR t.branch.id = :branchId)` ág eltávolítva,
     * mert ha bármely jövőbeli hívó `null`-t ad → cross-branch adatszivárgás.
     * A null-check most a hívó felelőssége (Spring Security: `@NonNull`).
     */
    @Query(value = "SELECT t FROM Transaction t " +
           "JOIN FETCH t.branch " +
           "JOIN FETCH t.company " +
           "LEFT JOIN FETCH t.currency " +
           "LEFT JOIN FETCH t.worker " +
           "LEFT JOIN FETCH t.originalTransaction " +
           "WHERE t.company.id = :companyId " +
           "AND t.branch.id = :branchId " +
           "AND (:startDate IS NULL OR t.transactionDate >= :startDate) " +
           "AND (:endDate IS NULL OR t.transactionDate <= :endDate) " +
           "AND (:type IS NULL OR t.transactionType = :type) " +
           // FR-PA-05: "csak ügyfeles" — szerver-oldali szűrés a HELYES lapozásért (a count-query is szűr).
           "AND (:customerOnly = false OR (t.customerName IS NOT NULL AND t.customerName <> '')) " +
           "ORDER BY t.transactionDate DESC, t.transactionTime DESC",
           countQuery = "SELECT COUNT(t) FROM Transaction t " +
           "WHERE t.company.id = :companyId " +
           "AND t.branch.id = :branchId " +
           "AND (:startDate IS NULL OR t.transactionDate >= :startDate) " +
           "AND (:endDate IS NULL OR t.transactionDate <= :endDate) " +
           "AND (:type IS NULL OR t.transactionType = :type) " +
           "AND (:customerOnly = false OR (t.customerName IS NOT NULL AND t.customerName <> ''))")
    Page<Transaction> findWithFilters(
        @Param("companyId") UUID companyId,
        @Param("branchId") UUID branchId,
        @Param("startDate") LocalDate startDate,
        @Param("endDate") LocalDate endDate,
        @Param("type") TransactionType type,
        @Param("customerOnly") boolean customerOnly,
        Pageable pageable
    );

    /**
     * 2026-04-29 v2.3.26 (Codex P1 PR #290 follow-up):
     * COMPANY-WIDE tranzakció-lekérdezés, branchId NÉLKÜL — csak a saját company-n belül.
     *
     * Use case: cég-szintű statisztikák (top customers, frequent customers, MNB
     * aggregate report). NEM keverendő össze a `findWithFilters` branch-scoped
     * query-vel, ami IDOR-érzékeny (B17 hardening).
     *
     * Security: a hívó controller-nek kell `@PreAuthorize`-szal védenie ezt a
     * metódust (csak MANAGER+ vagy ADMIN role használhatja, NEM CASHIER).
     */
    @Query(value = "SELECT t FROM Transaction t " +
           "JOIN FETCH t.branch " +
           "JOIN FETCH t.company " +
           "LEFT JOIN FETCH t.currency " +
           "LEFT JOIN FETCH t.worker " +
           "LEFT JOIN FETCH t.originalTransaction " +
           "WHERE t.company.id = :companyId " +
           "AND (:startDate IS NULL OR t.transactionDate >= :startDate) " +
           "AND (:endDate IS NULL OR t.transactionDate <= :endDate) " +
           "AND (:type IS NULL OR t.transactionType = :type) " +
           "ORDER BY t.transactionDate DESC, t.transactionTime DESC",
           countQuery = "SELECT COUNT(t) FROM Transaction t " +
           "WHERE t.company.id = :companyId " +
           "AND (:startDate IS NULL OR t.transactionDate >= :startDate) " +
           "AND (:endDate IS NULL OR t.transactionDate <= :endDate) " +
           "AND (:type IS NULL OR t.transactionType = :type)")
    Page<Transaction> findCompanyWideWithFilters(
        @Param("companyId") UUID companyId,
        @Param("startDate") LocalDate startDate,
        @Param("endDate") LocalDate endDate,
        @Param("type") TransactionType type,
        Pageable pageable
    );

    /**
     * FS-11 S1: cégszintű compliance tranzakció-kereső.
     * Company-scope KÖTELEZŐ és fix; branch OPCIONÁLIS szűrő. CSAK financialEffective=true
     * (a CONVERSION parent metadata-sor kimarad — nem duplázhat összeget).
     * Hívó: ComplianceTransactionSearchService (companyId a SecurityContextből).
     * currencyIds: SOHA nem üres lista — üres szűrőnél a service :currencyIdsEmpty=true-t
     * és List.of(-1L) sentinelt ad át (Hibernate üres-IN elkerülése).
     *
     * <p>FS11-DEF slice 1: {@code currencyIds} OR-relációval a {@code TransactionLine}-ra is
     * kiterjed (a fő-valuta VAGY bármely tétel-sor valutája illeszkedhet — multi-line
     * bizonylatnál a mellék-sor valutája is találjon). {@code beneficialOwnerName} EXISTS-alapú
     * részszöveg-szűrés a {@code transaction_beneficial_owner} altáblára (case-insensitive,
     * companyId-szűrt — cross-tenant tulajdonos-sor SOHA nem hozhat találatot).</p>
     * <p>FS11-DEF slice 4: {@code relatedCustomerIds} a service által előszámolt
     * min-count ügyfél-halmaz; SOHA nem üres lista. Inaktív szűrőnél
     * {@code relatedIdsEmpty=true} és sentinel lista kerül átadásra.</p>
     */
    @Query(value = "SELECT t FROM Transaction t " +
           "JOIN FETCH t.branch " +
           "JOIN FETCH t.company " +
           "LEFT JOIN FETCH t.currency " +
           "LEFT JOIN FETCH t.worker " +
           "LEFT JOIN FETCH t.originalTransaction " +
           "WHERE t.company.id = :companyId " +
           "AND t.financialEffective = true " +
           "AND (:branchId IS NULL OR t.branch.id = :branchId) " +
           "AND (:startDate IS NULL OR t.transactionDate >= :startDate) " +
           "AND (:endDate IS NULL OR t.transactionDate <= :endDate) " +
           "AND (:type IS NULL OR t.transactionType = :type) " +
           "AND (:minHufAmount IS NULL OR t.hufAmount >= :minHufAmount) " +
           "AND (:maxHufAmount IS NULL OR t.hufAmount <= :maxHufAmount) " +
           "AND (:currencyIdsEmpty = true OR t.currency.id IN :currencyIds " +
           "     OR EXISTS (SELECT 1 FROM TransactionLine tl " +
           "                WHERE tl.transaction = t AND tl.currency.id IN :currencyIds)) " +
           "AND (:paymentMethod IS NULL OR t.paymentMethod = :paymentMethod) " +
           "AND (:customRateOnly = false OR t.cashierCustomRate = true) " +
           "AND (:kkDiscountOnly = false OR t.discountTypeCode <> 0 " +
           "     OR (t.handlingFeeOverrideType IS NOT NULL " +
           "         AND t.handlingFeeOverrideType <> hu.puzzleir.valuta.entity.HandlingFeeOverrideType.NONE)) " +
           "AND (:onBehalfOfOtherOnly = false OR t.customerOnOwnBehalf = false) " +
           "AND (:pepOnly = false OR t.customerIsPep = true) " +
           "AND (:customerName IS NULL OR LOWER(t.customerName) LIKE LOWER(CONCAT('%', CAST(:customerName AS string), '%'))) " +
           "AND (:customerBirthDate IS NULL OR t.customerBirthDate = :customerBirthDate) " +
           "AND (:customerNationality IS NULL OR LOWER(t.customerNationality) LIKE LOWER(CONCAT('%', CAST(:customerNationality AS string), '%'))) " +
           "AND (:customerDocumentNumber IS NULL OR LOWER(t.customerDocumentNumber) LIKE LOWER(CONCAT('%', CAST(:customerDocumentNumber AS string), '%'))) " +
           "AND (:legalEntityOnly = false OR t.isLegalEntityCustomer = true) " +
           "AND (:legalEntityName IS NULL OR LOWER(t.legalEntityName) LIKE LOWER(CONCAT('%', CAST(:legalEntityName AS string), '%'))) " +
           "AND (:legalEntityTaxNumber IS NULL OR LOWER(t.legalEntityTaxNumber) LIKE LOWER(CONCAT('%', CAST(:legalEntityTaxNumber AS string), '%'))) " +
           "AND (:legalDeedNumber IS NULL OR LOWER(t.legalDeedNumber) LIKE LOWER(CONCAT('%', CAST(:legalDeedNumber AS string), '%'))) " +
           "AND (:legalEntitySeat IS NULL OR LOWER(t.legalEntitySeat) LIKE LOWER(CONCAT('%', CAST(:legalEntitySeat AS string), '%'))) " +
           "AND (:beneficialOwnerName IS NULL OR EXISTS (SELECT 1 FROM TransactionBeneficialOwner bo " +
           "     WHERE bo.transactionId = t.id AND bo.companyId = :companyId " +
           "     AND LOWER(bo.ownerName) LIKE LOWER(CONCAT('%', CAST(:beneficialOwnerName AS string), '%')))) " +
           "AND (:customerCountry IS NULL OR EXISTS (SELECT 1 FROM Customer c " +
           "     WHERE c.company.id = :companyId AND c.customerCode = t.customerId " +
           "     AND t.customerId <> '' " +
           "     AND LOWER(c.country) LIKE LOWER(CONCAT('%', CAST(:customerCountry AS string), '%')))) " +
           "AND (:customerBirthName IS NULL OR EXISTS (SELECT 1 FROM Customer c2 " +
           "     WHERE c2.company.id = :companyId AND c2.customerCode = t.customerId " +
           "     AND t.customerId <> '' " +
           "     AND LOWER(c2.birthName) LIKE LOWER(CONCAT('%', CAST(:customerBirthName AS string), '%')))) " +
           "AND (:relatedIdsEmpty = true OR t.customerId IN :relatedCustomerIds) " +
           "ORDER BY t.transactionDate DESC, t.transactionTime DESC",
           countQuery = "SELECT COUNT(t) FROM Transaction t " +
           "WHERE t.company.id = :companyId " +
           "AND t.financialEffective = true " +
           "AND (:branchId IS NULL OR t.branch.id = :branchId) " +
           "AND (:startDate IS NULL OR t.transactionDate >= :startDate) " +
           "AND (:endDate IS NULL OR t.transactionDate <= :endDate) " +
           "AND (:type IS NULL OR t.transactionType = :type) " +
           "AND (:minHufAmount IS NULL OR t.hufAmount >= :minHufAmount) " +
           "AND (:maxHufAmount IS NULL OR t.hufAmount <= :maxHufAmount) " +
           "AND (:currencyIdsEmpty = true OR t.currency.id IN :currencyIds " +
           "     OR EXISTS (SELECT 1 FROM TransactionLine tl " +
           "                WHERE tl.transaction = t AND tl.currency.id IN :currencyIds)) " +
           "AND (:paymentMethod IS NULL OR t.paymentMethod = :paymentMethod) " +
           "AND (:customRateOnly = false OR t.cashierCustomRate = true) " +
           "AND (:kkDiscountOnly = false OR t.discountTypeCode <> 0 " +
           "     OR (t.handlingFeeOverrideType IS NOT NULL " +
           "         AND t.handlingFeeOverrideType <> hu.puzzleir.valuta.entity.HandlingFeeOverrideType.NONE)) " +
           "AND (:onBehalfOfOtherOnly = false OR t.customerOnOwnBehalf = false) " +
           "AND (:pepOnly = false OR t.customerIsPep = true) " +
           "AND (:customerName IS NULL OR LOWER(t.customerName) LIKE LOWER(CONCAT('%', CAST(:customerName AS string), '%'))) " +
           "AND (:customerBirthDate IS NULL OR t.customerBirthDate = :customerBirthDate) " +
           "AND (:customerNationality IS NULL OR LOWER(t.customerNationality) LIKE LOWER(CONCAT('%', CAST(:customerNationality AS string), '%'))) " +
           "AND (:customerDocumentNumber IS NULL OR LOWER(t.customerDocumentNumber) LIKE LOWER(CONCAT('%', CAST(:customerDocumentNumber AS string), '%'))) " +
           "AND (:legalEntityOnly = false OR t.isLegalEntityCustomer = true) " +
           "AND (:legalEntityName IS NULL OR LOWER(t.legalEntityName) LIKE LOWER(CONCAT('%', CAST(:legalEntityName AS string), '%'))) " +
           "AND (:legalEntityTaxNumber IS NULL OR LOWER(t.legalEntityTaxNumber) LIKE LOWER(CONCAT('%', CAST(:legalEntityTaxNumber AS string), '%'))) " +
           "AND (:legalDeedNumber IS NULL OR LOWER(t.legalDeedNumber) LIKE LOWER(CONCAT('%', CAST(:legalDeedNumber AS string), '%'))) " +
           "AND (:legalEntitySeat IS NULL OR LOWER(t.legalEntitySeat) LIKE LOWER(CONCAT('%', CAST(:legalEntitySeat AS string), '%'))) " +
           "AND (:beneficialOwnerName IS NULL OR EXISTS (SELECT 1 FROM TransactionBeneficialOwner bo " +
           "     WHERE bo.transactionId = t.id AND bo.companyId = :companyId " +
           "     AND LOWER(bo.ownerName) LIKE LOWER(CONCAT('%', CAST(:beneficialOwnerName AS string), '%')))) " +
           "AND (:customerCountry IS NULL OR EXISTS (SELECT 1 FROM Customer c " +
           "     WHERE c.company.id = :companyId AND c.customerCode = t.customerId " +
           "     AND t.customerId <> '' " +
           "     AND LOWER(c.country) LIKE LOWER(CONCAT('%', CAST(:customerCountry AS string), '%')))) " +
           "AND (:customerBirthName IS NULL OR EXISTS (SELECT 1 FROM Customer c2 " +
           "     WHERE c2.company.id = :companyId AND c2.customerCode = t.customerId " +
           "     AND t.customerId <> '' " +
           "     AND LOWER(c2.birthName) LIKE LOWER(CONCAT('%', CAST(:customerBirthName AS string), '%')))) " +
           "AND (:relatedIdsEmpty = true OR t.customerId IN :relatedCustomerIds)")
    Page<Transaction> searchComplianceTransactions(
        @Param("companyId") UUID companyId,
        @Param("branchId") UUID branchId,
        @Param("startDate") LocalDate startDate,
        @Param("endDate") LocalDate endDate,
        @Param("type") TransactionType type,
        @Param("minHufAmount") BigDecimal minHufAmount,
        @Param("maxHufAmount") BigDecimal maxHufAmount,
        @Param("currencyIdsEmpty") boolean currencyIdsEmpty,
        @Param("currencyIds") List<Long> currencyIds,
        @Param("paymentMethod") hu.puzzleir.valuta.entity.PaymentMethod paymentMethod,
        @Param("customRateOnly") boolean customRateOnly,
        @Param("kkDiscountOnly") boolean kkDiscountOnly,
        @Param("onBehalfOfOtherOnly") boolean onBehalfOfOtherOnly,
        @Param("pepOnly") boolean pepOnly,
        @Param("customerName") String customerName,
        @Param("customerBirthDate") LocalDate customerBirthDate,
        @Param("customerNationality") String customerNationality,
        @Param("customerDocumentNumber") String customerDocumentNumber,
        @Param("legalEntityOnly") boolean legalEntityOnly,
        @Param("legalEntityName") String legalEntityName,
        @Param("legalEntityTaxNumber") String legalEntityTaxNumber,
        @Param("legalDeedNumber") String legalDeedNumber,
        @Param("legalEntitySeat") String legalEntitySeat,
        @Param("beneficialOwnerName") String beneficialOwnerName,
        @Param("customerCountry") String customerCountry,
        @Param("customerBirthName") String customerBirthName,
        @Param("relatedIdsEmpty") boolean relatedIdsEmpty,
        @Param("relatedCustomerIds") List<String> relatedCustomerIds,
        Pageable pageable
    );

    /**
     * Ügyfél tranzakciói
     */
    @Query("SELECT t FROM Transaction t " +
           "WHERE t.company.id = :companyId " +
           "AND t.customerId = :customerId " +
           "ORDER BY t.transactionDate DESC, t.transactionTime DESC")
    List<Transaction> findByCustomerId(
        @Param("companyId") UUID companyId,
        @Param("customerId") String customerId
    );

    /**
     * Batch: aktiv tranzakciok lekerese TOBB irodahoz egy napon.
     * N+1 query kivaltasa korzet szintu MNB aggregacional.
     *
     * <p>Codex P1 PR #362 follow-up: NEM szuri `financial_effective`-re — multi-callsite
     * query (continuity check + reporting). Reporting-celre lasd a scope-olt variansot.</p>
     */
    @Query("SELECT t FROM Transaction t " +
           "WHERE t.branch.id IN :branchIds " +
           "AND t.transactionDate = :date " +
           "AND t.status = 'COMPLETED' " +
           "ORDER BY t.branch.id ASC, t.transactionTime DESC")
    List<Transaction> findActiveByBranchIdsAndDate(
        @Param("branchIds") List<UUID> branchIds,
        @Param("date") LocalDate date
    );

    /**
     * Aktív (nem sztornózott) tranzakciók.
     *
     * <p>Codex P1 PR #362 follow-up (2026-05-03): NEM szuri `financial_effective`-re —
     * a query-t a `ReceiptSequenceService.checkReceiptContinuity()` is hasznalja a napi-zarasi
     * gap detection-hoz, amelynek a CONVERSION receipt-eket (K prefix) IS latnia kell.
     * Reporting-celre uj scope-olt query: {@link #findFinanciallyEffectiveByBranchAndDate}.</p>
     */
    @Query("SELECT t FROM Transaction t " +
           "WHERE t.branch.id = :branchId " +
           "AND t.transactionDate = :date " +
           "AND t.status = 'COMPLETED' " +
           "ORDER BY t.transactionTime DESC")
    List<Transaction> findActiveByBranchAndDate(
        @Param("branchId") UUID branchId,
        @Param("date") LocalDate date
    );

    /**
     * Aktív tranzakciók lekérése irodához, dátumtartományra.
     * NAV PTGSZLAH havi jelentéshez szükséges.
     *
     * <p>Codex P1 PR #362 follow-up: NEM szuri `financial_effective`-re — multi-callsite.</p>
     */
    @Query("SELECT t FROM Transaction t " +
           "WHERE t.branch.id = :branchId " +
           "AND t.transactionDate BETWEEN :dateFrom AND :dateTo " +
           "AND t.status = 'COMPLETED' " +
           "ORDER BY t.transactionDate ASC, t.transactionTime ASC")
    List<Transaction> findActiveByBranchAndDateRange(
        @Param("branchId") UUID branchId,
        @Param("dateFrom") LocalDate dateFrom,
        @Param("dateTo") LocalDate dateTo
    );

    // ============ AUDIT P0.8 + CODEX P1 PR #362 — SCOPE-OLT RIPORT VARIANSOK ============
    // Ezek a query-k EXPLICIT scope-oltak: `financial_effective = true` szuressel,
    // a parent CONVERSION sorok dupla-szamolas megelozesere riport-szervizekben.
    // Continuity-check / sync / dashboard query-k a fenti unfilttert hasznaljak.

    /** Riport scope: branch + date + financial_effective. */
    @Query("SELECT t FROM Transaction t " +
           "WHERE t.branch.id = :branchId " +
           "AND t.transactionDate = :date " +
           "AND t.status = 'COMPLETED' " +
           "AND t.financialEffective = true " +
           "ORDER BY t.transactionTime DESC")
    List<Transaction> findFinanciallyEffectiveByBranchAndDate(
        @Param("branchId") UUID branchId,
        @Param("date") LocalDate date
    );

    /** Riport scope: branch-IDs batch + financial_effective. */
    @Query("SELECT t FROM Transaction t " +
           "WHERE t.branch.id IN :branchIds " +
           "AND t.transactionDate = :date " +
           "AND t.status = 'COMPLETED' " +
           "AND t.financialEffective = true " +
           "ORDER BY t.branch.id ASC, t.transactionTime DESC")
    List<Transaction> findFinanciallyEffectiveByBranchIdsAndDate(
        @Param("branchIds") List<UUID> branchIds,
        @Param("date") LocalDate date
    );

    /** Riport scope: branch + date range + financial_effective. */
    @Query("SELECT t FROM Transaction t " +
           "WHERE t.branch.id = :branchId " +
           "AND t.transactionDate BETWEEN :dateFrom AND :dateTo " +
           "AND t.status = 'COMPLETED' " +
           "AND t.financialEffective = true " +
           "ORDER BY t.transactionDate ASC, t.transactionTime ASC")
    List<Transaction> findFinanciallyEffectiveByBranchAndDateRange(
        @Param("branchId") UUID branchId,
        @Param("dateFrom") LocalDate dateFrom,
        @Param("dateTo") LocalDate dateTo
    );

    /**
     * Napi tranzakció számláló típus szerint
     */
    @Query("SELECT COUNT(t) FROM Transaction t " +
           "WHERE t.branch.id = :branchId " +
           "AND t.transactionDate = :date " +
           "AND t.transactionType = :type " +
           "AND t.status = 'COMPLETED'")
    long countByBranchIdAndTransactionDateAndTransactionType(
        @Param("branchId") UUID branchId,
        @Param("date") LocalDate date,
        @Param("type") TransactionType type
    );

    // ============ AML QUERY-K ============

    /**
     * Ugyfel eves gongyolesi osszeg (AML).
     * Legacy: BIGCTRL.DLL — eves kumulativ osszeg
     *
     * <p>Audit P0.8 (V177, 2026-05-03): `financial_effective = TRUE` szuro hozzaadva,
     * hogy a parent CONVERSION sor NE duplazza a child convBuy + convSell osszeget.</p>
     */
    @Query("SELECT COALESCE(SUM(t.hufAmount), 0) FROM Transaction t " +
           "WHERE t.company.id = :companyId " +
           "AND t.customerId = :customerId " +
           "AND t.transactionDate BETWEEN :startDate AND :endDate " +
           "AND t.status = 'COMPLETED' " +
           "AND t.financialEffective = true")
    BigDecimal sumCustomerAnnualTotal(
        @Param("companyId") UUID companyId,
        @Param("customerId") String customerId,
        @Param("startDate") LocalDate startDate,
        @Param("endDate") LocalDate endDate
    );

    /**
     * Ugyfel napi osszeg (AML gyanusagi ellenorzes).
     *
     * <p>Audit P0.8 (V177, 2026-05-03): `financial_effective = TRUE` szuro a CONVERSION
     * dupla-szamolas megelozeseert.</p>
     */
    @Query("SELECT COALESCE(SUM(t.hufAmount), 0) FROM Transaction t " +
           "WHERE t.company.id = :companyId " +
           "AND t.customerId = :customerId " +
           "AND t.transactionDate = :date " +
           "AND t.status = 'COMPLETED' " +
           "AND t.financialEffective = true")
    BigDecimal sumCustomerDailyTotal(
        @Param("companyId") UUID companyId,
        @Param("customerId") String customerId,
        @Param("date") LocalDate date
    );

    // ============ AML LEGACY QUERY-K (BIGCTRL.DLL) ============

    /**
     * Heti göngyölés: ügyfél elmúlt 7 nap HUF összege.
     * Legacy: HETIOSSZ mező — _diff < 8 → _hasforint + _hetiforint
     */
    @Query("SELECT COALESCE(SUM(t.hufAmount), 0) FROM Transaction t " +
           "WHERE t.company.id = :companyId " +
           "AND t.customerId = :customerId " +
           "AND t.transactionDate >= :sinceDate " +
           "AND t.status = 'COMPLETED' " +
           "AND t.financialEffective = true")
    BigDecimal sumCustomerWeeklyTotal(
        @Param("companyId") UUID companyId,
        @Param("customerId") String customerId,
        @Param("sinceDate") LocalDate sinceDate
    );

    /**
     * Sprint 6.2 C2 audit: 8 napos gordulo limit felett levo ugyfelek.
     * Visszaadja a customerId-ket es a gongyolt osszeget az elmult 8 napra,
     * ahol a gongyolt osszeg >= thresholdHuf.
     *
     * Hasznalt: Compliance dashboard, Pmt. kotelezo audit.
     */
    @Query("SELECT t.customerId, COALESCE(SUM(t.hufAmount), 0) as total " +
           "FROM Transaction t " +
           "WHERE t.company.id = :companyId " +
           "AND t.customerId IS NOT NULL " +
           "AND t.customerId <> '' " +
           "AND t.transactionDate >= :sinceDate " +
           "AND t.status = 'COMPLETED' " +
           "AND t.financialEffective = true " +
           "GROUP BY t.customerId " +
           "HAVING COALESCE(SUM(t.hufAmount), 0) >= :thresholdHuf " +
           "ORDER BY total DESC")
    java.util.List<Object[]> findRollingWindowAuditCandidates(
        @Param("companyId") UUID companyId,
        @Param("sinceDate") LocalDate sinceDate,
        @Param("thresholdHuf") BigDecimal thresholdHuf
    );

    /**
     * FS-12: gyanús ügyfél aggregátumok — 3 minta (tranzakciószám / össz-érték /
     * váltópont-szám) OR-kapcsolattal, bekapcsolható feltételenként.
     * Halmaz-kontraktus a findRollingWindowAuditCandidates mintája szerint.
     */
    @Query("SELECT t.customerId, MAX(t.customerName), COUNT(t), " +
           "COALESCE(SUM(t.hufAmount), 0), COUNT(DISTINCT t.branch.id) " +
           "FROM Transaction t " +
           "WHERE t.company.id = :companyId " +
           "AND t.transactionDate BETWEEN :startDate AND :endDate " +
           "AND t.status = 'COMPLETED' " +
           "AND t.financialEffective = true " +
           "AND t.customerId IS NOT NULL " +
           "AND t.customerId <> '' " +
           "GROUP BY t.customerId " +
           "HAVING ((:byTransactionCount = true AND COUNT(t) >= :minTransactionCount) " +
           "     OR (:byTotalValue = true AND COALESCE(SUM(t.hufAmount), 0) >= :minTotalHuf) " +
           "     OR (:byBranchCount = true AND COUNT(DISTINCT t.branch.id) >= :minBranchCount)) " +
           "ORDER BY SUM(t.hufAmount) DESC")
    java.util.List<Object[]> findSuspiciousCustomerAggregates(
        @Param("companyId") UUID companyId,
        @Param("startDate") LocalDate startDate,
        @Param("endDate") LocalDate endDate,
        @Param("byTransactionCount") boolean byTransactionCount,
        @Param("minTransactionCount") long minTransactionCount,
        @Param("byTotalValue") boolean byTotalValue,
        @Param("minTotalHuf") BigDecimal minTotalHuf,
        @Param("byBranchCount") boolean byBranchCount,
        @Param("minBranchCount") long minBranchCount
    );

    /**
     * FS11-DEF-RELATED: azon ügyfelek (customerId) listája, akiknek az időszakban
     * legalább :minCount darab COMPLETED + financialEffective tranzakciójuk volt a cégnél.
     * Halmaz-kontraktus a findRollingWindowAuditCandidates mintája szerint; a compliance
     * kereső IN-szűrője fogyasztja (ComplianceTransactionSearchService). Null dátum = nyitott határ.
     */
    @Query("SELECT t.customerId FROM Transaction t " +
           "WHERE t.company.id = :companyId " +
           "AND t.customerId IS NOT NULL " +
           "AND t.customerId <> '' " +
           "AND (CAST(:startDate AS date) IS NULL OR t.transactionDate >= :startDate) " +
           "AND (CAST(:endDate AS date) IS NULL OR t.transactionDate <= :endDate) " +
           "AND t.status = 'COMPLETED' " +
           "AND t.financialEffective = true " +
           "GROUP BY t.customerId " +
           "HAVING COUNT(t) >= :minCount")
    List<String> findRelatedCustomerIdsWithMinTransactionCount(
        @Param("companyId") UUID companyId,
        @Param("startDate") LocalDate startDate,
        @Param("endDate") LocalDate endDate,
        @Param("minCount") long minCount
    );

    /**
     * Éves maximum tranzakció összeg.
     * Legacy: EVIMAX mező
     */
    @Query("SELECT COALESCE(MAX(t.hufAmount), 0) FROM Transaction t " +
           "WHERE t.company.id = :companyId " +
           "AND t.customerId = :customerId " +
           "AND t.transactionDate BETWEEN :yearStart AND :yearEnd " +
           "AND t.status = 'COMPLETED' " +
           "AND t.financialEffective = true")
    BigDecimal findCustomerYearlyMax(
        @Param("companyId") UUID companyId,
        @Param("customerId") String customerId,
        @Param("yearStart") LocalDate yearStart,
        @Param("yearEnd") LocalDate yearEnd
    );

    /**
     * Negyedéves tranzakciószám.
     * Legacy: BIGCTRL.DLL TranzTipus 4 — 4+ tranzakció a negyedévben
     */
    @Query("SELECT COUNT(t) FROM Transaction t " +
           "WHERE t.company.id = :companyId " +
           "AND t.customerId = :customerId " +
           "AND t.transactionDate BETWEEN :quarterStart AND :quarterEnd " +
           "AND t.status = 'COMPLETED' " +
           "AND t.financialEffective = true")
    long countCustomerQuarterlyTransactions(
        @Param("companyId") UUID companyId,
        @Param("customerId") String customerId,
        @Param("quarterStart") LocalDate quarterStart,
        @Param("quarterEnd") LocalDate quarterEnd
    );

    /**
     * Negyedéves HUF összeg.
     * Legacy: _negyedevFt >= 25.000.000
     */
    @Query("SELECT COALESCE(SUM(t.hufAmount), 0) FROM Transaction t " +
           "WHERE t.company.id = :companyId " +
           "AND t.customerId = :customerId " +
           "AND t.transactionDate BETWEEN :quarterStart AND :quarterEnd " +
           "AND t.status = 'COMPLETED' " +
           "AND t.financialEffective = true")
    BigDecimal sumCustomerQuarterlyTotal(
        @Param("companyId") UUID companyId,
        @Param("customerId") String customerId,
        @Param("quarterStart") LocalDate quarterStart,
        @Param("quarterEnd") LocalDate quarterEnd
    );

    /**
     * EDD V.2.7 a) (V309): adott napon >=küszöb egyedi tranzakciót adó (cég, ügyfél) párok.
     * Cross-company — a napi AmlEddService-scan security context nélkül fut, cégenként jelöl.
     */
    @Query("SELECT DISTINCT t.company.id, t.customerId FROM Transaction t " +
           "WHERE t.transactionDate = :day " +
           "AND t.hufAmount >= :threshold " +
           "AND t.customerId IS NOT NULL AND t.customerId <> '' " +
           "AND t.status = 'COMPLETED' " +
           "AND t.financialEffective = true")
    List<Object[]> findEddSingleTransactionTriggers(
        @Param("day") LocalDate day,
        @Param("threshold") BigDecimal threshold
    );

    /**
     * EDD V.2.7 b) (V309): a naptári hónapban (monthStart..day) >=küszöb kumulált
     * KÉSZPÉNZ-forgalmú (cég, ügyfél, összeg) hármasok — a szabály készpénzforgalomra
     * vonatkozik, a kártyás tranzakció nem számít bele. Cross-company, lásd fent.
     */
    @Query("SELECT t.company.id, t.customerId, SUM(t.hufAmount) FROM Transaction t " +
           "WHERE t.transactionDate BETWEEN :monthStart AND :day " +
           "AND t.customerId IS NOT NULL AND t.customerId <> '' " +
           "AND t.status = 'COMPLETED' " +
           "AND t.financialEffective = true " +
           "AND t.paymentMethod = hu.puzzleir.valuta.entity.PaymentMethod.CASH " +
           "GROUP BY t.company.id, t.customerId " +
           "HAVING SUM(t.hufAmount) >= :threshold")
    List<Object[]> findEddMonthlyCumulativeTriggers(
        @Param("monthStart") LocalDate monthStart,
        @Param("day") LocalDate day,
        @Param("threshold") BigDecimal threshold
    );

    /**
     * EDD V.2.7 g) (V311): a naptári hónap TELJES (nem készpénz-szűrt) forgalma >=küszöb —
     * a profil-kiugrás a teljes ügyfél-forgalomra értendő, szemben a b) készpénz-szabállyal
     * (Codex review). Cross-company scheduler-query, a service cégen belül jelöl.
     */
    @Query("SELECT t.company.id, t.customerId, SUM(t.hufAmount) FROM Transaction t " +
           "WHERE t.transactionDate BETWEEN :monthStart AND :day " +
           "AND t.customerId IS NOT NULL AND t.customerId <> '' " +
           "AND t.status = 'COMPLETED' " +
           "AND t.financialEffective = true " +
           "GROUP BY t.company.id, t.customerId " +
           "HAVING SUM(t.hufAmount) >= :threshold")
    List<Object[]> findEddMonthlyTurnoverTriggers(
        @Param("monthStart") LocalDate monthStart,
        @Param("day") LocalDate day,
        @Param("threshold") BigDecimal threshold
    );

    /**
     * EDD V.2.7 f) (V311): pass-through gyanú — az ablakon (72h) belül MINDKÉT irányban
     * (vétel ÉS eladás) >=küszöb forgalmú (cég, ügyfél, vétel-összeg, eladás-összeg)
     * négyesek. Cross-company scheduler-query, a service cégen belül jelöl.
     */
    @Query("SELECT t.company.id, t.customerId, " +
           "SUM(CASE WHEN t.transactionType = hu.puzzleir.valuta.entity.TransactionType.BUY THEN t.hufAmount ELSE 0 END), " +
           "SUM(CASE WHEN t.transactionType = hu.puzzleir.valuta.entity.TransactionType.SELL THEN t.hufAmount ELSE 0 END) " +
           "FROM Transaction t " +
           "WHERE t.transactionDate BETWEEN :windowStart AND :day " +
           "AND t.customerId IS NOT NULL AND t.customerId <> '' " +
           "AND t.status = 'COMPLETED' " +
           "AND t.financialEffective = true " +
           "AND t.transactionType IN (hu.puzzleir.valuta.entity.TransactionType.BUY, " +
           "                          hu.puzzleir.valuta.entity.TransactionType.SELL) " +
           "GROUP BY t.company.id, t.customerId " +
           "HAVING SUM(CASE WHEN t.transactionType = hu.puzzleir.valuta.entity.TransactionType.BUY THEN t.hufAmount ELSE 0 END) >= :threshold " +
           "AND SUM(CASE WHEN t.transactionType = hu.puzzleir.valuta.entity.TransactionType.SELL THEN t.hufAmount ELSE 0 END) >= :threshold")
    List<Object[]> findEddPassThroughTriggers(
        @Param("windowStart") LocalDate windowStart,
        @Param("day") LocalDate day,
        @Param("threshold") BigDecimal threshold
    );

    /**
     * EDD f) segéd (Codex review): volt-e az ügyfélnek BUY/SELL aktivitása az adott napon.
     * A pass-through trigger csak scan-napi aktivitással él — a csúszó 72h-ablak így nem
     * jelöli újra ugyanazt a párt aktivitás nélkül (hónap-határon sem).
     */
    @Query("SELECT COUNT(t) FROM Transaction t " +
           "WHERE t.company.id = :companyId AND t.customerId = :customerId " +
           "AND t.transactionDate = :day " +
           "AND t.status = 'COMPLETED' AND t.financialEffective = true " +
           "AND t.transactionType IN (hu.puzzleir.valuta.entity.TransactionType.BUY, " +
           "                          hu.puzzleir.valuta.entity.TransactionType.SELL)")
    long countEddDayActivity(
        @Param("companyId") UUID companyId,
        @Param("customerId") String customerId,
        @Param("day") LocalDate day
    );

    /**
     * Havi tranzakciók branch-hez (havi záráshoz).
     */
    @Query("SELECT t FROM Transaction t " +
           "WHERE t.branch.id = :branchId " +
           "AND t.transactionDate BETWEEN :monthStart AND :monthEnd " +
           "AND t.status = 'COMPLETED' " +
           "ORDER BY t.transactionDate, t.transactionTime")
    List<Transaction> findByBranchAndMonth(
        @Param("branchId") UUID branchId,
        @Param("monthStart") LocalDate monthStart,
        @Param("monthEnd") LocalDate monthEnd
    );

    /**
     * Havi összesítő: vétel HUF összeg branch-hez.
     */
    @Query("SELECT COALESCE(SUM(t.hufAmount), 0) FROM Transaction t " +
           "WHERE t.branch.id = :branchId " +
           "AND t.transactionDate BETWEEN :monthStart AND :monthEnd " +
           "AND t.transactionType IN ('BUY', 'WESTERN_UNION_RECEIVE', 'MONEYGRAM_RECEIVE') " +
           "AND t.status = 'COMPLETED'")
    BigDecimal sumMonthlyBuyHuf(
        @Param("branchId") UUID branchId,
        @Param("monthStart") LocalDate monthStart,
        @Param("monthEnd") LocalDate monthEnd
    );

    /**
     * Havi összesítő: eladás HUF összeg branch-hez.
     */
    @Query("SELECT COALESCE(SUM(t.hufAmount), 0) FROM Transaction t " +
           "WHERE t.branch.id = :branchId " +
           "AND t.transactionDate BETWEEN :monthStart AND :monthEnd " +
           "AND t.transactionType IN ('SELL', 'WESTERN_UNION_SEND', 'MONEYGRAM_SEND') " +
           "AND t.status = 'COMPLETED'")
    BigDecimal sumMonthlySellHuf(
        @Param("branchId") UUID branchId,
        @Param("monthStart") LocalDate monthStart,
        @Param("monthEnd") LocalDate monthEnd
    );

    /**
     * Havi kezelési díj összeg.
     */
    @Query("SELECT COALESCE(SUM(t.handlingFee), 0) FROM Transaction t " +
           "WHERE t.branch.id = :branchId " +
           "AND t.transactionDate BETWEEN :monthStart AND :monthEnd " +
           "AND t.status = 'COMPLETED'")
    BigDecimal sumMonthlyHandlingFees(
        @Param("branchId") UUID branchId,
        @Param("monthStart") LocalDate monthStart,
        @Param("monthEnd") LocalDate monthEnd
    );

    /**
     * Havi tranzakciószám.
     */
    @Query("SELECT COUNT(t) FROM Transaction t " +
           "WHERE t.branch.id = :branchId " +
           "AND t.transactionDate BETWEEN :monthStart AND :monthEnd " +
           "AND t.status = 'COMPLETED'")
    long countMonthlyTransactions(
        @Param("branchId") UUID branchId,
        @Param("monthStart") LocalDate monthStart,
        @Param("monthEnd") LocalDate monthEnd
    );

    // ============ HANDLING FEE QUERY-K (HIGH FIX #11, #12) ============

    /**
     * HIGH FIX #11: SHK (saját hatáskörű kedvezmény) napi felhasználás számlálása.
     * discountTypeCode=4 → SHK kedvezmény a legacy rendszerben.
     */
    @Query("SELECT COUNT(t) FROM Transaction t " +
           "WHERE t.branch.id = :branchId " +
           "AND t.transactionDate = :date " +
           "AND t.discountTypeCode = 4 " +
           "AND t.status = 'COMPLETED'")
    long countShkTransactionsToday(
        @Param("branchId") UUID branchId,
        @Param("date") LocalDate date
    );

    /**
     * HIGH FIX #12: Custom fee (egyedi kezdőjegy) napi felhasználás számlálása.
     * discountTypeCode=20 → egyedi kezdőjegy a legacy rendszerben.
     */
    @Query("SELECT COUNT(t) FROM Transaction t " +
           "WHERE t.branch.id = :branchId " +
           "AND t.transactionDate = :date " +
           "AND t.discountTypeCode = 20 " +
           "AND t.status = 'COMPLETED'")
    long countCustomFeeTransactionsToday(
        @Param("branchId") UUID branchId,
        @Param("date") LocalDate date
    );

    // ============ GAP 1: NAPI KEDVEZMÉNY LIMIT ============

    /**
     * Pénztáros napi kedvezményes tranzakcióinak száma.
     * Legacy: napi 5 db egyedi ráta kedvezmény limit pénztárosonként.
     */
    @Query("SELECT COUNT(t) FROM Transaction t " +
           "WHERE t.worker.id = :workerId " +
           "AND t.transactionDate = :date " +
           "AND t.discountPercent > 0 " +
           "AND t.status = 'COMPLETED'")
    long countDailyDiscountsByWorker(
        @Param("workerId") Long workerId,
        @Param("date") LocalDate date
    );

    /**
     * Penztaros napi egyedi arfolyam hasznalatok szama (penztarosi sav).
     */
    @Query("SELECT COUNT(t) FROM Transaction t " +
           "WHERE t.worker.id = :workerId " +
           "AND t.transactionDate = :date " +
           "AND t.cashierCustomRate = true " +
           "AND t.status = 'COMPLETED'")
    long countDailyCashierCustomRatesByWorker(
        @Param("workerId") Long workerId,
        @Param("date") LocalDate date
    );

    // ============ NAPZARAS QUERY-K ============

    /**
     * Napi kezelesi dij osszeg (napzaras ellenorzeshez).
     */
    @Query("SELECT COALESCE(SUM(t.handlingFee), 0) FROM Transaction t " +
           "WHERE t.branch.id = :branchId " +
           "AND t.transactionDate = :date " +
           "AND t.status = 'COMPLETED'")
    BigDecimal sumDailyHandlingFees(
        @Param("branchId") UUID branchId,
        @Param("date") LocalDate date
    );

    /**
     * Nem jelentett tranzakciok szama (NAV kontroll).
     */
    @Query("SELECT COUNT(t) FROM Transaction t " +
           "WHERE t.branch.id = :branchId " +
           "AND t.transactionDate = :date " +
           "AND t.status = 'COMPLETED' " +
           "AND t.printed = false")
    long countUnreportedTransactions(
        @Param("branchId") UUID branchId,
        @Param("date") LocalDate date
    );

    /**
     * WU tranzakciok MTCN szam nelkul.
     * CRITICAL FIX (Eszter review): LIKE parameterezve SQL injection ellen.
     */
    @Query("SELECT t FROM Transaction t " +
           "WHERE t.branch.id = :branchId " +
           "AND t.transactionDate = :date " +
           "AND t.mtcn IS NULL " +
           "AND t.referenceNumber LIKE :refPrefix")
    List<Transaction> findByBranchIdAndTransactionDateAndMtcnIsNull(
        @Param("branchId") UUID branchId,
        @Param("date") LocalDate date,
        @Param("refPrefix") String refPrefix
    );

    /**
     * FKH-028 kiegeszites (A resz): egy Transfer-bizonylathoz tartozo, MEG NEM sztornozott
     * EREDETI tranzakciok — irany-fuggetlenul.
     *
     * <p>A {@code stornoPending} ut (atvetel elotti Transfer-visszavonas) eddig NEM allitotta at
     * az eredeti tranzakcio statuszat, ezert a Tranzakciolistaban a visszavont tetel tovabbra is
     * "Feltoltve"-kent latszott, mikozben az Ertektari "Mozgasok" nezet mar helyesen mutatta a
     * visszavonast (FR-A1/FR-A2).</p>
     *
     * <p>SZANDEKOSAN nincs branch- es tipus-szures: a create iranyonkent MAST hoz letre
     * ({@code F} → TRANSFER_OUT a kuldonel, {@code U} → TRANSFER_IN a kuldonel,
     * {@code FF} → TRANSFER_OUT MINDKET fioknal), es mindegyik ugyanazt a
     * {@code referenceNumber}-t (= transfer szama) kapja. Egyetlen, ceg-scope-olt lekerdezes
     * igy mind a harom PENDING-kepes iranyt egysegesen lefedi.</p>
     *
     * <p>Ket biztonsagi szures:
     * <ul>
     *   <li>{@code company} — a {@code transfer_number} csak cegen belul egyedi (multi-tenant);</li>
     *   <li>{@code COMPLETED} — idempotencia: ismetelt hivas nem ir felul mar REVERSED sort.</li>
     * </ul>
     * A {@code -SZ} kompenzalo sor NEM talalat: az sajat, {@code "-SZ"} vegu
     * {@code referenceNumber}-t kap, az egyenloseg-feltetel kizarja.</p>
     */
    @Query("SELECT t FROM Transaction t " +
           "WHERE t.company.id = :companyId " +
           "AND t.referenceNumber = :referenceNumber " +
           "AND t.status = hu.puzzleir.valuta.entity.TransactionStatus.COMPLETED")
    List<Transaction> findCompletedByCompanyAndReferenceNumber(
        @Param("companyId") UUID companyId,
        @Param("referenceNumber") String referenceNumber
    );

    /**
     * Összes tranzakció egy irodához (készlet regeneráláshoz)
     */
    @Query("SELECT t FROM Transaction t WHERE t.branch.id = :branchId ORDER BY t.transactionDate")
    List<Transaction> findByBranchId(@Param("branchId") UUID branchId);

    // ============ BATCH 3: DEKÁD + TURNOVER + COMPETITION QUERY-K ============

    /**
     * Batch 3: HUF összeg branch + típus + időszak (DateTime) alapján.
     * Dekádjelentés és turnover szolgáltatáshoz.
     */
    @Query("SELECT COALESCE(SUM(t.hufAmount), 0) FROM Transaction t " +
           "WHERE t.branch.id = :branchId " +
           "AND CAST(t.transactionType AS string) = :txType " +
           "AND t.transactionDate BETWEEN :dateFrom AND :dateTo " +
           "AND t.status = 'COMPLETED'")
    BigDecimal sumHufAmountByBranchAndTypeAndPeriod(
        @Param("branchId") UUID branchId,
        @Param("txType") String txType,
        @Param("dateFrom") LocalDate dateFrom,
        @Param("dateTo") LocalDate dateTo
    );

    /**
     * Batch 3: Kezelési díj összeg branch + időszak (transactionDate).
     */
    @Query("SELECT COALESCE(SUM(t.handlingFee), 0) FROM Transaction t " +
           "WHERE t.branch.id = :branchId " +
           "AND t.transactionDate BETWEEN :dateFrom AND :dateTo " +
           "AND t.status = 'COMPLETED' " +
           "AND t.financialEffective = true")
    BigDecimal sumFeeByBranchAndPeriod(
        @Param("branchId") UUID branchId,
        @Param("dateFrom") LocalDate dateFrom,
        @Param("dateTo") LocalDate dateTo
    );

    /**
     * Batch 3: Tranzakció szám branch + időszak (transactionDate).
     */
    @Query("SELECT COUNT(t) FROM Transaction t " +
           "WHERE t.branch.id = :branchId " +
           "AND t.transactionDate BETWEEN :dateFrom AND :dateTo " +
           "AND t.status = 'COMPLETED' " +
           "AND t.financialEffective = true")
    long countByBranchAndPeriod(
        @Param("branchId") UUID branchId,
        @Param("dateFrom") LocalDate dateFrom,
        @Param("dateTo") LocalDate dateTo
    );

    /**
     * Batch 3: HUF összeg company + típus + időszak (DateTime).
     * Cégszintű turnover riporthoz.
     */
    @Query("SELECT COALESCE(SUM(t.hufAmount), 0) FROM Transaction t " +
           "WHERE t.company.id = :companyId " +
           "AND CAST(t.transactionType AS string) = :txType " +
           "AND t.createdAt BETWEEN :from AND :to " +
           "AND t.status = 'COMPLETED'")
    BigDecimal sumHufAmountByCompanyAndTypeAndPeriod(
        @Param("companyId") UUID companyId,
        @Param("txType") String txType,
        @Param("from") LocalDateTime from,
        @Param("to") LocalDateTime to
    );

    /**
     * Batch 3: Kezelési díj összeg company + időszak (DateTime).
     */
    @Query("SELECT COALESCE(SUM(t.handlingFee), 0) FROM Transaction t " +
           "WHERE t.company.id = :companyId " +
           "AND t.createdAt BETWEEN :from AND :to " +
           "AND t.status = 'COMPLETED'")
    BigDecimal sumFeeByCompanyAndPeriod(
        @Param("companyId") UUID companyId,
        @Param("from") LocalDateTime from,
        @Param("to") LocalDateTime to
    );

    /**
     * Batch 3: HUF összeg worker + időszak (Competition).
     */
    @Query("SELECT COALESCE(SUM(t.hufAmount), 0) FROM Transaction t " +
           "WHERE t.worker.id = :workerId " +
           "AND t.createdAt BETWEEN :from AND :to " +
           "AND t.status = 'COMPLETED'")
    BigDecimal sumHufAmountByWorkerAndPeriod(
        @Param("workerId") Long workerId,
        @Param("from") LocalDateTime from,
        @Param("to") LocalDateTime to
    );

    /**
     * Batch 3: Tranzakció szám worker + időszak (Competition).
     */
    @Query("SELECT COUNT(t) FROM Transaction t " +
           "WHERE t.worker.id = :workerId " +
           "AND t.createdAt BETWEEN :from AND :to " +
           "AND t.status = 'COMPLETED'")
    long countByWorkerAndPeriod(
        @Param("workerId") Long workerId,
        @Param("from") LocalDateTime from,
        @Param("to") LocalDateTime to
    );

    // ============ BATCH 7A: AML + NAV REPORT QUERY-K ============

    /**
     * Ügyfél elmúlt 30 nap tranzakcióinak összege.
     *
     * <p>Audit P0.8 follow-up (Copilot PR #360, 2026-05-03): `financial_effective = true`
     * szuro — `AmlService.getCustomerRiskProfile()` AML risk-szamitasahoz.</p>
     */
    @Query("SELECT COALESCE(SUM(t.hufAmount), 0) FROM Transaction t " +
           "WHERE t.company.id = :companyId " +
           "AND t.customerId = :customerId " +
           "AND t.transactionDate >= :sinceDate " +
           "AND t.status = 'COMPLETED' " +
           "AND t.financialEffective = true")
    BigDecimal sumCustomerTotalSince(
        @Param("companyId") UUID companyId,
        @Param("customerId") String customerId,
        @Param("sinceDate") LocalDate sinceDate
    );

    /**
     * Ügyfél elmúlt 30 nap tranzakciószáma.
     *
     * <p>Audit P0.8 follow-up (Copilot PR #360, 2026-05-03): `financial_effective = true`
     * szuro — AML risk-profile + structuring detektalas.</p>
     */
    @Query("SELECT COUNT(t) FROM Transaction t " +
           "WHERE t.company.id = :companyId " +
           "AND t.customerId = :customerId " +
           "AND t.transactionDate >= :sinceDate " +
           "AND t.status = 'COMPLETED' " +
           "AND t.financialEffective = true")
    long countCustomerTransactionsSince(
        @Param("companyId") UUID companyId,
        @Param("customerId") String customerId,
        @Param("sinceDate") LocalDate sinceDate
    );

    /**
     * Ügyfél napi tranzakciószáma (structuring detektálás).
     *
     * <p>Audit P0.8 follow-up (Copilot PR #360, 2026-05-03): `financial_effective = true`
     * szuro — structuring (smurfing) detection-hoz.</p>
     */
    @Query("SELECT COUNT(t) FROM Transaction t " +
           "WHERE t.company.id = :companyId " +
           "AND t.customerId = :customerId " +
           "AND t.transactionDate = :date " +
           "AND t.status = 'COMPLETED' " +
           "AND t.financialEffective = true")
    long countCustomerDailyTransactions(
        @Param("companyId") UUID companyId,
        @Param("customerId") String customerId,
        @Param("date") LocalDate date
    );

    /**
     * Ügyfél napi tranzakcióinak listája (structuring detektálás).
     *
     * <p>Audit P0.8 follow-up (Copilot PR #360, 2026-05-03): `financial_effective = true`
     * szuro — structuring lookup, lista a parent CONVERSION nelkul.</p>
     */
    @Query("SELECT t FROM Transaction t " +
           "WHERE t.company.id = :companyId " +
           "AND t.customerId = :customerId " +
           "AND t.transactionDate = :date " +
           "AND t.status = 'COMPLETED' " +
           "AND t.financialEffective = true " +
           "ORDER BY t.transactionTime")
    List<Transaction> findCustomerDailyTransactions(
        @Param("companyId") UUID companyId,
        @Param("customerId") String customerId,
        @Param("date") LocalDate date
    );

    /**
     * NAV adatszolgáltatás: 2M+ Ft tranzakciók adott napon, company szinten.
     *
     * <p>Audit P0.8 follow-up (Copilot PR #360, 2026-05-03): `financial_effective = true`
     * szuro — NAV reportable list NEM tartalmazza a parent CONVERSION soreket.</p>
     */
    @Query("SELECT t FROM Transaction t " +
           "WHERE t.company.id = :companyId " +
           "AND t.transactionDate = :date " +
           "AND t.hufAmount >= :threshold " +
           "AND t.status = 'COMPLETED' " +
           "AND t.financialEffective = true " +
           "ORDER BY t.hufAmount DESC")
    List<Transaction> findReportableTransactions(
        @Param("companyId") UUID companyId,
        @Param("date") LocalDate date,
        @Param("threshold") BigDecimal threshold
    );

    /**
     * MNB riport: aktív tranzakciók company + dátum alapján (branch-független).
     *
     * <p>Audit P0.8 follow-up (Copilot PR #360, 2026-05-03): `financial_effective = true`
     * szuro — daily-MNB report nem inflalt.</p>
     */
    @Query("SELECT t FROM Transaction t " +
           "WHERE t.company.id = :companyId " +
           "AND t.transactionDate = :date " +
           "AND t.status = 'COMPLETED' " +
           "AND t.financialEffective = true " +
           "ORDER BY t.transactionTime")
    List<Transaction> findActiveByCompanyAndDate(
        @Param("companyId") UUID companyId,
        @Param("date") LocalDate date
    );

    /**
     * MNB riport: aktív tranzakciók company + hónap alapján.
     *
     * <p>Audit P0.8 follow-up (Copilot PR #360, 2026-05-03): `financial_effective = true`
     * szuro — monthly-MNB report nem inflalt.</p>
     */
    @Query("SELECT t FROM Transaction t " +
           "WHERE t.company.id = :companyId " +
           "AND t.transactionDate BETWEEN :monthStart AND :monthEnd " +
           "AND t.status = 'COMPLETED' " +
           "AND t.financialEffective = true " +
           "ORDER BY t.transactionDate, t.transactionTime")
    List<Transaction> findActiveByCompanyAndMonth(
        @Param("companyId") UUID companyId,
        @Param("monthStart") LocalDate monthStart,
        @Param("monthEnd") LocalDate monthEnd
    );

    // ============ ÉRTÉKTÁR MODUL — KONSZOLIDÁLT RIPORT QUERY-K ============

    /**
     * Tranzakciószám branch + típus + dátum intervallum.
     * Értéktár konszolidált riporthoz.
     */
    @Query("SELECT COUNT(t) FROM Transaction t " +
           "WHERE t.branch.id = :branchId " +
           "AND t.transactionType = :type " +
           "AND t.transactionDate BETWEEN :dateFrom AND :dateTo " +
           "AND t.status = 'COMPLETED'")
    int countByBranchIdAndTransactionTypeAndTransactionDateBetween(
        @Param("branchId") UUID branchId,
        @Param("type") TransactionType type,
        @Param("dateFrom") LocalDate dateFrom,
        @Param("dateTo") LocalDate dateTo
    );

    /**
     * HUF összeg branch + típus + dátum intervallum.
     * Értéktár konszolidált riporthoz.
     */
    @Query("SELECT COALESCE(SUM(t.hufAmount), 0) FROM Transaction t " +
           "WHERE t.branch.id = :branchId " +
           "AND t.transactionType = :type " +
           "AND t.transactionDate BETWEEN :dateFrom AND :dateTo " +
           "AND t.status = 'COMPLETED'")
    BigDecimal sumHufAmountByBranchIdAndTypeAndDateBetween(
        @Param("branchId") UUID branchId,
        @Param("type") TransactionType type,
        @Param("dateFrom") LocalDate dateFrom,
        @Param("dateTo") LocalDate dateTo
    );

    /**
     * Kezelési díj összeg branch + dátum intervallum.
     * Értéktár konszolidált riporthoz.
     */
    @Query("SELECT COALESCE(SUM(t.handlingFee), 0) FROM Transaction t " +
           "WHERE t.branch.id = :branchId " +
           "AND t.transactionDate BETWEEN :dateFrom AND :dateTo " +
           "AND t.status = 'COMPLETED'")
    BigDecimal sumFeesByBranchIdAndDateBetween(
        @Param("branchId") UUID branchId,
        @Param("dateFrom") LocalDate dateFrom,
        @Param("dateTo") LocalDate dateTo
    );

    // ============ REPORT OPTIMIZATION QUERY-K ============

    /**
     * P2-14: Kezelési díj összesítő GROUP BY lekérdezés (N+1 kiváltása).
     * Visszaad: [transactionDate, currencyCode, SUM(handlingFee), COUNT(id)]
     */
    @Query("SELECT t.transactionDate, t.currency.code, SUM(t.handlingFee), COUNT(t) " +
           "FROM Transaction t " +
           "WHERE t.branch.id = :branchId " +
           "AND t.transactionDate BETWEEN :startDate AND :endDate " +
           "AND t.status = 'COMPLETED' " +
           "AND t.handlingFee > 0 " +
           "GROUP BY t.transactionDate, t.currency.code " +
           "ORDER BY t.transactionDate ASC")
    List<Object[]> findHandlingFeeSummaryByBranchAndDateRange(
        @Param("branchId") UUID branchId,
        @Param("startDate") LocalDate startDate,
        @Param("endDate") LocalDate endDate
    );

    /**
     * FK-053: napi KÉSZPÉNZES kezelési díj vétel/eladás bontásban.
     * NULL payment_method = legacy CASH sor (FS-15 konvenció) — beszámít.
     * Visszaad: [transactionDate, b.bankCode, b.code, transactionType, SUM(handlingFee)]
     */
    @Query("SELECT t.transactionDate, b.bankCode, b.code, t.transactionType, SUM(t.handlingFee) " +
           "FROM Transaction t " +
           "JOIN t.branch b " +
           "WHERE b.id = :branchId " +
           "AND t.transactionDate BETWEEN :startDate AND :endDate " +
           "AND t.status = 'COMPLETED' " +
           "AND (t.paymentMethod = hu.puzzleir.valuta.entity.PaymentMethod.CASH " +
           "     OR t.paymentMethod IS NULL) " +
           "AND t.handlingFee > 0 " +
           "GROUP BY t.transactionDate, b.bankCode, b.code, t.transactionType " +
           "ORDER BY t.transactionDate ASC, b.code ASC, t.transactionType ASC")
    List<Object[]> findDailyCashHandlingFeeByType(
        @Param("branchId") UUID branchId,
        @Param("startDate") LocalDate startDate,
        @Param("endDate") LocalDate endDate
    );

    /**
     * FK-055: napi KÉSZPÉNZES kezelési díj vétel/eladás bontásban, CÉG-szinten —
     * minden aktív, NEM értéktári fiókra összesítve. NULL payment_method = legacy CASH
     * sor (FS-15 konvenció) — beszámít.
     * FK-056: a VAULT_COUNTERPARTY virtuális partner-fiókok kanonikus, null-safe
     * branchType-kizárása. Az isVault = false defense-in-depth marad, mert az
     * értéktár-kizárás külön dimenzió.
     * Visszaad: [transactionDate, b.bankCode, b.code, transactionType, SUM(handlingFee)]
     */
    @Query("SELECT t.transactionDate, b.bankCode, b.code, t.transactionType, SUM(t.handlingFee) " +
           "FROM Transaction t " +
           "JOIN t.branch b " +
           "LEFT JOIN b.branchType bt " +
           "WHERE b.company.id = :companyId " +
           "AND b.isActive = true " +
           "AND b.isVault = false " +
           "AND (bt IS NULL OR bt.code <> 'VAULT_COUNTERPARTY') " +
           "AND t.transactionDate BETWEEN :startDate AND :endDate " +
           "AND t.status = 'COMPLETED' " +
           "AND (t.paymentMethod = hu.puzzleir.valuta.entity.PaymentMethod.CASH " +
           "     OR t.paymentMethod IS NULL) " +
           "AND t.handlingFee > 0 " +
           "GROUP BY t.transactionDate, b.bankCode, b.code, t.transactionType " +
           "ORDER BY t.transactionDate ASC, b.code ASC, t.transactionType ASC")
    List<Object[]> findDailyCashHandlingFeeByTypeForCompany(
        @Param("companyId") UUID companyId,
        @Param("startDate") LocalDate startDate,
        @Param("endDate") LocalDate endDate
    );

    /**
     * FK-059: napi POS (bankkártyás) kezelési díj + nettó, egy fiókra.
     * CARD + SELL + COMPLETED only (FR-3: CARD+BUY kizárva — A1 anomália).
     * Nettó = hufAmount - handlingFee - roundingAmount (D2). Nincs fee>0 szűrés (D3).
     * Visszaad: [transactionDate, b.bankCode, b.code, SUM(net), SUM(fee)]
     */
    @Query("SELECT t.transactionDate, b.bankCode, b.code, " +
           "SUM(t.hufAmount - COALESCE(t.handlingFee, 0) - COALESCE(t.roundingAmount, 0)), " +
           "SUM(COALESCE(t.handlingFee, 0)) " +
           "FROM Transaction t " +
           "JOIN t.branch b " +
           "WHERE b.id = :branchId " +
           "AND t.transactionDate BETWEEN :startDate AND :endDate " +
           "AND t.status = 'COMPLETED' " +
           "AND t.transactionType = hu.puzzleir.valuta.entity.TransactionType.SELL " +
           "AND t.paymentMethod = hu.puzzleir.valuta.entity.PaymentMethod.CARD " +
           "GROUP BY t.transactionDate, b.bankCode, b.code " +
           "ORDER BY t.transactionDate ASC, b.code ASC")
    List<Object[]> findDailyPosHandlingFee(
        @Param("branchId") UUID branchId,
        @Param("startDate") LocalDate startDate,
        @Param("endDate") LocalDate endDate
    );

    /**
     * FK-059 (FR-4): cég-szintű "Minden iroda" POS napi összesítő — a FK-056 kanonikus,
     * null-safe VAULT_COUNTERPARTY-kizárással. NEM a sumCardSalesByCurrencyAndBranchAndDate
     * kiterjesztése (annak nincs kizárása).
     * Visszaad: [transactionDate, b.bankCode, b.code, SUM(net), SUM(fee)]
     */
    @Query("SELECT t.transactionDate, b.bankCode, b.code, " +
           "SUM(t.hufAmount - COALESCE(t.handlingFee, 0) - COALESCE(t.roundingAmount, 0)), " +
           "SUM(COALESCE(t.handlingFee, 0)) " +
           "FROM Transaction t " +
           "JOIN t.branch b " +
           "LEFT JOIN b.branchType bt " +
           "WHERE b.company.id = :companyId " +
           "AND b.isActive = true " +
           "AND b.isVault = false " +
           "AND (bt IS NULL OR bt.code <> 'VAULT_COUNTERPARTY') " +
           "AND t.transactionDate BETWEEN :startDate AND :endDate " +
           "AND t.status = 'COMPLETED' " +
           "AND t.transactionType = hu.puzzleir.valuta.entity.TransactionType.SELL " +
           "AND t.paymentMethod = hu.puzzleir.valuta.entity.PaymentMethod.CARD " +
           "GROUP BY t.transactionDate, b.bankCode, b.code " +
           "ORDER BY t.transactionDate ASC, b.code ASC")
    List<Object[]> findDailyPosHandlingFeeForCompany(
        @Param("companyId") UUID companyId,
        @Param("startDate") LocalDate startDate,
        @Param("endDate") LocalDate endDate
    );

    // ============ TURNOVER BREAKDOWN QUERY-K ============

    /**
     * Valuta + típus szerinti bontás — forgalom riporthoz.
     * Sztornózott (REVERSED, CANCELLED) tranzakciókat kizárja.
     * Visszaad: [currencyCode, transactionType, SUM(currencyAmount), SUM(hufAmount), SUM(handlingFee), COUNT(id)]
     *
     * <p>Audit P0.8 follow-up (Copilot PR #360, 2026-05-03): `financial_effective = true`
     * szuro — turnover breakdown a parent CONVERSION sort kihagyja, kovetkezetes
     * a top-level BUY/SELL totallal.</p>
     */
    @Query("SELECT t.currency.code, CAST(t.transactionType AS string), " +
           "SUM(t.currencyAmount), SUM(t.hufAmount), SUM(t.handlingFee), COUNT(t.id) " +
           "FROM Transaction t " +
           "WHERE t.branch.id = :branchId " +
           "AND t.transactionDate BETWEEN :dateFrom AND :dateTo " +
           "AND t.status NOT IN ('REVERSED', 'CANCELLED') " +
           "AND t.financialEffective = true " +
           "GROUP BY t.currency.code, t.transactionType " +
           "ORDER BY t.currency.code, t.transactionType")
    List<Object[]> groupByCurrencyAndTypeForBranch(
        @Param("branchId") UUID branchId,
        @Param("dateFrom") LocalDate dateFrom,
        @Param("dateTo") LocalDate dateTo
    );

    /**
     * FS-15: valuta + típus + fizetési mód bontás a Darius importfájlhoz.
     * NULL payment_method = legacy CASH sor — a hívó normalizálja.
     */
    @Query("SELECT t.currency.code, t.transactionType, t.paymentMethod, " +
           "SUM(t.currencyAmount), SUM(t.hufAmount), SUM(t.handlingFee) " +
           "FROM Transaction t " +
           "WHERE t.branch.id = :branchId " +
           "AND t.transactionDate BETWEEN :dateFrom AND :dateTo " +
           "AND t.status NOT IN ('REVERSED', 'CANCELLED') " +
           "AND t.financialEffective = true " +
           "GROUP BY t.currency.code, t.transactionType, t.paymentMethod " +
           "ORDER BY t.currency.code, t.transactionType")
    List<Object[]> groupByCurrencyTypeAndPaymentMethodForBranch(
        @Param("branchId") UUID branchId,
        @Param("dateFrom") LocalDate dateFrom,
        @Param("dateTo") LocalDate dateTo
    );

    /**
     * FK-045 FR-4/FR-9: valuta + típus szerinti bontás egy ÉRTÉKTÁRI TERÜLET (vault_territory)
     * összes pénztárára. A {@link #groupByCurrencyAndTypeForBranch} territory-szintű párja: a
     * branch.id helyett a branch.vaultTerritoryId == :territoryId AND branch.company.id == :companyId
     * szűr (multi-tenant: idegen cég területe nem ad sort). Sztornó (REVERSED/CANCELLED) + nem-
     * financialEffective kizárva, a top-level total-lal konzisztensen.
     * Visszaad: [currencyCode, transactionType, SUM(currencyAmount), SUM(hufAmount), SUM(handlingFee), COUNT(id)]
     */
    @Query("SELECT t.currency.code, CAST(t.transactionType AS string), " +
           "SUM(t.currencyAmount), SUM(t.hufAmount), SUM(t.handlingFee), COUNT(t.id) " +
           "FROM Transaction t " +
           "WHERE t.branch.vaultTerritoryId = :territoryId " +
           "AND t.branch.company.id = :companyId " +
           "AND t.transactionDate BETWEEN :dateFrom AND :dateTo " +
           "AND t.status NOT IN ('REVERSED', 'CANCELLED') " +
           "AND t.financialEffective = true " +
           "GROUP BY t.currency.code, t.transactionType " +
           "ORDER BY t.currency.code, t.transactionType")
    List<Object[]> groupByCurrencyAndTypeForTerritory(
        @Param("companyId") UUID companyId,
        @Param("territoryId") Integer territoryId,
        @Param("dateFrom") LocalDate dateFrom,
        @Param("dateTo") LocalDate dateTo
    );

    /**
     * FK-045 FR-4/FR-9: a területi fő-összegek (BUY/SELL HUF) — a sztornó-kizáró branch-verzió
     * territory-szintű párja. A territory + company szűr a multi-tenant izolációhoz.
     */
    @Query("SELECT COALESCE(SUM(t.hufAmount), 0) FROM Transaction t " +
           "WHERE t.branch.vaultTerritoryId = :territoryId " +
           "AND t.branch.company.id = :companyId " +
           "AND CAST(t.transactionType AS string) = :txType " +
           "AND t.transactionDate BETWEEN :dateFrom AND :dateTo " +
           "AND t.status NOT IN ('REVERSED', 'CANCELLED') " +
           "AND t.financialEffective = true")
    BigDecimal sumHufAmountByTerritoryAndTypeAndPeriod(
        @Param("companyId") UUID companyId,
        @Param("territoryId") Integer territoryId,
        @Param("txType") String txType,
        @Param("dateFrom") LocalDate dateFrom,
        @Param("dateTo") LocalDate dateTo
    );

    /**
     * FK-045 FR-4/FR-9: a területi díj-összeg — a sztornó-kizáró branch-verzió territory-párja.
     */
    @Query("SELECT COALESCE(SUM(t.handlingFee), 0) FROM Transaction t " +
           "WHERE t.branch.vaultTerritoryId = :territoryId " +
           "AND t.branch.company.id = :companyId " +
           "AND t.transactionDate BETWEEN :dateFrom AND :dateTo " +
           "AND t.status NOT IN ('REVERSED', 'CANCELLED') " +
           "AND t.financialEffective = true")
    BigDecimal sumFeeByTerritoryAndPeriod(
        @Param("companyId") UUID companyId,
        @Param("territoryId") Integer territoryId,
        @Param("dateFrom") LocalDate dateFrom,
        @Param("dateTo") LocalDate dateTo
    );

    /**
     * FK-045 FR-5/FR-7: valuta + típus szerinti bontás a TELJES CÉG-re (minden branch). A
     * {@link #groupByCurrencyAndTypeForBranch} cég-szintű párja — a „Teljes cég" nézet valutánkénti
     * sorai (és az official_rate megjelenítés) ehhez kellenek. Sztornó + nem-financialEffective kizárva.
     * Visszaad: [currencyCode, transactionType, SUM(currencyAmount), SUM(hufAmount), SUM(handlingFee), COUNT(id)]
     */
    @Query("SELECT t.currency.code, CAST(t.transactionType AS string), " +
           "SUM(t.currencyAmount), SUM(t.hufAmount), SUM(t.handlingFee), COUNT(t.id) " +
           "FROM Transaction t " +
           "WHERE t.company.id = :companyId " +
           "AND t.transactionDate BETWEEN :dateFrom AND :dateTo " +
           "AND t.status NOT IN ('REVERSED', 'CANCELLED') " +
           "AND t.financialEffective = true " +
           "GROUP BY t.currency.code, t.transactionType " +
           "ORDER BY t.currency.code, t.transactionType")
    List<Object[]> groupByCurrencyAndTypeForCompany(
        @Param("companyId") UUID companyId,
        @Param("dateFrom") LocalDate dateFrom,
        @Param("dateTo") LocalDate dateTo
    );

    /**
     * FK-045 FR-4/FR-9: tenant-guard — hány branch tartozik az adott területhez a hívó cégében.
     * 0 → a területi lekérdezés idegen tenant / nemlétező terület → a service 404-et dob.
     */
    @Query("SELECT COUNT(b) FROM Branch b " +
           "WHERE b.vaultTerritoryId = :territoryId AND b.company.id = :companyId")
    long countBranchesInTerritory(
        @Param("companyId") UUID companyId,
        @Param("territoryId") Integer territoryId
    );

    /**
     * Pénztáros szerinti bontás — forgalom riporthoz.
     * Sztornózott (REVERSED, CANCELLED) tranzakciókat kizárja.
     * Visszaad: [workerId, workerName, SUM(hufAmount), SUM(handlingFee), COUNT(id)]
     *
     * <p>Audit P0.8 follow-up (Copilot PR #360, 2026-05-03): `financial_effective = true`
     * szuro — TurnoverService.buildByWorker() cashier breakdown NEM tartalmazza
     * a parent CONVERSION sort, igy a tranzakcio-szam es HUF osszeg kovetkezetes
     * a top-level BUY/SELL totallal.</p>
     */
    @Query("SELECT t.worker.id, t.worker.name, " +
           "SUM(t.hufAmount), SUM(t.handlingFee), COUNT(t.id) " +
           "FROM Transaction t " +
           "WHERE t.branch.id = :branchId " +
           "AND t.transactionDate BETWEEN :dateFrom AND :dateTo " +
           "AND t.status NOT IN ('REVERSED', 'CANCELLED') " +
           "AND t.financialEffective = true " +
           "GROUP BY t.worker.id, t.worker.name " +
           "ORDER BY t.worker.name")
    List<Object[]> groupByWorkerForBranch(
        @Param("branchId") UUID branchId,
        @Param("dateFrom") LocalDate dateFrom,
        @Param("dateTo") LocalDate dateTo
    );

    /**
     * HUF összeg branch + típus + időszak, sztornókat kizárva.
     * Turnover riport főösszegekhez (REVERSED/CANCELLED nélkül).
     */
    @Query("SELECT COALESCE(SUM(t.hufAmount), 0) FROM Transaction t " +
           "WHERE t.branch.id = :branchId " +
           "AND CAST(t.transactionType AS string) = :txType " +
           "AND t.transactionDate BETWEEN :dateFrom AND :dateTo " +
           "AND t.status NOT IN ('REVERSED', 'CANCELLED')")
    BigDecimal sumHufAmountByBranchAndTypeAndPeriodExcludingReversals(
        @Param("branchId") UUID branchId,
        @Param("txType") String txType,
        @Param("dateFrom") LocalDate dateFrom,
        @Param("dateTo") LocalDate dateTo
    );

    /**
     * Kezelési díj összeg branch + időszak, sztornókat kizárva.
     * Turnover riport főösszegekhez (REVERSED/CANCELLED nélkül).
     */
    @Query("SELECT COALESCE(SUM(t.handlingFee), 0) FROM Transaction t " +
           "WHERE t.branch.id = :branchId " +
           "AND t.transactionDate BETWEEN :dateFrom AND :dateTo " +
           "AND t.status NOT IN ('REVERSED', 'CANCELLED')")
    BigDecimal sumFeeByBranchAndPeriodExcludingReversals(
        @Param("branchId") UUID branchId,
        @Param("dateFrom") LocalDate dateFrom,
        @Param("dateTo") LocalDate dateTo
    );

    /**
     * Napi zárás ellenőrzés: van-e PENDING státuszú tranzakció az adott irodában.
     */
    boolean existsByBranchIdAndStatus(UUID branchId, TransactionStatus status);

    /**
     * Ugyfel tranzakcioi okmany szam alapjan (multi-tenant).
     */
    @Query("SELECT t FROM Transaction t " +
           "WHERE t.company.id = :companyId " +
           "AND t.customerDocumentNumber = :docNumber " +
           "AND t.status = 'COMPLETED' " +
           "ORDER BY t.transactionDate DESC, t.transactionTime DESC")
    List<Transaction> findByCompanyIdAndCustomerDocumentNumber(
        @Param("companyId") UUID companyId,
        @Param("docNumber") String docNumber
    );

    /**
     * Ugyfel tranzakcioi okmany szam es datum alapjan (multi-tenant).
     */
    @Query("SELECT t FROM Transaction t " +
           "WHERE t.company.id = :companyId " +
           "AND t.customerDocumentNumber = :docNumber " +
           "AND t.status = 'COMPLETED' " +
           "AND (:dateFrom IS NULL OR t.transactionDate >= :dateFrom) " +
           "AND (:dateTo IS NULL OR t.transactionDate <= :dateTo) " +
           "ORDER BY t.transactionDate DESC, t.transactionTime DESC")
    List<Transaction> findByCompanyIdAndCustomerDocumentNumberAndDateRange(
        @Param("companyId") UUID companyId,
        @Param("docNumber") String docNumber,
        @Param("dateFrom") LocalDate dateFrom,
        @Param("dateTo") LocalDate dateTo
    );

    // ============ TRB EXPORT (legacy G4) ============

    /**
     * Összeg GROUP BY valutanem egy irodára, típusra, napra.
     * TRB ügyfélforgalom export — legacy unit5.pas UgyfPrepare.
     * Returns Object[]{currencyCode, sumAmount}
     */
    @Query("SELECT t.currency.code, COALESCE(SUM(t.currencyAmount), 0) FROM Transaction t " +
           "WHERE t.branch.id = :branchId " +
           "AND t.transactionType = :type " +
           "AND t.transactionDate = :date " +
           "AND t.status = 'COMPLETED' " +
           "GROUP BY t.currency.code " +
           "ORDER BY t.currency.code")
    List<Object[]> sumAmountByCurrencyAndBranchAndTypeAndDate(
        @Param("branchId") UUID branchId,
        @Param("type") TransactionType type,
        @Param("date") LocalDate date
    );

    /**
     * Bankkártyás eladások összege GROUP BY valutanem.
     * TRB export — legacy unit5.pas bankkartyás/készpénzes megkülönböztetés.
     * Returns Object[]{currencyCode, cardAmount, cardFee}
     */
    @Query("SELECT t.currency.code, COALESCE(SUM(t.hufAmount), 0), COALESCE(SUM(t.handlingFee), 0) FROM Transaction t " +
           "WHERE t.branch.id = :branchId " +
           "AND t.transactionType = 'SELL' " +
           "AND t.paymentMethod = hu.puzzleir.valuta.entity.PaymentMethod.CARD " +
           "AND t.transactionDate = :date " +
           "AND t.status = 'COMPLETED' " +
           "GROUP BY t.currency.code")
    List<Object[]> sumCardSalesByCurrencyAndBranchAndDate(
        @Param("branchId") UUID branchId,
        @Param("date") LocalDate date
    );

    // ============ SYNC RESTORE (szerver → pénztár visszaállítás) ============

    /**
     * Branch összes tranzakciója (darabszám).
     */
    long countByBranchId(UUID branchId);

    /**
     * Branch tranzakciói egy dátum után, dátum szerint rendezve.
     * Szerver → Pénztár restore endpoint.
     */
    List<Transaction> findByBranchIdAndTransactionDateAfterOrderByTransactionDateAsc(
        UUID branchId, LocalDate since
    );

    /**
     * Legrégebbi tranzakció dátuma egy branch-ben.
     */
    // ============ B2: CASHIER KPI DASHBOARD ============

    /**
     * B2: Penztaros KPI aggregalas ceg szinten, adott idoszakra.
     * GROUP BY worker, visszaad:
     *   [0] workerId (Long)
     *   [1] workerName (String)
     *   [2] txCount (long) - osszes tranzakcio (aktiv)
     *   [3] buyCount (long)
     *   [4] sellCount (long)
     *   [5] reversalCount (long) - REVERSAL tipusu tranzakciok szama
     *   [6] totalHuf (BigDecimal) - BUY+SELL osszeg
     *   [7] buyHuf (BigDecimal)
     *   [8] sellHuf (BigDecimal)
     *   [9] totalFees (BigDecimal)
     *   [10] customerCount (long) - egyedi ugyfel azonositok szama
     *
     * Csak COMPLETED tranzakciok. A REVERSED statusz sorok nem szamolodnak.
     */
    @Query("SELECT w.id, w.name, " +
           "COUNT(t), " +
           "SUM(CASE WHEN t.transactionType = hu.puzzleir.valuta.entity.TransactionType.BUY THEN 1 ELSE 0 END), " +
           "SUM(CASE WHEN t.transactionType = hu.puzzleir.valuta.entity.TransactionType.SELL THEN 1 ELSE 0 END), " +
           "SUM(CASE WHEN t.transactionType = hu.puzzleir.valuta.entity.TransactionType.REVERSAL THEN 1 ELSE 0 END), " +
           "COALESCE(SUM(CASE WHEN t.transactionType IN (hu.puzzleir.valuta.entity.TransactionType.BUY, hu.puzzleir.valuta.entity.TransactionType.SELL) THEN t.hufAmount ELSE 0 END), 0), " +
           "COALESCE(SUM(CASE WHEN t.transactionType = hu.puzzleir.valuta.entity.TransactionType.BUY THEN t.hufAmount ELSE 0 END), 0), " +
           "COALESCE(SUM(CASE WHEN t.transactionType = hu.puzzleir.valuta.entity.TransactionType.SELL THEN t.hufAmount ELSE 0 END), 0), " +
           "COALESCE(SUM(t.handlingFee), 0), " +
           "COUNT(DISTINCT t.customerId) " +
           "FROM Transaction t JOIN t.worker w " +
           "WHERE t.company.id = :companyId " +
           "AND t.transactionDate BETWEEN :dateFrom AND :dateTo " +
           "AND t.status = hu.puzzleir.valuta.entity.TransactionStatus.COMPLETED " +
           "GROUP BY w.id, w.name " +
           "ORDER BY w.name ASC")
    List<Object[]> cashierKpiByCompanyAndDateRange(
        @Param("companyId") UUID companyId,
        @Param("dateFrom") LocalDate dateFrom,
        @Param("dateTo") LocalDate dateTo
    );

    /**
     * B2: Ceges osszesito penztaros KPI-khez (felette a cards).
     * Visszaad: [txCount, buyCount, sellCount, reversalCount, totalHuf, totalFees, workerCount, customerCount]
     */
    @Query("SELECT " +
           "COUNT(t), " +
           "SUM(CASE WHEN t.transactionType = hu.puzzleir.valuta.entity.TransactionType.BUY THEN 1 ELSE 0 END), " +
           "SUM(CASE WHEN t.transactionType = hu.puzzleir.valuta.entity.TransactionType.SELL THEN 1 ELSE 0 END), " +
           "SUM(CASE WHEN t.transactionType = hu.puzzleir.valuta.entity.TransactionType.REVERSAL THEN 1 ELSE 0 END), " +
           "COALESCE(SUM(CASE WHEN t.transactionType IN (hu.puzzleir.valuta.entity.TransactionType.BUY, hu.puzzleir.valuta.entity.TransactionType.SELL) THEN t.hufAmount ELSE 0 END), 0), " +
           "COALESCE(SUM(t.handlingFee), 0), " +
           "COUNT(DISTINCT t.worker.id), " +
           "COUNT(DISTINCT t.customerId) " +
           "FROM Transaction t " +
           "WHERE t.company.id = :companyId " +
           "AND t.transactionDate BETWEEN :dateFrom AND :dateTo " +
           "AND t.status = hu.puzzleir.valuta.entity.TransactionStatus.COMPLETED")
    Object[] cashierKpiCompanyTotals(
        @Param("companyId") UUID companyId,
        @Param("dateFrom") LocalDate dateFrom,
        @Param("dateTo") LocalDate dateTo
    );

    @Query("SELECT MIN(t.transactionDate) FROM Transaction t WHERE t.branch.id = :branchId")
    LocalDate findEarliestDateByBranchId(@Param("branchId") UUID branchId);

    /**
     * Legújabb tranzakció dátuma egy branch-ben.
     */
    @Query("SELECT MAX(t.transactionDate) FROM Transaction t WHERE t.branch.id = :branchId")
    LocalDate findLatestDateByBranchId(@Param("branchId") UUID branchId);

    /**
     * v2.3.48 (B7 audit fix): Bizonylatok lista companyId-szintu listazasa.
     * Hasznalata: a /api/v1/receipts endpoint synthesize Receipt-shape DTO-kat
     * a Transaction tablabol, mert a Receipt tabla uresen marad (nincs explicit
     * Receipt insert a TransactionService.processBuy/Sell flow-ban).
     *
     * Limit (top 500 most recent) — a frontend ReceiptPage NEM paginal,
     * igy a teljes listaval terhelnenk a UI-t.
     */
    @Query("SELECT t FROM Transaction t " +
           "JOIN FETCH t.branch " +
           "JOIN FETCH t.company " +
           "LEFT JOIN FETCH t.currency " +
           "LEFT JOIN FETCH t.worker " +
           "WHERE t.company.id = :companyId " +
           "ORDER BY t.transactionDate DESC, t.transactionTime DESC")
    List<Transaction> findReceiptListByCompanyId(
        @Param("companyId") UUID companyId,
        Pageable pageable);

    /**
     * EXCMD b5b FR-BSZUR-02 (Codex P2): bizonylat-lista OPCIONÁLIS dátum-tartománnyal.
     *
     * <p>A {@link #findReceiptListByCompanyId} a top-500 LEGUTÓBBI tranzakcióra korlátoz,
     * ezért egy régi hónap/tartomány kliens-oldali szűrése csendben hiányos lehet (a 500-as
     * ablakon kívüli egyező bizonylatok kimaradnak). Ez a query a dátum-szűrést a DB-be tolja:
     * a limit így a KIVÁLASZTOTT időszakon belüli legutóbbi 500-ra vonatkozik (helyes).</p>
     *
     * <p>A {@code fromDate}/{@code toDate} külön-külön elhagyható (NULL = nyitott vég), így
     * a "csak hónap", "csak tól", "csak ig" és "egyéni tartomány" esetek egy query-vel lefedettek.
     * Mindkettő NULL → a {@link #findReceiptListByCompanyId}-vel azonos (szűretlen, top-500).</p>
     *
     * <p>EXCMD b5b FR-BSZUR-03 (Codex P2): az ügyfél-adatlap LIKE-szűrők (custName..custDocNumber)
     * IS a DB-ben futnak, NEM a kliensen a már 500-ra csonkolt listán — különben egy >500 receiptes
     * időszakban egy régi, egyező ügyfél-rekord csendben kimaradna. Minden custX külön-külön elhagyható
     * (NULL = nincs szűrés); a caller `%érték%` formában, kisbetűsítve adja át (a query LOWER-rel
     * hasonlít). A születési dátumot string-re CAST-oljuk a részleges (pl. "1985-03") egyezéshez.</p>
     */
    @Query("SELECT t FROM Transaction t " +
           "JOIN FETCH t.branch " +
           "JOIN FETCH t.company " +
           "LEFT JOIN FETCH t.currency " +
           "LEFT JOIN FETCH t.worker " +
           "WHERE t.company.id = :companyId " +
           "AND (:fromDate IS NULL OR t.transactionDate >= :fromDate) " +
           "AND (:toDate IS NULL OR t.transactionDate <= :toDate) " +
           "AND (:custName IS NULL OR LOWER(t.customerName) LIKE :custName) " +
           "AND (:custMotherName IS NULL OR LOWER(t.customerMotherName) LIKE :custMotherName) " +
           "AND (:custBirthPlace IS NULL OR LOWER(t.customerBirthPlace) LIKE :custBirthPlace) " +
           "AND (:custBirthDate IS NULL OR LOWER(CAST(t.customerBirthDate AS string)) LIKE :custBirthDate) " +
           "AND (:custNationality IS NULL OR LOWER(t.customerNationality) LIKE :custNationality) " +
           "AND (:custAddress IS NULL OR LOWER(t.customerAddress) LIKE :custAddress) " +
           "AND (:custDocType IS NULL OR LOWER(t.customerDocumentType) LIKE :custDocType) " +
           "AND (:custDocNumber IS NULL OR LOWER(t.customerDocumentNumber) LIKE :custDocNumber) " +
           "AND (:custActorName IS NULL OR LOWER(t.customerActorName) LIKE :custActorName) " +
           "ORDER BY t.transactionDate DESC, t.transactionTime DESC")
    List<Transaction> findReceiptListByCompanyIdAndDateRange(
        @Param("companyId") UUID companyId,
        @Param("fromDate") LocalDate fromDate,
        @Param("toDate") LocalDate toDate,
        @Param("custName") String custName,
        @Param("custMotherName") String custMotherName,
        @Param("custBirthPlace") String custBirthPlace,
        @Param("custBirthDate") String custBirthDate,
        @Param("custNationality") String custNationality,
        @Param("custAddress") String custAddress,
        @Param("custDocType") String custDocType,
        @Param("custDocNumber") String custDocNumber,
        @Param("custActorName") String custActorName,
        Pageable pageable);

    /**
     * G23 (EXCMD b8-forgalom FR-13..15): körzet-szintű havi forgalmi összesítő.
     *
     * <p>Régiónként (branch.regionCode) aggregálja a COMPLETED, pénzügyileg
     * effektív tranzakciókat egy dátum-tartományban: vétel-darab, eladás-darab,
     * vétel-HUF, eladás-HUF, egyedi ügyfelek száma, aktív (forgalmas) napok száma.
     * A NULL régiókódot a hívó "EGYÉB"-ként kezeli. Multi-tenant: company.id szűrt.</p>
     *
     * <p>Visszatérés: {@code Object[]} sorok — [0]=regionCode (String, lehet null),
     * [1]=buyCount (Long), [2]=sellCount (Long), [3]=buyHuf (BigDecimal),
     * [4]=sellHuf (BigDecimal), [5]=distinctCustomers (Long),
     * [6]=activeDays (Long).</p>
     */
    @Query("SELECT t.branch.regionCode, " +
           "SUM(CASE WHEN t.transactionType = hu.puzzleir.valuta.entity.TransactionType.BUY THEN 1L ELSE 0L END), " +
           "SUM(CASE WHEN t.transactionType = hu.puzzleir.valuta.entity.TransactionType.SELL THEN 1L ELSE 0L END), " +
           "COALESCE(SUM(CASE WHEN t.transactionType = hu.puzzleir.valuta.entity.TransactionType.BUY THEN t.hufAmount ELSE 0 END), 0), " +
           "COALESCE(SUM(CASE WHEN t.transactionType = hu.puzzleir.valuta.entity.TransactionType.SELL THEN t.hufAmount ELSE 0 END), 0), " +
           "COUNT(DISTINCT t.customerId), " +
           "COUNT(DISTINCT t.transactionDate) " +
           "FROM Transaction t " +
           "WHERE t.company.id = :companyId " +
           "AND t.status = hu.puzzleir.valuta.entity.TransactionStatus.COMPLETED " +
           "AND t.financialEffective = true " +
           "AND t.transactionDate BETWEEN :startDate AND :endDate " +
           "GROUP BY t.branch.regionCode")
    List<Object[]> aggregateRegionTurnover(
        @Param("companyId") UUID companyId,
        @Param("startDate") LocalDate startDate,
        @Param("endDate") LocalDate endDate);

    /**
     * FK-099 — tranzakciós illeték riport forrás-sorok, EGY query / kérés (NFR-4).
     *
     * <p>Univerzum (ticket §5, D5): COMPLETED, és
     * (önálló BUY/SELL: conversion_group_id IS NULL + financial_effective = true)
     * VAGY conversion_group_id IS NOT NULL. A második ág a konverzió-csoport
     * MINDHÁROM sorát (parent CONVERSION + convBuy + convSell) behúzza, hogy a
     * service a szülőre vagy a convBuy-ra támaszkodva fold-olhasson — a child
     * BUY/SELL a conversion_group_id miatt sosem kerül az önálló Vétel/Eladás
     * csoportokba (dupla-adóztatás elleni őrzés, FR-5/§5.6).</p>
     *
     * <p>A financial_effective predikátum CSAK az önálló ágon van: a parent
     * CONVERSION sor financial_effective = false, egy query-szintű szűrő
     * eldobná a konverzió alapját (D5, pitfall 2).</p>
     *
     * <p>Round-2 D19 (FR-16 csoport-szint): a status-predikátum NEM közös —
     * az önálló ágon sor-szintű (COMPLETED), a konverzió-ágon CSAK a childokra
     * vonatkozik: a parent CONVERSION sor BÁRMELY státusszal látszik
     * ({@code t.status = COMPLETED OR t.transactionType = CONVERSION}), hogy a
     * fold megkülönböztesse a sztornózott (nem-COMPLETED parent ⇒ a csoport
     * 0 illeték) és a ténylegesen hiányzó parent alakot. A vetület 10 oszlopos:
     * a status-oszlop (row[9]) viszi a parent státuszát a foldnak.</p>
     *
     * <p>Visszaad: [transactionDate, branchId, branchCode, branchName,
     * transactionType, hufAmount, conversionGroupId, financialEffective, customerId, status]</p>
     *
     * <p>FR-2 (FK-100) TBD: a típus-fehérlistából a WESTERN_UNION_* / MONEYGRAM_* /
     * VIGNETTE tranzakciók kizárása IMPLICIT — nem szerepelnek a BUY/SELL/CONVERSION
     * felsorolásban, külön explicit predikátum nincs rájuk. Az ÁFA-visszatérítés
     * kezelése nyitott könyvelői kérdés, nem külön explicit döntés eredménye.</p>
     *
     * <p>FK-100 FR-6: az opcionális {@code region} paraméter a szöveges
     * {@code branch.region} oszlopon szűr (dictionary REGION kód, pl. SZEGED),
     * a {@code :branchId} sorával azonos {@code IS NULL OR} idiómával. A numerikus
     * {@code region_code} (KESZLEX) NEM a szűrő kulcsa — pénztáraknál gyakran NULL.</p>
     */
    @Query("SELECT t.transactionDate, b.id, b.code, b.name, t.transactionType, t.hufAmount, " +
           "t.conversionGroupId, t.financialEffective, t.customerId, t.status " +
           "FROM Transaction t JOIN t.branch b " +
           "WHERE t.company.id = :companyId " +
           "AND t.transactionDate BETWEEN :from AND :to " +
           "AND (:branchId IS NULL OR b.id = :branchId) " +
           "AND (:region IS NULL OR b.region = :region) " +
           "AND ((t.transactionType IN (hu.puzzleir.valuta.entity.TransactionType.BUY, " +
           "                            hu.puzzleir.valuta.entity.TransactionType.SELL) " +
           "      AND t.conversionGroupId IS NULL " +
           "      AND t.financialEffective = true " +
           "      AND t.status = hu.puzzleir.valuta.entity.TransactionStatus.COMPLETED) " +
           "     OR (t.conversionGroupId IS NOT NULL " +
           "         AND (t.status = hu.puzzleir.valuta.entity.TransactionStatus.COMPLETED " +
           "              OR t.transactionType = hu.puzzleir.valuta.entity.TransactionType.CONVERSION))) " +
           "ORDER BY t.transactionDate ASC, b.code ASC")
    List<Object[]> findTransactionLevySourceRows(
            @Param("companyId") UUID companyId,
            @Param("branchId") UUID branchId,
            @Param("from") LocalDate from,
            @Param("to") LocalDate to,
            @Param("region") String region);

    /**
     * FK-100 FR-6 kompatibilitási túlterhelés: region-szűrő nélkül
     * ({@code region = null}) — a régi 4 argumentumú hívók viselkedése változatlan.
     */
    default List<Object[]> findTransactionLevySourceRows(
            UUID companyId, UUID branchId, LocalDate from, LocalDate to) {
        return findTransactionLevySourceRows(companyId, branchId, from, to, null);
    }
}
