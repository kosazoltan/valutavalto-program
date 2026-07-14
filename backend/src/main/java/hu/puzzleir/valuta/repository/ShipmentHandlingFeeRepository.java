package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.ShipmentHandlingFee;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface ShipmentHandlingFeeRepository extends JpaRepository<ShipmentHandlingFee, UUID> {

    /** Tenant-safe egyetlen olvasási belépési pont. */
    Optional<ShipmentHandlingFee> findByShipmentRequestIdAndCompanyId(
            UUID shipmentRequestId, UUID companyId);
}
