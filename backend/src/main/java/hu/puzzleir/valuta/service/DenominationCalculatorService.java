package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Denomination;
import hu.puzzleir.valuta.repository.DenominationRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.*;

/**
 * Címlet kalkulátor — optimális címlet összetétel számítása.
 *
 * Legacy: KELLCIM — "Kellő címlet" kalkulátor
 * A Delphi rendszerben a pénztáros a kifizetendő összeghez
 * kapott javaslatot, mely címletekből adja ki (greedy algorithm).
 *
 * Két mód:
 * 1. GREEDY: legnagyobb címlettől lefelé (leggyorsabb, de nem mindig optimális)
 * 2. BALANCED: készlet-figyelembe-vevő (elkerüli hogy egy címletből kifogyjon)
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
@Slf4j
public class DenominationCalculatorService {

    private final DenominationRepository denominationRepository;

    /**
     * Greedy címlet javaslat — legnagyobb címlettől indul lefelé.
     *
     * @param currencyCode valuta kód (pl. "EUR", "HUF")
     * @param targetAmount kifizetendő összeg
     * @return Map<címletérték, darabszám>
     */
    public Map<BigDecimal, Integer> calculateGreedy(String currencyCode, BigDecimal targetAmount) {
        if (targetAmount == null || targetAmount.compareTo(BigDecimal.ZERO) <= 0) {
            return Collections.emptyMap();
        }

        List<Denomination> denoms = getActiveDenominations(currencyCode);
        if (denoms.isEmpty()) {
            log.warn("Nincs aktív címlet a {} valutához!", currencyCode);
            return Collections.emptyMap();
        }

        // Csökkenő sorrendbe faceValue szerint
        denoms.sort((a, b) -> b.getFaceValue().compareTo(a.getFaceValue()));

        Map<BigDecimal, Integer> result = new LinkedHashMap<>();
        BigDecimal remaining = targetAmount;

        for (Denomination denom : denoms) {
            BigDecimal denomValue = denom.getFaceValue();
            if (denomValue.compareTo(BigDecimal.ZERO) <= 0) continue;

            int count = remaining.divide(denomValue, 0, RoundingMode.DOWN).intValue();
            if (count > 0) {
                result.put(denomValue, count);
                remaining = remaining.subtract(denomValue.multiply(BigDecimal.valueOf(count)));
            }

            if (remaining.compareTo(BigDecimal.ZERO) == 0) break;
        }

        if (remaining.compareTo(BigDecimal.ZERO) > 0) {
            log.debug("Maradék {} {} nem adható ki címletben", remaining, currencyCode);
        }

        return result;
    }

    /**
     * Készlet-figyelő címlet javaslat.
     * Elkerüli hogy egy címletből túl sokat adjon ki (max a készlet 50%-a).
     *
     * @param currencyCode valuta kód
     * @param targetAmount kifizetendő összeg
     * @param availableStock Map<címletérték, elérhető darab> aktuális készlet
     * @return Map<címletérték, javasolt darab>
     */
    public Map<BigDecimal, Integer> calculateBalanced(
            String currencyCode,
            BigDecimal targetAmount,
            Map<BigDecimal, Integer> availableStock) {

        if (targetAmount == null || targetAmount.compareTo(BigDecimal.ZERO) <= 0) {
            return Collections.emptyMap();
        }

        List<Denomination> denoms = getActiveDenominations(currencyCode);
        denoms.sort((a, b) -> b.getFaceValue().compareTo(a.getFaceValue()));

        Map<BigDecimal, Integer> result = new LinkedHashMap<>();
        BigDecimal remaining = targetAmount;

        for (Denomination denom : denoms) {
            BigDecimal denomValue = denom.getFaceValue();
            if (denomValue.compareTo(BigDecimal.ZERO) <= 0) continue;

            int maxFromGreedy = remaining.divide(denomValue, 0, RoundingMode.DOWN).intValue();
            if (maxFromGreedy <= 0) continue;

            // Készlet limit: max a készlet 50%-a
            int stockLimit = Integer.MAX_VALUE;
            if (availableStock != null && availableStock.containsKey(denom.getFaceValue())) {
                stockLimit = Math.max(1, availableStock.get(denom.getFaceValue()) / 2);
            }

            int count = Math.min(maxFromGreedy, stockLimit);
            if (count > 0) {
                result.put(denomValue, count);
                remaining = remaining.subtract(denomValue.multiply(BigDecimal.valueOf(count)));
            }

            if (remaining.compareTo(BigDecimal.ZERO) == 0) break;
        }

        // Ha maradt, próbáljuk meg a készletkorlátozás nélkül
        if (remaining.compareTo(BigDecimal.ZERO) > 0) {
            for (Denomination denom : denoms) {
                BigDecimal denomValue = denom.getFaceValue();
                int existing = result.getOrDefault(denomValue, 0);
                int maxMore = remaining.divide(denomValue, 0, RoundingMode.DOWN).intValue();
                if (maxMore > 0) {
                    result.put(denomValue, existing + maxMore);
                    remaining = remaining.subtract(denomValue.multiply(BigDecimal.valueOf(maxMore)));
                }
                if (remaining.compareTo(BigDecimal.ZERO) == 0) break;
            }
        }

        return result;
    }

    /**
     * Összeg visszaellenőrzés — a kiadott címletek összege egyezik-e a célösszeggel.
     */
    public BigDecimal sumDenominations(Map<BigDecimal, Integer> denomMap) {
        return denomMap.entrySet().stream()
                .map(e -> e.getKey().multiply(BigDecimal.valueOf(e.getValue())))
                .reduce(BigDecimal.ZERO, BigDecimal::add);
    }

    // === PRIVÁT ===

    private List<Denomination> getActiveDenominations(String currencyCode) {
        return denominationRepository.findAll().stream()
                .filter(d -> d.getCurrency() != null
                        && currencyCode.equals(d.getCurrency().getCode()))
                .filter(d -> d.getActive() != null && d.getActive())
                .toList();
    }
}
