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
    Optional<SystemParameter> findByParameterKeyAndCompanyId(String key, UUID companyId);
    Optional<SystemParameter> findByParameterKeyAndCompanyIdIsNull(String key);
    List<SystemParameter> findByIsActiveTrue();
    List<SystemParameter> findByCategory(String category);

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
