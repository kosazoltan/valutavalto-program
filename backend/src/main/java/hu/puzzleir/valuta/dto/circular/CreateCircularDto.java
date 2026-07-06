package hu.puzzleir.valuta.dto.circular;

import jakarta.validation.constraints.NotBlank;
import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class CreateCircularDto {
    @NotBlank private String title;
    @NotBlank private String content;
    private Boolean urgent;
    /** A4 (b9-korlevelek FR-02): kötelező nyugtázás — ha true, blokkolja a tranzakciót, amíg nincs nyugtázva. */
    private Boolean requiresAcknowledgment;
    /** FS-C (Center FS-1): válaszolható-e a körlevél. Default false backward-compat miatt. */
    private Boolean allowsReply;
}
