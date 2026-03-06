package hu.puzzleir.valuta.dto.admin;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BranchUpdateDto {

    private String name;
    private String address;
    private String city;
    private String zipCode;
    private String phone;
    private String email;
}
