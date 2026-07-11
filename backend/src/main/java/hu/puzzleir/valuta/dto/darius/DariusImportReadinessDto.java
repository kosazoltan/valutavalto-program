package hu.puzzleir.valuta.dto.darius;

import com.fasterxml.jackson.annotation.JsonProperty;

import java.util.List;

public record DariusImportReadinessDto(
        String companyCode,
        boolean pvCodeConfigured,
        int activeBranchCount,
        List<String> branchesWithInvalidBankCode,
        int activeBankBranchCount,
        boolean fixingConfigured) {

    @JsonProperty
    public boolean ready() {
        return pvCodeConfigured && activeBranchCount > 0 && branchesWithInvalidBankCode.isEmpty();
    }
}
