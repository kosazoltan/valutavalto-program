package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.dto.denomination.DenominationBalanceDto;
import hu.puzzleir.valuta.dto.denomination.DenominationQuantityUpdateRequestDto;
import hu.puzzleir.valuta.entity.Denomination;
import hu.puzzleir.valuta.entity.DenominationBalance;
import hu.puzzleir.valuta.repository.DenominationBalanceRepository;
import hu.puzzleir.valuta.repository.DenominationRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Pénztárgép címlet egyenleg szolgáltatás.
 */
@Service
@RequiredArgsConstructor
@Transactional
@Slf4j
public class DenominationBalanceService {

    private final DenominationBalanceRepository denominationBalanceRepository;
    private final DenominationRepository denominationRepository;

    /**
     * Pénztárgép összes címletének lekérése
     */
    @Transactional(readOnly = true)
    public List<DenominationBalanceDto> getCashDeskDenominations(UUID cashDeskId) {
        return denominationBalanceRepository.findByCashDeskId(cashDeskId)
                .stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    /**
     * Pénztárgép adott valutájú címleteinek lekérése
     */
    @Transactional(readOnly = true)
    public List<DenominationBalanceDto> getCashDeskDenominationsByCurrency(UUID cashDeskId, Long currencyId) {
        return denominationBalanceRepository.findByCashDeskIdAndCurrencyId(cashDeskId, currencyId)
                .stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    /**
     * Egyedi címlet darabszám frissítése
     */
    public DenominationBalanceDto updateQuantity(UUID cashDeskId, Long denominationId, int quantity) {
        DenominationBalance balance = denominationBalanceRepository
                .findByCashDeskIdAndDenominationId(cashDeskId, denominationId)
                .orElseGet(() -> {
                    Denomination denom = denominationRepository.findById(denominationId)
                            .orElseThrow(() -> new ResourceNotFoundException("Címlet nem található: " + denominationId));
                    return DenominationBalance.builder()
                            .cashDeskId(cashDeskId)
                            .denomination(denom)
                            .quantity(0)
                            .totalValue(BigDecimal.ZERO)
                            .build();
                });

        balance.setQuantity(quantity);
        balance.recalculateTotalValue();

        DenominationBalance saved = denominationBalanceRepository.save(balance);
        log.info("Címlet egyenleg frissítve: cashDesk={}, denomination={}, quantity={}", cashDeskId, denominationId, quantity);

        return toDto(saved);
    }

    /**
     * Batch címlet darabszám frissítés
     */
    public List<DenominationBalanceDto> batchUpdate(UUID cashDeskId, List<DenominationQuantityUpdateRequestDto> updates) {
        List<DenominationBalanceDto> results = new ArrayList<>();

        for (DenominationQuantityUpdateRequestDto update : updates) {
            Long denominationId = Long.parseLong(update.getDenominationId());
            DenominationBalanceDto result = updateQuantity(cashDeskId, denominationId, update.getQuantity());
            results.add(result);
        }

        log.info("Batch címlet frissítés: cashDesk={}, {} tétel", cashDeskId, updates.size());
        return results;
    }

    /**
     * Adott valuta teljes értékének kiszámítása a címletekből
     */
    @Transactional(readOnly = true)
    public BigDecimal calculateTotal(UUID cashDeskId, Long currencyId) {
        return denominationBalanceRepository.sumTotalValueByCashDeskIdAndCurrencyId(cashDeskId, currencyId);
    }

    // ============ HELPER ============

    private DenominationBalanceDto toDto(DenominationBalance entity) {
        Denomination denom = entity.getDenomination();
        return DenominationBalanceDto.builder()
                .id(entity.getId().toString())
                .cashDeskId(entity.getCashDeskId().toString())
                .denominationId(String.valueOf(denom.getId()))
                .denominationValue(denom.getFaceValue())
                .denominationType(denom.getDenominationType().name())
                .currencyCode(denom.getCurrency().getCode())
                .quantity(entity.getQuantity())
                .totalValue(entity.getTotalValue())
                .updatedAt(entity.getUpdatedAt())
                .build();
    }
}
