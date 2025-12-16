package hu.puzzleir.valuta.dto.customer;

import hu.puzzleir.valuta.entity.DocumentType;
import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

/**
 * Ügyfél létrehozás DTO
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CreateCustomerDto {

    @NotBlank(message = "Név kötelező")
    private String name;

    private String birthName;
    private String motherName;
    private LocalDate birthDate;
    private String birthPlace;
    private String nationality;

    private String documentNumber;
    private DocumentType documentType;
    private LocalDate documentExpiry;

    private String address;
    private String postalCode;
    private String city;
    private String country;

    private String phone;
    private String email;

    private Boolean isCompany;
    private String companyName;
    private String taxNumber;
    private String registrationNumber;

    private Boolean isVip;
    private String notes;
}
