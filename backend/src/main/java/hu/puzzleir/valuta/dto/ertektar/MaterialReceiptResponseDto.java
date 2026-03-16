package hu.puzzleir.valuta.dto.ertektar;

import lombok.*;
import java.time.LocalDateTime;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MaterialReceiptResponseDto {
    private Long id;
    private String receiptNumber;
    private String receiptType;
    private Integer vaultTerritoryId;
    private String vaultTerritoryName;
    private String branchCode;
    private String counterpartName;
    private String note;
    private String status;
    private LocalDateTime createdAt;
    private LocalDateTime finalizedAt;
    private List<MaterialReceiptLineDto> lines;
}
