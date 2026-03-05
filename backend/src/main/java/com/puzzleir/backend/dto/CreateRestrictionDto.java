package com.puzzleir.backend.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.*;

import java.time.LocalDateTime;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CreateRestrictionDto {

    @NotBlank(message = "Korlátozás típusa kötelező")
    private String restrictionType;

    @NotBlank(message = "Indoklás kötelező")
    private String reason;

    private LocalDateTime expiresAt;
}
