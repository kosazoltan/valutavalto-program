package com.puzzleir.backend.dto;

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
    
    // Timestamps
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    
    // Computed fields
    private List<UUID> childBranchIds;
    private Integer level;
    private String fullPath;
}
