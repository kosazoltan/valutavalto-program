package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.CashRegisterDevice;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface CashRegisterDeviceRepository extends JpaRepository<CashRegisterDevice, UUID> {

    Optional<CashRegisterDevice> findByCompanyIdAndCode(UUID companyId, String code);

    Optional<CashRegisterDevice> findByDeviceFingerprint(String deviceFingerprint);

    List<CashRegisterDevice> findByBranchIdOrderByCodeAsc(UUID branchId);

    List<CashRegisterDevice> findByCompanyIdAndIsActiveTrueOrderByCodeAsc(UUID companyId);
}