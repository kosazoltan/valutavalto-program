package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.BranchHandlingFeeConfig;
import hu.puzzleir.valuta.entity.FeeConfigStatus;
import hu.puzzleir.valuta.entity.HandlingFeeBracket;
import hu.puzzleir.valuta.entity.HandlingFeeType;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchHandlingFeeConfigRepository;
import hu.puzzleir.valuta.repository.HandlingFeeBracketRepository;
import hu.puzzleir.valuta.repository.HandlingFeeTransactionRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;
import java.util.UUID;

/**
 * Kezelési díj szolgáltatás — autoritatív díjszámítás.
 *
 * <p>FK-096: a díj IRODA-SZINTŰ (branch_handling_fee_config, DRAFT/LIVE), nem cégszintű.
 * A feloldás companyId + branchId alapján történik, FAIL-CLOSED: ha az irodának nincs
 * aktív LIVE sora → ValidationException (400), SOHA nem néma 0 Ft (FR-5). A korábbi
 * egyargumentumú, cégszintű belépőpont TÖRÖLVE — a fail-closed így fordítási idejű garancia.
 * A díjszámítás a V383 seed révén bit-azonosan reproduálja a korábbi cégszintű
 * system_parameter eredményt (FR-2).</p>
 *
 * Legacy: GetKezelesidij — a Delphi rendszerben az EZRELÉK vagy SÁVOS
 * díjszámítás a _realEzrelek alapján dőlt el.
 *
 * A HandlingFeeCalculator erre a service-re épít:
 * - calculateHandlingFee() → szerver oldali díjszámítás
 * - getRemainingCustomFeeQuota() → napi egyedi díj limit
 *
 * System paraméter (csak az egyedi díj limithet, a díjfeloldáshoz NEM):
 * - DAILY_CUSTOM_FEE_LIMIT: napi egyedi díj limit (default: 5)
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
@Slf4j
public class HandlingFeeService {

    private final SystemParameterService systemParameterService;
    private final BranchHandlingFeeConfigRepository branchConfigRepository;
    private final HandlingFeeBracketRepository bracketRepository;
    private final HandlingFeeTransactionRepository feeTransactionRepository;
    private final DiscountThresholdService discountThresholdService;

    /** Default napi egyedi kezelési díj limit */
    /** Legacy: HARDWARE.SAJATHATASKORU max 5/nap. DB-ből felülírható (SystemParameter). */
    private static final int DEFAULT_DAILY_CUSTOM_FEE_LIMIT = 5;

    /**
     * Kezelési díj számítása a HUF összeg alapján — IRODA-TUDATOS (FK-096).
     *
     * A díj módja az iroda LIVE branch_handling_fee_config sorából jön:
     * - NONE: 0 Ft (nincs díj)
     * - PER_MILLE: összeg × ezrelék / 1000, az iroda saját mértékével/sapkájával (FR-4)
     * - BRACKET: sávos díjtáblázat — a közös LIVE sávokkal (FR-6)
     *
     * <p>FAIL-CLOSED (FR-5): nincs aktív LIVE sor → ValidationException, a tranzakció
     * nem könyvelhető; soha nem tér vissza néma 0 Ft-tal konfigurálatlan irodán.</p>
     *
     * @param hufAmount tranzakció HUF összege (nettó)
     * @param branchId  a díjat viselő iroda azonosítója (explicit, nem statikus rejtett olvasás — DIP)
     * @return kezelési díj (Ft)
     */
    public BigDecimal calculateHandlingFee(BigDecimal hufAmount, UUID branchId) {
        if (hufAmount == null || hufAmount.compareTo(BigDecimal.ZERO) <= 0) {
            return BigDecimal.ZERO;
        }

        UUID companyId = SecurityUtils.getCurrentCompanyId();
        BranchHandlingFeeConfig config = resolveLiveConfig(companyId, branchId);

        BigDecimal baseFee = switch (config.getFeeMode()) {
            case NONE -> BigDecimal.ZERO;
            case PER_MILLE -> calculatePerMille(hufAmount, config);
            case BRACKET -> calculateBracket(hufAmount, companyId);
        };

        // Automatikus kedvezmény/felár alkalmazása (BIGARFVALT/KISARFVALT)
        var discount = discountThresholdService.resolveDiscount(hufAmount);
        if (discount.isPresent()) {
            BigDecimal adjusted = discountThresholdService.applyDiscount(baseFee, discount.get());
            log.debug("Kezelési díj kedvezmény alkalmazva: {} Ft → {} Ft ({})",
                    baseFee, adjusted, discount.get().getCode());
            return adjusted;
        }

        return baseFee;
    }

    /**
     * Hátralévő egyedi kezelési díj kvóta az aktuális pénztáros számára.
     *
     * Legacy: HARDWARE.NAPIEGYEDIKEZDIJ — napi max 3 egyedi díj.
     * Az aktuális nap tranzakcióit számolja, ahol a pénztáros
     * egyedi (nem standard) kezelési díjat alkalmazott.
     *
     * @return hátralévő kvóta (0 = limit elérve)
     */
    public int getRemainingCustomFeeQuota() {
        int dailyLimit = getDailyCustomFeeLimit();
        Long workerId = SecurityUtils.getCurrentWorkerId();
        UUID branchId = SecurityUtils.getCurrentBranchId();

        LocalDateTime dayStart = LocalDate.now().atStartOfDay();
        LocalDateTime dayEnd = LocalDate.now().atTime(LocalTime.MAX);

        // Megszámoljuk a mai nap egyedi díjas tranzakcióit
        // Egyedi díj = discountReason kitöltött (supervisor által jóváhagyott egyedi díj)
        List<?> todayCustomFees = feeTransactionRepository
                .findByBranchAndPeriod(branchId, dayStart, dayEnd)
                .stream()
                .filter(h -> h.getDiscountReason() != null && !h.getDiscountReason().isBlank())
                .toList();

        int used = todayCustomFees.size();
        int remaining = dailyLimit - used;

        log.debug("Egyedi kezelési díj kvóta — worker: {}, használt: {}/{}, maradék: {}",
                workerId, used, dailyLimit, remaining);

        return Math.max(0, remaining);
    }

    // === PRIVÁT SEGÉDMETÓDUSOK ===

    /**
     * FK-096/FR-5: az iroda ÉLŐ (LIVE, aktív) díjkonfigurációjának feloldása.
     * DRAFT sor sosem kerül feloldásra; hiány → ValidationException (400), SOHA nem néma 0 Ft.
     */
    private BranchHandlingFeeConfig resolveLiveConfig(UUID companyId, UUID branchId) {
        return branchConfigRepository
                .findByCompanyIdAndBranchIdAndStatusAndActiveTrue(companyId, branchId, FeeConfigStatus.LIVE)
                .orElseThrow(() -> new ValidationException(
                        "Nincs élő kezelési díj konfiguráció ehhez az irodához (" + branchId + ")."
                                + " Kérj beállítást az ügyvezetőtől / főértéktárostól."));
    }

    /**
     * Ezrelékes díjszámítás — az iroda SAJÁT mértékével és sapkájával (FR-4).
     * Legacy: _realEzrelek > 0 esetén → összeg × ezrelék / 1000
     *
     * <p>Sapka-paritás (pitfall #6): a {@code per_mille_cap} NULL vagy 0 értéke egyaránt
     * „nincs sapka" (a korábbi {@code maxAmount > 0} guard reprodukálva) — különben
     * egy 0 sapka néma 0 Ft díjat eredményezne.</p>
     */
    private BigDecimal calculatePerMille(BigDecimal hufAmount, BranchHandlingFeeConfig config) {
        BigDecimal perMille = config.getPerMilleRate() != null
                ? config.getPerMilleRate()
                : BigDecimal.ZERO;
        BigDecimal fee = hufAmount.multiply(perMille)
                .divide(BigDecimal.valueOf(1000), 0, RoundingMode.HALF_UP);

        BigDecimal maxAmount = config.getPerMilleCap();
        if (maxAmount != null && maxAmount.compareTo(BigDecimal.ZERO) > 0
                && fee.compareTo(maxAmount) > 0) {
            log.debug("PER_MILLE díj {} Ft meghaladja a maximumot {} Ft — sapkázva", fee, maxAmount);
            fee = maxAmount;
        }

        return fee;
    }

    /**
     * Sávos díjszámítás — a közös LIVE sávokkal (FR-6).
     * Legacy: _tranzsav[1..23] és _kdij[1..23] tömbök
     * Az összeg sávba esését a bracket tábla alapján keressük.
     */
    private BigDecimal calculateBracket(BigDecimal hufAmount, UUID companyId) {
        List<HandlingFeeBracket> brackets = bracketRepository
                .findByCompanyIdAndStatusAndActiveOrderByBracketOrder(companyId, FeeConfigStatus.LIVE, true);

        if (brackets.isEmpty()) {
            log.warn("Nincs aktív kezelési díj sáv a {} céghez! Díj: 0 Ft", companyId);
            return BigDecimal.ZERO;
        }

        // Megkeressük az összeghez tartozó sávot
        for (HandlingFeeBracket bracket : brackets) {
            if (hufAmount.compareTo(bracket.getUpperLimit()) <= 0) {
                return bracket.getFeeAmount();
            }
        }

        // Ha túllépi az utolsó sávot → az utolsó sáv díja érvényesül
        HandlingFeeBracket lastBracket = brackets.get(brackets.size() - 1);
        log.info("Összeg ({} Ft) túllépi az utolsó sávot ({} Ft), díj: {} Ft",
                hufAmount, lastBracket.getUpperLimit(), lastBracket.getFeeAmount());
        return lastBracket.getFeeAmount();
    }

    /**
     * Napi egyedi díj limit lekérése system_parameter-ből.
     * (A díjfeloldás NEM használ system_paramétert — csak ez a limit maradt itt.)
     */
    private int getDailyCustomFeeLimit() {
        try {
            return Integer.parseInt(systemParameterService.getValue("DAILY_CUSTOM_FEE_LIMIT"));
        } catch (Exception e) {
            return DEFAULT_DAILY_CUSTOM_FEE_LIMIT;
        }
    }
}
