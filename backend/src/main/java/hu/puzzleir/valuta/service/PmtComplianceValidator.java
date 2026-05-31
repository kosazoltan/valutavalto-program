package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.exception.ValidationException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

/**
 * Pmt. (2017. évi LIII. tv.) kötelező compliance-mezők ellenőrzése 300k+ HUF tranzakcióknál.
 *
 * <p>Megosztott komponens, hogy a BUY/SELL ({@link TransactionService}) ÉS a KONVERZIÓ
 * ({@link TransactionConversionService}) UGYANAZT az ellenőrzést futtassa — különben a
 * konverzió-ág kicsúszna a Pmt-validáció alól (audit F-002 / Codex P1, 2026-05-29).</p>
 *
 * <p>Enforcement: a {@code PMT_STRICT_ENFORCEMENT} system-parameter dönti el; a kód-default
 * mostantól {@code true} (a v2.5.59 kompat-ablak rég lejárt). A strict-ág CSAK feltételesen
 * blokkol (300k+ ÉS hiányzó PEP-minőség / actor-adat) — a normál tranzakciót nem érinti.</p>
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class PmtComplianceValidator {

    private static final BigDecimal THRESHOLD = BigDecimal.valueOf(300_000);

    private final SystemParameterService systemParameterService;

    /**
     * @param hufAmount             a tranzakció HUF-ellenértéke (konverziónál az AML-alap)
     * @param customerIsPep         PEP-e az ügyfél
     * @param customerPepKind       PEP-minőség (isPep=true esetén kötelező)
     * @param customerOnOwnBehalf   saját nevében jár-e el (false → képviselt fél azonosítása kötelező)
     * @param operation             a művelet megnevezése a hibaüzenethez (BUY/SELL/KONVERZIO)
     */
    public void validate(
            BigDecimal hufAmount,
            Boolean customerIsPep,
            String customerPepKind,
            Boolean customerOnOwnBehalf,
            String customerActorName,
            String customerActorBirthPlace,
            String customerActorBirthDate,
            String customerActorMotherName,
            String customerActorDocumentNumber,
            String customerActorAddress,
            String operation) {
        if (hufAmount == null || hufAmount.compareTo(THRESHOLD) < 0) {
            return; // < 300k: Pmt. szerint nem kotelezo
        }
        // F-002 (audit 2026-05-29): a default mostantol 'true' (a v2.5.59 kompat-ablak lejart).
        // Null szerviz (mockolt unit-teszt) -> strictMode false marad (kompatibilitas).
        // Dev/test a system-parameterrel explicit 'false'-ra allithatja.
        boolean strictMode = systemParameterService != null
                && "true".equalsIgnoreCase(systemParameterService.getValue("PMT_STRICT_ENFORCEMENT", "true"));

        // PEP minoseg kotelezo, ha isPep=true
        if (Boolean.TRUE.equals(customerIsPep) && (customerPepKind == null || customerPepKind.isBlank())) {
            String msg = String.format(
                "Pmt. compliance (%s, %s HUF): customerIsPep=true de customerPepKind hianyzik. "
                + "Pmt. tv. 6.§ szerint kotelezo megjelolni a PEP minoseget.", operation, hufAmount);
            if (strictMode) {
                throw new ValidationException(msg);
            }
            log.warn("{} (WARN-only, PMT_STRICT_ENFORCEMENT=false).", msg);
        }
        // Actor teljes azonositasa kotelezo, ha onOwnBehalf=false
        if (Boolean.FALSE.equals(customerOnOwnBehalf)) {
            List<String> missing = new ArrayList<>();
            if (customerActorName == null          || customerActorName.isBlank())          missing.add("actorName");
            if (customerActorBirthPlace == null    || customerActorBirthPlace.isBlank())    missing.add("actorBirthPlace");
            if (customerActorBirthDate == null     || customerActorBirthDate.isBlank())     missing.add("actorBirthDate");
            if (customerActorMotherName == null    || customerActorMotherName.isBlank())    missing.add("actorMotherName");
            if (customerActorDocumentNumber == null|| customerActorDocumentNumber.isBlank()) missing.add("actorDocumentNumber");
            if (customerActorAddress == null       || customerActorAddress.isBlank())       missing.add("actorAddress");
            if (!missing.isEmpty()) {
                String msg = String.format(
                    "Pmt. compliance (%s, %s HUF): customerOnOwnBehalf=false de actor mezok hianyoznak: %s. "
                    + "Pmt. tv. 6.§ (2) szerint a kepviselt felre is teljes azonositast kell vegezni.",
                    operation, hufAmount, missing);
                if (strictMode) {
                    throw new ValidationException(msg);
                }
                log.warn("{} (WARN-only, PMT_STRICT_ENFORCEMENT=false).", msg);
            }
        }
    }
}
