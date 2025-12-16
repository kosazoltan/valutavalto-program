package hu.puzzleir.valuta.service;

import com.puzzleir.backend.entity.Branch;
import com.puzzleir.backend.entity.Company;
import com.puzzleir.backend.exception.ResourceNotFoundException;
import com.puzzleir.backend.exception.ValidationException;
import com.puzzleir.backend.repository.BranchRepository;
import com.puzzleir.backend.repository.CompanyRepository;
import hu.puzzleir.valuta.entity.CashBalance;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.repository.CashBalanceRepository;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Kassza egyenleg szolgáltatás.
 *
 * Legacy: PENZTAR tábla kezelés, PILLALL (pillanat állapot)
 * - Valutánkénti készlet nyilvántartás
 * - Alacsony/magas készlet figyelmeztetés
 * - Napi nyitó/záró egyenleg
 */
@Service
@RequiredArgsConstructor
@Transactional
@Slf4j
public class CashBalanceService {

    private final CashBalanceRepository cashBalanceRepository;
    private final CurrencyRepository currencyRepository;
    private final CompanyRepository companyRepository;
    private final BranchRepository branchRepository;

    /**
     * Aktuális iroda összes egyenlegének lekérése
     */
    @Transactional(readOnly = true)
    public List<CashBalance> getCurrentBranchBalances() {
        UUID branchId = SecurityUtils.getCurrentBranchId();
        return cashBalanceRepository.findByBranchId(branchId);
    }

    /**
     * Egyenleg lekérése valuta alapján
     */
    @Transactional(readOnly = true)
    public CashBalance getBalanceByCurrency(Long currencyId) {
        UUID branchId = SecurityUtils.getCurrentBranchId();
        return cashBalanceRepository.findByBranchIdAndCurrencyId(branchId, currencyId)
                .orElseThrow(() -> new ResourceNotFoundException(
                    "Kassza egyenleg nem található ehhez a valutához"));
    }

    /**
     * Egyenleg lekérése valuta kód alapján
     */
    @Transactional(readOnly = true)
    public CashBalance getBalanceByCurrencyCode(String currencyCode) {
        Currency currency = currencyRepository.findByCode(currencyCode)
                .orElseThrow(() -> new ResourceNotFoundException("Valuta nem található: " + currencyCode));
        return getBalanceByCurrency(currency.getId());
    }

    /**
     * Összes egyenleg lekérése a céghez
     */
    @Transactional(readOnly = true)
    public List<CashBalance> getCompanyBalances() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return cashBalanceRepository.findByCompanyId(companyId);
    }

    /**
     * Alacsony készletű valuták
     *
     * Legacy: FIGYELMEZTETÉS - alacsony készlet
     */
    @Transactional(readOnly = true)
    public List<CashBalance> getLowBalanceAlerts() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return cashBalanceRepository.findLowBalances(companyId);
    }

    /**
     * Magas készletű valuták
     */
    @Transactional(readOnly = true)
    public List<CashBalance> getHighBalanceAlerts() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return cashBalanceRepository.findHighBalances(companyId);
    }

    /**
     * Egyenleg inicializálása új irodához
     */
    public void initializeBranchBalances(UUID branchId) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();

        Company company = companyRepository.findById(companyId)
                .orElseThrow(() -> new ResourceNotFoundException("Company nem található"));
        Branch branch = branchRepository.findById(branchId)
                .orElseThrow(() -> new ResourceNotFoundException("Iroda nem található"));

        // Összes aktív valutához egyenleg létrehozása
        List<Currency> currencies = currencyRepository.findAllActiveOrdered();

        for (Currency currency : currencies) {
            // Ellenőrzés, hogy nincs-e már
            if (cashBalanceRepository.findByBranchIdAndCurrencyId(branchId, currency.getId()).isEmpty()) {
                CashBalance balance = CashBalance.builder()
                        .company(company)
                        .branch(branch)
                        .currency(currency)
                        .currentBalance(BigDecimal.ZERO)
                        .openingBalance(BigDecimal.ZERO)
                        .build();
                cashBalanceRepository.save(balance);
                log.debug("Kassza egyenleg inicializálva: {} - {}", branch.getName(), currency.getCode());
            }
        }

        log.info("Iroda kassza egyenlegek inicializálva: {}", branch.getName());
    }

    /**
     * Egyenleg kézi módosítása (pénztár feltöltés/levétel)
     *
     * Legacy: PENZTARFELTOLTES, PENZTARLEVONÁS
     */
    public CashBalance adjustBalance(AdjustBalanceRequest request) {
        UUID branchId = SecurityUtils.getCurrentBranchId();

        // Manager vagy magasabb szint kell
        if (!SecurityUtils.isManagerOrAbove()) {
            throw new ValidationException("Egyenleg módosításhoz manager jogosultság szükséges!");
        }

        CashBalance balance = cashBalanceRepository.findByBranchIdAndCurrencyId(branchId, request.getCurrencyId())
                .orElseThrow(() -> new ResourceNotFoundException("Kassza egyenleg nem található"));

        BigDecimal oldBalance = balance.getCurrentBalance();

        if (request.isIncoming()) {
            balance.addBalance(request.getAmount());
            log.info("Kassza feltöltés: {} {} - {} -> {}",
                    balance.getCurrency().getCode(), request.getAmount(),
                    oldBalance, balance.getCurrentBalance());
        } else {
            if (balance.getCurrentBalance().compareTo(request.getAmount()) < 0) {
                throw new ValidationException("Nincs elegendő egyenleg a levonáshoz!");
            }
            balance.subtractBalance(request.getAmount());
            log.info("Kassza levonás: {} {} - {} -> {}",
                    balance.getCurrency().getCode(), request.getAmount(),
                    oldBalance, balance.getCurrentBalance());
        }

        return cashBalanceRepository.save(balance);
    }

    /**
     * Min/max limitek beállítása
     */
    public CashBalance setLimits(SetLimitsRequest request) {
        UUID branchId = SecurityUtils.getCurrentBranchId();

        if (!SecurityUtils.isManagerOrAbove()) {
            throw new ValidationException("Limit beállításhoz manager jogosultság szükséges!");
        }

        CashBalance balance = cashBalanceRepository.findByBranchIdAndCurrencyId(branchId, request.getCurrencyId())
                .orElseThrow(() -> new ResourceNotFoundException("Kassza egyenleg nem található"));

        if (request.getMinBalance() != null) {
            balance.setMinBalance(request.getMinBalance());
        }
        if (request.getMaxBalance() != null) {
            balance.setMaxBalance(request.getMaxBalance());
        }

        log.info("Kassza limitek frissítve: {} - min: {}, max: {}",
                balance.getCurrency().getCode(), balance.getMinBalance(), balance.getMaxBalance());

        return cashBalanceRepository.save(balance);
    }

    /**
     * Kassza összesítő (összes iroda)
     */
    @Transactional(readOnly = true)
    public List<CurrencyTotalBalance> getCompanyTotals() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        List<CashBalance> allBalances = cashBalanceRepository.findByCompanyId(companyId);

        return allBalances.stream()
                .collect(Collectors.groupingBy(
                    cb -> cb.getCurrency().getCode(),
                    Collectors.reducing(
                        BigDecimal.ZERO,
                        CashBalance::getCurrentBalance,
                        BigDecimal::add
                    )
                ))
                .entrySet().stream()
                .map(e -> new CurrencyTotalBalance(e.getKey(), e.getValue()))
                .collect(Collectors.toList());
    }

    /**
     * Napi egyenleg pillanatkép
     *
     * Legacy: PILLALL - pillanat állás
     */
    @Transactional(readOnly = true)
    public BranchBalanceSummary getBranchSummary() {
        UUID branchId = SecurityUtils.getCurrentBranchId();
        List<CashBalance> balances = cashBalanceRepository.findByBranchId(branchId);

        BigDecimal totalHuf = BigDecimal.ZERO;
        int lowAlerts = 0;
        int highAlerts = 0;

        for (CashBalance balance : balances) {
            if ("HUF".equals(balance.getCurrency().getCode())) {
                totalHuf = balance.getCurrentBalance();
            }
            if (balance.isLowBalance()) lowAlerts++;
            if (balance.isHighBalance()) highAlerts++;
        }

        return BranchBalanceSummary.builder()
                .totalCurrencies(balances.size())
                .hufBalance(totalHuf)
                .lowBalanceAlerts(lowAlerts)
                .highBalanceAlerts(highAlerts)
                .balances(balances)
                .build();
    }

    // ============ REQUEST/RESPONSE DTO-k ============

    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class AdjustBalanceRequest {
        private Long currencyId;
        private BigDecimal amount;
        private boolean incoming;
        private String reason;
    }

    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class SetLimitsRequest {
        private Long currencyId;
        private BigDecimal minBalance;
        private BigDecimal maxBalance;
    }

    @lombok.Data
    @lombok.AllArgsConstructor
    public static class CurrencyTotalBalance {
        private String currencyCode;
        private BigDecimal totalBalance;
    }

    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class BranchBalanceSummary {
        private int totalCurrencies;
        private BigDecimal hufBalance;
        private int lowBalanceAlerts;
        private int highBalanceAlerts;
        private List<CashBalance> balances;
    }
}
