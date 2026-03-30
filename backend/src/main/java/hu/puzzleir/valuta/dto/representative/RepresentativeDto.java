package hu.puzzleir.valuta.dto.representative;

import lombok.*;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Meghatalmazott DTO — frontend AuthorizedRepresentative interface-szel kompatibilis.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RepresentativeDto {
    private UUID id;
    private Long customerId;
    private String customerName;
    private String firstName;
    private String lastName;
    private String fullName;
    private LocalDate birthDate;
    private String birthPlace;
    private String nationalityDid;
    private String documentTypeDid;
    private String documentNumber;
    private LocalDate documentValidFrom;
    private LocalDate documentValidTo;
    private String address;
    private String phone;
    private String email;
    private String representativeTypeDid;
    private String relationshipDid;
    private LocalDate authorizationStart;
    private LocalDate authorizationEnd;
    private Boolean isActive;
    private LocalDateTime registeredAt;
}
