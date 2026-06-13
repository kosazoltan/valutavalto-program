package hu.puzzleir.valuta.dto.worker;

import hu.puzzleir.valuta.entity.Worker;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.Collections;
import java.util.List;

/**
 * Worker DTO - response.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class WorkerDto {
    private Long id;

    // Frontend compatibility: companyId as String
    private String companyId;
    private String companyCode;
    private String companyName;

    // Frontend compatibility: workerCode instead of code
    private String workerCode;

    // Frontend compatibility: firstName, lastName, fullName instead of name
    private String firstName;
    private String lastName;
    private String fullName;

    // Role as string for frontend
    private String role;

    // FK-026: a Worker.region szöveges területi besorolása (lehet null).
    private String region;

    // FK-026: a dolgozóhoz tartozó kanonikus munkakör-kódok (worker_role_assignment),
    // pl. ["teruleti_vezeto", "ertektar"]. Üres lista, ha nincs hozzárendelés.
    private List<String> roleCodes;

    // Frontend compatibility: branchId as String
    private String branchId;
    private String branchCode;
    private String branchName;

    private Boolean active;
    private String phone;
    private String email;
    private String otpUserId;
    private Boolean otpEnabled;
    private LocalDateTime lastLoginAt;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    public static WorkerDto from(Worker worker) {
        return from(worker, Collections.emptyList());
    }

    /**
     * FK-026: a {@code roleCodes} listát kívülről (batch-lekérdezésből) adjuk át,
     * hogy ne keletkezzen N+1 a {@code worker_role_assignment} lekérdezésekor.
     */
    public static WorkerDto from(Worker worker, List<String> roleCodes) {
        String[] nameParts = splitName(worker.getName());

        return WorkerDto.builder()
                .id(worker.getId())
                .companyId(worker.getCompany().getId().toString())
                .companyCode(worker.getCompany().getCode())
                .companyName(worker.getCompany().getName())
                .workerCode(worker.getCode())
                .firstName(nameParts[0])
                .lastName(nameParts[1])
                .fullName(worker.getName())
                .role(worker.getRole().name())
                .region(worker.getRegion())
                .roleCodes(roleCodes != null ? roleCodes : Collections.emptyList())
                .branchId(worker.getBranch().getId().toString())
                .branchCode(worker.getBranch().getCode())
                .branchName(worker.getBranch().getName())
                .active(worker.getActive())
                .phone(worker.getPhone())
                .email(worker.getEmail())
                .otpUserId(worker.getOtpUserId())
                .otpEnabled(worker.getOtpEnabled())
                .lastLoginAt(worker.getLastLoginAt())
                .createdAt(worker.getCreatedAt())
                .updatedAt(worker.getUpdatedAt())
                .build();
    }

    /**
     * Split full name into firstName and lastName
     */
    private static String[] splitName(String fullName) {
        if (fullName == null || fullName.trim().isEmpty()) {
            return new String[]{"", ""};
        }
        String[] parts = fullName.trim().split("\\s+", 2);
        if (parts.length == 1) {
            return new String[]{parts[0], ""};
        }
        return parts;
    }
}
