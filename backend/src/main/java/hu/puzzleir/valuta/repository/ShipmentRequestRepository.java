package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.ShipmentRequest;
import hu.puzzleir.valuta.entity.ShipmentRequestStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public interface ShipmentRequestRepository extends JpaRepository<ShipmentRequest, UUID> {

    Page<ShipmentRequest> findByStatus(ShipmentRequestStatus status, Pageable pageable);

    @Query("SELECT sr FROM ShipmentRequest sr ORDER BY sr.createdAt DESC")
    Page<ShipmentRequest> findAllOrdered(Pageable pageable);

    @Query("SELECT COALESCE(MAX(CAST(SUBSTRING(sr.requestNumber, 5) AS integer)), 0) FROM ShipmentRequest sr " +
           "WHERE sr.requestNumber LIKE :prefix%")
    int findMaxRequestNumber(@Param("prefix") String prefix);
}
