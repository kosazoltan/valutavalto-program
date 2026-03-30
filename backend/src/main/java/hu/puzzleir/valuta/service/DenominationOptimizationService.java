package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Denomination;
import hu.puzzleir.valuta.repository.DenominationRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.*;
import java.util.UUID;

/**
 * Címletezés optimalizáció service.
 * Stratégiák: GREEDY, MIN_BANKNOTES, MIN_TOTAL, DYNAMIC.
 *
 * Feladata: adott összeg kifizetéséhez a rendelkezésre álló címletekből
 * az optimális összeállítás kiszámítása.
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
@Slf4j
public class DenominationOptimizationService {

    private final DenominationRepository denominationRepository;

    /**
     * Optimális címletezés kiszámítása.
     *
     * @param branchId    fiók ID (UUID)
     * @param currencyId  valuta ID
     * @param amount      kifizetendő összeg
     * @param strategy    optimalizálási stratégia
     * @return címlet → darabszám mapping
     */
    public Map<BigDecimal, Integer> optimize(UUID branchId, Long currencyId, BigDecimal amount, Strategy strategy) {
        List<Denomination> available = denominationRepository.findByBranchAndCurrency(branchId, currencyId);
        // already sorted DESC by the query

        return switch (strategy) {
            case GREEDY -> greedy(available, amount);
            case MIN_BANKNOTES -> minBanknotes(available, amount);
            case MIN_TOTAL -> minTotal(available, amount);
            case DYNAMIC -> dynamic(available, amount);
        };
    }

    /**
     * GREEDY: legnagyobb címlettől indul, amennyit tud kiad.
     * Gyors, de nem mindig optimális.
     */
    private Map<BigDecimal, Integer> greedy(List<Denomination> available, BigDecimal remaining) {
        Map<BigDecimal, Integer> result = new LinkedHashMap<>();
        BigDecimal left = remaining;

        for (Denomination denom : available) {
            if (left.compareTo(BigDecimal.ZERO) <= 0) break;
            if (denom.getQuantity() <= 0) continue;

            BigDecimal fv = denom.getFaceValue();
            int maxNeeded = left.divideToIntegralValue(fv).intValue();
            int use = Math.min(maxNeeded, denom.getQuantity());

            if (use > 0) {
                result.put(fv, use);
                left = left.subtract(fv.multiply(BigDecimal.valueOf(use)));
            }
        }

        if (left.compareTo(BigDecimal.ZERO) > 0) {
            log.warn("Greedy: nem tudtam teljesen lefedni az összeget. Maradék: {}", left);
        }
        return result;
    }

    /**
     * MIN_BANKNOTES: a legkevesebb bankjegy felhasználásával.
     * Lényegében greedy, de preferálja a nagy címleteket.
     */
    private Map<BigDecimal, Integer> minBanknotes(List<Denomination> available, BigDecimal amount) {
        // Nagytól kicsiig → greedy egyébként is ezt csinálja
        return greedy(available, amount);
    }

    /**
     * MIN_TOTAL: a legkisebb összegű bankjegyekből áll össze.
     * Kis címleteket preferálja (ellentétes a greedy-vel).
     */
    private Map<BigDecimal, Integer> minTotal(List<Denomination> available, BigDecimal amount) {
        List<Denomination> reversed = new ArrayList<>(available);
        reversed.sort(Comparator.comparing(Denomination::getFaceValue)); // asc
        return greedy(reversed, amount);
    }

    /**
     * DYNAMIC: dinamikus programozáson alapuló optimalizáció.
     * Pontosabb, de lassabb nagy összegekre.
     * Fallback: greedy ha az összeg túl nagy (>100K egység).
     */
    private Map<BigDecimal, Integer> dynamic(List<Denomination> available, BigDecimal amount) {
        // Egész számra kerekítjük
        int target = amount.intValue();
        if (target > 100_000) {
            log.info("Dynamic: összeg túl nagy ({}), fallback greedy-re", target);
            return greedy(available, amount);
        }

        // dp[i] = minimum bankjegy i összeg kifizetéséhez
        int[] dp = new int[target + 1];
        int[] lastDenom = new int[target + 1];
        Arrays.fill(dp, Integer.MAX_VALUE);
        Arrays.fill(lastDenom, -1);
        dp[0] = 0;

        int[] faceValues = available.stream()
                .filter(d -> d.getQuantity() > 0)
                .mapToInt(d -> d.getFaceValue().intValue())
                .distinct()
                .toArray();

        for (int i = 1; i <= target; i++) {
            for (int fv : faceValues) {
                if (fv <= i && dp[i - fv] != Integer.MAX_VALUE && dp[i - fv] + 1 < dp[i]) {
                    dp[i] = dp[i - fv] + 1;
                    lastDenom[i] = fv;
                }
            }
        }

        if (dp[target] == Integer.MAX_VALUE) {
            log.warn("Dynamic: nem találtam egzakt megoldást, fallback greedy");
            return greedy(available, amount);
        }

        // Backtrack
        Map<BigDecimal, Integer> result = new LinkedHashMap<>();
        int pos = target;
        while (pos > 0) {
            int fv = lastDenom[pos];
            result.merge(BigDecimal.valueOf(fv), 1, Integer::sum);
            pos -= fv;
        }

        return result;
    }

    public enum Strategy {
        GREEDY,
        MIN_BANKNOTES,
        MIN_TOTAL,
        DYNAMIC
    }
}
