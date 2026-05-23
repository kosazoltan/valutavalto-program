package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.TeaorCode;
import org.springframework.data.domain.Limit;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface TeaorCodeRepository extends JpaRepository<TeaorCode, Long> {

    /**
     * Kód-prefix VAGY megnevezés-tartalmaz keresés (case-insensitive), kód szerint rendezve.
     */
    @Query("""
            SELECT t FROM TeaorCode t
            WHERE LOWER(t.code) LIKE LOWER(CONCAT(:q, '%'))
               OR LOWER(t.name) LIKE LOWER(CONCAT('%', :q, '%'))
            ORDER BY t.code ASC
            """)
    List<TeaorCode> search(@Param("q") String q, Limit limit);
}
