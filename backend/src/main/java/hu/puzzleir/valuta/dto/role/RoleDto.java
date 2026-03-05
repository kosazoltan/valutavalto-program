package hu.puzzleir.valuta.dto.role;

import lombok.*;
import java.util.List;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class RoleDto {
    private String id;
    private String code;
    private String name;
    private String description;
    private String roleType;
    private Integer hierarchyLevel;
    private Boolean isSystemRole;
    private Boolean isActive;
    private List<String> permissions;
}
