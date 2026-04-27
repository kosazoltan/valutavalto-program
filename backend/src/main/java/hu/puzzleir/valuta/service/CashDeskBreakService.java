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
     * Szünetek listázása (multi-tenant scoped, audit-NO-GO-iter3 P0 fix).
     * A SecurityContext-ből kiolvasott companyId-ra szűr — cross-tenant lekérdezés nem lehetséges.
     */
    @Transactional(readOnly = true)
    public List<CashDeskBreakDto> listBreaks(UUID cashDeskId) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        List<CashDeskBreak> breaks;
        if (cashDeskId != null) {
            breaks = cashDeskBreakRepository.findByCompanyIdAndCashDeskIdOrderByBreakStartDesc(companyId, cashDeskId);
        } else {
            breaks = cashDeskBreakRepository.findByCompanyIdOrderByBreakStartDesc(companyId);
        }
        return breaks.stream().map(this::toDto).collect(Collectors.toList());
    }

    /**
     * Aktív szünet lekérése (multi-tenant scoped).
     */
    @Transactional(readOnly = true)
    public CashDeskBreakDto getActiveBreak(UUID cashDeskId) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return cashDeskBreakRepository.findByCompanyIdAndCashDeskIdAndIsActiveTrue(companyId, cashDeskId)
                .map(this::toDto)
                .orElse(null);
    }

    /**
     * Szünet indítása (multi-tenant scoped — companyId kötelezően a SecurityContext-ből).
     */
    public CashDeskBreakDto startBreak(UUID cashDeskId, String breakType, String reason) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();

        // Ellenőrzés: nincs-e már aktív szünet a saját company-ban
        cashDeskBreakRepository.findByCompanyIdAndCashDeskIdAndIsActiveTrue(companyId, cashDeskId).ifPresent(existing -> {
            throw new ValidationException("Már van aktív szünet ennél a pénztárgépnél!");
        });

        CashDeskBreak cashDeskBreak = CashDeskBreak.builder()
                .companyId(companyId)
                .cashDeskId(cashDeskId)
                .breakStart(LocalDateTime.now())
                .breakType(breakType)
                .reason(reason)
                .isActive(true)
                .build();

        CashDeskBreak saved = cashDeskBreakRepository.save(cashDeskBreak);
        log.info("Pénztár szünet indítva: company={}, cashDesk={}, típus={}", companyId, cashDeskId, breakType);

        return toDto(saved);
    }

    /**
     * Szünet befejezése (multi-tenant scoped — más company szünete nem zárható).
     */
    public CashDeskBreakDto endBreak(UUID breakId) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        CashDeskBreak cashDeskBreak = cashDeskBreakRepository.findById(breakId)
                .orElseThrow(() -> new ResourceNotFoundException("Szünet nem található: " + breakId));

        // Tenant boundary: másik company szünete = ResourceNotFoundException (nem ValidationException, hogy ne szivárogjon információ)
        if (cashDeskBreak.getCompanyId() == null || !cashDeskBreak.getCompanyId().equals(companyId)) {
            throw new ResourceNotFoundException("Szünet nem található: " + breakId);
        }

        if (!cashDeskBreak.getIsActive()) {
            throw new ValidationException("Ez a szünet már befejeződött!");
        }

        cashDeskBreak.setBreakEnd(LocalDateTime.now());
        cashDeskBreak.setIsActive(false);

        CashDeskBreak saved = cashDeskBreakRepository.save(cashDeskBreak);
        log.info("Pénztár szünet befejezve: company={}, breakId={}", companyId, breakId);

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
