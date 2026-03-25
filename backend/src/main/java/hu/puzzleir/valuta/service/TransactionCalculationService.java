package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.ExchangeRate;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.repository.TransactionRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;

/**
 * Tranzakcio szamitasi szolgaltatas.
 *
 * Arfolyam-szamitasok, kedvezmeny-szamitasok, kezelesi dij logika.
 * Kiemelve a TransactionService-bol a single-responsibility elv alapjan.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class TransactionCalculationService {

    private final TransactionRepository transactionRepository;

    // Napi kedvezmeny limit penztarosonkent (Legacy: 5 db/nap egyedi rata kedvezmeny)
    private static final int DAILY_DISCOUNT_LIMIT = 5;

    /**
     * Veteli HUF osszeg szamitasa arfolyam es kedvezmeny alapjan.
     */
    public BigDecimal calculateBuyHufAmount(BigDecimal currencyAmount, ExchangeRate rate, BigDecimal discountPercent) {
        BigDecimal baseAmount = currencyAmount.multiply(rate.getBaseBuyRate());
        BigDecimal appliedRate = rate.getBuyRateForAmount(baseAmount);
        BigDecimal hufAmount = currencyAmount.multiply(appliedRate).setScale(0, RoundingMode.HALF_UP);

        if (discountPercent != null && discountPercent.compareTo(BigDecimal.ZERO) > 0) {
            BigDecimal discount = hufAmount.multiply(discountPercent).divide(new BigDecimal("100"), 0, RoundingMode.HALF_UP);
            hufAmount = hufAmount.add(discount);
        }

        return hufAmount;
    }

    /**
     * Eladasi HUF osszeg szamitasa arfolyam es kedvezmeny alapjan.
     */
    public BigDecimal calculateSellHufAmount(BigDecimal currencyAmount, ExchangeRate rate, BigDecimal discountPercent) {
        BigDecimal baseAmount = currencyAmount.multiply(rate.getBaseSellRate());
        BigDecimal appliedRate = rate.getSellRateForAmount(baseAmount);
        BigDecimal hufAmount = currencyAmount.multiply(appliedRate).setScale(0, RoundingMode.HALF_UP);

        if (discountPercent != null && discountPercent.compareTo(BigDecimal.ZERO) > 0) {
            BigDecimal discount = hufAmount.multiply(discountPercent).divide(new BigDecimal("100"), 0, RoundingMode.HALF_UP);
            hufAmount = hufAmount.subtract(discount);
        }

        return hufAmount;
    }

    /**
     * Veteli arfolyam feloldasa (egyedi vagy tier-alapu).
     */
    public BigDecimal resolveBuyRate(ExchangeRate rate, BigDecimal currencyAmount, BigDecimal customExchangeRate) {
        if (customExchangeRate != null) {
            if (customExchangeRate.compareTo(BigDecimal.ZERO) <= 0) {
                throw new ValidationException("Az egyedi veteli arfolyamnak pozitivnak kell lennie!");
            }
            BigDecimal activeBuyRate = rate.getBaseBuyRate();
            if (customExchangeRate.compareTo(activeBuyRate) < 0) {
                throw new ValidationException(
                    String.format("Az egyedi veteli arfolyam (%s) nem lehet alacsonyabb az aktiv veteli arfolyamnal (%s)!",
                        customExchangeRate, activeBuyRate));
            }
            if (rate.getOfficialRate() != null && customExchangeRate.compareTo(rate.getOfficialRate()) > 0) {
                throw new ValidationException(
                    String.format("Az egyedi veteli arfolyam (%s) nem lepheti tul az MNB elszamolasi arfolyamot (%s)!",
                        customExchangeRate, rate.getOfficialRate()));
            }
            return customExchangeRate;
        }

        BigDecimal baseAmount = currencyAmount.multiply(rate.getBaseBuyRate());
        return rate.getBuyRateForAmount(baseAmount);
    }

    /**
     * Eladasi arfolyam feloldasa (egyedi vagy tier-alapu).
     */
    public BigDecimal resolveSellRate(ExchangeRate rate, BigDecimal currencyAmount, BigDecimal customExchangeRate) {
        if (customExchangeRate != null) {
            if (customExchangeRate.compareTo(BigDecimal.ZERO) <= 0) {
                throw new ValidationException("Az egyedi eladasi arfolyamnak pozitivnak kell lennie!");
            }
            BigDecimal activeSellRate = rate.getBaseSellRate();
            if (customExchangeRate.compareTo(activeSellRate) > 0) {
                throw new ValidationException(
                    String.format("Az egyedi eladasi arfolyam (%s) nem lehet magasabb az aktiv eladasi arfolyamnal (%s)!",
                        customExchangeRate, activeSellRate));
            }
            if (rate.getOfficialRate() != null && customExchangeRate.compareTo(rate.getOfficialRate()) < 0) {
                throw new ValidationException(
                    String.format("Az egyedi eladasi arfolyam (%s) nem lehet alacsonyabb az MNB elszamolasi arfolyamnal (%s)!",
                        customExchangeRate, rate.getOfficialRate()));
            }
            return customExchangeRate;
        }

        BigDecimal baseAmount = currencyAmount.multiply(rate.getBaseSellRate());
        return rate.getSellRateForAmount(baseAmount);
    }

    /**
     * Veteli kedvezmeny alkalmazasa.
     */
    public BigDecimal applyBuyDiscount(BigDecimal fullHufAmount, BigDecimal discountPercent) {
        if (discountPercent == null || discountPercent.compareTo(BigDecimal.ZERO) <= 0) {
            return fullHufAmount;
        }
        BigDecimal discount = fullHufAmount.multiply(discountPercent)
                .divide(new BigDecimal("100"), 0, RoundingMode.HALF_UP);
        return fullHufAmount.add(discount);
    }

    /**
     * Eladasi kedvezmeny alkalmazasa.
     */
    public BigDecimal applySellDiscount(BigDecimal fullHufAmount, BigDecimal discountPercent) {
        if (discountPercent == null || discountPercent.compareTo(BigDecimal.ZERO) <= 0) {
            return fullHufAmount;
        }
        BigDecimal discount = fullHufAmount.multiply(discountPercent)
                .divide(new BigDecimal("100"), 0, RoundingMode.HALF_UP);
        return fullHufAmount.subtract(discount);
    }

    /**
     * Kedvezmeny osszeg szamitasa.
     */
    public BigDecimal calculateDiscountAmount(BigDecimal hufAmount, BigDecimal discountPercent) {
        if (discountPercent == null || discountPercent.compareTo(BigDecimal.ZERO) == 0) {
            return BigDecimal.ZERO;
        }
        return hufAmount.multiply(discountPercent).divide(new BigDecimal("100"), 0, RoundingMode.HALF_UP);
    }

    /**
     * Kedvezmeny validalasa.
     */
    public void validateDiscount(BigDecimal discountPercent) {
        if (discountPercent.compareTo(BigDecimal.ZERO) < 0) {
            throw new ValidationException("Kedvezmeny nem lehet negativ!");
        }
        if (discountPercent.compareTo(new BigDecimal("15")) > 0) {
            throw new ValidationException("Maximum kedvezmeny: 15%!");
        }
        if (discountPercent.compareTo(new BigDecimal("2.0")) > 0 && !SecurityUtils.isSupervisorOrAbove()) {
            throw new ValidationException("2% feletti kedvezmenyhez supervisor jogosultsag szukseges!");
        }

        Long workerId = SecurityUtils.getCurrentWorkerId();
        long dailyDiscountCount = transactionRepository.countDailyDiscountsByWorker(workerId, LocalDate.now());
        if (dailyDiscountCount >= DAILY_DISCOUNT_LIMIT && !SecurityUtils.isSupervisorOrAbove()) {
            throw new ValidationException(
                String.format("Napi kedvezmeny limit (%d) elerve! Supervisor jovahagyas szukseges.", DAILY_DISCOUNT_LIMIT));
        }
    }
}
