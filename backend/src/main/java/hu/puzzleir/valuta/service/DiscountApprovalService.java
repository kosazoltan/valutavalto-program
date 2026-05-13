package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.ApprovalLevel;
import hu.puzzleir.valuta.exception.ValidationException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.Locale;

/**
 * Kedvezmény jóváhagyási szint meghatározó — Sprint 4 P2-D.
 *
 * <p>v2.0 spec 03_tranzakciok.md:
 * <ul>
 *   <li>0-2% — CASHIER (saját, nincs külön approval)</li>
 *   <li>2-5% — SUPERVISOR jóváhagyás</li>
 *   <li>5-10% — MANAGER jóváhagyás</li>
 *   <li>10-15% — DIRECTOR jóváhagyás</li>
 *   <li>15%+ — TILTVA</li>
 * </ul></p>
 *
 * <p>A küszöbök a SystemParameter-ből konfigurálhatóak.</p>
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class DiscountApprovalService {

    private final SystemParameterService systemParameterService;

    /**
     * Visszaadja a kívánt jóváhagyási szintet egy discount %-hoz.
     * SystemParameter küszöbök:
     *   DISCOUNT_SUPERVISOR_THRESHOLD_PCT (default 2.0)
     *   DISCOUNT_MANAGER_THRESHOLD_PCT (default 5.0)
     *   DISCOUNT_DIRECTOR_THRESHOLD_PCT (default 10.0)
     */
    public ApprovalLevel getRequiredLevel(BigDecimal discountPercent) {
        if (discountPercent == null || discountPercent.signum() <= 0) {
            return ApprovalLevel.CASHIER;
        }
        BigDecimal supervisor = parseParam("DISCOUNT_SUPERVISOR_THRESHOLD_PCT", "2.0");
        BigDecimal manager = parseParam("DISCOUNT_MANAGER_THRESHOLD_PCT", "5.0");
        BigDecimal director = parseParam("DISCOUNT_DIRECTOR_THRESHOLD_PCT", "10.0");

        if (discountPercent.compareTo(supervisor) <= 0) {
            return ApprovalLevel.CASHIER;
        }
        if (discountPercent.compareTo(manager) <= 0) {
            return ApprovalLevel.SUPERVISOR;
        }
        if (discountPercent.compareTo(director) <= 0) {
            return ApprovalLevel.MANAGER;
        }
        return ApprovalLevel.DIRECTOR;
    }

    /**
     * Validálja, hogy a hívó worker level >= required level.
     * Worker role-ja alapján határozzuk meg a saját szintjét.
     */
    public void validateApprovalLevel(BigDecimal discountPercent, String workerRole) {
        // Codex P2 #571 fix: 15%+ kedvezmény NEM engedélyezett senkinek (a class doc explicit
        // állítja: "15%+ tilos"). Korábban DIRECTOR-szintű worker auto-allow volt minden %-ot.
        if (discountPercent != null) {
            BigDecimal maxAllowed = parseParam("DISCOUNT_MAX_PCT", "15.0");
            if (discountPercent.compareTo(maxAllowed) > 0) {
                throw new ValidationException(String.format(
                        "A %s%% kedvezmény meghaladja a rendszer-szintű maximum %s%%-ot — üzleti policy szerint NEM alkalmazható.",
                        discountPercent.toPlainString(), maxAllowed.toPlainString()));
            }
        }
        ApprovalLevel required = getRequiredLevel(discountPercent);
        ApprovalLevel worker = mapRoleToLevel(workerRole);

        if (!worker.satisfies(required)) {
            throw new ValidationException(String.format(
                    "A %s%% kedvezmény %s szintű jóváhagyást igényel — a jelenlegi szint csak %s. " +
                    "Kérjen vezetői jóváhagyást.",
                    discountPercent.toPlainString(), required.name(), worker.name()));
        }
    }

    /**
     * Worker role → ApprovalLevel mapping.
     */
    public ApprovalLevel mapRoleToLevel(String role) {
        if (role == null) return ApprovalLevel.CASHIER;
        // Codex P2 #571 fix: a valós operational role code REGIONAL_MGR (NEM REGIONAL_MANAGER),
        // lásd JwtAuthenticationFilter.normalizeOperationalRoleForAuthority. Mindkét alak elfogadva
        // (REGIONAL_MGR a JWT activeRole-ból, REGIONAL_MANAGER a legacy worker.role mezőből vagy
        // hosszabb forma). Hasonlóan OFFICE_MGR vs OFFICE_MANAGER.
        return switch (role.toUpperCase(Locale.ROOT)) {
            case "DIRECTOR", "MAIN_TREASURY", "ADMIN", "SYSTEM_ADMIN", "UGYVEZETO", "FOERTEKTAR" -> ApprovalLevel.DIRECTOR;
            case "MANAGER", "REGIONAL_MANAGER", "REGIONAL_MGR", "TREASURY_MANAGER", "OFFICE_MGR", "OFFICE_MANAGER", "TERULETI_VEZETO", "IRODAVEZETO" -> ApprovalLevel.MANAGER;
            case "SUPERVISOR", "CASHIER_SUPERVISOR", "BELSO_ELLENOR" -> ApprovalLevel.SUPERVISOR;
            default -> ApprovalLevel.CASHIER;
        };
    }

    private BigDecimal parseParam(String key, String defaultValue) {
        String value = systemParameterService.getValue(key, defaultValue);
        // Codex P2 #571 follow-up: null-defense, ha a mock vagy üres rendszerből null jön vissza
        if (value == null || value.isBlank()) {
            return new BigDecimal(defaultValue);
        }
        try {
            return new BigDecimal(value.trim());
        } catch (NumberFormatException e) {
            log.warn("SystemParameter '{}' nem numerikus: '{}' — default '{}' használata", key, value, defaultValue);
            return new BigDecimal(defaultValue);
        }
    }
}
