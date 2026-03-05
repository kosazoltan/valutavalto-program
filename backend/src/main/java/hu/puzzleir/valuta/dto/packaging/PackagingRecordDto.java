package hu.puzzleir.valuta.dto.packaging;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class PackagingRecordDto {
    private UUID id;
    private UUID branchId;
    private String currencyCode;
    private LocalDate packagingDate;
    private Integer bundleCount;
    private Integer denomination;
    private Integer bundleSize;
    private String notes;
    private LocalDateTime createdAt;
}
