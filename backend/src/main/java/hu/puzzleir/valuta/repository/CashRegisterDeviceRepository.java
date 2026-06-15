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

    /** Cross-tenant biztonsag: mindig companyId-val szurve. */
    Optional<CashRegisterDevice> findByCompanyIdAndDeviceFingerprint(UUID companyId, String deviceFingerprint);

    List<CashRegisterDevice> findByBranchIdOrderByCodeAsc(UUID branchId);

    List<CashRegisterDevice> findByCompanyIdAndIsActiveTrueOrderByCodeAsc(UUID companyId);

    /**
     * Cross-tenant IDOR guard: a cashDeskId (= device id) tulajdonosi ellenorzese.
     * A nem letezo eszkoz es a mas ceg eszkoze ugyanazt az ures eredmenyt adja,
     * igy a cashDeskId-enumeracio nem szivarogtat letezest. Hasznalat:
     * {@code DenominationBalanceService.requireOwnCashDesk}.
     */
    boolean existsByIdAndCompanyId(UUID id, UUID companyId);
}