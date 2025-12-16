package hu.puzzleir.valuta.service;

import com.puzzleir.backend.entity.Branch;
import com.puzzleir.backend.entity.Company;
import com.puzzleir.backend.exception.ResourceNotFoundException;
import com.puzzleir.backend.exception.ValidationException;
import com.puzzleir.backend.repository.BranchRepository;
import com.puzzleir.backend.repository.CompanyRepository;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.Denomination;
import hu.puzzleir.valuta.entity.DenominationType;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.repository.DenominationRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.*;
import java.util.stream.Collectors;

/**
 * Címletezés szolgáltatás.
 *
 * Legacy: CIMLET tábla kezelés - napi zárás címletvalidálás
 * 14-féle HUF címlet: 20000, 10000, 5000, 2000, 1000, 500, 200, 100, 50, 20, 10, 5, 2, 1
 */
@Service
@RequiredArgsConstructor
@Transactional
@Slf4j
public class DenominationService {

    private final DenominationRepository denominationRepository;
    private final CurrencyRepository currencyRepository;
    private final CompanyRepository companyRepository;
    private final BranchRepository branchRepository;

    // HUF címletek (legacy kompatibilitás)
    private static final BigDecimal[] HUF_DENOMINATIONS = {
        new BigDecimal("20000"),
        new BigDecimal("10000"),
        new BigDecimal("5000"),
        new BigDecimal("2000"),
        new BigDecimal("1000"),
        new BigDecimal("500"),
        new BigDecimal("200"),
        new BigDecimal("100"),
        new BigDecimal("50"),
        new BigDecimal("20"),
        new BigDecimal("10"),
        new BigDecimal("5"),
        new BigDecimal("2"),
        new BigDecimal("1")
    };

    /**
     * Címletek lekérdezése az aktuális irodához és valutához
     */
    @Transactional(readOnly = true)
    public List<Denomination> getDenominations(Long currencyId) {
        UUID branchId = SecurityUtils.getCurrentBranchId();
        return denominationRepository.findByBranchAndCurrency(branchId, currencyId);
    }

    /**
     * Címletek lekérdezése valuta kód alapján
     */
    @Transactional(readOnly = true)
    public List<Denomination> getDenominationsByCurrencyCode(String currencyCode) {
        Currency currency = currencyRepository.findByCode(currencyCode)
                .orElseThrow(() -> new ResourceNotFoundException("Valuta nem található: " + currencyCode));
        return getDenominations(currency.getId());
    }

    /**
     * Összes címlet az aktuális irodához
     */
    @Transactional(readOnly = true)
    public List<Denomination> getAllBranchDenominations() {
        UUID branchId = SecurityUtils.getCurrentBranchId();
        return denominationRepository.findByBranchId(branchId);
    }

    /**
     * Alacsony készletű címletek figyelmeztetés
     */
    @Transactional(readOnly = true)
    public List<Denomination> getLowStockAlerts() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return denominationRepository.findLowStock(companyId);
    }

    /**
     * Címlet készlet módosítása
     *
     * Legacy: CIMLET frissítés
     */
    public Denomination updateDenominationQuantity(UpdateDenominationRequest request) {
        UUID branchId = SecurityUtils.getCurrentBranchId();

        Denomination denomination = denominationRepository
                .findByBranchIdAndCurrencyIdAndFaceValue(branchId, request.getCurrencyId(), request.getFaceValue())
                .orElseThrow(() -> new ResourceNotFoundException("Címlet nem található"));

        int oldQuantity = denomination.getQuantity();
        denomination.setQuantity(request.getNewQuantity());

        Denomination saved = denominationRepository.save(denomination);

        log.info("Címlet frissítve: {} {} - {} db -> {} db",
                denomination.getCurrency().getCode(), request.getFaceValue(),
                oldQuantity, request.getNewQuantity());

        return saved;
    }

    /**
     * Címletezés validálás (napi záráshoz)
     *
     * Legacy: NAPZAR - címletezés ellenőrzés
     * Összehasonlítja a címletezett összeget a kassza egyenleggel
     */
    public DenominationValidationResult validateDenomination(Long currencyId, BigDecimal expectedBalance) {
        UUID branchId = SecurityUtils.getCurrentBranchId();

        List<Denomination> denominations = denominationRepository.findByBranchAndCurrency(branchId, currencyId);

        BigDecimal denominatedTotal = denominations.stream()
                .map(Denomination::getTotalValue)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal difference = denominatedTotal.subtract(expectedBalance);
        boolean isValid = difference.compareTo(BigDecimal.ZERO) == 0;

        DenominationValidationResult result = DenominationValidationResult.builder()
                .currencyId(currencyId)
                .expectedBalance(expectedBalance)
                .denominatedTotal(denominatedTotal)
                .difference(difference)
                .isValid(isValid)
                .denominations(denominations)
                .build();

        if (!isValid) {
            log.warn("Címletezés eltérés: {} - várt: {}, címletezett: {}, különbség: {}",
                    denominations.isEmpty() ? "?" : denominations.get(0).getCurrency().getCode(),
                    expectedBalance, denominatedTotal, difference);
        }

        return result;
    }

    /**
     * Tömeges címlet frissítés (napi zárás űrlap)
     */
    public List<Denomination> bulkUpdateDenominations(List<UpdateDenominationRequest> requests) {
        List<Denomination> updated = new ArrayList<>();

        for (UpdateDenominationRequest request : requests) {
            updated.add(updateDenominationQuantity(request));
        }

        return updated;
    }

    /**
     * Címletek inicializálása új irodához
     */
    public void initializeBranchDenominations(UUID branchId) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();

        Company company = companyRepository.findById(companyId)
                .orElseThrow(() -> new ResourceNotFoundException("Company nem található"));
        Branch branch = branchRepository.findById(branchId)
                .orElseThrow(() -> new ResourceNotFoundException("Iroda nem található"));

        // HUF címletek inicializálása
        Currency huf = currencyRepository.findByCode("HUF")
                .orElseThrow(() -> new ResourceNotFoundException("HUF valuta nem található"));

        for (BigDecimal faceValue : HUF_DENOMINATIONS) {
            if (denominationRepository.findByBranchIdAndCurrencyIdAndFaceValue(branchId, huf.getId(), faceValue).isEmpty()) {
                DenominationType type = faceValue.compareTo(new BigDecimal("100")) >= 0
                        ? DenominationType.BANKNOTE
                        : DenominationType.COIN;

                Denomination denomination = Denomination.builder()
                        .company(company)
                        .branch(branch)
                        .currency(huf)
                        .faceValue(faceValue)
                        .denominationType(type)
                        .quantity(0)
                        .active(true)
                        .build();
                denominationRepository.save(denomination);
            }
        }

        log.info("HUF címletek inicializálva irodához: {}", branch.getName());
    }

    /**
     * Címletezés összesítő
     */
    @Transactional(readOnly = true)
    public DenominationSummary getDenominationSummary(Long currencyId) {
        UUID branchId = SecurityUtils.getCurrentBranchId();

        List<Denomination> denominations = denominationRepository.findByBranchAndCurrency(branchId, currencyId);

        BigDecimal totalValue = denominations.stream()
                .map(Denomination::getTotalValue)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        int totalPieces = denominations.stream()
                .mapToInt(Denomination::getQuantity)
                .sum();

        long banknoteCount = denominations.stream()
                .filter(d -> d.getDenominationType() == DenominationType.BANKNOTE)
                .mapToInt(Denomination::getQuantity)
                .sum();

        long coinCount = denominations.stream()
                .filter(d -> d.getDenominationType() == DenominationType.COIN)
                .mapToInt(Denomination::getQuantity)
                .sum();

        return DenominationSummary.builder()
                .currencyId(currencyId)
                .currencyCode(denominations.isEmpty() ? null : denominations.get(0).getCurrency().getCode())
                .totalValue(totalValue)
                .totalPieces(totalPieces)
                .banknoteCount((int) banknoteCount)
                .coinCount((int) coinCount)
                .denominations(denominations)
                .build();
    }

    /**
     * Optimális címlet kiadás számítása (visszajáró)
     *
     * Legacy: VISSZAJARO - optimális címlet kombináció
     */
    @Transactional(readOnly = true)
    public Map<BigDecimal, Integer> calculateOptimalChange(Long currencyId, BigDecimal amount) {
        UUID branchId = SecurityUtils.getCurrentBranchId();

        List<Denomination> denominations = denominationRepository.findByBranchAndCurrency(branchId, currencyId);
        Map<BigDecimal, Integer> result = new LinkedHashMap<>();

        BigDecimal remaining = amount;

        // Nagyobb címletektől kezdve
        for (Denomination denom : denominations) {
            if (denom.getQuantity() > 0 && remaining.compareTo(denom.getFaceValue()) >= 0) {
                int needed = remaining.divideToIntegralValue(denom.getFaceValue()).intValue();
                int available = Math.min(needed, denom.getQuantity());

                if (available > 0) {
                    result.put(denom.getFaceValue(), available);
                    remaining = remaining.subtract(denom.getFaceValue().multiply(BigDecimal.valueOf(available)));
                }
            }

            if (remaining.compareTo(BigDecimal.ZERO) == 0) {
                break;
            }
        }

        if (remaining.compareTo(BigDecimal.ZERO) > 0) {
            log.warn("Nem sikerült teljes visszajárót kiadni: {} maradék", remaining);
        }

        return result;
    }

    // ============ REQUEST/RESPONSE DTO-k ============

    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class UpdateDenominationRequest {
        private Long currencyId;
        private BigDecimal faceValue;
        private Integer newQuantity;
    }

    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class DenominationValidationResult {
        private Long currencyId;
        private BigDecimal expectedBalance;
        private BigDecimal denominatedTotal;
        private BigDecimal difference;
        private boolean isValid;
        private List<Denomination> denominations;
    }

    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class DenominationSummary {
        private Long currencyId;
        private String currencyCode;
        private BigDecimal totalValue;
        private int totalPieces;
        private int banknoteCount;
        private int coinCount;
        private List<Denomination> denominations;
    }
}
