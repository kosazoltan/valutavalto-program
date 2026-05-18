package hu.puzzleir.valuta.dto.diagnostics;

import java.util.List;

/**
 * AI-olvashato hibakod-katalogus valasz DTO.
 *
 * <p>Tartalmazza a {@code packages/shared-logging/error-codes.yaml}-bol
 * betoltott teljes listat, hogy a frontend / admin diagnostics UI
 * lekerdezhesse a hibakodok jelenleseit + AI-fix-hint-jeit.
 */
public record ErrorCodeCatalogDto(
        String version,
        int totalCodes,
        List<ErrorCodeEntry> codes
) {
    public record ErrorCodeEntry(
            String code,               // "VV-AML-001"
            String name,               // "AML_THRESHOLD_VIOLATION"
            String category,           // "AML"
            String level,              // "ERROR"
            String userImpact,         // "Tranzakcio elutasitva, identifikacio szukseges"
            String aiFixHint           // Hivatkozas a fix-receptre
    ) {}
}
