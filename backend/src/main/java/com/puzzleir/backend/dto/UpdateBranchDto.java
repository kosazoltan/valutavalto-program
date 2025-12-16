package com.puzzleir.backend.dto;

import jakarta.validation.constraints.*;
import lombok.*;

import java.time.LocalDate;
import java.util.UUID;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UpdateBranchDto {

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
    private LocalDate openingDate;

    private UUID denominationRuleId;

    private Boolean isActive;
}
