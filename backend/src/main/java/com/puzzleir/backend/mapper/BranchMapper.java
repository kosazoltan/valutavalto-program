package com.puzzleir.backend.mapper;

import com.puzzleir.backend.dto.BranchDto;
import com.puzzleir.backend.entity.Branch;
import org.springframework.stereotype.Component;

import java.util.Collections;
import java.util.List;
import java.util.stream.Collectors;

@Component
public class BranchMapper {

    public BranchDto toDto(Branch entity) {
        if (entity == null) {
            return null;
        }

        return BranchDto.builder()
                .id(entity.getId())
                .code(entity.getCode())
                .name(entity.getName())
                
                // Company
                .companyId(entity.getCompany() != null ? entity.getCompany().getId() : null)
                .companyName(entity.getCompany() != null ? entity.getCompany().getName() : null)
                
                // Branch Type
                .branchTypeId(entity.getBranchType() != null ? entity.getBranchType().getId() : null)
                .branchTypeCode(entity.getBranchType() != null ? entity.getBranchType().getCode() : null)
                .branchTypeName(entity.getBranchType() != null ? entity.getBranchType().getName() : null)
                
                // Parent Branch
                .parentBranchId(entity.getParentBranch() != null ? entity.getParentBranch().getId() : null)
                .parentBranchName(entity.getParentBranch() != null ? entity.getParentBranch().getName() : null)
                
                // Address
                .address(entity.getAddress())
                .city(entity.getCity())
                .zipCode(entity.getZipCode())
                
                // Country
                .countryId(entity.getCountry() != null ? entity.getCountry().getId() : null)
                .countryName(entity.getCountry() != null ? entity.getCountry().getName() : null)
                
                // Contact
                .phone(entity.getPhone())
                .email(entity.getEmail())
                
                // Status
                .branchStatusId(entity.getBranchStatus() != null ? entity.getBranchStatus().getId() : null)
                .branchStatusCode(entity.getBranchStatus() != null ? entity.getBranchStatus().getCode() : null)
                .branchStatusName(entity.getBranchStatus() != null ? entity.getBranchStatus().getName() : null)
                
                // Other
                .bankCode(entity.getBankCode())
                .openingDate(entity.getOpeningDate())
                .denominationRuleId(entity.getDenominationRuleId())
                .isActive(entity.getIsActive())
                
                // Timestamps
                .createdAt(entity.getCreatedAt())
                .updatedAt(entity.getUpdatedAt())
                
                // Will be populated by service if needed
                .childBranchIds(Collections.emptyList())
                .build();
    }

    public List<BranchDto> toDtoList(List<Branch> entities) {
        if (entities == null) {
            return Collections.emptyList();
        }
        return entities.stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }
}
