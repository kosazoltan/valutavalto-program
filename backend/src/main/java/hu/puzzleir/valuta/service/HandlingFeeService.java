package hu.puzzleir.valuta.service;

import com.puzzleir.backend.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.entity.HandlingFeeBracket;
import hu.puzzleir.valuta.entity.HandlingFeeType;
import hu.puzzleir.valuta.entity.InitialFeeConfig;
import hu.puzzleir.valuta.repository.HandlingFeeBracketRepository;
import hu.puzzleir.valuta.repository.InitialFeeConfigRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.List;
import java.util.UUID;

/**
 * Kezelési díj számító motor.
 *
 * Legacy: A régi rendszerben két kezelési díj rendszer létezett:
 *
 * 1. EZRELÉKES rendszer (_realEzrelek > 0):
 *    díj = összeg * ezrelék / 1000
 *    Pl. 5 ezrelék: 100.000 Ft tranzakció → 500 Ft díj
 *
 * 2. SÁVOS rendszer (_realEzrelek < 0):
 *    _tranzsav[1..23] = sáv felső határai
 *    _kdij[1..23] = sávhoz tartozó díjak
 *    Az összeg melyik sávba esik, annyi a díj.
 *
 * Ezen felül: KEZDŐJEGY (initial fee)
 *    - Minden tranzakcióhoz járhat kezdőjegy
 *    - Saját hatáskörű kedvezmény (SHK): max 5/nap, a pénztáros elengedheti
 *    - Egyedi kezdőjegy: max 3/nap
 *    - VIP, értéktáros engedély stb. felülírhatja
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
@Slf4j
public class HandlingFeeService {

    private final HandlingFeeBracketRepository bracketRepository;
    private final InitialFeeConfigRepository initialFeeConfigRepository;
    private final SystemParameterService systemParameterService;

    /**
     * Kezelési díj számítása az összeg alapján.
     *
     * @param hufAmount tranzakció forint összege
     * @return kezelési díj Ft-ban (kerekítve)
     */
    public BigDecimal calculateHandlingFee(BigDecimal hufAmount) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        HandlingFeeType feeType = getHandlingFeeType(companyId);

        switch (feeType) {
            case NONE:
                return BigDecimal.ZERO;

            case PER_MILLE:
                return calculatePerMilleFee(hufAmount, companyId);

            case BRACKET:
                return calculateBracketFee(hufAmount, companyId);

            default:
                return BigDecimal.ZERO;
        }
    }

    /**
     * Ezrelékes díj számítás.
     * Legacy: díj = összeg * _realEzrelek / 1000, kerekítve 5 Ft-ra
     */
    private BigDecimal calculatePerMilleFee(BigDecimal hufAmount, UUID companyId) {
        int perMille = getPerMilleRate(companyId);
        if (perMille <= 0) return BigDecimal.ZERO;

        BigDecimal fee = hufAmount
            .multiply(new BigDecimal(perMille))
            .divide(new BigDecimal( 1000), 0, RoundingMode.HALF_UP);

        // Kerekítés 5 Ft-ra (legacy: mindig 5-re kerekít)
        return roundToFive(fee);
    }

    /**
     * Sávos díj számítás.
     * Legacy: A _tranzsav tömbben keresi meg melyik sávba esik az összeg,
     *         és a _kdij tömbből veszi a díjat.
     */
    private BigDecimal calculateBracketFee(BigDecimal hufAmount, UUID companyId) {
        List<HandlingFeeBracket> brackets = bracketRepository
            .findByCompanyIdAndActiveOrderByBracketOrder(companyId, true);

        if (brackets.isEmpty()) return BigDecimal.ZERO;

        for (HandlingFeeBracket bracket : brackets) {
            if (hufAmount.compareTo(bracket.getUpperLimit()) <= 0) {
                return bracket.getFeeAmount();
            }
        }

        // Ha az összeg minden sávot meghalad, az utolsó sáv díja
        return brackets.get(brackets.size() - 1).getFeeAmount();
    }

    /**
     * Kezdőjegy (initial fee) számítása.
     *
     * Legacy: A KEZDIJ táblából olvassa, típustól függ.
     * Ha a tranzakció összege eléri a minimumot, jár a kezdőjegy.
     */
    public BigDecimal calculateInitialFee(BigDecimal hufAmount) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();

        InitialFeeConfig config = initialFeeConfigRepository
            .findByCompanyIdAndActive(companyId, true)
            .orElse(null);

        if (config == null) return BigDecimal.ZERO;

        // Minimum összeg ellenőrzés
        if (config.getMinTransactionAmount() != null
            && hufAmount.compareTo(config.getMinTransactionAmount()) < 0) {
            return BigDecimal.ZERO;
        }

        BigDecimal fee = config.getFeeAmount();

        // Maximum korlát
        if (config.getMaxFeeAmount() != null
            && fee.compareTo(config.getMaxFeeAmount()) > 0) {
            fee = config.getMaxFeeAmount();
        }

        return fee;
    }

    /**
     * Saját hatáskörű kedvezmény (SHK) ellenőrzése.
     *
     * Legacy: _shk = GetSajatHataskoru — max 5/nap
     * A pénztáros napi SHK kerete csökken minden kedvezményes tranzakcióval.
     *
     * @return hátralévő SHK keret (0 = nem adhat több kedvezményt)
     */
    public int getRemainingShkQuota() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();

        InitialFeeConfig config = initialFeeConfigRepository
            .findByCompanyIdAndActive(companyId, true)
            .orElse(null);

        int dailyLimit = (config != null && config.getDailyDiscountLimit() != null)
            ? config.getDailyDiscountLimit() : 5;

        int usedToday = getUsedShkToday();
        return Math.max(0, dailyLimit - usedToday);
    }

    /**
     * Egyedi kezdőjegy napi keret ellenőrzése.
     *
     * Legacy: _mekd = 3 - _ne (napiegyedikezdij)
     * Max 3 egyedi kezdőjegy naponta.
     */
    public int getRemainingCustomFeeQuota() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();

        InitialFeeConfig config = initialFeeConfigRepository
            .findByCompanyIdAndActive(companyId, true)
            .orElse(null);

        int dailyLimit = (config != null && config.getDailyCustomFeeLimit() != null)
            ? config.getDailyCustomFeeLimit() : 3;

        int usedToday = getUsedCustomFeeToday();
        return Math.max(0, dailyLimit - usedToday);
    }

    /**
     * Teljes díj összesítés (kezelési díj + kezdőjegy).
     */
    public FeeCalculationResult calculateTotalFees(BigDecimal hufAmount) {
        BigDecimal handlingFee = calculateHandlingFee(hufAmount);
        BigDecimal initialFee = calculateInitialFee(hufAmount);
        BigDecimal totalFee = handlingFee.add(initialFee);
        int remainingShk = getRemainingShkQuota();
        int remainingCustomFee = getRemainingCustomFeeQuota();

        return FeeCalculationResult.builder()
            .handlingFee(handlingFee)
            .initialFee(initialFee)
            .totalFee(totalFee)
            .remainingShkQuota(remainingShk)
            .remainingCustomFeeQuota(remainingCustomFee)
            .feeType(getHandlingFeeType(SecurityUtils.getCurrentCompanyId()))
            .build();
    }

    // ============ HELPER ============

    private HandlingFeeType getHandlingFeeType(UUID companyId) {
        try {
            String typeStr = systemParameterService.getValue("HANDLING_FEE_TYPE");
            return HandlingFeeType.valueOf(typeStr);
        } catch (Exception e) {
            return HandlingFeeType.NONE;
        }
    }

    private int getPerMilleRate(UUID companyId) {
        try {
            String val = systemParameterService.getValue("HANDLING_FEE_PER_MILLE");
            return Integer.parseInt(val);
        } catch (Exception e) {
            return 0;
        }
    }

    /**
     * Kerekítés 5 Ft-ra (legacy kompatibilis).
     * 1-2 → 0, 3-7 → 5, 8-9 → 10
     */
    private BigDecimal roundToFive(BigDecimal amount) {
        long value = amount.longValue();
        long remainder = value % 5;
        if (remainder < 3) {
            return new BigDecimal(value - remainder);
        } else {
            return new BigDecimal(value + (5 - remainder));
        }
    }

    private int getUsedShkToday() {
        // TODO: Query from daily session / transaction stats
        return 0;
    }

    private int getUsedCustomFeeToday() {
        // TODO: Query from daily session / transaction stats
        return 0;
    }

    // ============ RESULT DTO ============

    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class FeeCalculationResult {
        private BigDecimal handlingFee;
        private BigDecimal initialFee;
        private BigDecimal totalFee;
        private int remainingShkQuota;
        private int remainingCustomFeeQuota;
        private HandlingFeeType feeType;
    }
}