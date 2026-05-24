package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.ArchiveTask;
import hu.puzzleir.valuta.entity.ArchiveTaskStatus;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ArchiveTaskRepository extends JpaRepository<ArchiveTask, UUID> {

    List<ArchiveTask> findByStatus(ArchiveTaskStatus status);

    @Query("SELECT t FROM ArchiveTask t WHERE t.company.id = :companyId ORDER BY t.startedAt DESC")
    List<ArchiveTask> findByCompanyId(@Param("companyId") UUID companyId);

    @Query("SELECT t FROM ArchiveTask t WHERE t.id = :id AND t.company.id = :companyId")
    Optional<ArchiveTask> findByIdAndCompanyId(@Param("id") UUID id, @Param("companyId") UUID companyId);
}
