package hu.puzzleir.valuta.dto.user;

import lombok.*;
import java.util.List;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class UserDetailDto {
    private String id;
    private String username;
    private String name;
    private String email;
    private String role;
    private Boolean isActive;
    private String lastLogin;
    private String createdAt;
    private String workerId;
    private String workerName;
    private String defaultBranchId;
    private String defaultBranchName;
    private Boolean isLocked;
    private String lastLoginAt;
    private Boolean mustChangePassword;
    private List<String> roles;
    private List<String> permissions;
}
