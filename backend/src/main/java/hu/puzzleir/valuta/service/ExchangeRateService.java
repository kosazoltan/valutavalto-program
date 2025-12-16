package hu.puzzleir.valuta.service;

import com.puzzleir.backend.entity.Branch;
import com.puzzleir.backend.entity.Company;
import com.puzzleir.backend.exception.ResourceNotFoundException;
import com.puzzleir.backend.exception.ValidationException;
import com.puzzleir.backend.repository.BranchRepository;
import com.puzzleir.backend.repository.CompanyRepository;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.ExchangeRate;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.repository.ExchangeRateRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.UUID;

/**
 * Árfolyam szolgáltatás.
 *
 * Legacy: ARFOLYAM tábla kezelés, ARFREG, ARFVALT funkciók
 */
@Service
@RequiredArgsConstructor
@Transactional
@Slf4j
public class ExchangeRateService {

    private final ExchangeRateRepository exchangeRateRepository;
    private final CurrencyRepository currencyRepository;
    private final CompanyRepository companyRepository;
    private final BranchRepository branchRepository;

    /**
     * Aktuális árfolyam lekérése egy valutához
     */
    @Transactional(readOnly = true)
    public ExchangeRate getCurrentRate(Long currencyId) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        UUID branchId = SecurityUtils.getCurrentBranchId();

        return exchangeRateRepository.findLatestRate(companyId, currencyId, branchId)
                .orElseThrow(() -> new ResourceNotFoundException(
                    "Nincs érvényes árfolyam ehhez a valutához: " + currencyId));
    }

    /**
     * Aktuális árfolyam lekérése valuta kód alapján
     */
    @Transactional(readOnly = true)
    public ExchangeRate getCurrentRateByCode(String currencyCode) {
        Currency currency = currencyRepository.findByCode(currencyCode)
                .orElseThrow(() -> new ResourceNotFoundException("Valuta nem található: " + currencyCode));
        return getCurrentRate(currency.getId());
    }

    /**
     * Összes aktuális árfolyam lekérése
     */
    @Transactional(readOnly = true)
    public List<ExchangeRate> getAllCurrentRates() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return exchangeRateRepository.findActiveRatesByDate(companyId, LocalDate.now());
    }

    /**
     * Megfelelő árfolyam meghatározása összeg alapján (limit szintek)
     *
     * Legacy: ARFOLYAM tábla LIMIT1, LIMIT2, LIMIT3 mezők alapján
     */
    @Transactional(readOnly = true)
    public BigDecimal getBuyRateForAmount(Long currencyId, BigDecimal hufAmount) {
        ExchangeRate rate = getCurrentRate(currencyId);
        return rate.getBuyRateForAmount(hufAmount);
    }

    @Transactional(readOnly = true)
    public BigDecimal getSellRateForAmount(Long currencyId, BigDecimal hufAmount) {
        ExchangeRate rate = getCurrentRate(currencyId);
        return rate.getSellRateForAmount(hufAmount);
    }

    /**
     * Új árfolyam létrehozása
     */
    public ExchangeRate createExchangeRate(CreateExchangeRateRequest request) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();

        Company company = companyRepository.findById(companyId)
                .orElseThrow(() -> new ResourceNotFoundException("Company nem található"));

        Currency currency = currencyRepository.findById(request.getCurrencyId())
                .orElseThrow(() -> new ResourceNotFoundException("Valuta nem található: " + request.getCurrencyId()));

        // Validáció: eladási árfolyam > vételi árfolyam
        if (request.getBaseBuyRate().compareTo(request.getBaseSellRate()) >= 0) {
            throw new ValidationException("Az eladási árfolyamnak nagyobbnak kell lennie a vételinél!");
        }

        Branch branch = null;
        if (request.getBranchId() != null) {
            branch = branchRepository.findById(request.getBranchId())
                    .orElseThrow(() -> new ResourceNotFoundException("Iroda nem található"));
        }

        // Régi árfolyamok inaktiválása
        deactivateOldRates(companyId, currency.getId());

        ExchangeRate rate = ExchangeRate.builder()
                .company(company)
                .branch(branch)
                .currency(currency)
                .validDate(LocalDate.now())
                .validTime(LocalTime.now())
                .baseBuyRate(request.getBaseBuyRate())
                .baseSellRate(request.getBaseSellRate())
                .limit1Amount(request.getLimit1Amount())
                .limit1BuyRate(request.getLimit1BuyRate())
                .limit1SellRate(request.getLimit1SellRate())
                .limit2Amount(request.getLimit2Amount())
                .limit2BuyRate(request.getLimit2BuyRate())
                .limit2SellRate(request.getLimit2SellRate())
                .limit3Amount(request.getLimit3Amount())
                .limit3BuyRate(request.getLimit3BuyRate())
                .limit3SellRate(request.getLimit3SellRate())
                .officialRate(request.getOfficialRate())
                .active(true)
                .createdBy(SecurityUtils.getCurrentWorkerCode())
                .build();

        ExchangeRate saved = exchangeRateRepository.save(rate);
        log.info("Új árfolyam létrehozva: {} - vétel: {}, eladás: {}",
                currency.getCode(), saved.getBaseBuyRate(), saved.getBaseSellRate());

        return saved;
    }

    /**
     * Árfolyam módosítás kedvezménnyel
     *
     * Legacy: ARFVALT - kedvezményes árfolyam, supervisor ellenőrzés >2% felett
     */
    public ExchangeRate applyDiscount(Long rateId, BigDecimal discountPercent) {
        ExchangeRate rate = exchangeRateRepository.findById(rateId)
                .orElseThrow(() -> new ResourceNotFoundException("Árfolyam nem található"));

        // 2% feletti kedvezményhez supervisor jog kell
        if (discountPercent.compareTo(new BigDecimal("2.0")) > 0 && !SecurityUtils.isSupervisorOrAbove()) {
            throw new ValidationException("2% feletti kedvezményhez supervisor jogosultság szükséges!");
        }

        // Kedvezményes árfolyam számítása
        BigDecimal multiplier = BigDecimal.ONE.subtract(discountPercent.divide(new BigDecimal("100")));
        BigDecimal newBuyRate = rate.getBaseBuyRate().multiply(multiplier);
        BigDecimal newSellRate = rate.getBaseSellRate().multiply(multiplier);

        log.info("Árfolyam kedvezmény alkalmazva: {}% - új vétel: {}, eladás: {}",
                discountPercent, newBuyRate, newSellRate);

        // Visszaadjuk a módosított árfolyamot (tranzakció szintű, nem perzisztáljuk)
        rate.setBaseBuyRate(newBuyRate);
        rate.setBaseSellRate(newSellRate);
        return rate;
    }

    /**
     * Árfolyam történet lekérése
     */
    @Transactional(readOnly = true)
    public List<ExchangeRate> getRateHistory(Long currencyId, LocalDate startDate, LocalDate endDate) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return exchangeRateRepository.findRateHistory(companyId, currencyId, startDate, endDate);
    }

    /**
     * Régi árfolyamok inaktiválása
     */
    private void deactivateOldRates(UUID companyId, Long currencyId) {
        UUID branchId = SecurityUtils.getCurrentBranchId();
        List<ExchangeRate> oldRates = exchangeRateRepository.findCurrentRate(companyId, currencyId, branchId);
        for (ExchangeRate oldRate : oldRates) {
            oldRate.setActive(false);
            exchangeRateRepository.save(oldRate);
        }
    }

    /**
     * Árfolyam létrehozás request DTO (belső osztály)
     */
    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class CreateExchangeRateRequest {
        private Long currencyId;
        private UUID branchId;
        private BigDecimal baseBuyRate;
        private BigDecimal baseSellRate;
        private BigDecimal limit1Amount;
        private BigDecimal limit1BuyRate;
        private BigDecimal limit1SellRate;
        private BigDecimal limit2Amount;
        private BigDecimal limit2BuyRate;
        private BigDecimal limit2SellRate;
        private BigDecimal limit3Amount;
        private BigDecimal limit3BuyRate;
        private BigDecimal limit3SellRate;
        private BigDecimal officialRate;
    }
}
