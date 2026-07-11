package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.DariusFixingRequestLine;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Collection;
import java.util.List;
import java.util.UUID;

@Repository
public interface DariusFixingRequestLineRepository extends JpaRepository<DariusFixingRequestLine, UUID> {

    List<DariusFixingRequestLine> findByCompanyIdAndRequestIdOrderByCurrencyCodeAsc(UUID companyId, UUID requestId);

    List<DariusFixingRequestLine> findByCompanyIdAndRequestIdInOrderByRequestIdAscCurrencyCodeAsc(
            UUID companyId, Collection<UUID> requestIds);

    void deleteByCompanyIdAndRequestId(UUID companyId, UUID requestId);
}
