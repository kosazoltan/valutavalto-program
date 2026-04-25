package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.dto.cashdesk.CashDeskBreakDto;
import hu.puzzleir.valuta.entity.CashDeskBreak;
import hu.puzzleir.valuta.repository.CashDeskBreakRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Pénztár szünet szolgáltatás.
 */
@Service
@RequiredArgsConstructor
@Transactional(rollbackFor = Exception.class)
@Slf4j
public class CashDeskBreakService {

    private final CashDeskBreakRepository cashDeskBreakRepository;

    /**
     * Szünetek listázása
     *
     * <p>v2.3.2 multi-tenant audit: a null cashDeskId path most az aktuális
     * felhasználoi tenant-on belul listáz, NEM minden cég-en at. A CashDesk.companyId-t
     * subquery-vel szuri.</p>
     */
    @Transactional(readOnly = true)
    public List<CashDeskBreakDto> listBreaks(UUID cashDeskId) {
        List<CashDeskBreak> breaks;
        if (cashDeskId != null) {
            // CashDesk maga is company-scope-os, igy a cashDeskId-n at biztonsagos
            breaks = cashDeskBreakRepository.findByCashDeskIdOrderByBreakStartDesc(cashDeskId);
        } else {
            // v2.3.2 multi-tenant fix: aktualis company-tenant break-jei
            UUID companyId = SecurityUtils.getCurrentCompanyId();
            breaks = cashDeskBreakRepository.findByCompanyIdOrderByBreakStartDesc(companyId);
        }
        return breaks.stream().map(this::toDto).collect(Collectors.toList());
    }

    /**
     * Aktív szünet lekérése
     */
    @Transactional(readOnly = true)
    public CashDeskBreakDto getActiveBreak(UUID cashDeskId) {
        return cashDeskBreakRepository.findByCashDeskIdAndIsActiveTrue(cashDeskId)
                .map(this::toDto)
                .orElse(null);
    }

    /**
     * Szünet indítása
     */
    public CashDeskBreakDto startBreak(UUID cashDeskId, String breakType, String reason) {
        // Ellenőrzés: nincs-e már aktív szünet
        cashDeskBreakRepository.findByCashDeskIdAndIsActiveTrue(cashDeskId).ifPresent(existing -> {
            throw new ValidationException("Már van aktív szünet ennél a pénztárgépnél!");
        });

        CashDeskBreak cashDeskBreak = CashDeskBreak.builder()
                .cashDeskId(cashDeskId)
                .breakStart(LocalDateTime.now())
                .breakType(breakType)
                .reason(reason)
                .isActive(true)
                .build();

        CashDeskBreak saved = cashDeskBreakRepository.save(cashDeskBreak);
        log.info("Pénztár szünet indítva: cashDesk={}, típus={}", cashDeskId, breakType);

        return toDto(saved);
    }

    /**
     * Szünet befejezése
     */
    public CashDeskBreakDto endBreak(UUID breakId) {
        CashDeskBreak cashDeskBreak = cashDeskBreakRepository.findById(breakId)
                .orElseThrow(() -> new ResourceNotFoundException("Szünet nem található: " + breakId));

        if (!cashDeskBreak.getIsActive()) {
            throw new ValidationException("Ez a szünet már befejeződött!");
        }

        cashDeskBreak.setBreakEnd(LocalDateTime.now());
        cashDeskBreak.setIsActive(false);

        CashDeskBreak saved = cashDeskBreakRepository.save(cashDeskBreak);
        log.info("Pénztár szünet befejezve: breakId={}", breakId);

        return toDto(saved);
    }

    // ============ HELPER ============

    private CashDeskBreakDto toDto(CashDeskBreak entity) {
        return CashDeskBreakDto.builder()
                .id(entity.getId().toString())
                .cashDeskId(entity.getCashDeskId().toString())
                .breakStart(entity.getBreakStart())
                .breakEnd(entity.getBreakEnd())
                .breakType(entity.getBreakType())
                .reason(entity.getReason())
                .isActive(entity.getIsActive())
                .build();
    }
}
