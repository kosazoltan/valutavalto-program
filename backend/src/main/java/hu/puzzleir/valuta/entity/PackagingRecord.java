package hu.puzzleir.valuta.entity;

import com.puzzleir.backend.entity.Branch;
import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Göngyöleg kezelés (bankjegy csomagolás nyilvántartás).
 * Nyilvántartja hány köteg bankjegy lett becsomagolva adott címletben.
 */
@Entity
@Table(name = "packaging_record", indexes = {
    @Index(name = "idx_packaging_branch", columnList = "branch_id"),
    @Index(name = "idx_packaging_date", columnList = "packaging_date")
})
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class PackagingRecord {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "branch_id", nullable = false)
    private Branch branch;

    @Column(name = "currency_code", nullable = false, length = 3)
    private String currencyCode;

    @Column(name = "packaging_date", nullable = false)
    private LocalDate packagingDate;

    @Column(name = "bundle_count", nullable = false)
    @Builder.Default
    private Integer bundleCount = 0;

    /** Bankjegy címlet (pl. 10000, 5000, stb.) */
    @Column(nullable = false)
    private Integer denomination;

    /** Egy köteg bankjegyeinek száma (általában 100) */
    @Column(name = "bundle_size", nullable = false)
    @Builder.Default
    private Integer bundleSize = 100;

    @Column(length = 500)
    private String notes;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
}
