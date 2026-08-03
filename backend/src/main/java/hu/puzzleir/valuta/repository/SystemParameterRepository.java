package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.SystemParameter;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface SystemParameterRepository extends JpaRepository<SystemParameter, UUID> {

    /** Szűretlen lookup — az ADMIN/ÍRÁSI utak (upsert, config-import, bootstrap-flag) használják:
     *  az inaktivált sort is meg kell találni, különben duplikátum jönne létre (V348 parciális unique). */
    Optional<SystemParameter> findByParameterKeyAndCompanyId(String key, UUID companyId);
    Optional<SystemParameter> findByParameterKeyAndCompanyIdIsNull(String key);

    /**
     * EFFEKTÍV (olvasási) lookup: az inaktivált (is_active=false) sor NEM találat — az admin
     * által "Inaktív"-ra állított paraméter ténylegesen kiesik, és a hívó fallback-ága dönt.
     *
     * <p>NULL-toleráns: az is_active oszlopnak nincs NOT NULL kikötése (V3_5/V74 —
     * {@code is_active BOOLEAN DEFAULT TRUE}), az entitás builder-defaultja true, és egyetlen
     * migráció sem seedel false-t. Ezért a NULL AKTÍV-nak számít; ez védi a régi, is_active
     * nélkül beszúrt sorokat a néma kieséstől. (Ugyanaz a szemantika, mint a V310
     * {@code IS DISTINCT FROM} mintája.)
     *
     * <p>A lista-utak (findAllVisibleTo / findActiveVisibleTo / findByCategoryVisibleTo) és a
     * fenti szűretlen metódusok szándékosan változatlanok.
     */
    @Query("SELECT p FROM SystemParameter p WHERE p.parameterKey = :key AND p.companyId = :companyId "
            + "AND (p.isActive = TRUE OR p.isActive IS NULL)")
    Optional<SystemParameter> findEffectiveByParameterKeyAndCompanyId(@Param("key") String key,
                                                                     @Param("companyId") UUID companyId);

    /** Effektív globális (company_id IS NULL) lookup — lásd
     *  {@link #findEffectiveByParameterKeyAndCompanyId} NULL-tolerancia leírását. */
    @Query("SELECT p FROM SystemParameter p WHERE p.parameterKey = :key AND p.companyId IS NULL "
            + "AND (p.isActive = TRUE OR p.isActive IS NULL)")
    Optional<SystemParameter> findEffectiveGlobalByParameterKey(@Param("key") String key);

    /** Id-alapú lookup tenant-láthatósággal: globál (companyId IS NULL) vagy a saját cég sora.
     *  companyId=null (nincs kontextus) → csak globál sor látható (fail-closed). */
    @Query("SELECT p FROM SystemParameter p WHERE p.id = :id AND (p.companyId IS NULL OR p.companyId = :companyId)")
    Optional<SystemParameter> findVisibleById(@Param("id") UUID id, @Param("companyId") UUID companyId);

    /** Globál + a megadott cég sorai. companyId=null → csak globálok (fail-closed). */
    @Query("SELECT p FROM SystemParameter p WHERE p.companyId IS NULL OR p.companyId = :companyId")
    List<SystemParameter> findAllVisibleTo(@Param("companyId") UUID companyId);

    @Query("SELECT p FROM SystemParameter p WHERE p.isActive = TRUE "
            + "AND (p.companyId IS NULL OR p.companyId = :companyId)")
    List<SystemParameter> findActiveVisibleTo(@Param("companyId") UUID companyId);

    @Query("SELECT p FROM SystemParameter p WHERE p.category = :category "
            + "AND (p.companyId IS NULL OR p.companyId = :companyId)")
    List<SystemParameter> findByCategoryVisibleTo(@Param("category") String category,
                                                  @Param("companyId") UUID companyId);
}
