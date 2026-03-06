package hu.puzzleir.valuta.dto.admin;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CompanyUpdateDto {

    private String name;
    private String taxNumber;
    private String registrationNumber;
    private String address;
    private String phone;
    private String email;
}
