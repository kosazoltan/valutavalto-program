package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "branch")
@EntityListeners(AuditingEntityListener.class)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Branch {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false, length = 20, unique = true)
    private String code;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "company_id", nullable = false)
    private Company company;

    @Column(name = "bank_code", nullable = false, length = 20)
    private String bankCode;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "branch_type_did", nullable = false)
    private Dictionary branchType;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "parent_branch_id")
    private Branch parentBranch;

    @Column(nullable = false)
    private String name;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String address;

    @Column(nullable = false, length = 100)
    private String city;

    @Column(name = "zip_code", nullable = false, length = 10)
    private String zipCode;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "country_did", nullable = false)
    private Dictionary country;

    @Column(length = 50)
    private String phone;

    @Column(length = 255)
    private String email;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "branch_status_did", nullable = false)
    private Dictionary branchStatus;

    @Column(name = "opening_date", nullable = false)
    private LocalDate openingDate;

    @Column(name = "denomination_rule_id")
    private UUID denominationRuleId;

    /**
     * Értéktári terület hozzárendelés (V60 migráció)
     */
    @Column(name = "vault_territory_id")
    private Integer vaultTerritoryId;

    /**
     * v2.5.1 B6 (V174 migráció): a fiók ÉRTÉKTÁR-e?
     *  - TRUE  = értéktári fiók (lokál vagy központi)
     *  - FALSE = pénztár (default)
     * A SetupWizard értéktár módú telepítésnél csak is_vault=TRUE fiókokat enged kiválasztani.
     */
    @Column(name = "is_vault", nullable = false)
    @Builder.Default
    private Boolean isVault = Boolean.FALSE;

    /**
     * Legacy körzet kód (KESZLEX készlet export).
     * Értékek: 10 (Szekszárd), 20 (Szeged), 40 (Kecskemét), 50 (Debrecen),
     * 63 (Nyíregyháza), 75 (Békéscsaba), 120 (Pécs), 145 (Kaposvár)
     */
    @Column(name = "region_code", length = 10)
    private String regionCode;

    /** Region grouping (BEKESCSABA, DEBRECEN, NYIREGYHAZA, KECSKEMET, SZEGED, KAPOSVAR, PECS, SZEKSZARD, IRODA) for login-prefill. */
    @Column(name = "region", length = 40)
    private String region;

    @Column(name = "is_active")
    @Builder.Default
    private Boolean isActive = true;

    // ── Pénztár Törzs alapmodul (V293, Kasza Helga FELTERKEPEZES 2026-06-03) ──────────────
    /** Rövid név (opcionális, listákhoz/címkékhez). */
    @Column(name = "short_name", length = 100)
    private String shortName;

    /** ÁFA-visszatérítés elérhető-e az irodában. */
    @Column(name = "has_afa", nullable = false)
    @Builder.Default
    private Boolean hasAfa = Boolean.FALSE;

    /** Western Union szolgáltatás elérhető-e. */
    @Column(name = "has_wu", nullable = false)
    @Builder.Default
    private Boolean hasWu = Boolean.FALSE;

    /** MoneyGram szolgáltatás elérhető-e. */
    @Column(name = "has_mg", nullable = false)
    @Builder.Default
    private Boolean hasMg = Boolean.FALSE;

    /** Bankkártya-elfogadás (POS) elérhető-e. */
    @Column(name = "has_pos", nullable = false)
    @Builder.Default
    private Boolean hasPos = Boolean.FALSE;

    /** Az iroda szombaton zárva van-e. */
    @Column(name = "closed_saturday", nullable = false)
    @Builder.Default
    private Boolean closedSaturday = Boolean.FALSE;

    /** Az iroda vasárnap zárva van-e. */
    @Column(name = "closed_sunday", nullable = false)
    @Builder.Default
    private Boolean closedSunday = Boolean.FALSE;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
