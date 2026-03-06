package hu.puzzleir.valuta.dto.admin;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BranchDetailsDto {

    private String id;
    private String code;
    private String name;
    private String address;
    private String city;
    private String zipCode;
    private String phone;
    private String email;
    private boolean active;

    private String companyId;
    private String companyName;

    private int workerCount;
    private BigDecimal totalInventoryHuf;
    private String lastSyncAt;
    private String openingHours;
}
