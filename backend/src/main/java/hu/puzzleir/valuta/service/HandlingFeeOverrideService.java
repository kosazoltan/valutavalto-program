package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.ApprovalLevel;
import hu.puzzleir.valuta.entity.HandlingFeeOverrideReason;
import hu.puzzleir.valuta.entity.HandlingFeeOverrideType;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.util.HungarianRounding;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;

/**
 * FK-KEZDÍJ (2026-06-02): a kezelési díj módosításának (override) SZERVER-OLDALI, AUTORITATÍV
 * validálása és feloldása az üzleti engedély-mátrix szerint.
 *
 * <p><b>Engedély-mátrix (Kósa Zoltán, 2026-06-02):</b>
 * <ul>
 *   <li>Ügyvezető/főértéktáros jóváhagyással ({@code DIRECTOR_APPROVAL}): felezés / elengedés / speciális.</li>
 *   <li>Ügyfélkártyával ({@code CUSTOMER_CARD}, kártyaszám KÖTELEZŐ): felezés / elengedés.</li>
 *   <li>Akció keretében ({@code PROMOTION}): felezés / elengedés.</li>
 *   <li>Speciális (egyedi összegű) díj KIZÁRÓLAG {@code DIRECTOR_APPROVAL} + director-szintű worker.</li>
 * </ul>
 *
 * <p>A kliens által küldött díj-összeget CSAK a {@code SPECIAL} (director-jóváhagyott) ágon
 * fogadjuk el; {@code HALF}/{@code WAIVED} esetén a szerver SZÁMOLJA a végeredményt (base/2, ill. 0),
 * így a kliens nem manipulálhatja az összeget. A worker-szint a bejelentkezett dolgozó role-jából
 * jön (ugyanaz a {@link DiscountApprovalService#mapRoleToLevel} leképzés).</p>
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class HandlingFeeOverrideService {

    private final DiscountApprovalService discountApprovalService;

    /**
     * Validálja a kezelési díj override-ot, és visszaadja a VÉGLEGES (alkalmazandó) díjat.
     *
     * @param baseFee       a szerver által számolt alap kezelési díj
     * @param type          override típus (NONE → nincs módosítás)
     * @param reason        override jogcím
     * @param cardNumber    ügyfélkártya-szám (CUSTOMER_CARD esetén kötelező)
     * @param requestedFee  a kliens által kért díj (CSAK SPECIAL ágon használt)
     * @param workerRole    a bejelentkezett dolgozó szerepköre (jogosultság-ellenőrzéshez)
     * @return a véglegesen alkalmazandó kezelési díj
     * @throws ValidationException ha az override az engedély-mátrix szerint nem megengedett
     */
    public BigDecimal resolveOverride(BigDecimal baseFee,
                                      HandlingFeeOverrideType type,
                                      HandlingFeeOverrideReason reason,
                                      String cardNumber,
                                      BigDecimal requestedFee,
                                      String workerRole) {
        BigDecimal base = (baseFee == null) ? BigDecimal.ZERO : baseFee;
        if (type == null || type == HandlingFeeOverrideType.NONE) {
            return base;
        }
        if (reason == null) {
            throw new ValidationException("A kezelési díj módosításához jogcím (ügyvezetői jóváhagyás / ügyfélkártya / akció) kötelező.");
        }

        ApprovalLevel workerLevel = discountApprovalService.mapRoleToLevel(workerRole);
        boolean isDirector = workerLevel.satisfies(ApprovalLevel.DIRECTOR);

        // Jogcím-előfeltételek
        switch (reason) {
            case DIRECTOR_APPROVAL -> {
                if (!isDirector) {
                    throw new ValidationException(
                            "A kezelési díj módosításához ügyvezetői/főértéktárosi jóváhagyás szükséges.");
                }
            }
            case CUSTOMER_CARD -> {
                if (cardNumber == null || cardNumber.isBlank()) {
                    throw new ValidationException(
                            "Ügyfélkártyás kezelésidíj-kedvezményhez a kártyaszám megadása kötelező.");
                }
            }
            case PROMOTION -> { /* akció — bárki alkalmazhatja (felezés/elengedés) */ }
        }

        BigDecimal resolved = switch (type) {
            case HALF -> HungarianRounding.roundToFive(
                    base.divide(BigDecimal.valueOf(2), 0, RoundingMode.HALF_UP));
            case WAIVED -> BigDecimal.ZERO;
            case SPECIAL -> {
                // Speciális (egyedi) díj KIZÁRÓLAG ügyvezetői/főértéktárosi jóváhagyással.
                if (reason != HandlingFeeOverrideReason.DIRECTOR_APPROVAL || !isDirector) {
                    throw new ValidationException(
                            "Speciális (egyedi) kezelési díjhoz ügyvezetői/főértéktárosi jóváhagyás szükséges.");
                }
                if (requestedFee == null || requestedFee.compareTo(BigDecimal.ZERO) < 0) {
                    throw new ValidationException("A speciális kezelési díj nem lehet negatív.");
                }
                yield HungarianRounding.roundToFive(requestedFee);
            }
            case NONE -> base; // nem érhető el (a fenti early-return miatt)
        };

        log.info("HANDLING_FEE_OVERRIDE type={} reason={} base={} resolved={} role={}",
                type, reason, base, resolved, workerRole);
        return resolved;
    }
}
