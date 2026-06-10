package hu.puzzleir.valuta.dto.storno;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.*;

import java.util.UUID;

/**
 * Sztornó telefonos supervisor-PIN jóváhagyás request (egyszemélyes iroda flow).
 * A PIN body-ban utazik (nem query-paramban), hogy ne kerüljön access-logba.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class StornoPinApprovalRequestDto {

    @NotNull
    private UUID approvalId;

    /** A telefonon jóváhagyó supervisor/manager/admin workerId-ja. */
    @NotNull
    private Long approverWorkerId;

    /** A jóváhagyó supervisor-PIN-je (4-6 számjegy; a backend BCrypt-hash ellen ellenőrzi). */
    @NotBlank
    private String pin;

    /** true = engedélyezés, false = elutasítás. */
    @NotNull
    private Boolean approved;

    /** Elutasítás indoka (elutasításnál kötelező üzletileg; a service kezeli). */
    private String reason;
}
