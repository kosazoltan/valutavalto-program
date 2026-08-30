package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.TransactionLevyRateHistory;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

/** FK-099 — append-only illeték-ráta history repository. */
@Repository
public interface TransactionLevyRateHistoryRepository
        extends JpaRepository<TransactionLevyRateHistory, UUID> {

    /** A cég teljes ráta-historyja, hatálybalépés szerint csökkenő sorrendben. */
    List<TransactionLevyRateHistory> findByCompanyIdOrderByEffectiveFromDesc(UUID companyId);

    /** A cég legutolsó (max effective_from) ráta-sora — monotonitás-ellenőrzéshez. */
    Optional<TransactionLevyRateHistory> findFirstByCompanyIdOrderByEffectiveFromDesc(UUID companyId);
}
