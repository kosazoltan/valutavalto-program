package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.FeeDiscount;
import hu.puzzleir.valuta.repository.FeeDiscountRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import java.util.Optional;

/**
 * Kedvezmény automatikus kiválasztás — nagy/kis összeg threshold.
 *
 * Legacy: BIGARFVALT / KISARFVALT
 * - BIGARFVALT: nagy összegű tranzakció → automatikus kedvezmény (pl. 500.000 Ft felett)
 * - KISARFVALT: kis összegű tranzakció → felár (pl. 10.000 Ft alatt)
 *
 * Az automatikus kiválasztás system_parameter-ek alapján:
 * - BIG_DISCOUNT_THRESHOLD_HUF: 500000 (felette nagy kedvezmény)
 * - SMALL_SURCHARGE_THRESHOLD_HUF: 10000 (alatta felár)
 * - BIG_DISCOUNT_CODE: "NAGY_OSSZEG" (FeeDiscount kód)
 * - SMALL_SURCHARGE_CODE: "KIS_OSSZEG" (FeeDiscount kód)
 *
 * A pénztáros NEM választ manuálisan — a rendszer automatikusan alkalmazza.
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
@Slf4j
public class DiscountThresholdService {

    private final FeeDiscountRepository feeDiscountRepository;
    private final SystemParameterService systemParameterService;

    /** Default threshold-ok ha nincs system_parameter */
    private static final BigDecimal DEFAULT_BIG_THRESHOLD = new BigDecimal("500000");
    private static final BigDecimal DEFAULT_SMALL_THRESHOLD = new BigDecimal("10000");

    /**
     * Automatikus kedvezmény/felár meghatározása a HUF összeg alapján.
     *
     * @param hufAmount tranzakció HUF összege
     * @return alkalmazandó FeeDiscount (vagy empty ha nincs)
     */
    public Optional<FeeDiscount> resolveDiscount(BigDecimal hufAmount) {
        if (hufAmount == null || hufAmount.compareTo(BigDecimal.ZERO) <= 0) {
            return Optional.empty();
        }

        BigDecimal bigThreshold = getThreshold("BIG_DISCOUNT_THRESHOLD_HUF", DEFAULT_BIG_THRESHOLD);
        BigDecimal smallThreshold = getThreshold("SMALL_SURCHARGE_THRESHOLD_HUF", DEFAULT_SMALL_THRESHOLD);

        // Nagy összeg → kedvezmény
        if (hufAmount.compareTo(bigThreshold) >= 0) {
            return findActiveDiscount("BIG_DISCOUNT_CODE", "NAGY_OSSZEG");
        }

        // Kis összeg → felár
        if (hufAmount.compareTo(smallThreshold) <= 0) {
            return findActiveDiscount("SMALL_SURCHARGE_CODE", "KIS_OSSZEG");
        }

        // Normál sáv → nincs automatikus kedvezmény/felár
        return Optional.empty();
    }

    /**
     * Kedvezmény alkalmazása a kezelési díjra.
     *
     * @param originalFee eredeti kezelési díj
     * @param discount alkalmazandó kedvezmény
     * @return módosított kezelési díj
     */
    public BigDecimal applyDiscount(BigDecimal originalFee, FeeDiscount discount) {
        if (discount == null || discount.getDiscountValue() == null) {
            return originalFee;
        }

        String type = discount.getDiscountType();
        BigDecimal value = discount.getDiscountValue();

        return switch (type != null ? type.toUpperCase() : "") {
            case "PERCENT" -> {
                // Százalékos kedvezmény: díj * (1 - kedvezmény/100)
                BigDecimal multiplier = BigDecimal.ONE.subtract(
                        value.divide(new BigDecimal("100"), 6, java.math.RoundingMode.HALF_UP));
                yield originalFee.multiply(multiplier).setScale(0, java.math.RoundingMode.HALF_UP);
            }
            case "FIXED" -> {
                // Fix összegű kedvezmény
                BigDecimal result = originalFee.subtract(value);
                yield result.compareTo(BigDecimal.ZERO) > 0 ? result : BigDecimal.ZERO;
            }
            case "SURCHARGE_PERCENT" -> {
                // Százalékos felár: díj * (1 + felár/100)
                BigDecimal multiplier = BigDecimal.ONE.add(
                        value.divide(new BigDecimal("100"), 6, java.math.RoundingMode.HALF_UP));
                yield originalFee.multiply(multiplier).setScale(0, java.math.RoundingMode.HALF_UP);
            }
            case "SURCHARGE_FIXED" -> {
                // Fix összegű felár
                yield originalFee.add(value);
            }
            default -> {
                log.warn("Ismeretlen kedvezmény típus: {}", type);
                yield originalFee;
            }
        };
    }

    /**
     * Összes aktív kedvezmény listázása. F2 (V189): csak az aktuális cég.
     */
    public List<FeeDiscount> listActiveDiscounts() {
        UUID companyId = SecurityUtils.getCurrentCompanyIdOrNull();
        if (companyId == null) {
            return List.of();
        }
        return feeDiscountRepository.findByCompanyIdAndIsActiveTrue(companyId).stream()
                .filter(d -> d.getValidTo() == null || !d.getValidTo().isBefore(LocalDate.now()))
                .toList();
    }

    // === PRIVÁT ===

    private BigDecimal getThreshold(String paramKey, BigDecimal defaultValue) {
        try {
            return new BigDecimal(systemParameterService.getValue(paramKey));
        } catch (Exception e) {
            return defaultValue;
        }
    }

    /**
     * F2 cross-tenant fix (V189, 2026-05-06): a discount lookup most cég-szinten
     * szűri a `fee_discount` táblát. A SecurityUtils.getCurrentCompanyId()
     * visszaadja a JWT-ből a worker cégét.
     */
    private Optional<FeeDiscount> findActiveDiscount(String paramKey, String defaultCode) {
        UUID companyId = SecurityUtils.getCurrentCompanyIdOrNull();
        if (companyId == null) {
            return Optional.empty();
        }

        String resolvedCode;
        try {
            resolvedCode = systemParameterService.getValue(paramKey);
        } catch (Exception e) {
            resolvedCode = defaultCode;
        }
        final String code = resolvedCode;

        return feeDiscountRepository.findByCompanyIdAndCode(companyId, code)
                .filter(d -> d.getIsActive() != null && d.getIsActive())
                .filter(d -> d.getValidTo() == null || !d.getValidTo().isBefore(LocalDate.now()));
    }
}
