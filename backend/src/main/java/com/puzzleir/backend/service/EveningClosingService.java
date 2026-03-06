package com.puzzleir.backend.service;

import com.puzzleir.backend.dto.EveningClosingDto;
import com.puzzleir.backend.entity.EveningClosing;
import com.puzzleir.backend.exception.ResourceNotFoundException;
import com.puzzleir.backend.exception.ValidationException;
import com.puzzleir.backend.repository.EveningClosingRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class EveningClosingService {

    private final EveningClosingRepository eveningClosingRepository;

    /**
     * Esti zárás előkészítése — napi tranzakciók összesítése
     */
    public EveningClosingDto prepareEvening(UUID companyId, UUID branchId, LocalDate date) {
        log.info("Esti zárás előkészítése - branch: {}, dátum: {}", branchId, date);

        // Ellenőrzés: már létezik-e zárás erre a napra
        eveningClosingRepository.findByBranchIdAndClosingDate(branchId, date)
                .ifPresent(existing -> {
                    throw new ValidationException("Erre a napra már van esti zárás: " + date);
                });

        // TODO(integration): Valódi összesítés a Transaction repository-ból — TransactionRepository összesítő query szükséges
        // Egyelőre placeholder adatokkal — a production integrációnál bekötjük
        EveningClosing closing = EveningClosing.builder()
                .companyId(companyId)
                .branchId(branchId)
                .closingDate(date)
                .status("PREPARING")
                .transactionCount(0)
                .totalBuyHuf(BigDecimal.ZERO)
                .totalSellHuf(BigDecimal.ZERO)
                .build();

        EveningClosing saved = eveningClosingRepository.save(closing);

        // Átállítás READY-re (miután a csomag összeállt)
        saved.setStatus("READY");
        saved.setPackageData("{\"prepared\": true}");
        saved.setInventorySnapshot("{\"currencies\": []}");
        EveningClosing ready = eveningClosingRepository.save(saved);

        log.info("Esti zárás kész: {}", ready.getId());
        return toDto(ready);
    }

    /**
     * Csomag küldése a szervernek
     */
    public EveningClosingDto sendPackage(UUID closingId) {
        log.info("Esti zárás csomag küldése: {}", closingId);

        EveningClosing closing = eveningClosingRepository.findById(closingId)
                .orElseThrow(() -> new ResourceNotFoundException("Esti zárás nem található: " + closingId));

        if (!"READY".equals(closing.getStatus())) {
            throw new ValidationException("Csak READY státuszú zárás küldhető el");
        }

        // TODO(integration): REST API hívás a központi szerverre — FtpSyncService vagy RestTemplate integráció szükséges
        closing.setStatus("SENT");
        closing.setSentAt(LocalDateTime.now());
        EveningClosing sent = eveningClosingRepository.save(closing);

        log.info("Esti zárás elküldve: {}", sent.getId());
        return toDto(sent);
    }

    /**
     * Esti zárás állapot lekérdezése
     */
    @Transactional(readOnly = true)
    public EveningClosingDto getEveningStatus(UUID branchId, LocalDate date) {
        EveningClosing closing = eveningClosingRepository.findByBranchIdAndClosingDate(branchId, date)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Esti zárás nem található: branch=" + branchId + ", dátum=" + date));
        return toDto(closing);
    }

    // --- Helper ---

    private EveningClosingDto toDto(EveningClosing entity) {
        return EveningClosingDto.builder()
                .id(entity.getId())
                .branchId(entity.getBranchId())
                .closingDate(entity.getClosingDate())
                .status(entity.getStatus())
                .packageData(entity.getPackageData())
                .transactionCount(entity.getTransactionCount())
                .totalBuyHuf(entity.getTotalBuyHuf())
                .totalSellHuf(entity.getTotalSellHuf())
                .inventorySnapshot(entity.getInventorySnapshot())
                .sentAt(entity.getSentAt())
                .confirmedAt(entity.getConfirmedAt())
                .createdAt(entity.getCreatedAt())
                .build();
    }
}
