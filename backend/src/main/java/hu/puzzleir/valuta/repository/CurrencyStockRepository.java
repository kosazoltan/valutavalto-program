package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.CurrencyStock;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import jakarta.persistence.LockModeType;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface CurrencyStockRepository extends JpaRepository<CurrencyStock, Long> {

    Optional<CurrencyStock> findByCompanyIdAndEntityTypeAndEntityIdAndCurrencyCode(
            UUID companyId, String entityType, String entityId, String currencyCode);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT cs FROM CurrencyStock cs WHERE cs.company.id = :companyId " +
           "AND cs.entityType = :entityType AND cs.entityId = :entityId " +
           "AND cs.currencyCode = :currencyCode")
    Optional<CurrencyStock> findForUpdate(
            @Param("companyId") UUID companyId,
            @Param("entityType") String entityType,
            @Param("entityId") String entityId,
            @Param("currencyCode") String currencyCode);

    /**
     * INVSTOCK-ROLLBACK fix: race-mentes sor-garantálás. A get-or-create korábbi
     * saveAndFlush + DIVE-catch mintája valós PG-n a tranzakciót rollback-only-ra
     * jelölte (a javító save a commitnál UnexpectedRollbackException-nel veszett el).
     * Az ON CONFLICT DO NOTHING-gal a kivétel létre sem jön; konkurens uncommitted
     * beszúrásnál a hívó a unique-indexen vár, majd no-op — a sort ezután a
     * findForUpdate zárolja. Oszloplistás konfliktus-cél (a V58 auto-nevű UNIQUE és a
     * teszt-séma Hibernate-neve eltér).
     */
    @Modifying
    @Query(value = """
            INSERT INTO currency_stock
                (company_id, entity_type, entity_id, currency_code, quantity, weighted_avg_cost, last_updated)
            VALUES (:companyId, :entityType, :entityId, :currencyCode, 0, 0, NOW())
            ON CONFLICT (company_id, entity_type, entity_id, currency_code) DO NOTHING
            """, nativeQuery = true)
    int insertIfAbsent(@Param("companyId") UUID companyId,
                       @Param("entityType") String entityType,
                       @Param("entityId") String entityId,
                       @Param("currencyCode") String currencyCode);

    List<CurrencyStock> findByEntityTypeAndEntityId(String entityType, String entityId);

    List<CurrencyStock> findByCompanyIdAndEntityType(UUID companyId, String entityType);

    /**
     * FKH-029 kieg. (Sourcery): egy entitás (pl. vault-territory) sorai közvetlenül, cég-szűrten —
     * a per-territory olvasóknál kiváltja a cég-szintű VAULT-scant és a kód-oldali entityId-szűrést.
     * A cégszintű batch (findByCompanyIdAndEntityType) a StockSnapshotService-ben szándékosan marad:
     * ott az összes vault egy lekérdezésben kell.
     */
    List<CurrencyStock> findByCompanyIdAndEntityTypeAndEntityId(UUID companyId, String entityType, String entityId);

    /**
     * Iroda (CASHIER típusú entitás) készlete valutanem szerint (nyitó egyenleg fallback).
     *
     * Az entityId a branch UUID string-je.
     */
    @Query("SELECT cs FROM CurrencyStock cs " +
           "WHERE cs.entityType = 'CASHIER' " +
           "AND cs.entityId = :branchId " +
           "AND cs.currencyCode = :currencyCode")
    Optional<CurrencyStock> findByBranchIdAndCurrencyCode(
        @Param("branchId") String branchId,
        @Param("currencyCode") String currencyCode);

    /**
     * Több iroda készlete egyben (KESZLEX batch lekérdezés, N+1 elkerülés).
     */
    @Query("SELECT cs FROM CurrencyStock cs " +
           "WHERE cs.entityType = 'CASHIER' " +
           "AND cs.entityId IN :branchIds")
    List<CurrencyStock> findAllByBranchIds(@Param("branchIds") List<String> branchIds);
    @Query("SELECT cs.currencyCode, SUM(cs.quantity), SUM(cs.quantity * cs.weightedAvgCost) " +
           "FROM CurrencyStock cs WHERE cs.company.id = :companyId " +
           "GROUP BY cs.currencyCode ORDER BY cs.currencyCode")
    List<Object[]> sumCompanyLevelByCurrency(@Param("companyId") UUID companyId);
}
