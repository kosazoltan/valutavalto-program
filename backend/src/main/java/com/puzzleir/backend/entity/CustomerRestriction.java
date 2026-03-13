package com.puzzleir.backend.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "customer_restriction")
@EntityListeners(AuditingEntityListener.class)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CustomerRestriction {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "customer_id", nullable = false)
    private Long customerId;

    @Column(name = "restriction_type", nullable = false, length = 30)
    private String restrictionType; // BLOCKED / SUSPICIOUS / WATCH_LIST / ANNUAL_LIMIT

    @Column(nullable = false, columnDefinition = "TEXT")
    private String reason;

    @Column(name = "added_by", nullable = false)
    private Long addedBy;

    @Column(name = "added_at", nullable = false)
    private LocalDateTime addedAt;

    @Column(name = "expires_at")
    private LocalDateTime expiresAt;

    @Column(name = "is_active", nullable = false)
    private Boolean active;
}
