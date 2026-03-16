package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.SealTracking;
import hu.puzzleir.valuta.entity.SealTransitStatus;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.SealTrackingRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class SealTrackingService {

    private final SealTrackingRepository sealTrackingRepository;
    private final AuditLogService auditLogService;

    /**
     * Plomba felhelyezése — SEALED rekord létrehozása.
     */
    @Transactional
    public SealTracking seal(String transferType, Long transferId, String sealNumber) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        Long workerId = SecurityUtils.getCurrentWorkerId();
        if (workerId == null) {
            throw new ValidationException("Worker ID nem elérhető a security kontextusból");
        }

        if (sealTrackingRepository.existsByCompanyIdAndSealNumber(companyId, sealNumber)) {
            throw new ValidationException("A plomba szám már foglalt: " + sealNumber);
        }

        SealTracking tracking = SealTracking.builder()
                .companyId(companyId)
                .transferType(transferType)
                .transferId(transferId)
                .sealNumber(sealNumber)
                .sealedAt(LocalDateTime.now())
                .sealedBy(workerId)
                .transitStatus(SealTransitStatus.SEALED)
                .build();

        SealTracking saved = sealTrackingRepository.save(tracking);

        auditLogService.log("SEAL_CREATED",
                "Plomba felhelyezve: " + sealNumber + " (" + transferType + "/" + transferId + ")",
                saved.getId());

        return saved;
    }

    /**
     * Szállítás megkezdése — SEALED → IN_TRANSIT átmenet.
     */
    @Transactional
    public SealTracking startTransit(String transferType, Long transferId) {
        SealTracking tracking = findByTransferOrThrow(transferType, transferId);

        if (tracking.getTransitStatus() != SealTransitStatus.SEALED) {
            throw new ValidationException(
                    "Csak SEALED státuszú rekord indítható tranzitba, jelenlegi státusz: "
                            + tracking.getTransitStatus());
        }

        tracking.setTransitStatus(SealTransitStatus.IN_TRANSIT);
        SealTracking saved = sealTrackingRepository.save(tracking);

        auditLogService.log("SEAL_IN_TRANSIT",
                "Szállítás megkezdve: " + tracking.getSealNumber(),
                saved.getId());

        return saved;
    }

    /**
     * Megérkezés visszaigazolása — IN_TRANSIT → ARRIVED átmenet.
     */
    @Transactional
    public SealTracking confirmArrival(String transferType, Long transferId) {
        SealTracking tracking = findByTransferOrThrow(transferType, transferId);

        if (tracking.getTransitStatus() != SealTransitStatus.IN_TRANSIT) {
            throw new ValidationException(
                    "Csak IN_TRANSIT státuszú rekord igazolható megérkezettnek, jelenlegi státusz: "
                            + tracking.getTransitStatus());
        }

        tracking.setTransitStatus(SealTransitStatus.ARRIVED);
        SealTracking saved = sealTrackingRepository.save(tracking);

        auditLogService.log("SEAL_ARRIVED",
                "Megérkezés visszaigazolva: " + tracking.getSealNumber(),
                saved.getId());

        return saved;
    }

    /**
     * Plomba felnyitása — ARRIVED → OPENED átmenet, rögzíti a megnyitót és az időpontot.
     */
    @Transactional
    public SealTracking openSeal(String transferType, Long transferId) {
        SealTracking tracking = findByTransferOrThrow(transferType, transferId);

        if (tracking.getTransitStatus() != SealTransitStatus.ARRIVED) {
            throw new ValidationException(
                    "Csak ARRIVED státuszú plomba nyitható fel, jelenlegi státusz: "
                            + tracking.getTransitStatus());
        }

        Long workerId = SecurityUtils.getCurrentWorkerId();
        if (workerId == null) {
            throw new ValidationException("Worker ID nem elérhető a security kontextusból");
        }
        tracking.setTransitStatus(SealTransitStatus.OPENED);
        tracking.setOpenedBy(workerId);
        tracking.setOpenedAt(LocalDateTime.now());
        SealTracking saved = sealTrackingRepository.save(tracking);

        auditLogService.log("SEAL_OPENED",
                "Plomba felnyitva: " + tracking.getSealNumber() + " (worker: " + workerId + ")",
                saved.getId());

        return saved;
    }

    /**
     * Plomba integritásának ellenőrzése — a rögzített szám egyezik-e a vártal?
     */
    @Transactional(readOnly = true)
    public boolean validateSealIntegrity(String transferType, Long transferId, String expectedSealNumber) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        Optional<SealTracking> tracking = sealTrackingRepository
                .findByCompanyIdAndTransferTypeAndTransferId(companyId, transferType, transferId);
        return tracking.isPresent()
                && tracking.get().getSealNumber().equals(expectedSealNumber);
    }

    /**
     * Aktív (SEALED + IN_TRANSIT) rekordok az aktuális céghez.
     */
    @Transactional(readOnly = true)
    public List<SealTracking> getActiveTransits() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return sealTrackingRepository.findByCompanyIdAndTransitStatusIn(
                companyId,
                List.of(SealTransitStatus.SEALED, SealTransitStatus.IN_TRANSIT));
    }

    /**
     * Keresés plomba szám alapján — csak az aktuális cég rekordjait adja vissza.
     */
    @Transactional(readOnly = true)
    public Optional<SealTracking> getBySealNumber(String sealNumber) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return sealTrackingRepository.findBySealNumber(sealNumber)
                .filter(t -> t.getCompanyId().equals(companyId));
    }

    /**
     * Keresés transfer alapján — csak az aktuális cég rekordjait adja vissza.
     */
    @Transactional(readOnly = true)
    public Optional<SealTracking> getByTransfer(String transferType, Long transferId) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return sealTrackingRepository.findByCompanyIdAndTransferTypeAndTransferId(companyId, transferType, transferId);
    }

    // --- private ---

    private SealTracking findByTransferOrThrow(String transferType, Long transferId) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return sealTrackingRepository
                .findByCompanyIdAndTransferTypeAndTransferId(companyId, transferType, transferId)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Nem található plomba rekord: " + transferType + "/" + transferId));
    }
}
