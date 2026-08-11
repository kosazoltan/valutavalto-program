package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.DenominationAllowed;
import org.springframework.data.jpa.repository.JpaRepository;
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
}
