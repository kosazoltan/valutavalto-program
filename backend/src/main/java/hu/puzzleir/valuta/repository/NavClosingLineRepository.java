package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.NavClosingLine;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

/**
 * NAV zárás sor repository.
 */
@Repository
public interface NavClosingLineRepository extends JpaRepository<NavClosingLine, UUID> {

    List<NavClosingLine> findByNavClosingId(UUID navClosingId);
}
