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
import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface TransferRepository extends JpaRepository<Transfer, Long> {

    // TENANT-NOTE: szándékosan companyId-szűrés NÉLKÜL (lookup-query) — a hívó
    // KÖTELEZŐEN assertOwnCompany-t futtat (TransferService.getByTransferNumber).
    Optional<Transfer> findByTransferNumber(String transferNumber);

    /** Pessimistic lock a sztornóhoz: a konkurens dupla-sztornó (kétszeres készlet-visszafordítás) ellen. */
    // TENANT-NOTE: szándékosan companyId-szűrés NÉLKÜL (lock-query) — a hívó
    // KÖTELEZŐEN assertOwnCompany-t futtat (TransferService.storno).
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT t FROM Transfer t WHERE t.id = :id")
    Optional<Transfer> findByIdForUpdate(@Param("id") Long id);

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

    @Query("SELECT t FROM Transfer t WHERE t.fromBranch.company.id = :companyId " +
           "AND t.fromBranch.id = :branchId AND t.status IN ('PENDING', 'IN_TRANSIT')")
    List<Transfer> findOutgoingByBranch(@Param("companyId") UUID companyId,
                                        @Param("branchId") UUID branchId);

    @Query("SELECT t FROM Transfer t WHERE t.toBranch.company.id = :companyId " +
           "AND t.toBranch.id = :branchId AND t.status IN ('PENDING', 'IN_TRANSIT')")
    List<Transfer> findIncomingByBranch(@Param("companyId") UUID companyId,
                                        @Param("branchId") UUID branchId);

    @Query("SELECT t FROM Transfer t WHERE " +
           "(t.fromBranch.company.id = :companyId OR t.toBranch.company.id = :companyId) " +
           "AND (:branchId IS NULL OR t.fromBranch.id = :branchId OR t.toBranch.id = :branchId) " +
           "AND (:startDate IS NULL OR t.transferDate >= :startDate) " +
           "AND (:endDate IS NULL OR t.transferDate <= :endDate) " +
           "AND (:status IS NULL OR t.status = :status) " +
           "AND (:type IS NULL OR t.transferType = :type)")
    Page<Transfer> search(
            @Param("companyId") UUID companyId,
            @Param("branchId") UUID branchId,
            @Param("startDate") LocalDate startDate,
            @Param("endDate") LocalDate endDate,
            @Param("status") Transfer.TransferStatus status,
            @Param("type") Transfer.TransferType type,
            Pageable pageable);

    /**
     * Territory-scope-olt keresés (2026-07-15 security hardening): a meglévő {@link #search}
     * tenant-klauzulái + a tétel CSAK akkor látható, ha BÁRMELYIK vége (from VAGY to) a
     * hívó region-scope-jában van. Üres branchIds-szel TILOS hívni (a hívó fail-closed
     * üres oldalt ad vissza előtte).
     */
    @Query("SELECT t FROM Transfer t WHERE " +
           "(t.fromBranch.company.id = :companyId OR t.toBranch.company.id = :companyId) " +
           "AND (t.fromBranch.id IN :branchIds OR t.toBranch.id IN :branchIds) " +
           "AND (:branchId IS NULL OR t.fromBranch.id = :branchId OR t.toBranch.id = :branchId) " +
           "AND (:startDate IS NULL OR t.transferDate >= :startDate) " +
           "AND (:endDate IS NULL OR t.transferDate <= :endDate) " +
           "AND (:status IS NULL OR t.status = :status) " +
           "AND (:type IS NULL OR t.transferType = :type)")
    Page<Transfer> searchWithinBranches(
            @Param("companyId") UUID companyId,
            @Param("branchIds") Collection<UUID> branchIds,
            @Param("branchId") UUID branchId,
            @Param("startDate") LocalDate startDate,
            @Param("endDate") LocalDate endDate,
            @Param("status") Transfer.TransferStatus status,
            @Param("type") Transfer.TransferType type,
            Pageable pageable);

    @Query("SELECT COUNT(t) FROM Transfer t WHERE t.toBranch.company.id = :companyId " +
           "AND t.toBranch.id = :branchId AND t.status IN ('PENDING', 'IN_TRANSIT')")
    long countPendingByBranch(@Param("companyId") UUID companyId,
                              @Param("branchId") UUID branchId);

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
    // TENANT-NOTE: szándékosan companyId-szűrés NÉLKÜL (rendszer-szintű sorszám-query) —
    // a teljes prefix branch-kódolt, a hívó saját branch-ből képzi.
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

    // ===== FK-052: napi ellenőrző lista — BANK+/BANK− =====

    /**
     * FK-052 BANK+: az értéktár által a banktól átvett ({@code direction=U}) technikai RB
     * tételek napi összege valutánként. Multi-line transfernél kizárólag a sorok számítanak;
     * üres sorlista esetén a header currency/amount az igazság. Tenant-szűrés kizárólag a
     * fromBranch cégén fut, mert a transfer.company_id legacy-nullable.
     *
     * <p>Az eredmény sora: line-valutakód (nullable), header-valutakód, összeg. A két nyers
     * valutakód szerinti GROUP BY csoportokat a service olvasztja össze.
     */
    @Query("SELECT lc.code, tc.code, " +
           "SUM(CASE WHEN l.id IS NOT NULL THEN l.amount ELSE t.amount END) " +
           "FROM Transfer t " +
           "JOIN t.currency tc " +
           "LEFT JOIN t.lines l " +
           "LEFT JOIN l.currency lc " +
           "WHERE t.fromBranch.id = :branchId " +
           "AND t.fromBranch.company.id = :companyId " +
           "AND t.transferDate = :date " +
           "AND t.transferType IN (hu.puzzleir.valuta.entity.Transfer$TransferType.ERB, " +
           "hu.puzzleir.valuta.entity.Transfer$TransferType.FRB, " +
           "hu.puzzleir.valuta.entity.Transfer$TransferType.TRB, " +
           "hu.puzzleir.valuta.entity.Transfer$TransferType.PRB) " +
           "AND t.status = hu.puzzleir.valuta.entity.Transfer$TransferStatus.COMPLETED " +
           "AND t.isCancelled = false " +
           "AND t.direction = hu.puzzleir.valuta.entity.Transfer$TransferDirection.U " +
           "GROUP BY lc.code, tc.code")
    List<Object[]> sumBankInByDay(@Param("branchId") UUID branchId,
                                  @Param("companyId") UUID companyId,
                                  @Param("date") LocalDate date);

    /**
     * FK-052 BANK−: az értéktár bank felé átadott ({@code direction=F/UF/FF}) technikai
     * RB tételeinek napi összege. A multi-line, tenant-, státusz- és sztornószabályok a
     * BANK+ lekérdezéssel azonosak.
     */
    @Query("SELECT lc.code, tc.code, " +
           "SUM(CASE WHEN l.id IS NOT NULL THEN l.amount ELSE t.amount END) " +
           "FROM Transfer t " +
           "JOIN t.currency tc " +
           "LEFT JOIN t.lines l " +
           "LEFT JOIN l.currency lc " +
           "WHERE t.fromBranch.id = :branchId " +
           "AND t.fromBranch.company.id = :companyId " +
           "AND t.transferDate = :date " +
           "AND t.transferType IN (hu.puzzleir.valuta.entity.Transfer$TransferType.ERB, " +
           "hu.puzzleir.valuta.entity.Transfer$TransferType.FRB, " +
           "hu.puzzleir.valuta.entity.Transfer$TransferType.TRB, " +
           "hu.puzzleir.valuta.entity.Transfer$TransferType.PRB) " +
           "AND t.status = hu.puzzleir.valuta.entity.Transfer$TransferStatus.COMPLETED " +
           "AND t.isCancelled = false " +
           "AND t.direction IN (hu.puzzleir.valuta.entity.Transfer$TransferDirection.F, " +
           "hu.puzzleir.valuta.entity.Transfer$TransferDirection.UF, " +
           "hu.puzzleir.valuta.entity.Transfer$TransferDirection.FF) " +
           "GROUP BY lc.code, tc.code")
    List<Object[]> sumBankOutByDay(@Param("branchId") UUID branchId,
                                   @Param("companyId") UUID companyId,
                                   @Param("date") LocalDate date);

    /** Havi aggregalt bejovo transfer osszegek devizanementkent */
    @Query("SELECT t.currency.code, COALESCE(SUM(t.amount), 0) FROM Transfer t " +
           "WHERE t.toBranch.company.id = :companyId " +
           "AND t.toBranch.id = :branchId AND t.transferDate BETWEEN :startDate AND :endDate " +
           "AND t.status = 'COMPLETED' GROUP BY t.currency.code")
    List<Object[]> sumTransfersInByPeriod(@Param("companyId") UUID companyId,
                                          @Param("branchId") UUID branchId,
                                          @Param("startDate") LocalDate startDate,
                                          @Param("endDate") LocalDate endDate);

    /** Havi aggregalt kimeno transfer osszegek devizanementkent */
    @Query("SELECT t.currency.code, COALESCE(SUM(t.amount), 0) FROM Transfer t " +
           "WHERE t.fromBranch.company.id = :companyId " +
           "AND t.fromBranch.id = :branchId AND t.transferDate BETWEEN :startDate AND :endDate " +
           "AND t.status = 'COMPLETED' GROUP BY t.currency.code")
    List<Object[]> sumTransfersOutByPeriod(@Param("companyId") UUID companyId,
                                           @Param("branchId") UUID branchId,
                                           @Param("startDate") LocalDate startDate,
                                           @Param("endDate") LocalDate endDate);

    /**
     * FKH-022 FR-K6: a HUF naplókönyv transfer-oldali FF/UF tételei az adott napra.
     * Napi szűrés = {@code transferDate} (NEM a created_at dátumrésze — FR-K6/11: éjfél
     * után rögzített, előző napi transferDate-ű bizonylat az előző napi naplóba tartozik).
     * Irány: FF → fromBranch, UF → toBranch (a shipment-oldali daybook-lekérdezéssel
     * konzisztensen). Tenant-szűrés SZIGORÚAN t.companyId alapján (FR-K6/8) — a
     * legacy-nullable company_id-jű sorok fail-closed kimaradnak. A legacy '...-SZ'
     * sorszámú sorok (külön-rekordos sztornó-műtermékek) kizárva.
     * FR-K13 (Bugbot #1, PR #1518): az érvénytelenített bizonylat (PENDING-fázisú
     * cancel → CANCELLED, ill. REJECTED) nem valós pénzmozgás — kizárva, a
     * {@code findForReconciliation} precedense szerint. A sztornózott COMPLETED
     * bizonylat (is_cancelled=true) bent marad: azt az eredeti + sztornó sorpár
     * ellentételezi.
     *
     * <p><b>PENDING-sztornó bővítés:</b> az FR-K13 eredeti premisszája („CANCELLED = nem volt
     * pénzmozgás") KIZÁRÓLAG a régi, hibás {@code cancel()} útra volt igaz. A
     * {@code TransferService.stornoPending} úton a bizonylat a create-kor MÁR könyvelt, a
     * sztornó pedig visszafordította — két valós {@code cash_balance}-mozgás. Az ilyen tétel
     * ezért eredeti + sztornó sorpárként MEGJELENIK (nettó nulla), mint a COMPLETED-sztornó.
     * Megkülönböztető: {@code isCancelled = true AND cancellationReason IS NOT NULL} — a régi
     * {@code cancel()} soha nem állított indoklást, a {@code reject()} a {@code notes}-ba ír,
     * és a {@code cancellationReason}-t egyedül a storno-út tölti. Ugyanez a predikátum áll a
     * párjában ({@link #sumHufDaybookSignedHufBeforeDate}) — a kettőt CSAK EGYÜTT szabad
     * módosítani, különben a Nyitó egyenleg elcsúszik a napi soroktól.
     */
    @Query("""
            SELECT DISTINCT t FROM Transfer t
            JOIN FETCH t.fromBranch fb
            JOIN FETCH t.toBranch tb
            WHERE t.companyId = :companyId
              AND t.transferDate = :date
              AND ((t.transferNumber LIKE 'FF-%' AND fb.id = :branchId)
                OR (t.transferNumber LIKE 'UF-%' AND tb.id = :branchId))
              AND t.transferNumber NOT LIKE '%-SZ'
              AND (t.status NOT IN (hu.puzzleir.valuta.entity.Transfer$TransferStatus.CANCELLED,
                                    hu.puzzleir.valuta.entity.Transfer$TransferStatus.REJECTED)
                OR (t.isCancelled = true AND t.cancellationReason IS NOT NULL))
            ORDER BY t.createdAt ASC, t.transferNumber ASC
            """)
    List<Transfer> findHufDaybookTransfersForDate(@Param("companyId") UUID companyId,
                                                  @Param("branchId") UUID branchId,
                                                  @Param("date") LocalDate date);

    /**
     * FKH-030 FR-3/FR-6: Penzforgalom riport — transfer-tetelek DATUMTARTOMANYRA es
     * BRANCH-HALMAZRA (nem egy napra es egy fiokra, mint a naplokonyv).
     *
     * <p>Elteresek a {@link #findHufDaybookTransfersForDate}-tol, mind szandekos:
     * <ul>
     *   <li><b>Tartomany:</b> {@code transferDate BETWEEN :from AND :to} (FR-2).</li>
     *   <li><b>Branch-halmaz:</b> {@code IN :branchIds} — az Ertektaros teljes korzete
     *       (FR-9, {@code AccessScopeService.vaultRegionBranchScopeOrNull}).</li>
     *   <li><b>Prefix-kor:</b> a naplokonyv csak FF/UF-et nez; itt AT/AV IS bekerul
     *       (FR-6), mert a penzforgalom a penztarak fele iranyulo mozgast is tartalmazza.
     *       A KK (kezelesi dij) NEM transfer-prefix, igy FR-7 a Transfer-oldalon
     *       automatikusan teljesul.</li>
     * </ul>
     *
     * <p>VALTOZATLANUL atvett a naplokonyv-mintabol (FR-11, TBD-3): a {@code -SZ} sorok
     * kizarasa (azok kulon, szamitott sorkent jelennek meg) es az ervenytelenitett
     * bizonylatok kezelese — a CANCELLED/REJECTED tetel csak akkor latszik, ha valodi
     * storno-uton szunt meg ({@code isCancelled AND cancellationReason IS NOT NULL}),
     * mert olyankor ket valos kassza-mozgas tortent.</p>
     *
     * <p>Az irany (atadas/atvetel) meghatarozasa a SZOLGALTATAS dolga: ugyanaz a bizonylat
     * a kuldo fioknal atadas, a fogadonal atvetel — ezert itt MINDKET oldalt visszaadjuk,
     * ha barmelyik fiok a scope-ban van.</p>
     */
    @Query("""
            SELECT DISTINCT t FROM Transfer t
            JOIN FETCH t.fromBranch fb
            JOIN FETCH t.toBranch tb
            WHERE t.companyId = :companyId
              AND t.transferDate BETWEEN :from AND :to
              AND (fb.id IN :branchIds OR tb.id IN :branchIds)
              AND (t.transferNumber LIKE 'AT-%' OR t.transferNumber LIKE 'AV-%'
                OR t.transferNumber LIKE 'FF-%' OR t.transferNumber LIKE 'UF-%')
              AND t.transferNumber NOT LIKE '%-SZ'
              AND (t.status NOT IN (hu.puzzleir.valuta.entity.Transfer$TransferStatus.CANCELLED,
                                    hu.puzzleir.valuta.entity.Transfer$TransferStatus.REJECTED)
                OR (t.isCancelled = true AND t.cancellationReason IS NOT NULL))
            ORDER BY t.transferDate ASC, t.createdAt ASC, t.transferNumber ASC
            """)
    List<Transfer> findCashFlowReportTransfers(@Param("companyId") UUID companyId,
                                               @Param("branchIds") java.util.Collection<UUID> branchIds,
                                               @Param("from") LocalDate from,
                                               @Param("to") LocalDate to);

    /**
     * FKH-022 FR-K6/10: a naplókönyv transfer-oldali SZTORNÓ-sorai. A sztornó-ág
     * kizárólag {@code isCancelled = true} esetén él (a kitöltött cancelledAt önmagában
     * NEM sztornó); a nap-hozzárendelés a cancelledAt alapján történik.
     * FR-K13 (Bugbot #1): a CANCELLED/REJECTED státuszú (érvénytelenített) bizonylat
     * defenzíven a sztornó-ágból is kizárva — sztornó csak COMPLETED bizonylaton él.
     *
     * <p><b>PENDING-sztornó bővítés:</b> a {@code stornoPending} úton a bizonylat CANCELLED
     * státuszt kap, de VALÓS könyvelés-visszafordítás történt — ezért a sztornó-sora
     * megjelenik. Megkülönböztető: {@code cancellationReason IS NOT NULL} (a régi
     * {@code cancel()} indoklás nélkül hagyta). A pár ({@link #sumCancelledHufDaybookSignedHufBefore})
     * ugyanezt a predikátumot hordozza — CSAK EGYÜTT módosíthatók.
     */
    @Query("""
            SELECT DISTINCT t FROM Transfer t
            JOIN FETCH t.fromBranch fb
            JOIN FETCH t.toBranch tb
            WHERE t.companyId = :companyId
              AND t.isCancelled = true
              AND t.cancelledAt >= :from
              AND t.cancelledAt < :to
              AND ((t.transferNumber LIKE 'FF-%' AND fb.id = :branchId)
                OR (t.transferNumber LIKE 'UF-%' AND tb.id = :branchId))
              AND t.transferNumber NOT LIKE '%-SZ'
              AND (t.status NOT IN (hu.puzzleir.valuta.entity.Transfer$TransferStatus.CANCELLED,
                                    hu.puzzleir.valuta.entity.Transfer$TransferStatus.REJECTED)
                OR (t.isCancelled = true AND t.cancellationReason IS NOT NULL))
            ORDER BY t.cancelledAt ASC, t.transferNumber ASC
            """)
    List<Transfer> findCancelledHufDaybookTransfersForDate(@Param("companyId") UUID companyId,
                                                           @Param("branchId") UUID branchId,
                                                           @Param("from") java.time.LocalDateTime from,
                                                           @Param("to") java.time.LocalDateTime to);

    /**
     * FKH-022 FR-K5: a naplókönyv Nyitó egyenlegének transfer-oldali, ELŐJELES összege a
     * megadott nap ELŐTTI eredeti bizonylatokból (UF = átvétel +, FF = átadás −; összeg:
     * hufValue, fallback amount — a {@code HufDaybookService.transferHuf} logikával azonosan).
     * A szűrők a napi lista-lekérdezéssel ({@link #findHufDaybookTransfersForDate}) azonosak
     * (FR-K13: CANCELLED/REJECTED kizárva; '-SZ' műtermék kizárva), csak
     * {@code transferDate < :date} (implicit horgony).
     */
    @Query("""
            SELECT COALESCE(SUM(CASE WHEN t.transferNumber LIKE 'UF-%'
                                     THEN COALESCE(t.hufValue, t.amount)
                                     ELSE -COALESCE(t.hufValue, t.amount) END), 0)
            FROM Transfer t
            WHERE t.companyId = :companyId
              AND t.transferDate < :date
              AND ((t.transferNumber LIKE 'FF-%' AND t.fromBranch.id = :branchId)
                OR (t.transferNumber LIKE 'UF-%' AND t.toBranch.id = :branchId))
              AND t.transferNumber NOT LIKE '%-SZ'
              AND (t.status NOT IN (hu.puzzleir.valuta.entity.Transfer$TransferStatus.CANCELLED,
                                    hu.puzzleir.valuta.entity.Transfer$TransferStatus.REJECTED)
                OR (t.isCancelled = true AND t.cancellationReason IS NOT NULL))
            """)
    BigDecimal sumHufDaybookSignedHufBeforeDate(@Param("companyId") UUID companyId,
                                                @Param("branchId") UUID branchId,
                                                @Param("date") LocalDate date);

    /**
     * FKH-022 FR-K5: a nap ELŐTTI transfer-SZTORNÓ-események előjeles NETTÓ hatása — az
     * eredetivel ellentétes előjellel (UF-sztornó −, FF-sztornó +). Sztornó kizárólag
     * {@code isCancelled = true} esetén (FR-K6/10), nap-hozzárendelés a {@code cancelledAt}
     * szerint; FR-K13: CANCELLED/REJECTED státusz a sztornó-ágból is kizárva.
     */
    @Query("""
            SELECT COALESCE(SUM(CASE WHEN t.transferNumber LIKE 'UF-%'
                                     THEN -COALESCE(t.hufValue, t.amount)
                                     ELSE COALESCE(t.hufValue, t.amount) END), 0)
            FROM Transfer t
            WHERE t.companyId = :companyId
              AND t.isCancelled = true
              AND t.cancelledAt < :before
              AND ((t.transferNumber LIKE 'FF-%' AND t.fromBranch.id = :branchId)
                OR (t.transferNumber LIKE 'UF-%' AND t.toBranch.id = :branchId))
              AND t.transferNumber NOT LIKE '%-SZ'
              AND (t.status NOT IN (hu.puzzleir.valuta.entity.Transfer$TransferStatus.CANCELLED,
                                    hu.puzzleir.valuta.entity.Transfer$TransferStatus.REJECTED)
                OR (t.isCancelled = true AND t.cancellationReason IS NOT NULL))
            """)
    BigDecimal sumCancelledHufDaybookSignedHufBefore(@Param("companyId") UUID companyId,
                                                     @Param("branchId") UUID branchId,
                                                     @Param("before") java.time.LocalDateTime before);

    /** ReportService â€" kimenĹ' ĂˇtadĂˇsok */
    @Query("SELECT t FROM Transfer t WHERE t.fromBranch.company.id = :companyId " +
           "AND t.fromBranch.id = :branchId ORDER BY t.createdAt DESC")
    List<Transfer> findByFromBranchIdOrderByCreatedAtDesc(@Param("companyId") UUID companyId,
                                                          @Param("branchId") UUID branchId);

    /** ReportService â€" bejĂ¶vĹ' ĂˇtadĂˇsok */
    @Query("SELECT t FROM Transfer t WHERE t.toBranch.company.id = :companyId " +
           "AND t.toBranch.id = :branchId ORDER BY t.createdAt DESC")
    List<Transfer> findByToBranchIdOrderByCreatedAtDesc(@Param("companyId") UUID companyId,
                                                        @Param("branchId") UUID branchId);
}
