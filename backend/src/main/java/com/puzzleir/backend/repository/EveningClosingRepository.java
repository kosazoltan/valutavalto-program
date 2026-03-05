package com.puzzleir.backend.repository;

import com.puzzleir.backend.entity.EveningClosing;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface EveningClosingRepository extends JpaRepository<EveningClosing, UUID> {

    Optional<EveningClosing> findByBranchIdAndClosingDate(UUID branchId, LocalDate closingDate);
}
