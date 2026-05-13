package hu.puzzleir.valuta.dto.setup;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SetupGoogleIdentifyResponseDto {

    private String matchType;
    private Boolean requiresWorkerSelection;
    private String message;

    private GoogleIdentityDto googleIdentity;
    private SetupBranchDto branch;
    private SetupWorkerDto worker;
    private List<SetupWorkerDto> workerOptions;

    private List<String> validAppModes;
    private Boolean requestedAppModeAllowed;

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class GoogleIdentityDto {
        private String email;
        private String googleSub;
        private String name;
        private String picture;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class SetupBranchDto {
        private String code;
        private String name;
        private String city;
        private String address;
        private Boolean isVault;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class SetupWorkerDto {
        private String code;
        private String name;
        private String role;
        private List<String> roles;
        private List<String> validAppModes;
    }
}
