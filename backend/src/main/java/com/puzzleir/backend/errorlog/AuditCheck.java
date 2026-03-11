package com.puzzleir.backend.errorlog;

import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AuditCheck {
    private String name;
    private boolean pass;
    private String detail;
}
