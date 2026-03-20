package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Kamera szegmens hash-lánc elem.
 *
 * Minden videó szegmenshez egy hash-lánc bejegyzés tartozik.
 * A chainHash az előző szegmens hash-ét is tartalmazza,
 * biztosítva a forenzikus integritást.
 *
 * Hash: SHA-256(previousHash | fileHash | metadata)
 */
@Entity
@Table(name = "camera_segment_hash", indexes = {
    @Index(name = "idx_camera_hash_branch_camera", columnList = "branch_id, camera_id"),
    @Index(name = "idx_camera_hash_recording", columnList = "recording_id"),
    @Index(name = "idx_camera_hash_sequence", columnList = "branch_id, camera_id, sequence_number")
}, uniqueConstraints = {
    @UniqueConstraint(name = "uk_camera_hash_sequence",
        columnNames = {"branch_id", "camera_id", "sequence_number"})
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CameraSegmentHash {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    /** A felvétel entity ID-ja */
    @Column(name = "recording_id", nullable = false)
    private UUID recordingId;

    /** Iroda */
    @Column(name = "branch_id", nullable = false)
    private UUID branchId;

    /** Kamera azonosító */
    @Column(name = "camera_id", nullable = false, length = 50)
    private String cameraId;

    /** Sorszám a láncon belül */
    @Column(name = "sequence_number", nullable = false)
    private Integer sequenceNumber;

    /** A szegmens fájl SHA-256 hash-e */
    @Column(name = "file_hash", nullable = false, length = 64)
    private String fileHash;

    /** Az előző lánc-elem chainHash értéke (genesis: 64×'0') */
    @Column(name = "previous_hash", nullable = false, length = 64)
    private String previousHash;

    /** Lánc hash: SHA-256(previousHash | fileHash | metadata) */
    @Column(name = "chain_hash", nullable = false, length = 64)
    private String chainHash;

    /** Fájl elérési út (helyi) */
    @Column(name = "file_path", length = 500)
    private String filePath;

    /** Fájl méret byte-ban */
    @Column(name = "file_size_bytes")
    private Long fileSizeBytes;

    /** Létrehozás időpontja */
    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;
}
