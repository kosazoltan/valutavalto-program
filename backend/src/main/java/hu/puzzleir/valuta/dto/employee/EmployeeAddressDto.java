package hu.puzzleir.valuta.dto.employee;

import hu.puzzleir.valuta.entity.AddressType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Dolgozói cím DTO.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class EmployeeAddressDto {
    private Long id;
    private AddressType addressType;
    private String postalCode;
    private String city;
    private String streetName;
    private String streetType;
    private String houseNumber;
    private String building;
    private String staircase;
    private String floor;
    private String door;
}
