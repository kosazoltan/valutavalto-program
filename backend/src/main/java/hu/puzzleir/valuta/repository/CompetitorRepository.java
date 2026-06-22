package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.Competitor;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Collection;
import java.util.List;
import java.util.UUID;

@Repository
public interface CompetitorRepository extends JpaRepository<Competitor, UUID> {

    List<Competitor> findByIsActiveTrueOrderByNameAsc();

    List<Competitor> findByBranchIdAndIsActiveTrueOrderByNameAsc(UUID branchId);

    /**
     * FK-041/II: a TERÜLET (régió) több irodájához tartozó aktív versenyhelyek. A hívó (árfolyam néző)
     * a régiója pénztáraihoz rendelt versenyhelyekhez vihet be árfolyamot. A branchId-halmazt a service
     * companyId-scope-oltan állítja elő (findActiveByCompanyIdAndRegion), így ez a lekérdezés a hívó
     * cégének régiós irodáira korlátozott.
     */
    List<Competitor> findByBranchIdInAndIsActiveTrueOrderByNameAsc(Collection<UUID> branchIds);
}
