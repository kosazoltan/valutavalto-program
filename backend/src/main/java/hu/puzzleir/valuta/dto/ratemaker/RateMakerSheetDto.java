package hu.puzzleir.valuta.dto.ratemaker;

import java.time.LocalDateTime;

/**
 * Az árfolyamkészítő munkaív (rate-maker working sheet) szerver→kliens reprezentációja.
 * A {@code sheetJson} kliens-átlátszó (opaque) JSON-snapshot; a szerver nem értelmezi a tartalmát.
 */
public record RateMakerSheetDto(
        String sheetJson,
        Long version,
        String source,
        String deviceId,
        Long updatedBy,
        LocalDateTime updatedAt
) {
}
