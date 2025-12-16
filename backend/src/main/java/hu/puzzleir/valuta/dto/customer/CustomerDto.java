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

    // Dokumentum
    private String documentNumber;
    private DocumentType documentType;
    private LocalDate documentExpiry;

    // Cím
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
