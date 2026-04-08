package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Denomination;
import hu.puzzleir.valuta.entity.DenominationType;
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
            case MIN_COINS -> minCoins(available, amount);
            case CUSTOM -> greedy(available, amount); // Custom = alapértelmezetten greedy, de felülírható
            case BRANCH_SPECIFIC -> greedy(available, amount); // Branch-specifikus = branch config-ból jön, fallback greedy
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
     * DYNAMIC: bounded knapsack DP készletkorláttal.
     *
     * Tizedes összegek kezelése: a legkisebb címlet decimális helyei alapján
     * skálázunk egészre (pl. 0.50 → *100 → 50). Fallback: greedy ha az összeg
     * túl nagy a DP-hez (>500K skálázott egység) vagy nincs egész címlet.
     */
    private Map<BigDecimal, Integer> dynamic(List<Denomination> available, BigDecimal amount) {
        // Csak aktív, készletes címletek
        List<Denomination> usable = available.stream()
                .filter(d -> d.getQuantity() > 0)
                .toList();
        if (usable.isEmpty()) {
            log.warn("Dynamic: nincs elérhető címlet, üres eredmény");
            return new LinkedHashMap<>();
        }

        // Skálázási faktor: a legkisebb tizedes jegy alapján (pl. 0.50 → scale=2 → mult=100)
        int maxScale = usable.stream()
                .map(d -> d.getFaceValue().stripTrailingZeros().scale())
                .reduce(0, Math::max);
        maxScale = Math.max(maxScale, amount.stripTrailingZeros().scale());
        BigDecimal multiplier = BigDecimal.TEN.pow(maxScale);

        long target;
        try {
            target = amount.multiply(multiplier).longValueExact();
        } catch (ArithmeticException e) {
            log.info("Dynamic: összeg nem konvertálható egészre, fallback greedy");
            return greedy(available, amount);
        }
        if (target <= 0 || target > 500_000L) {
            log.info("Dynamic: target={} kívül esik a DP tartományon, fallback greedy", target);
            return greedy(available, amount);
        }
        int t = (int) target;

        // Készlet-korlátozott DP (bounded knapsack)
        // dp[i] = minimum bankjegy szám i egységhez, -1 = elérhetetlen
        int[] dp = new int[t + 1];
        int[][] used = new int[usable.size()][t + 1]; // used[denomIdx][amount] = hány db ebből
        Arrays.fill(dp, Integer.MAX_VALUE);
        dp[0] = 0;

        for (int di = 0; di < usable.size(); di++) {
            Denomination denom = usable.get(di);
            long fvScaled;
            try {
                fvScaled = denom.getFaceValue().multiply(multiplier).longValueExact();
            } catch (ArithmeticException e) {
                continue;
            }
            if (fvScaled <= 0 || fvScaled > t) continue;
            int fv = (int) fvScaled;
            int maxQty = denom.getQuantity();

            // Backward pass: az adott címlettel max maxQty-ot használhatunk
            for (int i = t; i >= fv; i--) {
                for (int q = 1; q <= maxQty && (long) q * fv <= i; q++) {
                    int prev = i - q * fv;
                    if (dp[prev] != Integer.MAX_VALUE && dp[prev] + q < dp[i]) {
                        dp[i] = dp[prev] + q;
                        used[di][i] = q;
                    }
                }
            }
        }

        if (dp[t] == Integer.MAX_VALUE) {
            log.warn("Dynamic: nem találtam egzakt megoldást, fallback greedy");
            return greedy(available, amount);
        }

        // Backtrack
        Map<BigDecimal, Integer> result = new LinkedHashMap<>();
        int pos = t;
        for (int di = usable.size() - 1; di >= 0 && pos > 0; di--) {
            int q = used[di][pos];
            if (q > 0) {
                result.put(usable.get(di).getFaceValue(), q);
                long fvScaled = usable.get(di).getFaceValue().multiply(multiplier).longValueExact();
                pos -= (int) (q * fvScaled);
            }
        }

        return result;
    }

    /**
     * MIN_COINS: a legkevesebb érme felhasználásával.
     * Bankjegyeket preferálja, érméket csak ha szükséges.
     * Felmérés: 07_cimletkezeles.md követelmény.
     */
    private Map<BigDecimal, Integer> minCoins(List<Denomination> available, BigDecimal amount) {
        // Szétválogatjuk bankjegyekre és érmékre a denominationType alapján
        List<Denomination> banknotes = available.stream()
                .filter(d -> d.getDenominationType() == DenominationType.BANKNOTE)
                .collect(java.util.stream.Collectors.toList());
        List<Denomination> coins = available.stream()
                .filter(d -> d.getDenominationType() == DenominationType.COIN)
                .collect(java.util.stream.Collectors.toList());

        // Először bankjegyekkel fedünk amennyit lehet
        Map<BigDecimal, Integer> result = greedy(banknotes, amount);

        // Maradékot érmékkel
        BigDecimal covered = result.entrySet().stream()
                .map(e -> e.getKey().multiply(BigDecimal.valueOf(e.getValue())))
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        BigDecimal remaining = amount.subtract(covered);

        if (remaining.compareTo(BigDecimal.ZERO) > 0) {
            Map<BigDecimal, Integer> coinResult = greedy(coins, remaining);
            coinResult.forEach((k, v) -> result.merge(k, v, Integer::sum));

            // Ellenőrzés: a teljes összeg lefedve?
            BigDecimal totalCovered = result.entrySet().stream()
                    .map(e -> e.getKey().multiply(BigDecimal.valueOf(e.getValue())))
                    .reduce(BigDecimal.ZERO, BigDecimal::add);
            BigDecimal finalRemaining = amount.subtract(totalCovered);
            if (finalRemaining.compareTo(BigDecimal.ZERO) > 0) {
                log.warn("MIN_COINS: nem sikerült teljesen lefedni az összeget. Maradék: {}", finalRemaining);
            }
        }

        return result;
    }

    public enum Strategy {
        GREEDY,
        MIN_BANKNOTES,
        MIN_TOTAL,
        DYNAMIC,
        /** Minimum érme kiadása — bankjegyeket preferálja */
        MIN_COINS,
        /** Egyedi algoritmus — alapértelmezetten greedy, felülírható */
        CUSTOM,
        /** Fiókspecifikus optimalizálás — branch konfigból jön */
        BRANCH_SPECIFIC
    }
}
