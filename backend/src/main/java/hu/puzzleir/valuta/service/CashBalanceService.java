package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.entity.CashBalance;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.repository.CashBalanceRepository;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import hu.puzzleir.valuta.entity.ExchangeRate;
import hu.puzzleir.valuta.repository.ExchangeRateRepository;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
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
    private final ExchangeRateRepository exchangeRateRepository;

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
     * HIGH FIX #9: Negatív készlet ellenőrzés ELADÁSNÁL.
     * Ellenőrzi, hogy az adott valutából van-e elegendő készlet a kiadáshoz.
     *
     * @param currencyId valuta ID
     * @param amount     kiadandó összeg
     * @throws ValidationException ha nincs elegendő készlet (negatívba menne)
     */
    public void validateSufficientBalance(Long currencyId, BigDecimal amount) {
        UUID branchId = SecurityUtils.getCurrentBranchId();
        CashBalance balance = cashBalanceRepository.findByBranchIdAndCurrencyId(branchId, currencyId)
                .orElseThrow(() -> new ResourceNotFoundException("Kassza egyenleg nem található"));

        if (balance.getCurrentBalance().compareTo(amount) < 0) {
            throw new ValidationException(String.format(
                "Nincs elegendő %s készlet! Jelenlegi: %s, szükséges: %s",
                balance.getCurrency().getCode(),
                balance.getCurrentBalance().toPlainString(),
                amount.toPlainString()));
        }
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
            // HIGH FIX #9: Negatív készlet ellenőrzés — ne lehessen mínuszba menni
            if (balance.getCurrentBalance().compareTo(request.getAmount()) < 0) {
                throw new ValidationException(String.format(
                    "Nincs elegendő %s egyenleg a levonáshoz! Jelenlegi: %s, kért: %s",
                    balance.getCurrency().getCode(),
                    balance.getCurrentBalance().toPlainString(),
                    request.getAmount().toPlainString()));
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

    /**
     * Részletes pillanat állás HUF egyenértékekkel
     *
     * Legacy: PILLALL - pillanat állás részletes
     * - Minden valuta egyenleg
     * - Aktuális árfolyam
     * - HUF egyenérték
     * - Napi változás
     */
    @Transactional(readOnly = true)
    public DetailedCashPosition getDetailedCashPosition() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        UUID branchId = SecurityUtils.getCurrentBranchId();

        List<CashBalance> balances = cashBalanceRepository.findByBranchId(branchId);
        List<CashPositionItem> items = new ArrayList<>();

        BigDecimal totalHufValue = BigDecimal.ZERO;
        BigDecimal totalOpeningHufValue = BigDecimal.ZERO;
        int lowAlerts = 0;
        int highAlerts = 0;

        for (CashBalance balance : balances) {
            Currency currency = balance.getCurrency();
            BigDecimal currentBalance = balance.getCurrentBalance();
            BigDecimal openingBalance = balance.getOpeningBalance() != null ? balance.getOpeningBalance() : BigDecimal.ZERO;

            // Árfolyam lekérése
            BigDecimal rate = BigDecimal.ONE; // HUF-nak 1
            BigDecimal buyRate = BigDecimal.ONE;
            BigDecimal sellRate = BigDecimal.ONE;

            if (!"HUF".equals(currency.getCode())) {
                Optional<ExchangeRate> exchangeRate = exchangeRateRepository.findLatestRate(companyId, currency.getId(), branchId);
                if (exchangeRate.isPresent()) {
                    ExchangeRate er = exchangeRate.get();
                    if (er.getBaseBuyRate() != null && er.getBaseSellRate() != null) {
                        buyRate = er.getBaseBuyRate();
                        sellRate = er.getBaseSellRate();
                        // Középárfolyam HUF értékhez
                        rate = buyRate.add(sellRate).divide(BigDecimal.valueOf(2), 4, RoundingMode.HALF_UP);
                    }
                }
            }

            // HUF egyenérték számítás
            BigDecimal hufValue = currentBalance.multiply(rate).setScale(0, RoundingMode.HALF_UP);
            BigDecimal openingHufValue = openingBalance.multiply(rate).setScale(0, RoundingMode.HALF_UP);
            BigDecimal dailyChange = currentBalance.subtract(openingBalance);
            BigDecimal dailyChangeHuf = hufValue.subtract(openingHufValue);

            totalHufValue = totalHufValue.add(hufValue);
            totalOpeningHufValue = totalOpeningHufValue.add(openingHufValue);

            if (balance.isLowBalance()) lowAlerts++;
            if (balance.isHighBalance()) highAlerts++;

            CashPositionItem item = CashPositionItem.builder()
                    .currencyId(currency.getId())
                    .currencyCode(currency.getCode())
                    .currencyName(currency.getName())
                    .currentBalance(currentBalance)
                    .openingBalance(openingBalance)
                    .dailyChange(dailyChange)
                    .buyRate(buyRate)
                    .sellRate(sellRate)
                    .midRate(rate)
                    .hufValue(hufValue)
                    .openingHufValue(openingHufValue)
                    .dailyChangeHuf(dailyChangeHuf)
                    .minBalance(balance.getMinBalance())
                    .maxBalance(balance.getMaxBalance())
                    .isLowBalance(balance.isLowBalance())
                    .isHighBalance(balance.isHighBalance())
                    .lastTransactionAt(balance.getLastTransactionAt())
                    .build();

            items.add(item);
        }

        return DetailedCashPosition.builder()
                .branchId(branchId)
                .timestamp(LocalDateTime.now())
                .items(items)
                .totalHufValue(totalHufValue)
                .totalOpeningHufValue(totalOpeningHufValue)
                .totalDailyChangeHuf(totalHufValue.subtract(totalOpeningHufValue))
                .currencyCount(items.size())
                .lowBalanceAlerts(lowAlerts)
                .highBalanceAlerts(highAlerts)
                .build();
    }

    /**
     * Cég szintű pillanat állás (összes iroda összesítve)
     */
    @Transactional(readOnly = true)
    public CompanyCashPosition getCompanyCashPosition() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();

        List<CashBalance> allBalances = cashBalanceRepository.findByCompanyId(companyId);

        // Csoportosítás valutánként
        List<CompanyCurrencyPosition> currencyPositions = allBalances.stream()
                .collect(Collectors.groupingBy(cb -> cb.getCurrency().getCode()))
                .entrySet().stream()
                .map(entry -> {
                    String currencyCode = entry.getKey();
                    List<CashBalance> balances = entry.getValue();

                    BigDecimal totalBalance = balances.stream()
                            .map(CashBalance::getCurrentBalance)
                            .reduce(BigDecimal.ZERO, BigDecimal::add);

                    int branchCount = balances.size();

                    // Árfolyam (első elem alapján)
                    BigDecimal rate = BigDecimal.ONE;
                    if (!"HUF".equals(currencyCode) && !balances.isEmpty()) {
                        CashBalance first = balances.get(0);
                        Optional<ExchangeRate> er = exchangeRateRepository.findLatestRate(
                                companyId, first.getCurrency().getId(), first.getBranch().getId());
                        if (er.isPresent()
                                && er.get().getBaseBuyRate() != null
                                && er.get().getBaseSellRate() != null) {
                            rate = er.get().getBaseBuyRate().add(er.get().getBaseSellRate())
                                    .divide(BigDecimal.valueOf(2), 4, RoundingMode.HALF_UP);
                        }
                    }

                    BigDecimal hufValue = totalBalance.multiply(rate).setScale(0, RoundingMode.HALF_UP);

                    return CompanyCurrencyPosition.builder()
                            .currencyCode(currencyCode)
                            .totalBalance(totalBalance)
                            .branchCount(branchCount)
                            .hufValue(hufValue)
                            .build();
                })
                .collect(Collectors.toList());

        BigDecimal grandTotalHuf = currencyPositions.stream()
                .map(CompanyCurrencyPosition::getHufValue)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        return CompanyCashPosition.builder()
                .companyId(companyId)
                .timestamp(LocalDateTime.now())
                .currencyPositions(currencyPositions)
                .grandTotalHuf(grandTotalHuf)
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

    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class CashPositionItem {
        private Long currencyId;
        private String currencyCode;
        private String currencyName;
        private BigDecimal currentBalance;
        private BigDecimal openingBalance;
        private BigDecimal dailyChange;
        private BigDecimal buyRate;
        private BigDecimal sellRate;
        private BigDecimal midRate;
        private BigDecimal hufValue;
        private BigDecimal openingHufValue;
        private BigDecimal dailyChangeHuf;
        private BigDecimal minBalance;
        private BigDecimal maxBalance;
        private boolean isLowBalance;
        private boolean isHighBalance;
        private LocalDateTime lastTransactionAt;
    }

    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class DetailedCashPosition {
        private UUID branchId;
        private LocalDateTime timestamp;
        private List<CashPositionItem> items;
        private BigDecimal totalHufValue;
        private BigDecimal totalOpeningHufValue;
        private BigDecimal totalDailyChangeHuf;
        private int currencyCount;
        private int lowBalanceAlerts;
        private int highBalanceAlerts;
    }

    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class CompanyCurrencyPosition {
        private String currencyCode;
        private BigDecimal totalBalance;
        private int branchCount;
        private BigDecimal hufValue;
    }

    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class CompanyCashPosition {
        private UUID companyId;
        private LocalDateTime timestamp;
        private List<CompanyCurrencyPosition> currencyPositions;
        private BigDecimal grandTotalHuf;
    }
}
