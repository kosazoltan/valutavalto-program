package hu.puzzleir.valuta.dto.worker;

import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.entity.WorkerRole;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Worker DTO - response.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class WorkerDto {
    private Long id;
    private UUID companyId;
    private String companyCode;
    private String companyName;
    private String code;
    private String name;
    private WorkerRole role;
    private UUID branchId;
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
        return WorkerDto.builder()
                .id(worker.getId())
                .companyId(worker.getCompany().getId())
                .companyCode(worker.getCompany().getCode())
                .companyName(worker.getCompany().getName())
                .code(worker.getCode())
                .name(worker.getName())
                .role(worker.getRole())
                .branchId(worker.getBranch().getId())
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
}
