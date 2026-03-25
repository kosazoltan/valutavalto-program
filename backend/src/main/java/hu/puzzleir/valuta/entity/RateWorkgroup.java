package hu.puzzleir.valuta.entity;

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
    private Company company;

    @Column(nullable = false, length = 100)
    private String name;

    @Column(nullable = false, length = 20)
    private String code;

    @Column(name = "legacy_group_number")
    private Integer legacyGroupNumber;

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

    @ManyToMany
    @JoinTable(
        name = "rate_workgroup_branch",
        joinColumns = @JoinColumn(name = "workgroup_id"),
        inverseJoinColumns = @JoinColumn(name = "branch_id")
    )
    @Builder.Default
    private Set<Branch> branches = new HashSet<>();
}
