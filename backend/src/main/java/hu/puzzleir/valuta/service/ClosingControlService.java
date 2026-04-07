package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.ClosingControlDto;
import hu.puzzleir.valuta.entity.ClosingControl;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.ClosingControlRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional(rollbackFor = Exception.class)
public class ClosingControlService {

    private final ClosingControlRepository closingControlRepository;
    private final NotificationService notificationService;

    /**
     * Összes iroda zárási állapota egy adott napon
     */
    @Transactional(readOnly = true)
    public List<ClosingControlDto> checkAllBranches(LocalDate date) {
        log.info("Zárás kontroll — összes iroda lekérése: {}", date);
        return closingControlRepository.findByControlDate(date)
                .stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    /**
     * Egy adott iroda zárási állapota
     */
    @Transactional(readOnly = true)
    public ClosingControlDto getBranchStatus(UUID branchId, LocalDate date) {
        ClosingControl control = closingControlRepository.findByBranchIdAndControlDate(branchId, date)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Zárás kontroll nem található: branch=" + branchId + ", dátum=" + date));
        return toDto(control);
    }

    /**
     * Figyelmeztető üzenet küldése egy irodának
     */
    public void sendAlert(UUID branchId, String message) {
        log.warn("ZÁRÁS FIGYELMEZTETÉS — branch: {}, üzenet: {}", branchId, message);

        LocalDate today = LocalDate.now();
        ClosingControl control = closingControlRepository.findByBranchIdAndControlDate(branchId, today)
                .orElseGet(() -> {
                    ClosingControl newControl = ClosingControl.builder()
                            .branchId(branchId)
                            .companyId(SecurityUtils.getCurrentCompanyId())
                            .controlDate(today)
                            .dailyClosingDone(false)
                            .eveningClosingDone(false)
                            .navClosingDone(false)
                            .alertLevel("WARNING")
                            .notes(message)
                            .build();
                    return closingControlRepository.save(newControl);
                });

        control.setAlertLevel("WARNING");
        control.setNotes(message);
        closingControlRepository.save(control);

        // Értesítés küldése az iroda összes dolgozójának (P0-8 fix)
        try {
            notificationService.sendToBranch(branchId,
                    "Zárási figyelmeztetés",
                    message);
        } catch (Exception e) {
            log.warn("Értesítés küldése sikertelen: branch={}, error={}", branchId, e.getMessage());
        }
        log.info("Figyelmeztetés rögzítve és értesítés küldve: branch={}", branchId);
    }

    // --- Helper ---

    private ClosingControlDto toDto(ClosingControl entity) {
        return ClosingControlDto.builder()
                .id(entity.getId())
                .branchId(entity.getBranchId())
                .controlDate(entity.getControlDate())
                .dailyClosingDone(entity.getDailyClosingDone())
                .eveningClosingDone(entity.getEveningClosingDone())
                .navClosingDone(entity.getNavClosingDone())
                .lastTransactionAt(entity.getLastTransactionAt())
                .alertLevel(entity.getAlertLevel())
                .notes(entity.getNotes())
                .build();
    }
}
