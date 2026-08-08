package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.dto.denomination.DenominationBalanceDto;
import hu.puzzleir.valuta.dto.denomination.DenominationQuantityUpdateRequestDto;
import hu.puzzleir.valuta.entity.Denomination;
import hu.puzzleir.valuta.entity.DenominationBalance;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CashRegisterDeviceRepository;
import hu.puzzleir.valuta.repository.DenominationBalanceRepository;
import hu.puzzleir.valuta.repository.DenominationRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Pénztárgép címlet egyenleg szolgáltatás.
 */
@Service
@RequiredArgsConstructor
@Transactional(rollbackFor = Exception.class)
@Slf4j
public class DenominationBalanceService {

    private final DenominationBalanceRepository denominationBalanceRepository;
    private final DenominationRepository denominationRepository;
    private final CashRegisterDeviceRepository cashRegisterDeviceRepository;
    private final BranchRepository branchRepository;

    /**
     * Multi-tenant IDOR guard: a cashDeskId a hivo cegehez tartozik-e.
     *
     * <p>FK-077 (FR-2): a {@code denomination_balance.cash_desk_id} oszlop szemantikaja
     * a gyakorlatban FIOK (branch) UUID — a {@code ClosingWizardService.saveDenominationBalance}
     * a {@code branchId}-t irja bele, es a frontend is a {@code worker.branchId}-t kuldi.
     * A guard korabban KIZAROLAG a {@code cash_register_device} tabla PK-jat fogadta el,
     * ezert minden valos hivast {@code ResourceNotFoundException}-nal utasitott el (404),
     * amitol a Cimletezes oldal csendben kiurult. Ezert a guard mostantol MINDKET
     * ervenyes szemantikat elfogadja — fiok-UUID VAGY penztargep-eszkoz-id —, de
     * mindkettot a hivo cegere szurve, igy a tenant-izolacio valtozatlanul szoros
     * (cross-tenant VAGY nem letezo azonosito → 404, a letezes se szivarogjon).</p>
     *
     * <p>Csak controller-utak hivjak (getCashDeskDenominations/...ByCurrency/updateQuantity/
     * batchUpdate/calculateTotal); nincs @Scheduled/@Async/auth nelkuli hivo, ezert a
     * SecurityUtils.getCurrentCompanyId() biztonsagos.</p>
     */
    private void requireOwnCashDesk(UUID cashDeskId) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        if (cashDeskId == null) {
            throw new ResourceNotFoundException("Pénztár nem található: " + cashDeskId);
        }
        boolean ownBranch = branchRepository.existsByIdAndCompanyId(cashDeskId, companyId);
        boolean ownDevice = !ownBranch
                && cashRegisterDeviceRepository.existsByIdAndCompanyId(cashDeskId, companyId);
        if (!ownBranch && !ownDevice) {
            throw new ResourceNotFoundException("Pénztár nem található: " + cashDeskId);
        }
    }

    /**
     * Pénztárgép összes címletének lekérése
     */
    @Transactional(readOnly = true)
    public List<DenominationBalanceDto> getCashDeskDenominations(UUID cashDeskId) {
        requireOwnCashDesk(cashDeskId);
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
        requireOwnCashDesk(cashDeskId);
        return denominationBalanceRepository.findByCashDeskIdAndCurrencyId(cashDeskId, currencyId)
                .stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    /**
     * Egyedi címlet darabszám frissítése
     */
    public DenominationBalanceDto updateQuantity(UUID cashDeskId, Long denominationId, int quantity) {
        requireOwnCashDesk(cashDeskId);
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
        // FK-060: ez a karbantartó út nem kap zárási varázsló-dátumot, ezért a
        // ClosingWizardService.startWizard által is használt aktuális üzleti napot rögzíti.
        balance.setSubmissionDate(LocalDate.now());

        DenominationBalance saved = denominationBalanceRepository.save(balance);
        log.info("Címlet egyenleg frissítve: cashDesk={}, denomination={}, quantity={}", cashDeskId, denominationId, quantity);

        return toDto(saved);
    }

    /**
     * Batch címlet darabszám frissítés
     */
    public List<DenominationBalanceDto> batchUpdate(UUID cashDeskId, List<DenominationQuantityUpdateRequestDto> updates) {
        requireOwnCashDesk(cashDeskId);
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
        requireOwnCashDesk(cashDeskId);
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
