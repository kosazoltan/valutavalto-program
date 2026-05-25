package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Bank-törzs (FK-005/C1) — a banki átadás-átvétel cél/forrás bankjai.
 *
 * <p>Kósa Zoltán user-direktíva („Értéktári jogosultság, átadás-átvételek"): a banki
 * átadás-átvételnél cél/forrásként KIZÁRÓLAG Bankok + a jogosult Területek szerepelhessenek.
 * Ez a törzs adja a választható bankokat. Multi-tenant (company), területi (region_code):
 * a {@code null} region_code = cég-szintű bank (minden területen választható); a kitöltött
 * region_code = csak az adott terület értéktárosának. Az N4 (WuPartnerCompany) mintájára.</p>
 */
@Entity
@Table(name = "bank", indexes = {
        @Index(name = "idx_bank_company", columnList = "company_id"),
        @Index(name = "idx_bank_company_region", columnList = "company_id, region_code")
})
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Bank {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    /** Multi-tenant: a bank-törzs tulajdonos cége. */
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "company_id", nullable = false)
    private Company company;

    @Column(name = "name", nullable = false, length = 200)
    private String name;

    /** Területi kötés: NULL = cég-szintű (minden terület); kitöltött = csak az adott region. */
    @Column(name = "region_code", length = 10)
    private String regionCode;

    @Column(name = "active", nullable = false)
    @Builder.Default
    private Boolean active = true;

    @CreatedDate
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;
}
