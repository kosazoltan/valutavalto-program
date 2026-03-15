package hu.puzzleir.valuta.dto.ertektar;

import lombok.Builder;
import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
public class DistributionResponseDto {
    private Long id;
    private String status;
    private String note;
    private LocalDateTime createdAt;
    private LocalDateTime completedAt;
    private List<DistributionLineDto> lines;
}
