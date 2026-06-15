package hu.puzzleir.valuta.dto.ratemaker;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * Az árfolyamkészítő munkaív (rate-maker working sheet) kliens→szerver feltöltése (PUT).
 *
 * <p>A {@code sheetJson} a munkaív teljes JSON-snapshotja. A {@code baseVersion} (opcionális) az a
 * verzió, amelyről a kliens a szerkesztést indította — ütközés-detektáláshoz. A {@code source}
 * 'rate-maker' (vékony kliens) vagy 'central' (központi modul).
 */
public record RateMakerSheetUpdateRequest(
        @NotBlank String sheetJson,
        @Size(max = 32) String source,
        @Size(max = 128) String deviceId,
        Long baseVersion
) {
}
