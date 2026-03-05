package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.HandlingFeeBracket;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface HandlingFeeBracketRepository extends JpaRepository<HandlingFeeBracket, Long> {

    List<HandlingFeeBracket> findByCompanyIdAndActiveOrderByBracketOrder(UUID companyId, Boolean active);
}
