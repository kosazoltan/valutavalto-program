package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.MachineConfig;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

/**
 * EXCMD b6-beallitasok FR-14 — gépenként izolált konfigurációs rekordok.
 *
 * <p>Minden lekérdezésnek tartalmaznia kell a {@code companyId}-t (multi-tenant izoláció).
 * Soha ne hívj {@code findAll()} szűrés nélkül.</p>
 */
@Repository
public interface MachineConfigRepository extends JpaRepository<MachineConfig, UUID> {

    /**
     * Konfigurációs rekord lekérése gép és cég szerint (multi-tenant szűrt).
     *
     * @param companyId       a bejelentkezett cég UUID-ja (SecurityUtils.getCurrentCompanyId())
     * @param workstationCode a gép kódja (Electron branch_code, pl. BR039)
     */
    Optional<MachineConfig> findByCompanyIdAndWorkstationCode(UUID companyId, String workstationCode);
}
