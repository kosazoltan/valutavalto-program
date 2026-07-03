package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.exception.ValidationException;

import java.math.BigDecimal;

/**
 * FK-054 service-layer pre-gate for {@link hu.puzzleir.valuta.entity.CurrencyStock#issueStock(BigDecimal)}.
 * The entity keeps its IllegalStateException invariant as the last-resort guard; business denials must reach
 * controllers as ValidationException before any stock mutation happens.
 */
final class VaultStockCoverageGate {

    private static final String ENTITY_TYPE_VAULT = "VAULT";

    private VaultStockCoverageGate() {
    }

    static void requireSufficientStock(String entityType, String entityId, String currencyCode,
                                       BigDecimal available, BigDecimal required) {
        if (available.compareTo(required) >= 0) {
            return;
        }
        throw insufficientStockException(entityType, entityId, currencyCode, available, required);
    }

    static ValidationException insufficientStockException(String entityType, String entityId, String currencyCode,
                                                         BigDecimal available, BigDecimal required) {
        boolean vault = ENTITY_TYPE_VAULT.equals(entityType);
        String stockLabel = vault ? "értéktári" : "pénztári";
        String location = vault ? "territory: " + entityId : "entity: " + entityType + "/" + entityId;
        return new ValidationException(String.format(
                "Nincs elegendő %s %s készlet! Elérhető: %s, szükséges: %s (%s). "
                        + "A művelet nem hajtható végre — készleten túli forgalmazás tiltva.",
                stockLabel,
                currencyCode,
                available.toPlainString(),
                required.toPlainString(),
                location));
    }
}
