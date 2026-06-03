package hu.puzzleir.valuta.dto.ratemanagement;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * FR-HL-11 (b3-arfolyam-karbantarto-hibalista): árfolyam-publikálási audit-bejegyzés OLVASÓ nézete.
 *
 * <p>A {@link hu.puzzleir.valuta.entity.RatePublication} insert-only audit-rekord (módosítás/törlés
 * nincs → immutable). A nyers entitás csak a {@code publishedBy} workerId-t tartalmazza; a hibalista
 * a MÓDOSÍTÓ NEVÉT kéri, ezért ez a DTO a workerId mellé feloldja a {@code publishedByName}-et is.</p>
 */
public record RatePublicationAuditDto(
        UUID id,
        UUID workgroupId,
        Long publishedBy,
        String publishedByName,
        LocalDateTime publishedAt,
        Integer affectedBranches,
        String source,
        String clientVersion
) {
}
