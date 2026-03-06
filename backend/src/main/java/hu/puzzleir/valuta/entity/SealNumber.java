package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Plomba szám nyilvántartás.
 *
 * Legacy: GETPLOMB — a Delphi rendszerben a pénztárnyitás/zárás
 * során rögzítették a plomba számot (páncélszekrény/széf biztosítás).
 *
 * A plomba szám formátuma: {branchCode}-{date}-{sequence}
 * Pl.: "BC01-20260306-001"
 */
@Entity
@Table(name = "seal_number", indexes = {
    @Index(name = "idx_seal_branch", columnList = "branch_id"),
    @Index(name = "idx_seal_number_unique", columnList = "seal_number", unique = true)
})
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class SealNumber {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "branch_id", nullable = false)
    private UUID branchId;

    @Column(name = "seal_number", nullable = false, unique = true, length = 30)
    private String sealNumber;

    /**
     * Plomba típusa: OPEN (nyitás), CLOSE (zárás), TRANSFER (átadás)
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "seal_type", nullable = false, length = 20)
    @Builder.Default
    private SealType sealType = SealType.CLOSE;

    /**
     * Felhasználva — melyik session-ben
     */
    @Column(name = "session_id")
    private UUID sessionId;

    /**
     * Ki hozta létre
     */
    @Column(name = "worker_id")
    private Long workerId;

    /**
     * Megjegyzés (opcionális)
     */
    @Column(length = 255)
    private String note;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "used_at")
    private LocalDateTime usedAt;

    public enum SealType {
        OPEN, CLOSE, TRANSFER
    }
}
