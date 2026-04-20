package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.cashregister.CashRegisterDeviceDto;
import hu.puzzleir.valuta.dto.cashregister.RegisterCashRegisterDeviceRequest;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.CashRegisterDevice;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CashRegisterDeviceRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

/**
 * Penztar-eszkoz nyilvantarto service.
 * SetupWizard kuldi a RegisterCashRegisterDeviceRequest-et a telepites pillanataban.
 * Idempotens: ha mar letezik ugyanazzal a (companyId, code) kombinacioval, frissiti.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class CashRegisterDeviceService {

    private final CashRegisterDeviceRepository repository;
    private final BranchRepository branchRepository;

    @Transactional
    public CashRegisterDeviceDto register(RegisterCashRegisterDeviceRequest request) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();

        // Branch IDOR-vedelem: sajat ceg
        Branch branch = branchRepository.findById(request.getBranchId())
                .orElseThrow(() -> new ResourceNotFoundException("Branch nem talalhato: " + request.getBranchId()));
        if (!branch.getCompany().getId().equals(companyId)) {
            throw new ResourceNotFoundException("Branch nem talalhato a sajat ceghez: " + request.getBranchId());
        }

        CashRegisterDevice device = repository.findByCompanyIdAndCode(companyId, request.getCode())
                .orElseGet(() -> CashRegisterDevice.builder()
                        .companyId(companyId)
                        .code(request.getCode())
                        .build());

        // Device-hijacking vedelem: ha mar letezik a (companyId, code) eszkoz, de MAS
        // device_fingerprint-tel ujra-regisztralnak, az egy masik fizikai gep -> 409 Conflict.
        // Kivetel: ha a regi fingerprint ures (legacy rekord), frissitest engedelyezunk.
        if (device.getId() != null
                && device.getDeviceFingerprint() != null && !device.getDeviceFingerprint().isBlank()
                && request.getDeviceFingerprint() != null && !request.getDeviceFingerprint().isBlank()
                && !device.getDeviceFingerprint().equals(request.getDeviceFingerprint())) {
            log.warn("Device-hijacking kiserlet: code={}, existing_fp={}, requested_fp={}",
                    device.getCode(), device.getDeviceFingerprint(), request.getDeviceFingerprint());
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                    "Ez a penztar-kod mar egy masik fizikai gephez tartozik. Valassz masik kodot vagy kerj torlest az adminisztratortol.");
        }

        device.setBranchId(request.getBranchId());
        device.setName(request.getName());
        device.setAppMode(request.getAppMode() != null ? request.getAppMode() : "penztar");
        device.setAppVersion(request.getAppVersion());
        device.setDeviceFingerprint(request.getDeviceFingerprint());
        device.setOsInfo(request.getOsInfo());
        device.setRegisteredByWorkerId(SecurityUtils.getCurrentWorkerId());
        device.setIsActive(true);
        device.setLastSeenAt(LocalDateTime.now());
        if (device.getInstalledAt() == null) {
            device.setInstalledAt(LocalDateTime.now());
        }

        CashRegisterDevice saved = repository.save(device);
        log.info("Penztar-eszkoz regisztralva: id={}, code={}, branchId={}, companyId={}",
                saved.getId(), saved.getCode(), saved.getBranchId(), saved.getCompanyId());

        return toDto(saved);
    }

    @Transactional
    public CashRegisterDeviceDto heartbeat(UUID deviceId) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        CashRegisterDevice device = repository.findById(deviceId)
                .orElseThrow(() -> new ResourceNotFoundException("Penztar-eszkoz nem talalhato: " + deviceId));
        if (!device.getCompanyId().equals(companyId)) {
            throw new ResourceNotFoundException("Penztar-eszkoz nem talalhato: " + deviceId);
        }
        device.setLastSeenAt(LocalDateTime.now());
        return toDto(repository.save(device));
    }

    @Transactional(readOnly = true)
    public List<CashRegisterDeviceDto> listForCurrentCompany() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return repository.findByCompanyIdAndIsActiveTrueOrderByCodeAsc(companyId)
                .stream().map(this::toDto).toList();
    }

    private CashRegisterDeviceDto toDto(CashRegisterDevice d) {
        return CashRegisterDeviceDto.builder()
                .id(d.getId())
                .companyId(d.getCompanyId())
                .branchId(d.getBranchId())
                .code(d.getCode())
                .name(d.getName())
                .appMode(d.getAppMode())
                .appVersion(d.getAppVersion())
                .deviceFingerprint(d.getDeviceFingerprint())
                .osInfo(d.getOsInfo())
                .installedAt(d.getInstalledAt())
                .lastSeenAt(d.getLastSeenAt())
                .isActive(d.getIsActive())
                .build();
    }
}