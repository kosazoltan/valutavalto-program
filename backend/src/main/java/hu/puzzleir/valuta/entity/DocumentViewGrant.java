package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * FS-5: Okmány full-res megtekintési engedély — egyszer-használatos grant (törvényi kapu).
 *
 * <p>A {@code DocumentViewGrantService.issueViewGrant} a supervisor-PIN sikeres
 * ellenőrzésekor létrehoz egy SINGLE-USE grant-rekordot, amely a konkrét dokumentumhoz
 * ({@code documentId}) kötött. A {@code serveFullImage} CSAK akkor szolgálja ki a
 * full-res bájtokat, ha van le nem járt, FEL NEM HASZNÁLT grant a
 * (company, requester, documentId) hármasra — a kiszolgálás atomikusan elhasználja
 * ({@code uses_remaining--}). FAIL-CLOSED: nincs érvényes grant → nincs bájt (403).</p>
 *
 * <p>A minta az {@link AmlApprovalGrant}: IDENTITY id, sima @Column mezők, NINCS
 * auditing-listener. A 10 perces lejárat a rövid megtekintési ablakot fedi (nem offline-sync).</p>
 */
@Entity
@Table(name = "document_view_grant", indexes = {
        @Index(name = "ix_document_view_grant_consume",
                columnList = "company_id,requester_worker_id,document_id,uses_remaining")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DocumentViewGrant {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "company_id", nullable = false)
    private UUID companyId;

    /** A megtekintést KÉRŐ (hívó) workerId-ja. */
    @Column(name = "requester_worker_id", nullable = false)
    private Long requesterWorkerId;

    /** A PIN-nel igazolt ENGEDÉLYEZŐ (supervisor/manager/admin) workerId-ja. */
    @Column(name = "approver_worker_id", nullable = false)
    private Long approverWorkerId;

    /** A dokumentum, amelynek full-res megtekintéséhez a grant kötve van. */
    @Column(name = "document_id", nullable = false)
    private UUID documentId;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @Column(name = "expires_at", nullable = false)
    private LocalDateTime expiresAt;

    /**
     * Hátralévő felhasználások száma (1 = friss grant; 0 = kimerült). A kiszolgáláskor
     * atomikus feltételes UPDATE csökkenti — párhuzamos hívásoknál sem fogyhat 0 alá.
     */
    @Column(name = "uses_remaining", nullable = false)
    private Integer usesRemaining;
}
