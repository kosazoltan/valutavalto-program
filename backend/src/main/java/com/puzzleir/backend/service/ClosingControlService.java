package com.puzzleir.backend.service;

import com.puzzleir.backend.dto.ClosingControlDto;
import com.puzzleir.backend.entity.ClosingControl;
import com.puzzleir.backend.exception.ResourceNotFoundException;
import com.puzzleir.backend.repository.ClosingControlRepository;
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
@Transactional
public class ClosingControlService {

    private final ClosingControlRepository closingControlRepository;

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
                            .companyId(UUID.randomUUID()) // TODO: company ID from context
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

        // TODO: Email/push notification küldés az irodának
        log.info("Figyelmeztetés rögzítve: branch={}", branchId);
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
