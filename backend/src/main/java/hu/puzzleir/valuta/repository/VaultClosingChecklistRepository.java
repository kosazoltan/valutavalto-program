package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.VaultClosingChecklist;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.Optional;
import java.util.UUID;

/**
 * Értéktári zárás-előtti ellenőrzőlista repository.
 *
 * <p>FR-ZARUI-16..26 (b2-zaras-kepernyok-bizonylatok.md)</p>
 * <p>Minden lekérdezés company_id + branch_id scopeolású (multi-tenant P0 invariáns).</p>
 */
@Repository
public interface VaultClosingChecklistRepository extends JpaRepository<VaultClosingChecklist, UUID> {

    /**
     * Adott cég + pénztár + dátum kombinációra keres.
     * A getOrCreate() idempotencia-kulcsa.
     */
    Optional<VaultClosingChecklist> findByCompanyIdAndBranch_IdAndClosingDate(
            UUID companyId, UUID branchId, LocalDate closingDate);
}
