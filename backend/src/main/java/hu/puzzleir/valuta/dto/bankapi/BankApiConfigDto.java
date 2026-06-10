package hu.puzzleir.valuta.dto.bankapi;

import hu.puzzleir.valuta.entity.BankApiAuthType;
import hu.puzzleir.valuta.entity.BankApiMode;
import hu.puzzleir.valuta.entity.BankApiRunStatus;
import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.UUID;

@Data
@Builder
public class BankApiConfigDto {
    private UUID id;
    private String providerName;
    private BankApiMode mode;
    private String endpointUrl;
    private BankApiAuthType authType;
    private String clientId;
    private Boolean clientSecretConfigured;
    private String mtlsCertificateAlias;
    private String updateFrequency;
    private Boolean enabled;
    private LocalDateTime lastRunTimestamp;
    private BankApiRunStatus lastRunStatus;
    private String lastRunMessage;
    private LocalDateTime updatedAt;
}
