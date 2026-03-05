package com.puzzleir.backend.dto;

import lombok.*;

import java.time.LocalDateTime;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CustomerScreeningLogDto {
    private UUID id;
    private Long customerId;
    private String screeningType;
    private String result;
    private String details;
    private LocalDateTime screenedAt;
    private Long screenedBy;
}
