package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.ClientErrorLog;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface ClientErrorLogRepository extends JpaRepository<ClientErrorLog, Long> {

    Page<ClientErrorLog> findAllByOrderByCreatedAtDesc(Pageable pageable);

    long countByCreatedAtAfter(LocalDateTime since);

    @Query("SELECT c.component AS component, COUNT(c) AS errorCount "
            + "FROM ClientErrorLog c "
            + "WHERE c.createdAt >= :since "
            + "GROUP BY c.component "
            + "ORDER BY COUNT(c) DESC")
    List<ComponentCount> countByComponentSince(@Param("since") LocalDateTime since);

    @Query("SELECT c.version AS version, COUNT(c) AS errorCount "
            + "FROM ClientErrorLog c "
            + "WHERE c.createdAt >= :since AND c.version IS NOT NULL "
            + "GROUP BY c.version "
            + "ORDER BY COUNT(c) DESC")
    List<VersionCount> countByVersionSince(@Param("since") LocalDateTime since);

    interface ComponentCount {
        String getComponent();
        long getErrorCount();
    }

    interface VersionCount {
        String getVersion();
        long getErrorCount();
    }
}
