package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.FeeDiscount;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface FeeDiscountRepository extends JpaRepository<FeeDiscount, UUID> {

    /**
     * F2 cross-tenant fix (V189, 2026-05-06): minden lekérdezés cég-szinten szűrve.
     */
    List<FeeDiscount> findByCompanyId(UUID companyId);

    Optional<FeeDiscount> findByCompanyIdAndCode(UUID companyId, String code);

    List<FeeDiscount> findByCompanyIdAndIsActiveTrue(UUID companyId);
}
