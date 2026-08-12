package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.DenominationAllowed;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * FK-076/FK-080: engedelyezett cimlet-katalogus repository.
 *
 * <p>FK-080 ota ez a tabla az EGYETLEN igazsagforras arra, hogy melyik
 * (deviza, nevertek) par letezhet es az BANKNOTE vagy COIN-e — a HUF-ot IS
 * beleertve (V379 seed). Minden iro ut ezen a katalogus keresztul validal:
 * uj fiok cimlet-inicializalasa, zaras-varazslo auto-create es a
 * cimlet-egyenleg mentes.</p>
 *
 * <p>MULTI-TENANT: minden lekerdezes kotelezoen company_id-szurt.</p>
 */
@Repository
public interface DenominationAllowedRepository extends JpaRepository<DenominationAllowed, Long> {

    @Query("SELECT da FROM DenominationAllowed da "
            + "JOIN FETCH da.currency c "
            + "WHERE da.company.id = :companyId AND da.active = true "
            + "ORDER BY c.code ASC, da.faceValue DESC")
    List<DenominationAllowed> findActiveByCompanyId(@Param("companyId") UUID companyId);

    /**
     * FK-080 (FR-3/FR-5): az engedelyezett katalogus-SOR lekerdezese.
     *
     * <p>A korabbi boolean {@code existsAllowed} helyett magat a sort adja vissza,
     * mert a hivoknak a {@code denominationType} is kell (a cimlet tipusa a
     * katalogusbol jon, nem nevertek-kuszobbol), es igy nem all fenn ket kulon
     * gat, amelyik egymastol elcsuszhat.</p>
     *
     * <p>Nincs JOIN FETCH: a hivok csak a {@code faceValue}/{@code denominationType}
     * mezoket olvassak, mindketto magan a soron van.</p>
     */
    @Query("SELECT da FROM DenominationAllowed da "
            + "WHERE da.company.id = :companyId "
            + "AND da.currency.id = :currencyId "
            + "AND da.faceValue = :faceValue "
            + "AND da.active = true")
    Optional<DenominationAllowed> findActiveAllowed(@Param("companyId") UUID companyId,
                                                    @Param("currencyId") Long currencyId,
                                                    @Param("faceValue") BigDecimal faceValue);

    /**
     * FK-081: a torvenyes cimlet-katalogus feltoltese egy olyan cegre, amelynek meg
     * nincs egyetlen sora sem.
     *
     * <p><b>Miert kell:</b> a katalogust eddig KIZAROLAG migracio toltotte (V376
     * deviza-seed, V379 HUF-seed), es azok `INSERT ... SELECT`-je a futasuk pillanataban
     * letezo cegekre toltott. Egy kesobb felvett ceg katalogusa ezert URES marad, ami az
     * FK-080 ota a torvenyes HUF-zarast is megakadalyozna (VV-VALID-006/007 mindent
     * elutasit). Lasd: `.hermes/tickets/2026-08-11-fk081-uj-ceg-katalogus-seed.md`.
     *
     * <p><b>Nincs masodik igazsagforras</b> (a ticket kifejezett elvarasa): a seed nem
     * ismetli meg a nevertek-listat Java-ban, hanem a MAR MEGLEVO, migraciobol szarmazo
     * katalogus egy referencia-ceget masolja at. Igy a V376/V379 marad az egyetlen hely,
     * ahol a torvenyes lista definialva van — ha az valtozik, ez automatikusan koveti.
     *
     * <p><b>Referencia-ceg valasztasa:</b> a legtobb aktiv katalogus-sorral rendelkezo ceg
     * (determinisztikus tie-break a company_id-n), igy egy esetleg maga is hianyos tenant
     * nem valik mintava.
     *
     * <p><b>Idempotencia:</b> a `WHERE NOT EXISTS` gat miatt ismetelt futas 0 sort ir be.
     * <p><b>Multi-tenant:</b> a beirt sorok company_id-ja KIZAROLAG a parameterben kapott
     * ceg — a referencia-ceg soraibol csak a (currency_id, face_value, denomination_type)
     * harmas kerul at, a tulajdonos nem.
     *
     * @return a ténylegesen beszúrt sorok száma
     */
    @Modifying
    @Query(value = """
            INSERT INTO denomination_allowed
                   (company_id, currency_id, face_value, denomination_type, is_active, created_at, updated_at)
            SELECT :companyId, src.currency_id, src.face_value, src.denomination_type, true, now(), now()
              FROM denomination_allowed src
             WHERE src.company_id = (
                       SELECT da.company_id
                         FROM denomination_allowed da
                        WHERE da.is_active = true
                        GROUP BY da.company_id
                        ORDER BY count(*) DESC, da.company_id ASC
                        LIMIT 1)
               AND src.is_active = true
               AND NOT EXISTS (
                       SELECT 1
                         FROM denomination_allowed tgt
                        WHERE tgt.company_id = :companyId
                          AND tgt.currency_id = src.currency_id
                          AND tgt.face_value = src.face_value)
            """, nativeQuery = true)
    int seedCatalogForCompany(@Param("companyId") UUID companyId);
}
