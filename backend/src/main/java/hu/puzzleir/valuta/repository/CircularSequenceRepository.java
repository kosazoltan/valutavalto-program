package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.CircularSequence;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface CircularSequenceRepository extends JpaRepository<CircularSequence, Integer> {

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT cs FROM CircularSequence cs WHERE cs.companyId = :companyId AND cs.prefix = :prefix")
    Optional<CircularSequence> findForUpdate(
            @Param("companyId") UUID companyId,
            @Param("prefix") String prefix);

    List<CircularSequence> findByCompanyId(UUID companyId);
}
