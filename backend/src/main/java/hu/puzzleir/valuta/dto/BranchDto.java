package hu.puzzleir.valuta.dto;

import lombok.*;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class BranchDto {

    private UUID id;
    private String code;
    private String name;
    
    // Company info
    private UUID companyId;
    private String companyName;
    
    // Branch type
    private UUID branchTypeId;
    private String branchTypeCode;
    private String branchTypeName;
    
    // Parent branch
    private UUID parentBranchId;
    private String parentBranchName;
    
    // Address
    private String address;
    private String city;
    private String zipCode;
    
    // Country
    private UUID countryId;
    private String countryName;
    
    // Contact
    private String phone;
    private String email;
    
    // Status
    private UUID branchStatusId;
    private String branchStatusCode;
    private String branchStatusName;
    
    // Other
    private String bankCode;
    private LocalDate openingDate;
    private UUID denominationRuleId;
    private Boolean isActive;

    // v2.5.1: értéktári terület + értéktár-e
    private Integer vaultTerritoryId;
    private Boolean isVault;

    // FK-002: területi besorolás neve (SZEGED, DEBRECEN, BEKESCSABA, ... IRODA) —
    // az Országos készlet nézet területi csoportosításához (régió-szekciófejlécek).
    private String region;

    // #891 Copilot fix: a numerikus KESZLEX területi kód (10/20/40/50/63/75/120/145) —
    // a területi scope-szűrés kulcsa (AccessScopeService). A region (szöveges) display-célú,
    // a regionCode (numerikus) a scope-logika input-ja.
    private String regionCode;

    // Pénztár Törzs alapmodul (V293): rövid név + szolgáltatás-flagek + nyitvatartás
    private String shortName;
    private Boolean hasAfa;
    private Boolean hasWu;
    private Boolean hasMg;
    private Boolean hasPos;
    private Boolean closedSaturday;
    private Boolean closedSunday;

    // Timestamps
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    
    // Computed fields
    private List<UUID> childBranchIds;
    private Integer level;
    private String fullPath;
}
