package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.HandlingFeeBracket;
import hu.puzzleir.valuta.entity.HandlingFeeType;
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
 * Legacy: GetKezelesidij — a Delphi rendszerben az EZRELÉK vagy SÁVOS
 * díjszámítás a _realEzrelek alapján dőlt el.
 *
 * A HandlingFeeCalculator erre a service-re épít:
 * - calculateHandlingFee() → szerver oldali díjszámítás
 * - getRemainingCustomFeeQuota() → napi egyedi díj limit
 *
 * System paraméterek:
 * - HANDLING_FEE_TYPE: NONE / PER_MILLE / BRACKET
 * - HANDLING_FEE_PER_MILLE: ezrelék érték (pl. "5" = 5‰)
 * - DAILY_CUSTOM_FEE_LIMIT: napi egyedi díj limit (default: 3)
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
@Slf4j
public class HandlingFeeService {

    private final SystemParameterService systemParameterService;
    private final HandlingFeeBracketRepository bracketRepository;
    private final HandlingFeeTransactionRepository feeTransactionRepository;
    private final DiscountThresholdService discountThresholdService;

    /** Default napi egyedi kezelési díj limit */
    private static final int DEFAULT_DAILY_CUSTOM_FEE_LIMIT = 3;

    /**
     * Kezelési díj számítása a HUF összeg alapján.
     *
     * A díj típusa a system_parameter HANDLING_FEE_TYPE értékétől függ:
     * - NONE: 0 Ft (nincs díj)
     * - PER_MILLE: összeg × ezrelék / 1000
     * - BRACKET: sávos díjtáblázat
     *
     * @param hufAmount tranzakció HUF összege (nettó)
     * @return kezelési díj (Ft)
     */
    public BigDecimal calculateHandlingFee(BigDecimal hufAmount) {
        if (hufAmount == null || hufAmount.compareTo(BigDecimal.ZERO) <= 0) {
            return BigDecimal.ZERO;
        }

        HandlingFeeType feeType = resolveFeeType();

        BigDecimal baseFee = switch (feeType) {
            case NONE -> BigDecimal.ZERO;
            case PER_MILLE -> calculatePerMille(hufAmount);
            case BRACKET -> calculateBracket(hufAmount);
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
     * Díj típus feloldása system_parameter-ből.
     */
    private HandlingFeeType resolveFeeType() {
        try {
            String typeStr = systemParameterService.getValue("HANDLING_FEE_TYPE");
            return HandlingFeeType.valueOf(typeStr.toUpperCase());
        } catch (Exception e) {
            log.warn("HANDLING_FEE_TYPE paraméter nem olvasható ({}), default: BRACKET", e.getMessage());
            return HandlingFeeType.BRACKET;
        }
    }

    /**
     * Ezrelékes díjszámítás.
     * Legacy: _realEzrelek > 0 esetén → összeg × ezrelék / 1000
     */
    private BigDecimal calculatePerMille(BigDecimal hufAmount) {
        try {
            String perMilleStr = systemParameterService.getValue("HANDLING_FEE_PER_MILLE");
            BigDecimal perMille = new BigDecimal(perMilleStr);
            return hufAmount.multiply(perMille)
                    .divide(BigDecimal.valueOf(1000), 0, RoundingMode.HALF_UP);
        } catch (Exception e) {
            log.error("PER_MILLE díjszámítás hiba: {}", e.getMessage());
            return BigDecimal.ZERO;
        }
    }

    /**
     * Sávos díjszámítás.
     * Legacy: _tranzsav[1..23] és _kdij[1..23] tömbök
     * Az összeg sávba esését a bracket tábla alapján keressük.
     */
    private BigDecimal calculateBracket(BigDecimal hufAmount) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        List<HandlingFeeBracket> brackets = bracketRepository
                .findByCompanyIdAndActiveOrderByBracketOrder(companyId, true);

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
     */
    private int getDailyCustomFeeLimit() {
        try {
            return Integer.parseInt(systemParameterService.getValue("DAILY_CUSTOM_FEE_LIMIT"));
        } catch (Exception e) {
            return DEFAULT_DAILY_CUSTOM_FEE_LIMIT;
        }
    }
}
