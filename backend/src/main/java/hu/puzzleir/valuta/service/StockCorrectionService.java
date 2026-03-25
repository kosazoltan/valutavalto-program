package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.ertektar.StockCorrectionRequestDto;
import hu.puzzleir.valuta.dto.ertektar.StockCorrectionResponseDto;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.CurrencyStockRepository;
import hu.puzzleir.valuta.repository.StockCorrectionRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Készletkorrekció — legacy KESZEDIT megfelelő.
 *
 * Leltárkülönbözet rendezés: a tényleges készletet kézzel állítjuk be,
 * ha az nem egyezik a nyilvántartott értékkel.
 *
 * Workflow: REQUESTED → COMPLETED (jóváhagyáskor) vagy REJECTED
 * A COMPLETED állapotba lépéskor módosul a CurrencyStock.quantity.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class StockCorrectionService {

    private final StockCorrectionRepository stockCorrectionRepository;
    private final CurrencyStockRepository currencyStockRepository;

    @Transactional(readOnly = true)
    public List<StockCorrectionResponseDto> getCorrections() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return stockCorrectionRepository.findByCompanyIdOrderByCreatedAtDesc(companyId)
                .stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<StockCorrectionResponseDto> getPendingCorrections() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return stockCorrectionRepository.findByCompanyIdAndStatusOrderByCreatedAtDesc(
                        companyId, VaultOperationStatus.REQUESTED)
                .stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    /**
     * Korrekciós kérelem létrehozása.
     * Az aktuális készletet olvassuk ki, és kiszámoljuk a különbözetet.
     */
    @Transactional(rollbackFor = Exception.class)
    public StockCorrectionResponseDto createCorrection(StockCorrectionRequestDto request) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        Long workerId = SecurityUtils.getCurrentWorkerId();

        // Aktuális készlet lekérdezése
        BigDecimal oldQuantity = currencyStockRepository.findByCompanyIdAndEntityTypeAndEntityIdAndCurrencyCode(
                        companyId, request.getEntityType(), request.getEntityId(), request.getCurrencyCode())
                .map(CurrencyStock::getQuantity)
                .orElse(BigDecimal.ZERO);

        BigDecimal difference = request.getNewQuantity().subtract(oldQuantity);

        StockCorrection correction = StockCorrection.builder()
                .companyId(companyId)
                .entityType(request.getEntityType())
                .entityId(request.getEntityId())
                .currencyCode(request.getCurrencyCode())
                .oldQuantity(oldQuantity)
                .newQuantity(request.getNewQuantity())
                .difference(difference)
                .reason(request.getReason())
                .status(VaultOperationStatus.REQUESTED)
                .createdAt(LocalDateTime.now())
                .createdBy(workerId)
                .build();

        StockCorrection saved = stockCorrectionRepository.save(correction);
        log.info("Készletkorrekció kérelem: {}/{}/{} {} → {} (diff: {}), company={}",
                request.getEntityType(), request.getEntityId(), request.getCurrencyCode(),
                oldQuantity, request.getNewQuantity(), difference, companyId);

        return toDto(saved);
    }

    /**
     * Korrekció jóváhagyása — készlet effektív módosítása.
     * A WAC nem változik korrekciónál (a készlet mennyisége módosul).
     */
    @Transactional(rollbackFor = Exception.class)
    public StockCorrectionResponseDto approveCorrection(Long id) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        Long workerId = SecurityUtils.getCurrentWorkerId();

        StockCorrection correction = stockCorrectionRepository.findById(id)
                .filter(c -> c.getCompanyId().equals(companyId))
                .orElseThrow(() -> new ResourceNotFoundException("Korrekció nem található: " + id));

        if (correction.getStatus() != VaultOperationStatus.REQUESTED) {
            throw new IllegalStateException("Csak REQUESTED státuszú korrekció hagyható jóvá!");
        }

        // Készlet direkt módosítása
        CurrencyStock stock = currencyStockRepository.findForUpdate(
                companyId, correction.getEntityType(), correction.getEntityId(), correction.getCurrencyCode())
                .orElseGet(() -> {
                    CurrencyStock newStock = CurrencyStock.builder()
                            .company(Company.builder().id(companyId).build())
                            .entityType(correction.getEntityType())
                            .entityId(correction.getEntityId())
                            .currencyCode(correction.getCurrencyCode())
                            .quantity(BigDecimal.ZERO)
                            .weightedAvgCost(BigDecimal.ZERO)
                            .lastUpdated(LocalDateTime.now())
                            .build();
                    return currencyStockRepository.save(newStock);
                });

        stock.setQuantity(correction.getNewQuantity());
        stock.setLastUpdated(LocalDateTime.now());

        correction.setStatus(VaultOperationStatus.COMPLETED);
        correction.setApprovedAt(LocalDateTime.now());
        correction.setApprovedBy(workerId);

        log.info("Készletkorrekció jóváhagyva: {}/{}/{} → {} (worker={})",
                correction.getEntityType(), correction.getEntityId(),
                correction.getCurrencyCode(), correction.getNewQuantity(), workerId);

        return toDto(stockCorrectionRepository.save(correction));
    }

    @Transactional(rollbackFor = Exception.class)
    public StockCorrectionResponseDto rejectCorrection(Long id) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        StockCorrection correction = stockCorrectionRepository.findById(id)
                .filter(c -> c.getCompanyId().equals(companyId))
                .orElseThrow(() -> new ResourceNotFoundException("Korrekció nem található: " + id));

        if (correction.getStatus() != VaultOperationStatus.REQUESTED) {
            throw new IllegalStateException("Csak REQUESTED státuszú korrekció utasítható el!");
        }

        correction.setStatus(VaultOperationStatus.REJECTED);
        log.info("Készletkorrekció elutasítva: id={}", id);
        return toDto(stockCorrectionRepository.save(correction));
    }

    private StockCorrectionResponseDto toDto(StockCorrection entity) {
        return StockCorrectionResponseDto.builder()
                .id(entity.getId())
                .entityType(entity.getEntityType())
                .entityId(entity.getEntityId())
                .currencyCode(entity.getCurrencyCode())
                .oldQuantity(entity.getOldQuantity())
                .newQuantity(entity.getNewQuantity())
                .difference(entity.getDifference())
                .reason(entity.getReason())
                .status(entity.getStatus().name())
                .createdAt(entity.getCreatedAt())
                .approvedAt(entity.getApprovedAt())
                .build();
    }
}
