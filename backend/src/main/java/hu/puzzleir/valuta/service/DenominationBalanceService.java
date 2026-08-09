package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.dto.denomination.DenominationBalanceDto;
import hu.puzzleir.valuta.dto.denomination.DenominationQuantityUpdateRequestDto;
import hu.puzzleir.valuta.dto.denomination.DenominationSelfCheckDto;
import hu.puzzleir.valuta.entity.CashBalance;
import hu.puzzleir.valuta.entity.Denomination;
import hu.puzzleir.valuta.entity.DenominationBalance;
import hu.puzzleir.valuta.entity.DenominationCategory;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CashBalanceRepository;
import hu.puzzleir.valuta.repository.CashRegisterDeviceRepository;
import hu.puzzleir.valuta.repository.DenominationBalanceRepository;
import hu.puzzleir.valuta.repository.DenominationRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
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
    private final CashBalanceRepository cashBalanceRepository;

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
     * Egyedi címlet darabszám frissítése (kategória nélkül — EVENING, visszamenőleg kompatibilis).
     */
    public DenominationBalanceDto updateQuantity(UUID cashDeskId, Long denominationId, int quantity) {
        return updateQuantity(cashDeskId, denominationId, quantity, DenominationCategory.EVENING);
    }

    /**
     * Egyedi címlet darabszám frissítése, EXPLICIT kategóriával.
     *
     * <p>FK-078 (FR-3): korábban minden karbantartó mentés {@code EVENING}-ként íródott,
     * függetlenül attól, melyik felületről indult. A becímletező oldal mostantól átadja a
     * tényleges kategóriát ({@code EVENING} vagy {@code HANDLING_FEE}), így a
     * {@code denomination_balance} sor helyesen tagelődik.</p>
     *
     * <p>FK-078 (FR-2): ez az út SEMMILYEN zárási munkamenetet nem indít — a mentés
     * napközben, korlátlanul ismételhető.</p>
     */
    public DenominationBalanceDto updateQuantity(UUID cashDeskId, Long denominationId, int quantity,
                                                 DenominationCategory category) {
        requireOwnCashDesk(cashDeskId);
        DenominationCategory effectiveCategory =
                category == null ? DenominationCategory.EVENING : category;
        DenominationBalance balance = denominationBalanceRepository
                .findByCashDeskIdAndDenominationIdAndCategory(cashDeskId, denominationId, effectiveCategory)
                .orElseGet(() -> {
                    Denomination denom = denominationRepository.findById(denominationId)
                            .orElseThrow(() -> new ResourceNotFoundException("Címlet nem található: " + denominationId));
                    return DenominationBalance.builder()
                            .cashDeskId(cashDeskId)
                            .denomination(denom)
                            .quantity(0)
                            .totalValue(BigDecimal.ZERO)
                            .denominationCategory(effectiveCategory)
                            .build();
                });

        balance.setQuantity(quantity);
        balance.setDenominationCategory(effectiveCategory);
        balance.recalculateTotalValue();
        // FK-060: ez a karbantartó út nem kap zárási varázsló-dátumot, ezért a
        // ClosingWizardService.startWizard által is használt aktuális üzleti napot rögzíti.
        balance.setSubmissionDate(LocalDate.now());

        DenominationBalance saved = denominationBalanceRepository.save(balance);
        log.info("Címlet egyenleg frissítve: cashDesk={}, denomination={}, quantity={}, category={}",
                cashDeskId, denominationId, quantity, effectiveCategory);

        return toDto(saved);
    }

    /**
     * Batch címlet darabszám frissítés (kategória nélkül — EVENING).
     */
    public List<DenominationBalanceDto> batchUpdate(UUID cashDeskId, List<DenominationQuantityUpdateRequestDto> updates) {
        return batchUpdate(cashDeskId, updates, DenominationCategory.EVENING);
    }

    /**
     * Batch címlet darabszám frissítés EXPLICIT kategóriával (FK-078 FR-3).
     */
    public List<DenominationBalanceDto> batchUpdate(UUID cashDeskId,
                                                    List<DenominationQuantityUpdateRequestDto> updates,
                                                    DenominationCategory category) {
        requireOwnCashDesk(cashDeskId);
        DenominationCategory effectiveCategory =
                category == null ? DenominationCategory.EVENING : category;
        List<DenominationBalanceDto> results = new ArrayList<>();

        for (DenominationQuantityUpdateRequestDto update : updates) {
            Long denominationId = Long.parseLong(update.getDenominationId());
            DenominationBalanceDto result =
                    updateQuantity(cashDeskId, denominationId, update.getQuantity(), effectiveCategory);
            results.add(result);
        }

        log.info("Batch címlet frissítés: cashDesk={}, {} tétel, kategória={}",
                cashDeskId, updates.size(), effectiveCategory);
        return results;
    }

    /**
     * FK-078 FR-4: napközbeni önellenőrzés — a MAI napra becímletezett összeg összevetése a
     * könyv szerinti {@code cash_balance.currentBalance}-szal, PÉNZNEMENKÉNT.
     *
     * <p>Kizárólag tájékoztató: a hívó felület zöld/piros jelzést mutat, de semmit nem blokkol
     * (FK-078 Scope OUT). Csak azokra a pénznemekre ad sort, amelyekre a kasszának van
     * {@code cash_balance} sora — a többihez nincs mihez viszonyítani.</p>
     *
     * <p>A {@code cashDeskId} szemantikája itt is fiók-UUID (FK-077, lásd
     * {@link #requireOwnCashDesk(UUID)}); a {@code cash_balance} lekérdezés ezért
     * branch + company szűréssel megy — cross-tenant szivárgás nélkül.</p>
     */
    @Transactional(readOnly = true)
    public List<DenominationSelfCheckDto> selfCheck(UUID cashDeskId, DenominationCategory category) {
        requireOwnCashDesk(cashDeskId);
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        DenominationCategory effectiveCategory =
                category == null ? DenominationCategory.EVENING : category;
        LocalDate today = LocalDate.now();

        // Becimletezett osszeg penznemenkent: [currencyCode, SUM(totalValue)]
        Map<String, BigDecimal> denominated = new HashMap<>();
        for (Object[] row : denominationBalanceRepository
                .sumActualStockByCurrency(cashDeskId, today, effectiveCategory)) {
            denominated.put((String) row[0], (BigDecimal) row[1]);
        }

        List<DenominationSelfCheckDto> result = new ArrayList<>();
        for (CashBalance cashBalance : cashBalanceRepository
                .findByBranchIdAndCompanyId(cashDeskId, companyId)) {
            String currencyCode = cashBalance.getCurrency().getCode();
            BigDecimal denominatedAmount = denominated
                    .getOrDefault(currencyCode, BigDecimal.ZERO)
                    .setScale(2, RoundingMode.HALF_UP);
            BigDecimal expected = (cashBalance.getCurrentBalance() == null
                    ? BigDecimal.ZERO : cashBalance.getCurrentBalance())
                    .setScale(2, RoundingMode.HALF_UP);
            BigDecimal difference = denominatedAmount.subtract(expected);

            result.add(DenominationSelfCheckDto.builder()
                    .currencyCode(currencyCode)
                    .currencyId(cashBalance.getCurrency().getId())
                    .denominatedAmount(denominatedAmount)
                    .expectedBalance(expected)
                    .difference(difference)
                    .matches(difference.compareTo(BigDecimal.ZERO) == 0)
                    .build());
        }
        return result;
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
