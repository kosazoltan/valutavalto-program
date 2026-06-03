package hu.puzzleir.valuta.dto.ratemanagement;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * FR-HL-11 (b3-arfolyam-karbantarto-hibalista): árfolyam-publikálási audit-bejegyzés OLVASÓ nézete.
 *
 * <p>A {@link hu.puzzleir.valuta.entity.RatePublication} insert-only audit-rekord (módosítás/törlés
 * nincs → immutable). A nyers entitás csak a {@code publishedBy} workerId-t tartalmazza; a hibalista
 * a MÓDOSÍTÓ NEVÉT kéri, ezért ez a DTO a workerId mellé feloldja a {@code publishedByName}-et is.
 * A korábbi (entitás-)válasz mezőit megtartjuk ({@code templateId}, {@code notes}) a frontend
 * kompatibilitásért (Copilot review).</p>
 */
public record RatePublicationAuditDto(
        UUID id,
        UUID templateId,
        UUID workgroupId,
        Long publishedBy,
        String publishedByName,
        LocalDateTime publishedAt,
        Integer affectedBranches,
        String notes,
        String source,
        String clientVersion
) {
}
