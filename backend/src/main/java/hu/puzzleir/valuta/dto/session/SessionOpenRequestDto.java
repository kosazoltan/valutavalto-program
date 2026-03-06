package hu.puzzleir.valuta.dto.session;

import lombok.*;

import java.util.UUID;

/**
 * Pénztárnyitás kérés DTO.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SessionOpenRequestDto {

    private Long workerId;
    private UUID branchId;
}
