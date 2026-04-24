package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.dto.ratehistory.RateHistoryDto;
import hu.puzzleir.valuta.entity.RateHistory;
import hu.puzzleir.valuta.repository.RateHistoryRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Árfolyam történet szolgáltatás.
 * Árfolyam változások naplózása és lekérdezése.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class RateHistoryService {

    private final RateHistoryRepository rateHistoryRepository;

    /**
     * Új árfolyam változás rögzítése
     */
    @Transactional(rollbackFor = Exception.class)
    public RateHistory recordRateChange(RateHistoryDto dto) {
        // Előző bejegyzés lezárása (effectiveTo beállítása)
        rateHistoryRepository.findLatestByCurrency(dto.getCompanyId(), dto.getCurrencyCode())
                .ifPresent(prev -> {
                    if (prev.getEffectiveTo() == null) {
                        prev.setEffectiveTo(dto.getEffectiveFrom());
                        rateHistoryRepository.save(prev);
                    }
                });

        RateHistory rateHistory = RateHistory.builder()
                .currencyCode(dto.getCurrencyCode())
                .buyRate(dto.getBuyRate())
                .sellRate(dto.getSellRate())
                .mnbRate(dto.getMnbRate())
                .spread(dto.getSpread())
                .category(dto.getCategory())
                .effectiveFrom(dto.getEffectiveFrom())
                .effectiveTo(dto.getEffectiveTo())
                .setBy(dto.getSetBy())
                .approvedBy(dto.getApprovedBy())
                .branchId(dto.getBranchId())
                .companyId(dto.getCompanyId())
                .build();

        RateHistory saved = rateHistoryRepository.save(rateHistory);
        log.info("Árfolyam változás rögzítve: {} - vétel: {}, eladás: {}, MNB: {}",
                saved.getCurrencyCode(), saved.getBuyRate(), saved.getSellRate(), saved.getMnbRate());

        return saved;
    }

    /**
     * Adott pillanatban érvényes árfolyam lekérdezése
     */
    @Transactional(readOnly = true)
    public RateHistoryDto getRateAtDate(String currency, LocalDateTime date) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();

        RateHistory rateHistory = rateHistoryRepository.findRateAtDate(companyId, currency, date)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Nem található árfolyam: " + currency + " @ " + date));

        return toDto(rateHistory);
    }

    /**
     * Árfolyam változások listázása időszakra (valuta opcionális).
     * Fix 2026-04-24 (Issue #184): currency = null -> minden valuta history.
     */
    @Transactional(readOnly = true)
    public List<RateHistoryDto> getRateChanges(String currency, LocalDate from, LocalDate to) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();

        LocalDateTime fromDt = from.atStartOfDay();
        LocalDateTime toDt = to.atTime(LocalTime.MAX);

        List<RateHistory> history;
        if (currency == null || currency.isBlank()) {
            history = rateHistoryRepository.findByDateRange(companyId, fromDt, toDt);
        } else {
            history = rateHistoryRepository.findByCurrencyAndDateRange(companyId, currency, fromDt, toDt);
        }

        return history.stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    private RateHistoryDto toDto(RateHistory entity) {
        return RateHistoryDto.builder()
                .id(entity.getId())
                .currencyCode(entity.getCurrencyCode())
                .buyRate(entity.getBuyRate())
                .sellRate(entity.getSellRate())
                .mnbRate(entity.getMnbRate())
                .spread(entity.getSpread())
                .category(entity.getCategory())
                .effectiveFrom(entity.getEffectiveFrom())
                .effectiveTo(entity.getEffectiveTo())
                .setBy(entity.getSetBy())
                .approvedBy(entity.getApprovedBy())
                .branchId(entity.getBranchId())
                .companyId(entity.getCompanyId())
                .createdAt(entity.getCreatedAt())
                .build();
    }
}
