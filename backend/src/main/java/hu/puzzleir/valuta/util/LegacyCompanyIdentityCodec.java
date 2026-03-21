package hu.puzzleir.valuta.util;

import java.util.UUID;

/**
 * UUID -> legacy Integer company identity bridge.
 *
 * Legacy modulok egy resze Integer companyId-t hasznal,
 * mig az uj multi-tenant modell UUID-t. A lekepzesnek stabilnak
 * es reprodukalhatonak kell lennie ugyanarra a UUID-re.
 */
public final class LegacyCompanyIdentityCodec {

    private LegacyCompanyIdentityCodec() {
    }

    public static Integer toLegacyInt(UUID companyUuid) {
        if (companyUuid == null) {
            return null;
        }
        return Math.abs((int) (companyUuid.getLeastSignificantBits() % Integer.MAX_VALUE));
    }
}
