package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.dto.calculator.CalculationResultDto;
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
import java.math.MathContext;
import java.math.RoundingMode;
import java.util.*;

/**
 * Deviza átváltás kalkulátor szolgáltatás.
 *
 * Élő árfolyamok alapján végez átváltási számításokat.
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
@Slf4j
public class CurrencyCalculatorService {

    private final ExchangeRateRepository exchangeRateRepository;
    private final CurrencyRepository currencyRepository;
    private final RoundingRuleService roundingRuleService;
    private final HandlingFeeService handlingFeeService;

    /**
     * Deviza átváltás kalkuláció.
     *
     * @param fromCurrency forráspénznem
     * @param toCurrency célpénznem
     * @param amount átváltandó összeg
     * @param direction "BUY" (ügyfél valutát ad el) vagy "SELL" (ügyfél valutát vesz)
     * @return átváltási eredmény
     */
    public CalculationResultDto calculate(String fromCurrency, String toCurrency, BigDecimal amount, String direction) {
        if (amount == null || amount.compareTo(BigDecimal.ZERO) <= 0) {
            throw new ValidationException("Az összegnek pozitívnak kell lennie!");
        }

        UUID companyId = SecurityUtils.getCurrentCompanyId();
        UUID branchId = SecurityUtils.getCurrentBranchId();

        // HUF-ra vagy HUF-ról váltás
        if ("HUF".equals(fromCurrency) || "HUF".equals(toCurrency)) {
            return calculateWithHuf(fromCurrency, toCurrency, amount, direction, companyId, branchId);
        }

        // Cross-rate: deviza→deviza (HUF-on keresztül)
        return calculateCrossRate(fromCurrency, toCurrency, amount, direction, companyId, branchId);
    }

    /**
     * Fordított kalkuláció: mennyi devizát kap az ügyfél X forintért.
     */
    public BigDecimal calculateReverse(String currency, BigDecimal hufAmount) {
        if (hufAmount == null || hufAmount.compareTo(BigDecimal.ZERO) <= 0) {
            throw new ValidationException("Az összegnek pozitívnak kell lennie!");
        }

        UUID companyId = SecurityUtils.getCurrentCompanyId();
        UUID branchId = SecurityUtils.getCurrentBranchId();

        Currency curr = currencyRepository.findByCode(currency)
                .orElseThrow(() -> new ResourceNotFoundException("Ismeretlen valuta: " + currency));

        ExchangeRate rate = exchangeRateRepository.findLatestRate(companyId, curr.getId(), branchId)
                .orElseThrow(() -> new ResourceNotFoundException("Nincs árfolyam: " + currency));

        // Ügyfél vesz devizát → sell rate alkalmazása
        BigDecimal sellRate = rate.getSellRateForAmount(hufAmount);
        BigDecimal foreignAmount = hufAmount.divide(sellRate, 4, RoundingMode.HALF_UP);

        // Kerekítés a deviza szabályai szerint
        return roundingRuleService.roundAmount(currency, foreignAmount, "SELL");
    }

    /**
     * Összes valutapár cross-rate mátrix.
     */
    public Map<String, Map<String, BigDecimal>> getExchangeMatrix() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        UUID branchId = SecurityUtils.getCurrentBranchId();

        List<Currency> currencies = currencyRepository.findByActiveTrueOrderByDisplayOrderAsc();
        Map<String, Map<String, BigDecimal>> matrix = new LinkedHashMap<>();

        for (Currency from : currencies) {
            if ("HUF".equals(from.getCode())) continue;

            Map<String, BigDecimal> row = new LinkedHashMap<>();
            ExchangeRate fromRate = exchangeRateRepository.findLatestRate(companyId, from.getId(), branchId)
                    .orElse(null);
            if (fromRate == null) continue;

            for (Currency to : currencies) {
                if ("HUF".equals(to.getCode()) || from.getCode().equals(to.getCode())) continue;

                ExchangeRate toRate = exchangeRateRepository.findLatestRate(companyId, to.getId(), branchId)
                        .orElse(null);
                if (toRate == null) continue;
                if (fromRate.getBaseBuyRate() == null || toRate.getBaseSellRate() == null) continue;

                // Cross-rate: from buy rate / to sell rate (customer sells from, buys to)
                BigDecimal crossRate = fromRate.getBaseBuyRate()
                        .divide(toRate.getBaseSellRate(), 6, RoundingMode.HALF_UP);
                row.put(to.getCode(), crossRate);
            }

            if (!row.isEmpty()) {
                matrix.put(from.getCode(), row);
            }
        }

        return matrix;
    }

    // ============ PRIVATE METHODS ============

    private CalculationResultDto calculateWithHuf(
            String fromCurrency, String toCurrency, BigDecimal amount,
            String direction, UUID companyId, UUID branchId) {

        String foreignCode = "HUF".equals(fromCurrency) ? toCurrency : fromCurrency;

        Currency curr = currencyRepository.findByCode(foreignCode)
                .orElseThrow(() -> new ResourceNotFoundException("Ismeretlen valuta: " + foreignCode));

        ExchangeRate rate = exchangeRateRepository.findLatestRate(companyId, curr.getId(), branchId)
                .orElseThrow(() -> new ResourceNotFoundException("Nincs árfolyam: " + foreignCode));

        if (rate.getBaseBuyRate() == null || rate.getBaseSellRate() == null) {
            throw new ValidationException("Az árfolyam nincs megfelelően konfigurálva: " + foreignCode);
        }

        BigDecimal appliedRate;
        BigDecimal fromAmount;
        BigDecimal toAmount;
        BigDecimal spread;

        if ("BUY".equalsIgnoreCase(direction)) {
            // Ügyfél elad devizát → mi veszünk → buy rate
            BigDecimal amountInHuf = "HUF".equals(fromCurrency)
                    ? amount
                    : amount.multiply(rate.getBaseBuyRate());
            appliedRate = rate.getBuyRateForAmount(amountInHuf);
            if ("HUF".equals(fromCurrency)) {
                // HUF → deviza (fordított: ügyfél forintot ad, devizát kap — de BUY irányban ez atipikus)
                fromAmount = amount;
                toAmount = amount.divide(appliedRate, 4, RoundingMode.HALF_UP);
                toAmount = roundingRuleService.roundAmount(foreignCode, toAmount, direction);
            } else {
                // deviza → HUF: ügyfél devizát ad, forintot kap
                fromAmount = amount;
                toAmount = amount.multiply(appliedRate).setScale(0, RoundingMode.HALF_UP);
            }
        } else {
            // Ügyfél vesz devizát → mi eladunk → sell rate
            BigDecimal amountInHuf = "HUF".equals(fromCurrency)
                    ? amount
                    : amount.multiply(rate.getBaseSellRate());
            appliedRate = rate.getSellRateForAmount(amountInHuf);
            if ("HUF".equals(fromCurrency)) {
                // HUF → deviza: ügyfél forintot ad, devizát kap
                fromAmount = amount;
                toAmount = amount.divide(appliedRate, 4, RoundingMode.HALF_UP);
                toAmount = roundingRuleService.roundAmount(foreignCode, toAmount, direction);
            } else {
                // deviza → HUF: ügyfél devizát ad (atipikus SELL irányban)
                fromAmount = amount;
                toAmount = amount.multiply(appliedRate).setScale(0, RoundingMode.HALF_UP);
            }
        }

        spread = rate.getBaseSellRate().subtract(rate.getBaseBuyRate());

        return CalculationResultDto.builder()
                .fromCurrency(fromCurrency)
                .toCurrency(toCurrency)
                .fromAmount(fromAmount)
                .toAmount(toAmount)
                .appliedRate(appliedRate)
                .spread(spread)
                .commission(handlingFeeService.calculateHandlingFee(
                    "HUF".equals(fromCurrency) ? fromAmount : toAmount, branchId))
                .direction(direction)
                .roundingInfo("Kerekítés: " + foreignCode + " szabály alkalmazva")
                .build();
    }

    private CalculationResultDto calculateCrossRate(
            String fromCurrency, String toCurrency, BigDecimal amount,
            String direction, UUID companyId, UUID branchId) {

        Currency fromCurr = currencyRepository.findByCode(fromCurrency)
                .orElseThrow(() -> new ResourceNotFoundException("Ismeretlen valuta: " + fromCurrency));
        Currency toCurr = currencyRepository.findByCode(toCurrency)
                .orElseThrow(() -> new ResourceNotFoundException("Ismeretlen valuta: " + toCurrency));

        ExchangeRate fromRate = exchangeRateRepository.findLatestRate(companyId, fromCurr.getId(), branchId)
                .orElseThrow(() -> new ResourceNotFoundException("Nincs árfolyam: " + fromCurrency));
        ExchangeRate toRate = exchangeRateRepository.findLatestRate(companyId, toCurr.getId(), branchId)
                .orElseThrow(() -> new ResourceNotFoundException("Nincs árfolyam: " + toCurrency));

        if (fromRate.getBaseBuyRate() == null || fromRate.getBaseSellRate() == null) {
            throw new ValidationException("Az árfolyam nincs megfelelően konfigurálva: " + fromCurrency);
        }
        if (toRate.getBaseBuyRate() == null || toRate.getBaseSellRate() == null) {
            throw new ValidationException("Az árfolyam nincs megfelelően konfigurálva: " + toCurrency);
        }

        // Cross-rate: from → HUF → to
        BigDecimal hufAmount;
        BigDecimal appliedRate;

        if ("BUY".equalsIgnoreCase(direction)) {
            hufAmount = amount.multiply(fromRate.getBaseBuyRate());
            BigDecimal toAmount = hufAmount.divide(toRate.getBaseSellRate(), 4, RoundingMode.HALF_UP);
            toAmount = roundingRuleService.roundAmount(toCurrency, toAmount, direction);
            appliedRate = fromRate.getBaseBuyRate().divide(toRate.getBaseSellRate(), 6, RoundingMode.HALF_UP);

            return CalculationResultDto.builder()
                    .fromCurrency(fromCurrency)
                    .toCurrency(toCurrency)
                    .fromAmount(amount)
                    .toAmount(toAmount)
                    .appliedRate(appliedRate)
                    .spread(BigDecimal.ZERO)
                    .commission(BigDecimal.ZERO)
                    .direction(direction)
                    .roundingInfo("Cross-rate: " + fromCurrency + " → HUF → " + toCurrency)
                    .build();
        } else {
            hufAmount = amount.multiply(fromRate.getBaseSellRate());
            BigDecimal toAmount = hufAmount.divide(toRate.getBaseBuyRate(), 4, RoundingMode.HALF_UP);
            toAmount = roundingRuleService.roundAmount(toCurrency, toAmount, direction);
            appliedRate = fromRate.getBaseSellRate().divide(toRate.getBaseBuyRate(), 6, RoundingMode.HALF_UP);

            return CalculationResultDto.builder()
                    .fromCurrency(fromCurrency)
                    .toCurrency(toCurrency)
                    .fromAmount(amount)
                    .toAmount(toAmount)
                    .appliedRate(appliedRate)
                    .spread(BigDecimal.ZERO)
                    .commission(BigDecimal.ZERO)
                    .direction(direction)
                    .roundingInfo("Cross-rate: " + fromCurrency + " → HUF → " + toCurrency)
                    .build();
        }
    }
}
