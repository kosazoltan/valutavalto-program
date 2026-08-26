package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.entity.HandlingFeeBracket;
import hu.puzzleir.valuta.entity.HandlingFeeType;
import hu.puzzleir.valuta.entity.TransactionType;
import hu.puzzleir.valuta.repository.HandlingFeeBracketRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.util.HungarianRounding;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/**
 * Kezelési díj kalkulátor — szerver oldali autoritatív számítás.
 *
 * Legacy: GetKezelesidij — a Delphi rendszerben az EZRELÉK vagy SÁVOS
 * díjszámítás a _realEzrelek alapján dőlt el.
 *
 * FONTOS: A kliens által küldött handlingFee-t SOHA nem fogadjuk el vakon.
 * A szerver MINDIG újraszámolja, és ha eltér → WARNING log + szerver oldali érték érvényesül.
 *
 * Egyedi kezelési díj limit: max 3/nap/pénztáros (legacy: HARDWARE.NAPIEGYEDIKEZDIJ)
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
@Slf4j
public class HandlingFeeCalculator {

    private final HandlingFeeService handlingFeeService;
    private final TransactionRepository transactionRepository;

    /** Napi egyedi kezelési díj limit (legacy: HARDWARE.SAJATHATASKORU max 5/nap) */
    private static final int DAILY_CUSTOM_FEE_LIMIT = 5;

    /**
     * Kezelési díj számítása és validálása — IRODA-TUDATOS (FK-096).
     *
     * @param hufAmount tranzakció HUF összege (nettó, díj nélkül)
     * @param transactionType tranzakció típusa
     * @param clientHandlingFee kliens által küldött kezelési díj (lehet null)
     * @param branchId a díjat viselő iroda azonosítója — a hívó adja át EXPLICITEN
     *                 (DIP: a kalkulator SecurityContext nélkül tesztelhető)
     * @return szerver által számított kezelési díj
     */
    public BigDecimal calculate(BigDecimal hufAmount, TransactionType transactionType,
                                BigDecimal clientHandlingFee, UUID branchId) {
        if (hufAmount == null || hufAmount.compareTo(BigDecimal.ZERO) <= 0) {
            return BigDecimal.ZERO;
        }

        // Legacy: konverziónál kezelési díj = 0 (Delphi: if _ezkonverzio then _kezelesidij := 0)
        if (transactionType == TransactionType.CONVERSION) {
            return BigDecimal.ZERO;
        }

        // Szerver oldali számítás — iroda-szintű, fail-closed (FR-5)
        BigDecimal serverFee = handlingFeeService.calculateHandlingFee(hufAmount, branchId);

        // 5 Ft-ra kerekítés
        serverFee = HungarianRounding.roundToFive(serverFee);

        // Kliens-szerver eltérés validáció
        if (clientHandlingFee != null && clientHandlingFee.compareTo(BigDecimal.ZERO) != 0) {
            BigDecimal diff = clientHandlingFee.subtract(serverFee).abs();
            if (diff.compareTo(BigDecimal.ONE) > 0) {
                log.warn("Kezelési díj eltérés! Kliens: {} Ft, Szerver: {} Ft, Típus: {}, Összeg: {} Ft. " +
                         "Szerver oldali érték érvényesül.",
                        clientHandlingFee, serverFee, transactionType, hufAmount);
            }
        }

        return serverFee;
    }

    /**
     * Egyedi kezelési díj validálása.
     * Ellenőrzi, hogy a pénztáros nem lépte-e túl a napi limitet.
     *
     * @param customFee egyedi kezelési díj összege
     * @throws ValidationException ha a napi limit elérve
     */
    public void validateCustomFee(BigDecimal customFee) {
        if (customFee == null || customFee.compareTo(BigDecimal.ZERO) == 0) {
            return;
        }

        int remaining = handlingFeeService.getRemainingCustomFeeQuota();
        if (remaining <= 0) {
            throw new ValidationException(
                String.format("Napi egyedi kezelési díj limit (%d) elérve! Supervisor jóváhagyás szükséges.",
                    DAILY_CUSTOM_FEE_LIMIT));
        }
    }

    /**
     * Bruttó összeg számítása eladásnál.
     * Eladás: bruttó = nettó + kezelési díj
     *
     * @param netAmount nettó HUF összeg
     * @param handlingFee kezelési díj
     * @return bruttó összeg
     */
    public BigDecimal calculateSellGross(BigDecimal netAmount, BigDecimal handlingFee) {
        if (netAmount == null) {
            throw new ValidationException("Nettó összeg nem lehet null!");
        }
        return netAmount.add(handlingFee != null ? handlingFee : BigDecimal.ZERO);
    }

    /**
     * Bruttó összeg számítása vételnél.
     * Vétel: bruttó = nettó - kezelési díj (a cég a kezelési díjat levonja)
     *
     * @param netAmount nettó HUF összeg
     * @param handlingFee kezelési díj
     * @return bruttó összeg
     */
    public BigDecimal calculateBuyGross(BigDecimal netAmount, BigDecimal handlingFee) {
        if (netAmount == null) {
            throw new ValidationException("Nettó összeg nem lehet null!");
        }
        return netAmount.subtract(handlingFee != null ? handlingFee : BigDecimal.ZERO);
    }
}
