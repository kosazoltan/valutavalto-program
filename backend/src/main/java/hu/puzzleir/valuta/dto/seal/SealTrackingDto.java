package hu.puzzleir.valuta.dto.seal;

import hu.puzzleir.valuta.entity.SealTransitStatus;
import lombok.*;

import java.time.LocalDateTime;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SealTrackingDto {
    private Long id;
    private UUID companyId;
    private String transferType;
    private Long transferId;
    private String sealNumber;
    private LocalDateTime sealedAt;
    private Long sealedBy;
    private LocalDateTime openedAt;
    private Long openedBy;
    private SealTransitStatus transitStatus;
    private String notes;
    private Long version;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
