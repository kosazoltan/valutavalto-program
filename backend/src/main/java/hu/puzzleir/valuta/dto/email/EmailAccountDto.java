package hu.puzzleir.valuta.dto.email;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.UUID;

/**
 * Email fiók DTO — létrehozás/módosítás.
 * Pontosan EGY a 4 FK-ból (branchId, vaultTerritoryId, ownCompanyId, workerId) kitöltve!
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class EmailAccountDto {

    private UUID id;

    private UUID branchId;

    private Integer vaultTerritoryId;

    private UUID ownCompanyId;

    /** Worker.id — LONG, NEM UUID! */
    private Long workerId;

    private String gmailAddress;

    private String displayName;

    @Builder.Default
    private Boolean isActive = true;
}
