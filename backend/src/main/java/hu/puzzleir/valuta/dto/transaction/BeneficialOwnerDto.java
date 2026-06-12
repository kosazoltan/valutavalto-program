package hu.puzzleir.valuta.dto.transaction;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * V325 (Batch3-C): tényleges tulajdonos adatai jogi személy ügyfélnél —
 * a legacy UJTULAJOK mezőinek tükre. Max 4 tulajdonos tranzakciónként.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BeneficialOwnerDto {

    @NotBlank
    @Size(max = 255)
    private String name;

    @Size(max = 500)
    private String address;

    @Size(max = 255)
    private String birthPlace;

    @Size(max = 20)
    private String birthDate;

    @Size(max = 100)
    private String nationality;

    /** Külföldi tartózkodási hely (legacy TARTHELY) — opcionális. */
    @Size(max = 255)
    private String residenceAbroad;

    /** Az érdekeltség jellege (legacy ERDJELLEG). */
    @Size(max = 255)
    private String interestNature;

    /** A részesedés mértéke, pl. "50%" (legacy ERDMERTEK). */
    @Size(max = 100)
    private String interestExtent;

    private Boolean isPep;
}
