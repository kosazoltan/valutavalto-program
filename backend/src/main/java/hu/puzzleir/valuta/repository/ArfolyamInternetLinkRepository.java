package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.ArfolyamInternetLink;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface ArfolyamInternetLinkRepository extends JpaRepository<ArfolyamInternetLink, UUID> {

    List<ArfolyamInternetLink> findByCompanyIdOrderByButtonNumberAsc(UUID companyId);

    Optional<ArfolyamInternetLink> findByCompanyIdAndButtonNumber(UUID companyId, Integer buttonNumber);
}
