package hu.puzzleir.valuta.util;

import java.util.UUID;

/**
 * Segéd osztály a legacy LONG transaction ID és a kamera/dokumentum modulok
 * UUID-alapú referenciái közti determinisztikus leképezéshez.
 */
public final class TransactionIdentityCodec {

    private TransactionIdentityCodec() {
    }

    public static UUID toUuid(Long transactionId) {
        if (transactionId == null) {
            return null;
        }
        return new UUID(0L, transactionId);
    }

    public static UUID parseUuidOrLegacyLong(String value) {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException("transactionId nem lehet üres");
        }

        try {
            return UUID.fromString(value);
        } catch (IllegalArgumentException ignored) {
            return toUuid(Long.parseLong(value));
        }
    }
}
