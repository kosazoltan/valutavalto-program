package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.DenominationAllowed;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

/**
 * FK-076: engedelyezett cimlet-katalogus repository.
 *
 * MULTI-TENANT: minden lekerdezes kotelezoen company_id-szurt.
 */
@Repository
public interface DenominationAllowedRepository extends JpaRepository<DenominationAllowed, Long> {

    @Query("SELECT da FROM DenominationAllowed da "
            + "JOIN FETCH da.currency c "
            + "WHERE da.company.id = :companyId AND da.active = true "
            + "ORDER BY c.code ASC, da.faceValue DESC")
    List<DenominationAllowed> findActiveByCompanyId(@Param("companyId") UUID companyId);

    @Query("SELECT CASE WHEN COUNT(da) > 0 THEN true ELSE false END "
            + "FROM DenominationAllowed da "
            + "WHERE da.company.id = :companyId "
            + "AND da.currency.id = :currencyId "
            + "AND da.faceValue = :faceValue "
            + "AND da.active = true")
    boolean existsAllowed(@Param("companyId") UUID companyId,
                          @Param("currencyId") Long currencyId,
                          @Param("faceValue") BigDecimal faceValue);
}
