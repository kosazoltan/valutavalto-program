package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.BackupRecord;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public interface BackupRecordRepository extends JpaRepository<BackupRecord, UUID> {

    Page<BackupRecord> findAllByOrderByStartedAtDesc(Pageable pageable);
}
