package com.puzzleir.backend.dto;

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
    private LocalDate openingDate;

    private UUID denominationRuleId;
}
