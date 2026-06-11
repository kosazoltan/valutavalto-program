package hu.puzzleir.valuta.dto;

import com.fasterxml.jackson.databind.annotation.JsonDeserialize;
import jakarta.validation.constraints.*;
import lombok.*;

import java.time.LocalDate;
import java.util.UUID;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CreateBranchDto {

    @NotBlank(message = "A kód megadása kötelező")
    @Size(min = 1, max = 20, message = "A kód hossza 1-20 karakter lehet")
    @Pattern(regexp = "^[A-Z0-9]+$", message = "A kód csak nagybetűket és számokat tartalmazhat")
    private String code;

    @NotNull(message = "A cég azonosító kötelező")
    private UUID companyId;

    @NotBlank(message = "A banki kód kötelező")
    @Size(max = 20, message = "A banki kód max 20 karakter")
    private String bankCode;

    @NotNull(message = "A fiók típus kötelező")
    private UUID branchTypeId;

    private UUID parentBranchId;

    @NotBlank(message = "A név kötelező")
    @Size(min = 3, max = 255, message = "A név 3-255 karakter hosszú lehet")
    private String name;

    @NotBlank(message = "A cím kötelező")
    @Size(min = 5, message = "A cím legalább 5 karakter")
    private String address;

    @NotBlank(message = "A város kötelező")
    @Size(min = 2, max = 100)
    private String city;

    @NotBlank(message = "Az irányítószám kötelező")
    @Pattern(regexp = "^\\d{4}$", message = "Az irányítószám 4 számjegyből áll")
    private String zipCode;

    @NotNull(message = "Az ország kötelező")
    private UUID countryId;

    @Pattern(regexp = "^\\+?[0-9\\s\\-\\(\\)]+$", message = "Érvénytelen telefonszám formátum")
    private String phone;

    @Email(message = "Érvénytelen email cím")
    private String email;

    @NotNull(message = "A fiók státusz kötelező")
    private UUID branchStatusId;

    @NotNull(message = "A nyitás dátuma kötelező")
    @PastOrPresent(message = "A nyitás dátuma nem lehet jövőbeli")
    @JsonDeserialize(using = BlankTolerantLocalDateDeserializer.class)
    private LocalDate openingDate;

    private UUID denominationRuleId;

    // Pénztár Törzs alapmodul (V293): opcionális rövid név + szolgáltatás-flagek + nyitvatartás.
    // Backward-compat: ha a kliens nem küldi, a service a FALSE default-okat hagyja érvényben.
    @Size(max = 100, message = "A rövid név max 100 karakter")
    private String shortName;
    private Boolean hasAfa;
    private Boolean hasWu;
    private Boolean hasMg;
    private Boolean hasPos;
    private Boolean closedSaturday;
    private Boolean closedSunday;

    // ========================================================================
    // FK-022 hotfix (FK-025 TBD#1): a spec "BranchCreateRequest"-je ebben a repóban ez a
    // DTO (POST /api/v1/branches). Az opcionális szövegmezők üres stringként ("") is
    // érkezhetnek (programmatic kliens) → blank → null normalizálás, hogy a @Pattern/@Email
    // ne utasítsa vissza (a null-t a Bean Validation átengedi) — az UpdateBranchDto
    // mintája (commit 4cf0ebc6f). Create-nél nincs clear-szemantika (nincs előző érték).
    // A kötelező @NotBlank mezőkhöz nem nyúlunk — ott a "" elutasítása a helyes viselkedés.
    // Figyelem: a Lombok @Builder/@AllArgsConstructor megkerüli a settereket — a Jackson
    // setter-úton deszerializál (HTTP-kérésnél a normalizálás garantált), builderrel csak
    // teszt-kód épít DTO-t.
    // ========================================================================

    private static String blankToNull(String value) {
        return (value == null || value.isBlank()) ? null : value.trim();
    }

    public void setShortName(String shortName) {
        this.shortName = blankToNull(shortName);
    }

    public void setPhone(String phone) {
        this.phone = blankToNull(phone);
    }

    public void setEmail(String email) {
        this.email = blankToNull(email);
    }
}
