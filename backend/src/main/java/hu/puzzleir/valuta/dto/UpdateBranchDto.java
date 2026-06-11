package hu.puzzleir.valuta.dto;

import com.fasterxml.jackson.core.JsonParser;
import com.fasterxml.jackson.databind.DeserializationContext;
import com.fasterxml.jackson.databind.JsonDeserializer;
import com.fasterxml.jackson.databind.annotation.JsonDeserialize;
import jakarta.validation.constraints.*;
import lombok.*;

import java.io.IOException;
import java.time.LocalDate;
import java.util.UUID;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UpdateBranchDto {

    /**
     * FK-022 hotfix (FK-025): a BranchEditPage az üres opcionális mezőket üres stringként
     * ("") küldi (BranchEditPage.tsx:102-108) — a Bean Validation a null-t átengedi, a ""-t
     * viszont validálja (@Pattern/@Size min), ami 400-at okozott. A blank → null normalizálás
     * az explicit setterekben történik (a Jackson a settereken keresztül deszerializál;
     * a Lombok @Builder ezeket megkerüli — builderrel csak teszt-kód épít DTO-t).
     * Partial-update szemantika: a null mező = nincs változás (a service null-guard mintája).
     */
    private static String blankToNull(String value) {
        return (value == null || value.isBlank()) ? null : value.trim();
    }

    @Size(max = 255, message = "A név max 255 karakter")
    private String name;

    @Size(min = 5, message = "A cím legalább 5 karakter")
    private String address;

    @Size(min = 2, max = 100)
    private String city;

    @Pattern(regexp = "^\\d{4}$", message = "Az irányítószám 4 számjegyből áll")
    private String zipCode;

    private UUID countryId;

    @Pattern(regexp = "^\\+?[0-9\\s\\-\\(\\)]+$", message = "Érvénytelen telefonszám formátum")
    private String phone;

    @Email(message = "Érvénytelen email cím")
    private String email;

    @Size(max = 20, message = "A banki kód max 20 karakter")
    private String bankCode;

    private UUID branchStatusId;

    @PastOrPresent(message = "A nyitás dátuma nem lehet jövőbeli")
    @JsonDeserialize(using = BlankTolerantLocalDateDeserializer.class)
    private LocalDate openingDate;

    private UUID denominationRuleId;

    private Boolean isActive;

    // Pénztár Törzs alapmodul (V293): opcionális rövid név + szolgáltatás-flagek + nyitvatartás.
    // Partial update: csak a nem-null mezők íródnak felül (a service null-guard mintája szerint).
    @Size(max = 100, message = "A rövid név max 100 karakter")
    private String shortName;
    private Boolean hasAfa;
    private Boolean hasWu;
    private Boolean hasMg;
    private Boolean hasPos;
    private Boolean closedSaturday;
    private Boolean closedSunday;

    // FK-022: iroda szerkesztése — az iroda típusa (Pénztár/Értéktár) is módosítható.
    private Boolean isVault;

    // FK-022: területi besorolás — szöveges REGION dictionary-kód (pl. SZEGED). A service
    // ugyanazon az úton dolgozza fel, mint createSimpleCashier-nél: REGION-dict validáció +
    // KESZLEX numerikus mapping (Branch.regionCode) + szöveges régió (Branch.region).
    // A `code` mező szándékosan NINCS a DTO-ban: a pénztár kódja nem szerkeszthető (FR-3).
    private String regionCode;

    // ========================================================================
    // FK-022 hotfix (FK-025): blank → null normalizáló setterek. A spec a
    // shortName/phone/email/bankCode mezőket nevesíti; a zipCode és city ugyanazon
    // root cause része (a FE üres stringként küldi őket is — BranchEditPage.tsx:104-105 —
    // és a @Pattern ^\d{4}$ / @Size(min=2) a ""-t elutasítja).
    // ========================================================================

    public void setShortName(String shortName) {
        this.shortName = blankToNull(shortName);
    }

    public void setPhone(String phone) {
        this.phone = blankToNull(phone);
    }

    public void setEmail(String email) {
        this.email = blankToNull(email);
    }

    public void setBankCode(String bankCode) {
        this.bankCode = blankToNull(bankCode);
    }

    public void setZipCode(String zipCode) {
        this.zipCode = blankToNull(zipCode);
    }

    public void setCity(String city) {
        this.city = blankToNull(city);
    }

    /**
     * FK-025: üres string ("") → null a nyitás dátumára, hogy a Jackson ne dobjon
     * deszerializálási hibát (a BranchEditPage nem küldi a mezőt, de programmatic /
     * Electron kliens küldhet üres stringet). ISO-8601 formátum (pl. "2020-01-15").
     */
    public static class BlankTolerantLocalDateDeserializer extends JsonDeserializer<LocalDate> {
        @Override
        public LocalDate deserialize(JsonParser p, DeserializationContext ctx) throws IOException {
            String value = p.getText();
            if (value == null || value.isBlank()) {
                return null;
            }
            return LocalDate.parse(value.trim());
        }
    }
}
