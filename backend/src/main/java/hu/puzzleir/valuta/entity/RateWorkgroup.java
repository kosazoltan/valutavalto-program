package hu.puzzleir.valuta.entity;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonProperty;
import hu.puzzleir.valuta.entity.Branch;
import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.HashSet;
import java.util.Set;
import java.util.UUID;

@Entity
@Table(name = "rate_workgroup", indexes = {
    @Index(name = "idx_rate_workgroup_company", columnList = "company_id")
}, uniqueConstraints = {
    @UniqueConstraint(name = "uq_rate_workgroup_company_code", columnNames = {"company_id", "code"})
})
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class RateWorkgroup {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "company_id", nullable = false)
    @JsonIgnore
    private Company company;

    @Column(nullable = false, length = 100)
    private String name;

    @Column(nullable = false, length = 20)
    private String code;

    @Column(name = "legacy_group_number")
    private Integer legacyGroupNumber;

    /** FK-02: csempe-szín paletta-kulcs (pl. 'amber', 'sky'); NULL = alapértelmezett. */
    @Column(name = "tile_color", length = 20)
    private String tileColor;

    @Column(name = "is_active")
    @Builder.Default
    private Boolean active = true;

    @Column(name = "created_at")
    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "limit1_boundary", precision = 15, scale = 2)
    private BigDecimal limit1Boundary;

    @Column(name = "limit2_boundary", precision = 15, scale = 2)
    private BigDecimal limit2Boundary;

    @Column(name = "limit3_boundary", precision = 15, scale = 2)
    private BigDecimal limit3Boundary;

    /**
     * FK-04/E árfolyamvédelem: ha TRUE, a csoport-lap mentése elutasít olyan
     * rátákat, ahol a vételi oszlopok (L,N,P,R) {@literal >} J (elszámoló)
     * vagy az eladási oszlopok (M,O,Q,S) {@literal <} J. A csempe jobb felső
     * checkbox-a vezérli (FK-04 A.3). Default: TRUE (biztonság alapból be).
     */
    @Column(name = "protection_enabled", nullable = false)
    @Builder.Default
    private Boolean protectionEnabled = Boolean.TRUE;

    @ManyToMany
    @JsonIgnore
    @JoinTable(
        name = "rate_workgroup_branch",
        joinColumns = @JoinColumn(name = "workgroup_id"),
        inverseJoinColumns = @JoinColumn(name = "branch_id")
    )
    @Builder.Default
    private Set<Branch> branches = new HashSet<>();

    /** Fix #146+ live UI test P1: Jackson LazyInit bypass - expose companyId as flat field */
    @JsonProperty("companyId")
    @Transient
    public UUID getCompanyId() {
        return company != null ? company.getId() : null;
    }
}
