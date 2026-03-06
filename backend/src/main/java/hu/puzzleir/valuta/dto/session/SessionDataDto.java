package hu.puzzleir.valuta.dto.session;

import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

/**
 * Session adat DTO (nyitáshoz és általános session info).
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SessionDataDto {

    private Long sessionId;
    private String branchId;
    private String branchName;
    private Long workerId;
    private String workerName;
    private LocalDate sessionDate;
    private String status;
    private LocalDateTime openedAt;
    private LocalDateTime closedAt;
    private Map<String, BigDecimal> openingBalances;
    private List<String> warnings;
}
