package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.ExchangeRate;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.repository.ExchangeRateRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import org.springframework.beans.factory.annotation.Value;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.temporal.ChronoUnit;
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

    /** Árfolyam maximális kora órában (0 = nincs limit) */
    @Value("${exchange-rate.max-age-hours:24}")
    private int maxAgeHours;

    /**
     * Aktuális árfolyam lekérése egy valutához
     */
    @Transactional(readOnly = true)
    public ExchangeRate getCurrentRate(Long currencyId) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        UUID branchId = SecurityUtils.getCurrentBranchId();

        ExchangeRate rate = exchangeRateRepository.findLatestRate(companyId, currencyId, branchId)
                .orElseThrow(() -> new ResourceNotFoundException(
                    "Nincs érvényes árfolyam ehhez a valutához: " + currencyId));

        // Árfolyam frissesség ellenőrzése
        validateRateFreshness(rate);

        return rate;
    }

    /**
     * Árfolyam frissesség validálása.
     * Ha az árfolyam régebbi mint a konfigurált max kor, elutasítjuk.
     */
    private void validateRateFreshness(ExchangeRate rate) {
        if (maxAgeHours <= 0) {
            return; // nincs korhatár
        }
        LocalDateTime rateTimestamp = LocalDateTime.of(rate.getValidDate(), rate.getValidTime());
        long hoursOld = ChronoUnit.HOURS.between(rateTimestamp, LocalDateTime.now());
        if (hoursOld > maxAgeHours) {
            log.warn("Lejárt árfolyam: {} — {} órás (max: {} óra)",
                    rate.getCurrency().getCode(), hoursOld, maxAgeHours);
            throw new ValidationException(
                String.format("Az árfolyam lejárt! (Utolsó frissítés: %s %s, %d órája — maximum: %d óra). " +
                              "Kérjük frissítse az árfolyamokat.",
                    rate.getValidDate(), rate.getValidTime(), hoursOld, maxAgeHours));
        }
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

        // Validáció: árfolyamok pozitívak
        if (request.getBaseBuyRate() == null || request.getBaseBuyRate().compareTo(BigDecimal.ZERO) <= 0) {
            throw new ValidationException("Vételi árfolyam 0-nál nagyobb kell legyen!");
        }
        if (request.getBaseSellRate() == null || request.getBaseSellRate().compareTo(BigDecimal.ZERO) <= 0) {
            throw new ValidationException("Eladási árfolyam 0-nál nagyobb kell legyen!");
        }

        // Validáció: eladási árfolyam > vételi árfolyam
        if (request.getBaseBuyRate().compareTo(request.getBaseSellRate()) >= 0) {
            throw new ValidationException("Az eladási árfolyamnak nagyobbnak kell lennie a vételinél!");
        }

        // Validáció: limit összegek növekvő sorrendben
        if (request.getLimit1Amount() != null && request.getLimit2Amount() != null
                && request.getLimit1Amount().compareTo(request.getLimit2Amount()) >= 0) {
            throw new ValidationException("Limit1 összegnek kisebbnek kell lennie Limit2-nél!");
        }
        if (request.getLimit2Amount() != null && request.getLimit3Amount() != null
                && request.getLimit2Amount().compareTo(request.getLimit3Amount()) >= 0) {
            throw new ValidationException("Limit2 összegnek kisebbnek kell lennie Limit3-nál!");
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
    @Transactional(readOnly = true)
    public ExchangeRate applyDiscount(Long rateId, BigDecimal discountPercent) {
        ExchangeRate rate = exchangeRateRepository.findById(rateId)
                .orElseThrow(() -> new ResourceNotFoundException("Árfolyam nem található"));

        // 2% feletti kedvezményhez supervisor jog kell
        if (discountPercent.compareTo(new BigDecimal("2.0")) > 0 && !SecurityUtils.isSupervisorOrAbove()) {
            throw new ValidationException("2% feletti kedvezményhez supervisor jogosultság szükséges!");
        }

        // Kedvezményes árfolyam számítása
        // Kedvezmény = spread csökkentés → buy rate NŐ (ügyfél többet kap), sell rate CSÖKKEN (ügyfél kevesebbet fizet)
        BigDecimal discountFraction = discountPercent.divide(new BigDecimal("100"), 6, RoundingMode.HALF_UP);
        BigDecimal newBuyRate = rate.getBaseBuyRate().multiply(BigDecimal.ONE.add(discountFraction));
        BigDecimal newSellRate = rate.getBaseSellRate().multiply(BigDecimal.ONE.subtract(discountFraction));

        log.info("Árfolyam kedvezmény alkalmazva: {}% - új vétel: {}, eladás: {}",
                discountPercent, newBuyRate, newSellRate);

        // Visszaadjuk a módosított árfolyamot tranzakció szintű használatra
        // FONTOS: NE módosítsuk a managed entity-t — az JPA dirty checking miatt perzisztálódna!
        // Ehelyett másolatot készítünk a kedvezményes értékekkel.
        return ExchangeRate.builder()
                .id(rate.getId())
                .company(rate.getCompany())
                .branch(rate.getBranch())
                .currency(rate.getCurrency())
                .validDate(rate.getValidDate())
                .validTime(rate.getValidTime())
                .baseBuyRate(newBuyRate)
                .baseSellRate(newSellRate)
                .limit1Amount(rate.getLimit1Amount())
                .limit1BuyRate(rate.getLimit1BuyRate())
                .limit1SellRate(rate.getLimit1SellRate())
                .limit2Amount(rate.getLimit2Amount())
                .limit2BuyRate(rate.getLimit2BuyRate())
                .limit2SellRate(rate.getLimit2SellRate())
                .limit3Amount(rate.getLimit3Amount())
                .limit3BuyRate(rate.getLimit3BuyRate())
                .limit3SellRate(rate.getLimit3SellRate())
                .officialRate(rate.getOfficialRate())
                .active(rate.getActive())
                .createdBy(rate.getCreatedBy())
                .build();
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
