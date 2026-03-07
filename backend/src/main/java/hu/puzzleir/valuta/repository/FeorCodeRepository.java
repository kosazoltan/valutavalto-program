package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.FeorCode;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

/**
 * FEOR kód referencia repository.
 */
@Repository
public interface FeorCodeRepository extends JpaRepository<FeorCode, Long> {

    /** FEOR kód alapján keresés */
    Optional<FeorCode> findByCode(String code);
}
