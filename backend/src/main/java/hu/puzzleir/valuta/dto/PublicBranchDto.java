package hu.puzzleir.valuta.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Publikus branch info — a pénztáros kliens first-run wizard
 * számára készített adat. NINCS benne érzékeny mező (pl. belső ID,
 * bank-kód, létrehozási idő stb.), csak a felhasználó-felé
 * látható alapadatok.
 *
 * <p>Csak {@code active=true} branch-ek kerülnek a listába,
 * company-szűrten.</p>
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PublicBranchDto {

    /** Kötelező — pl. "TISZA", "101" */
    private String code;

    /** Kötelező — pl. "Tisza Sarok" */
    private String name;

    /** Opcionális — pl. "Szeged" */
    private String city;

    /** Opcionális — pl. "Tisza Sarok, Szeged" */
    private String address;
}
