package hu.puzzleir.valuta.dto.diagnostics;

import java.util.UUID;

/**
 * Audit hash-chain integritas ellenorzes valasz.
 *
 * <p>Ha a {@code firstBrokenEntryId} = NULL → minden OK.
 * Ha NEM NULL → az adott audit_log sor utan a chain megsertve (tamper-evidence).
 */
public record HashChainIntegrityResponseDto(
        int checkedCount,
        boolean intact,
        UUID firstBrokenEntryId,
        String message
) {
    public static HashChainIntegrityResponseDto ok(int checkedCount) {
        return new HashChainIntegrityResponseDto(checkedCount, true, null,
                "Hash chain integritasa rendben: " + checkedCount + " bejegyzes ellenorizve.");
    }

    public static HashChainIntegrityResponseDto broken(int checkedCount, UUID brokenId) {
        return new HashChainIntegrityResponseDto(checkedCount, false, brokenId,
                "Hash chain SERTETT - elso problemás sor: " + brokenId);
    }
}
