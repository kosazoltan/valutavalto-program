package hu.puzzleir.valuta.dto.vaultchecklist;

import com.fasterxml.jackson.annotation.JsonInclude;
import hu.puzzleir.valuta.entity.VaultClosingChecklist;
import lombok.*;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Értéktári zárás-előtti ellenőrzőlista DTO.
 *
 * <p>FR-ZARUI-16..26 — a 9 tétel checkbox állapota + FR-ZARUI-26 ellenőrző személy adatai.</p>
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class VaultClosingChecklistDto {

    private UUID id;
    private UUID branchId;
    private String branchName;
    private LocalDate closingDate;

    /** FR-ZARUI-17 */
    private boolean item1;
    /** FR-ZARUI-18 */
    private boolean item2;
    /** FR-ZARUI-19 */
    private boolean item3;
    /** FR-ZARUI-20 */
    private boolean item4;
    /** FR-ZARUI-21 */
    private boolean item5;
    /** FR-ZARUI-22 */
    private boolean item6;
    /** FR-ZARUI-23 */
    private boolean item7;
    /** FR-ZARUI-24 */
    private boolean item8;
    /** FR-ZARUI-25 */
    private boolean item9;

    /** FR-ZARUI-26 ellenőrző személy neve. */
    private String auditorName;
    /** FR-ZARUI-26 ellenőrző személy beosztása. */
    private String auditorRole;

    private Long completedByWorkerId;
    private LocalDateTime completedAt;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    public static VaultClosingChecklistDto from(VaultClosingChecklist e) {
        if (e == null) return null;
        return VaultClosingChecklistDto.builder()
                .id(e.getId())
                .branchId(e.getBranch() != null ? e.getBranch().getId() : null)
                .branchName(e.getBranch() != null ? e.getBranch().getName() : null)
                .closingDate(e.getClosingDate())
                .item1(e.isItem1())
                .item2(e.isItem2())
                .item3(e.isItem3())
                .item4(e.isItem4())
                .item5(e.isItem5())
                .item6(e.isItem6())
                .item7(e.isItem7())
                .item8(e.isItem8())
                .item9(e.isItem9())
                .auditorName(e.getAuditorName())
                .auditorRole(e.getAuditorRole())
                .completedByWorkerId(e.getCompletedByWorkerId())
                .completedAt(e.getCompletedAt())
                .createdAt(e.getCreatedAt())
                .updatedAt(e.getUpdatedAt())
                .build();
    }
}
