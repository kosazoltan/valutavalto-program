package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * AML felsővezetői jóváhagyás — egyszer-használatos engedély ("grant").
 *
 * <p>A {@code /api/v1/aml-approval/verify-approver} a supervisor-PIN sikeres ellenőrzésekor létrehoz
 * egy grant-rekordot, amely bizonyítja, hogy az adott engedélyező (approver) PIN-nel igazolta a
 * jelenlétét az adott pénztáros (cashier) sessionjében. A tranzakció-rögzítés
 * ({@code AmlApprovalService.recordSeniorApproval}) CSAK akkor rögzít jóváhagyást, ha van fel nem
 * használt, le nem járt grant a (company, cashier, approver) hármasra — rögzítéskor a grant
 * elhasználódik ({@code usedAt}). Így egy pénztáros nem forgeolhat jóváhagyást a PIN megkerülésével
 * (Codex P1, 2026-06-04). A 7 napos lejárat a local-first offline → sync késleltetést fedi.</p>
 */
@Entity
@Table(name = "aml_approval_grant", indexes = {
        @Index(name = "ix_aml_approval_grant_consume",
                columnList = "company_id,cashier_worker_id,approver_worker_id,session_id,uses_remaining")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AmlApprovalGrant {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "company_id", nullable = false)
    private UUID companyId;

    /** A jóváhagyást KÉRŐ (a tranzakciót rögzítő) pénztáros workerId-ja. */
    @Column(name = "cashier_worker_id", nullable = false)
    private Long cashierWorkerId;

    /** A PIN-nel igazolt ENGEDÉLYEZŐ (supervisor/manager/admin) workerId-ja. */
    @Column(name = "approver_worker_id", nullable = false)
    private Long approverWorkerId;

    /**
     * A jóváhagyás-session (nyugta/kérés) azonosítója — a kliens generálja a modal megnyitásakor, és a
     * nyugta MINDEN tranzakciója magával viszi. A grant csak az ezzel a sessionId-vel tagelt
     * tranzakciókat hagyhatja jóvá → a maradék felhasználások nem szivároghatnak másik nyugtára.
     */
    @Column(name = "session_id", nullable = false, length = 64)
    private String sessionId;

    /**
     * Az ügyfél-kulcs (a jóváhagyott ügyfél neve), amihez a grant kötve van — Codex P1. Egy multi-line
     * nyugta minden sora ugyanazt az ügyfelet viszi: az első sor elhasználja a grantot, a többi (ugyanaz a
     * session ÉS ugyanaz a customer_key) jóváhagyás-fedettként átmegy. MÁS ügyfélre újrahasznált session
     * elbukik → nincs amplifikáció nem-összefüggő tranzakciókra. NULL a régi (V294) grantoknál (BC).
     */
    @Column(name = "customer_key", length = 160)
    private String customerKey;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @Column(name = "expires_at", nullable = false)
    private LocalDateTime expiresAt;

    /**
     * Hátralévő felhasználások száma (server-fix kapu egy PIN-ellenőrzésből; 0 = kimerült). A rögzítéskor
     * atomikus feltételes UPDATE csökkenti — így párhuzamos sync-nél sem fogyhat 0 alá (single-use garancia).
     */
    @Column(name = "uses_remaining", nullable = false)
    private Integer usesRemaining;
}
