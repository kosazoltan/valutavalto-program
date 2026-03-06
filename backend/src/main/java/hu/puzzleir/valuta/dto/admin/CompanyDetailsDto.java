package hu.puzzleir.valuta.dto.admin;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CompanyDetailsDto {

    private String id;
    private String code;
    private String name;
    private String taxNumber;
    private String registrationNumber;
    private String address;
    private String phone;
    private String email;
    private boolean active;

    private int activeBranchCount;
    private int totalWorkerCount;
    private BigDecimal dailyTurnoverHuf;

    private List<BranchSummaryDto> branches;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class BranchSummaryDto {
        private String id;
        private String code;
        private String name;
        private String city;
        private boolean active;
    }
}
