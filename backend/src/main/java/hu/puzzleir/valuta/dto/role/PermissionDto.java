package hu.puzzleir.valuta.dto.role;

import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class PermissionDto {
    private String id;
    private String code;
    private String name;
    private String description;
    private String module;
    private Boolean isSystemPermission;
    private Boolean isActive;
    private String createdAt;
}
