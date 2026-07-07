package hu.puzzleir.valuta.dto.customer;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/** FS-3 (D1): verzió-metaadat + (részletnél) a snapshot JSON-string. */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CustomerVersionDto {
    private Long versionNo;
    private String changedBy;
    private LocalDateTime changedAt;
    private String changeSource;
    /** Teljes CustomerDto-JSON; a lista-végpontnál null (payload-takarékosság). */
    private String snapshot;
}
