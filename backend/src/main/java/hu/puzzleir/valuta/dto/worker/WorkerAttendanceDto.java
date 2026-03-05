package hu.puzzleir.valuta.dto.worker;

import hu.puzzleir.valuta.entity.WorkerAttendance;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.UUID;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class WorkerAttendanceDto {
    private UUID id;
    private Long workerId;
    private UUID branchId;
    private LocalDateTime loginAt;
    private LocalDateTime logoutAt;
    private String ipAddress;

    public static WorkerAttendanceDto from(WorkerAttendance attendance) {
        return WorkerAttendanceDto.builder()
                .id(attendance.getId())
                .workerId(attendance.getWorker().getId())
                .branchId(attendance.getBranchId())
                .loginAt(attendance.getLoginAt())
                .logoutAt(attendance.getLogoutAt())
                .ipAddress(attendance.getIpAddress())
                .build();
    }
}
