package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.CashDeskBreak;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Pénztár szünet repository.
 */
@Repository
public interface CashDeskBreakRepository extends JpaRepository<CashDeskBreak, UUID> {

    /**
     * Pénztárgép összes szünete
     */
    List<CashDeskBreak> findByCashDeskIdOrderByBreakStartDesc(UUID cashDeskId);

    /**
     * Összes szünet (legújabb elöl)
     */
    List<CashDeskBreak> findAllByOrderByBreakStartDesc();

    /**
     * Aktív szünet keresése pénztárgéphez
     */
    Optional<CashDeskBreak> findByCashDeskIdAndIsActiveTrue(UUID cashDeskId);
}
