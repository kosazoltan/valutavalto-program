package hu.puzzleir.valuta.dto.customer;

import hu.puzzleir.valuta.entity.DocumentType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * Ügyfél DTO - válasz
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CustomerDto {
    private Long id;
    private String customerCode;

    // Személyes adatok
    private String name;
    private String birthName;
    private String motherName;
    private LocalDate birthDate;
    private String birthPlace;
    private String nationality;

    // Dokumentum (legacy)
    private String documentNumber;
    private DocumentType documentType;
    private LocalDate documentExpiry;

    // Külön okmányszámok
    private String idCardNumber;
    private LocalDate idCardExpiry;
    private String passportNumber;
    private LocalDate passportExpiry;

    // Cím
    private String residence;
    private String addressCardNumber;
    private String address;
    private String postalCode;
    private String city;
    private String country;

    // Kapcsolat
    private String phone;
    private String email;

    // Jogi személy
    private Boolean isCompany;
    private String companyName;
    private String taxNumber;
    private String registrationNumber;
    private String teaorCode; // G27 — jogi-személy TEÁOR tevékenységi kód

    // Státusz
    private Boolean active;
    private Boolean isVip;
    private String notes;

    // Statisztika
    private LocalDate lastTransactionDate;
    private Integer transactionCount;

    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
