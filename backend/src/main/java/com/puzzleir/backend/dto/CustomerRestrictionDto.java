package com.puzzleir.backend.dto;

import lombok.*;

import java.time.LocalDateTime;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CustomerRestrictionDto {
    private UUID id;
    private Long customerId;
    private String restrictionType;
    private String reason;
    private Long addedBy;
    private LocalDateTime addedAt;
    private LocalDateTime expiresAt;
    private Boolean active;
}
