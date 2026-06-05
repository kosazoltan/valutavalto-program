package hu.puzzleir.valuta.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Bali Henriett FK-013 / 2. pont (2026-05-27): minimális adatlap egy új lakossági
 * pénztár felrögzítéséhez egy értéktáros vagy főértéktáros által.
 *
 * <p>A standard {@link CreateBranchDto} túl sok kötelező mezőt vár (bankCode,
 * branchTypeId, countryId, branchStatusId, openingDate, denominationRuleId) — ezeket
 * egy értéktáros nem tudja megadni. A backend service ezeket automatikusan kitölti
 * sensible default-okkal (HU ország, PENZTAR branch_type, ACTIVE branch_status,
 * mai nyitásdátum, bankCode = code).</p>
 *
 * <p>Kötelező a területi besorolás: a {@code regionCode} a {@code dictionary}
 * kategória {@code REGION} egy aktív kódja (pl. SZEGED, KECSKEMET, DEBRECEN). Ez
 * teszi lehetővé, hogy az új pénztár automatikusan megjelenjen a megfelelő
 * értéktár területi szűrt listájában (FK-005/B4).</p>
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CreateSimpleCashierBranchDto {

    @NotBlank(message = "A pénztár száma / azonosítója kötelező")
    @Size(min = 1, max = 20, message = "A kód hossza 1-20 karakter lehet")
    @Pattern(regexp = "^[A-Z0-9]+$", message = "A kód csak nagybetűket és számokat tartalmazhat (pl. BR099)")
    private String code;

    /** Opcionális megjelenítendő név. Ha üres, a service code-ból generál ("Pénztár <code>"). */
    @Size(max = 255, message = "A név max 255 karakter")
    private String name;

    @NotBlank(message = "A pénztár pontos címe kötelező")
    @Size(min = 5, max = 500, message = "A cím legalább 5, legfeljebb 500 karakter")
    private String address;

    /** Opcionális város. Ha üres, a service a regionCode-ból tölti ki (pl. "SZEGED" → "Szeged"). */
    @Size(max = 100, message = "A város max 100 karakter")
    private String city;

    /**
     * Opcionális irányítószám (4 számjegy). Ha üres, a service üres stringet (`""`)
     * ment — a {@code branch.zip_code} oszlop NOT NULL DEFAULT '' (V0_1__base_tables.sql),
     * post-create szerkesztésnél kitölthető (UpdateBranchDto-n keresztül).
     */
    @Pattern(regexp = "^(\\d{4})?$", message = "Az irányítószám 4 számjegyből áll, vagy üres")
    private String zipCode;

    /**
     * Kötelező területi besorolás: a {@code dictionary} kategória {@code REGION}
     * egy aktív {@code code}-ja (pl. SZEGED, KECSKEMET, DEBRECEN, PECS, KAPOSVAR,
     * NYIREGYHAZA, BEKESCSABA, SZEKSZARD, IRODA). A {@link Branch#regionCode}
     * mezőbe kerül — ez vezérli a területi szűrést.
     */
    @NotBlank(message = "A területi (régiós) hozzárendelés kötelező")
    @Pattern(regexp = "^[A-Z_]+$", message = "A régió kód csak nagybetűk és aláhúzás (pl. SZEGED)")
    private String regionCode;

    // ========================================================================
    // FK-021 (2026-06-05): teljes törzsadat-felrögzítés. Mind OPCIONÁLIS (nullable),
    // így a meglévő minimál NewCashierBranchPage-flow változatlanul működik (a service
    // null esetén a korábbi default-ot használja: isVault=false, isActive=true,
    // bankCode=code, V293-flagek=false).
    // ========================================================================

    /** Opcionális rövid név. Ha üres, a service nem állít (a name marad a megjelenítendő). */
    @Size(max = 100, message = "A rövid név max 100 karakter")
    private String shortName;

    /** Opcionális telefonszám. */
    @Size(max = 50, message = "A telefonszám max 50 karakter")
    private String phone;

    /** Opcionális e-mail cím. */
    @Email(message = "Érvénytelen e-mail formátum")
    @Size(max = 255, message = "Az e-mail max 255 karakter")
    private String email;

    /** Opcionális bankkód (banki hivatkozási szám). Ha üres, a service a code-ot használja. */
    @Size(max = 50, message = "A bankkód max 50 karakter")
    private String bankCode;

    /** FK-021: iroda típusa. true = Értéktár, false = Pénztár. Null → pénztár (default). */
    private Boolean isVault;

    /** FK-021: aktív-e. false, ha "tartósan zárva". Null → aktív (default). */
    private Boolean isActive;

    /** V293 szolgáltatás-flagek (ÁFA / WU / MG / POS). Null → false. */
    private Boolean hasAfa;
    private Boolean hasWu;
    private Boolean hasMg;
    private Boolean hasPos;

    /** Hétvégi nyitvatartás. Null → false (nyitva). */
    private Boolean closedSaturday;
    private Boolean closedSunday;
}
