package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Chain of Custody (birtoklási lánc) rekord.
 *
 * Minden videó export és hozzáférési eseményről
 * nem törölhető, append-only napló.
 *
 * Hatósági bizonyíték felhasználáshoz kötelező:
 * ki, mikor, mit, miért, milyen eszközre.
 */
@Entity
@Table(name = "chain_of_custody_record", indexes = {
    @Index(name = "idx_coc_export", columnList = "export_request_id"),
    @Index(name = "idx_coc_branch", columnList = "branch_id"),
    @Index(name = "idx_coc_timestamp", columnList = "event_timestamp")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ChainOfCustodyRecord {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    /** Kapcsolódó export kérelem (opcionális — visszanézés is naplózódik) */
    @Column(name = "export_request_id")
    private UUID exportRequestId;

    @Column(name = "branch_id", nullable = false)
    private UUID branchId;

    @Column(name = "camera_id", length = 50)
    private String cameraId;

    /** Esemény típusa */
    @Enumerated(EnumType.STRING)
    @Column(name = "event_type", nullable = false, length = 30)
    private CustodyEventType eventType;

    /** Ki végezte */
    @Column(name = "actor", nullable = false, length = 100)
    private String actor;

    /** Mikor */
    @Column(name = "event_timestamp", nullable = false)
    private LocalDateTime eventTimestamp;

    /** Részletek (pl. fájlnév, hash, céleszköz) */
    @Column(name = "details", columnDefinition = "TEXT")
    private String details;

    /** Érintett időszak kezdete */
    @Column(name = "period_from")
    private LocalDateTime periodFrom;

    /** Érintett időszak vége */
    @Column(name = "period_to")
    private LocalDateTime periodTo;

    /** IP cím / eszköz azonosító */
    @Column(name = "source_ip", length = 45)
    private String sourceIp;

    /** Manifest hash (ha export esemény) */
    @Column(name = "manifest_hash", length = 64)
    private String manifestHash;
}
