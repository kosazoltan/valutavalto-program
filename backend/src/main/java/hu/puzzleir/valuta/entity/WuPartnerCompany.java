package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Western Union partner-cég törzs (legacy: WUCEGEK / GETWCEG.dll).
 *
 * <p>A WU-ügynöki tevékenységnél a vállalati partnerek (cégek) kereshető
 * nyilvántartása — a legacy GETWCEG egy listát + keresést + új-cég-felvételt adott.
 * Multi-tenant: minden cég a saját partnercég-törzsét látja.</p>
 */
@Entity
@Table(name = "wu_partner_company", indexes = {
        @Index(name = "idx_wu_partner_company_company", columnList = "company_id")
})
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class WuPartnerCompany {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    /** Multi-tenant: a partnercég-törzs tulajdonos cége. */
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "company_id", nullable = false)
    private Company company;

    @Column(name = "name", nullable = false, length = 200)
    private String name;

    @Column(name = "active", nullable = false)
    @Builder.Default
    private Boolean active = true;

    @CreatedDate
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;
}
