package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.DariusFixingRequest;
import hu.puzzleir.valuta.entity.DariusFixingRequestStatus;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface DariusFixingRequestRepository extends JpaRepository<DariusFixingRequest, UUID> {

    List<DariusFixingRequest> findByCompanyIdAndRequestDateOrderByCreatedAtAsc(
            UUID companyId, LocalDate requestDate);

    Optional<DariusFixingRequest> findByIdAndCompanyId(UUID id, UUID companyId);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("""
        SELECT r FROM DariusFixingRequest r
        WHERE r.id = :id
          AND r.companyId = :companyId
    """)
    Optional<DariusFixingRequest> findForUpdateByIdAndCompanyId(
            @Param("id") UUID id,
            @Param("companyId") UUID companyId);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("""
        SELECT r FROM DariusFixingRequest r
        WHERE r.companyId = :companyId
          AND r.requestDate = :requestDate
          AND r.status IN :statuses
        ORDER BY r.createdAt ASC, r.id ASC
    """)
    List<DariusFixingRequest> findForUpdateByCompanyIdAndRequestDateAndStatusInOrderByCreatedAtAscIdAsc(
            @Param("companyId") UUID companyId,
            @Param("requestDate") LocalDate requestDate,
            @Param("statuses") Collection<DariusFixingRequestStatus> statuses);

    boolean existsByCompanyIdAndRequestDateAndBankBranchIdAndStatusNot(
            UUID companyId,
            LocalDate requestDate,
            UUID bankBranchId,
            DariusFixingRequestStatus status);
}
