package hu.puzzleir.valuta.dto.cashregister;

import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.UUID;

@Data
@Builder
public class CashRegisterDeviceDto {
    private UUID id;
    private UUID companyId;
    private UUID branchId;
    private String code;
    private String name;
    private String appMode;
    private String appVersion;
    private String deviceFingerprint;
    private String osInfo;
    private LocalDateTime installedAt;
    private LocalDateTime lastSeenAt;
    private Boolean isActive;
}