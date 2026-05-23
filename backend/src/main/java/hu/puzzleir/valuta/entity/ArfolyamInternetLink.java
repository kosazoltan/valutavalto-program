package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Árfolyamkészítő internet-link (legacy: ARFOLYAM / TINTERNETTMKFORM, Unit2.pas).
 *
 * <p>A rate-maker Főlapján gyors-megnyitható internet-linkek (pl. versenytárs/MNB
 * árfolyam-oldalak). Minden link: egyedi gombszám (sorrend), felirat, URL.
 * A legacy gombszám-egyediséget kényszerített ("X SZÁMÚ GOMB MÁR KI VAN OSZTVA").
 * Multi-tenant: cégenként saját link-készlet.</p>
 */
@Entity
@Table(name = "arfolyam_internet_link", indexes = {
        @Index(name = "idx_arf_internet_link_company", columnList = "company_id")
})
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class ArfolyamInternetLink {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "company_id", nullable = false)
    private Company company;

    /** Gombszám (sorrend) — cégen belül egyedi. Legacy: GOMBSZAMEDIT / _urlgombszam. */
    @Column(name = "button_number", nullable = false)
    private Integer buttonNumber;

    /** Gomb felirata. Legacy: GOMBFELIRATEDIT / _urlgombnevek. */
    @Column(name = "label", nullable = false, length = 100)
    private String label;

    /** Internet-cím (URL). Legacy: INTERNETCIMEDIT / _urlnevek. */
    @Column(name = "url", nullable = false, length = 500)
    private String url;

    @CreatedDate
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;
}
