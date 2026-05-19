package hu.puzzleir.valuta.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import hu.puzzleir.valuta.entity.Denomination;
import hu.puzzleir.valuta.entity.DenominationType;
import hu.puzzleir.valuta.entity.OptimizationStrategy;
import hu.puzzleir.valuta.repository.DenominationRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.*;

/**
 * Címletezés optimalizáció service — v2.0 spec 07_cimletkezeles.md alapján.
 *
 * <p>7 stratégia (lásd {@link OptimizationStrategy}):
 * <ul>
 *   <li>GREEDY — mohó, nagytól kicsiig</li>
 *   <li>DYNAMIC — bounded knapsack DP, minimum darabszám</li>
 *   <li>MIN_COINS — bankjegyeket preferál, érméket csak ha kell</li>
 *   <li>MIN_BANKNOTES — egyenértékű a GREEDY-vel (nagytól kicsiig)</li>
 *   <li>MIN_TOTAL — kicsi címleteket preferál (max darabszám, ellentétes greedy)</li>
 *   <li>CUSTOM — priorityOrderJson alapján definiált sorrend</li>
 *   <li>BRANCH_SPECIFIC — készlet-aware: nagy készletű címleteket preferál (kiegyenlít)</li>
 * </ul></p>
 *
 * <p>v2.5.65+ Sprint A close-out: 7 strategy mind valós impl (CUSTOM + BRANCH_SPECIFIC
 * korábban fallback greedy volt).</p>
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
@Slf4j
public class DenominationOptimizationService {

    private final DenominationRepository denominationRepository;
    private final ObjectMapper objectMapper = new ObjectMapper();

    /**
     * Optimális címletezés a megadott stratégia szerint.
     *
     * @param branchId    fiók
     * @param currencyId  valuta
     * @param amount      kifizetendő összeg
     * @param strategy    optimalizálási stratégia (lásd {@link OptimizationStrategy})
     * @return címlet → darabszám mapping (LinkedHashMap, csökkenő/növekvő sorrend a stratégia szerint)
     */
    public Map<BigDecimal, Integer> optimize(UUID branchId, Long currencyId, BigDecimal amount,
                                              OptimizationStrategy strategy) {
        return optimize(branchId, currencyId, amount, strategy, null);
    }

    /**
     * Optimális címletezés stratégiával + opcionális CUSTOM priority order JSON.
     *
     * @param priorityOrderJson  CUSTOM strategy esetén: JSON tömb a faceValue-k preferenciasorrendjével,
     *                           pl. {@code ["20000", "10000", "5000", "1000", "500", "200", "100"]}
     */
    public Map<BigDecimal, Integer> optimize(UUID branchId, Long currencyId, BigDecimal amount,
                                              OptimizationStrategy strategy, String priorityOrderJson) {
        if (strategy == null) {
            throw new IllegalArgumentException("strategy must not be null");
        }
        if (amount == null || amount.signum() < 0) {
            throw new IllegalArgumentException("amount must be non-null and non-negative");
        }
        if (amount.signum() == 0) {
            return new LinkedHashMap<>();
        }

        // TODO Sprint A P0.3 (companyId audit): a findByBranchAndCurrency lekérdezés
        // jelenleg NEM szűr company-ra (defense-in-depth hiányzik). A controller-szintű
        // @PreAuthorize + branch.company FK gondoskodik a tenant-elszigetelésről, de a
        // companyId formalis multi-tenant audit során ide is bekerül a szűrés.
        List<Denomination> available = denominationRepository.findByBranchAndCurrency(branchId, currencyId);

        return switch (strategy) {
            case GREEDY, MIN_BANKNOTES -> greedy(available, amount);
            case MIN_TOTAL -> minTotal(available, amount);
            case DYNAMIC -> dynamic(available, amount);
            case MIN_COINS -> minCoins(available, amount);
            case CUSTOM -> custom(available, amount, priorityOrderJson);
            case BRANCH_SPECIFIC -> branchSpecific(available, amount);
        };
    }

    // ==========================================================================
    // Stratégia implementációk
    // ==========================================================================

    /** GREEDY: legnagyobb címlettől indul, amennyit tud kiad. Gyors, de nem mindig optimális. */
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

    /** Helper: a result Map összegét számolja (faceValue × count összegzés). */
    private static BigDecimal sumOf(Map<BigDecimal, Integer> result) {
        return result.entrySet().stream()
                .map(e -> e.getKey().multiply(BigDecimal.valueOf(e.getValue())))
                .reduce(BigDecimal.ZERO, BigDecimal::add);
    }

    /**
     * MIN_TOTAL: **minimum** összes darabszám — Copilot P0 #701 fix.
     *
     * <p>A v2.0 spec (OptimizationStrategy.MIN_TOTAL "Minimum összes darabszám") a
     * minimális darabszámú összeállítást kéri. Korábban (v2.5.65) tévesen ascending
     * greedy-vel hívtuk, ami a **maximális** darabszámot adta volna (pl. 100 Ft →
     * 20×5 Ft helyett 1×100 Ft a helyes). Most delegáljuk a DYNAMIC-ra (bounded
     * knapsack DP), ami egzakt minimum darabszámot ad. A DYNAMIC-on belül fallback
     * GREEDY van, ha a DP nem alkalmazható (>500K skálázott egység vagy infeasible).</p>
     */
    private Map<BigDecimal, Integer> minTotal(List<Denomination> available, BigDecimal amount) {
        return dynamic(available, amount);
    }

    /** DYNAMIC: bounded knapsack DP készletkorláttal — minimum darabszám. */
    private Map<BigDecimal, Integer> dynamic(List<Denomination> available, BigDecimal amount) {
        List<Denomination> usable = available.stream()
                .filter(d -> d.getQuantity() > 0)
                .toList();
        if (usable.isEmpty()) {
            log.warn("Dynamic: nincs elérhető címlet, üres eredmény");
            return new LinkedHashMap<>();
        }

        int maxScale = usable.stream()
                .map(d -> d.getFaceValue().stripTrailingZeros().scale())
                .reduce(0, Math::max);
        maxScale = Math.max(maxScale, amount.stripTrailingZeros().scale());
        // Negatív scale (pl. 1000 → stripTrailingZeros scale = -3) clamp 0-ra,
        // különben BigDecimal.TEN.pow(negative) ArithmeticException.
        maxScale = Math.max(0, maxScale);
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

        int[] dp = new int[t + 1];
        int[][] used = new int[usable.size()][t + 1];
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
     * MIN_COINS: bankjegyeket preferál, érméket csak akkor használ ha kell — Copilot P1 #701 fix.
     *
     * <p>Korábban (v2.5.65): banknote-greedy → coin-greedy. Bug: ha a banknote-greedy
     * irrevocable választása után a maradék érmével nem fedhető (pl. 500 banknote + 3×200
     * coin, amount=600 → greedy 500-at vesz, maradék 100, érme nincs erre → részleges).
     * Pedig 3×200=600 EGZAKT lett volna érmével.</p>
     *
     * <p>Most 3-fázisú megoldás:
     * 1. Banknote-only DP (egzakt). Ha sikerül → érmék nélküli megoldás.
     * 2. Coin-only DP (egzakt). Ha sikerül → preferált, ha a banknote-only failed.
     *    Wait: érmék nélkül NEM preferált (érme nincs nagy összegre). Skip.
     * 3. Full mixed DP (banknote + coin). Minimum darabszám-optimum.</p>
     *
     * <p>A 3-fázisú megoldás biztosítja:
     * - Ha tisztán bankjeggyel lehetséges → 0 érme.
     * - Ha nem (bug-eset) → mixed DP, ami nem feltétlenül 0 érmé, de EGZAKT fedés.
     * - Ha még az sem megy → partial coverage warning-gal.</p>
     */
    private Map<BigDecimal, Integer> minCoins(List<Denomination> available, BigDecimal amount) {
        List<Denomination> banknotes = available.stream()
                .filter(d -> d.getDenominationType() == DenominationType.BANKNOTE)
                .toList();

        // Phase 1: csak bankjegyek (DP egzakt)
        Map<BigDecimal, Integer> banknoteOnly = dynamic(banknotes, amount);
        if (sumOf(banknoteOnly).compareTo(amount) == 0) {
            return banknoteOnly;
        }

        // Phase 2: full mixed DP — egzakt fedés ha lehetséges
        Map<BigDecimal, Integer> mixed = dynamic(available, amount);
        if (sumOf(mixed).compareTo(amount) == 0) {
            return mixed;
        }

        // Phase 3: utolsó esély — banknote-greedy + coin-greedy (eredeti logika, de csak fallback)
        List<Denomination> coins = available.stream()
                .filter(d -> d.getDenominationType() == DenominationType.COIN)
                .toList();
        Map<BigDecimal, Integer> result = new LinkedHashMap<>(greedy(banknotes, amount));
        BigDecimal covered = sumOf(result);
        BigDecimal remaining = amount.subtract(covered);

        if (remaining.compareTo(BigDecimal.ZERO) > 0) {
            Map<BigDecimal, Integer> coinResult = greedy(coins, remaining);
            coinResult.forEach((k, v) -> result.merge(k, v, Integer::sum));

            BigDecimal finalRemaining = amount.subtract(sumOf(result));
            if (finalRemaining.compareTo(BigDecimal.ZERO) > 0) {
                log.warn("MIN_COINS: nem sikerült teljesen lefedni az összeget. Maradék: {}", finalRemaining);
            }
        }

        return result;
    }

    /**
     * CUSTOM: priorityOrderJson alapján definiált sorrendben greedy.
     *
     * <p>A JSON tömb minden eleme egy faceValue (BigDecimal-szöveg). Az algoritmus ebben
     * a sorrendben próbálja a címleteket. Olyan címletek, amik a JSON-ban nincsenek
     * felsorolva, a végén kerülnek sorra (csökkenő érték szerint), greedy fallback.</p>
     */
    private Map<BigDecimal, Integer> custom(List<Denomination> available, BigDecimal amount, String priorityOrderJson) {
        if (priorityOrderJson == null || priorityOrderJson.isBlank()) {
            log.info("CUSTOM: priorityOrderJson hiányzik, fallback GREEDY (amount={})", amount);
            return greedy(available, amount);
        }

        List<BigDecimal> priorityFaceValues;
        try {
            List<String> raw = objectMapper.readValue(priorityOrderJson, new TypeReference<>() {});
            priorityFaceValues = raw.stream().map(BigDecimal::new).toList();
        } catch (JsonProcessingException | NumberFormatException e) {
            String truncatedJson = priorityOrderJson.length() > 200
                    ? priorityOrderJson.substring(0, 200) + "…"
                    : priorityOrderJson;
            log.warn("CUSTOM: priorityOrderJson parse hiba, fallback GREEDY. amount={}, priorityOrderJson_truncated='{}'. Hiba: {}",
                    amount, truncatedJson, e.getMessage());
            return greedy(available, amount);
        }

        // BigDecimal scale-független matching: stripTrailingZeros() normalizál
        // ("1000.00" ↔ "1000" ↔ "1E+3" mind ugyanaz logikailag).
        // Codex P1 #701: de-duplikálás kötelező — ha a JSON kétszer tartalmaz ugyanazt
        // a faceValue-t, NEM szabad kétszer hozzáadni a denominationhez (különben a
        // greedy() ugyanazt a stock bucket-et kétszer használja, többet allokál mint
        // amennyi a készletben van).
        Set<BigDecimal> priorityNormalized = new LinkedHashSet<>();
        for (BigDecimal fv : priorityFaceValues) {
            priorityNormalized.add(fv.stripTrailingZeros());
        }
        Map<BigDecimal, Denomination> byFvNormalized = new HashMap<>();
        for (Denomination d : available) {
            if (d.getFaceValue() == null) continue;
            byFvNormalized.put(d.getFaceValue().stripTrailingZeros(), d);
        }

        List<Denomination> ordered = new ArrayList<>();
        // priorityNormalized már de-dup (LinkedHashSet → első előfordulás sorrendje
        // megőrzött); de iterálni a priorityFaceValues-on kell hogy megtartsuk a
        // raw JSON-beli sorrendet, és külön Set-tel követjük már hozzáadott fv-ket.
        Set<BigDecimal> alreadyAdded = new HashSet<>();
        for (BigDecimal fv : priorityFaceValues) {
            BigDecimal normalized = fv.stripTrailingZeros();
            if (alreadyAdded.contains(normalized)) continue;
            Denomination d = byFvNormalized.get(normalized);
            if (d != null) {
                ordered.add(d);
                alreadyAdded.add(normalized);
            }
        }
        // A priority-ben nem szereplő címletek a végén, greedy (descending)
        available.stream()
                .filter(d -> d.getFaceValue() != null
                        && !priorityNormalized.contains(d.getFaceValue().stripTrailingZeros()))
                .forEach(ordered::add);

        return greedy(ordered, amount);
    }

    /**
     * BRANCH_SPECIFIC: készlet-aware optimalizálás.
     *
     * <p>Készletkiegyenlítés: a magas készletű címleteket preferálja, alacsony készletet
     * megőriz. A címleteket descending quantity szerint rendezi (egyenlő mennyiségnél
     * descending faceValue), majd greedy a megfordított sorrendben.</p>
     *
     * <p>Cél: a pénztáros gyakran adja ki a "bőven van" címleteket, és tartogatja a
     * "kifogyóban" címleteket, hogy a kasszában mindig vegyes maradjon a készlet.</p>
     */
    private Map<BigDecimal, Integer> branchSpecific(List<Denomination> available, BigDecimal amount) {
        List<Denomination> byStockDescThenFvDesc = new ArrayList<>(available);
        byStockDescThenFvDesc.sort(
                Comparator.comparingInt(Denomination::getQuantity).reversed()
                        .thenComparing(Comparator.comparing(Denomination::getFaceValue).reversed())
        );
        return greedy(byStockDescThenFvDesc, amount);
    }
}
