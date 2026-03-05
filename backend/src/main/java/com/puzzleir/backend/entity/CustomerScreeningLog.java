package com.puzzleir.backend.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "customer_screening_log")
@EntityListeners(AuditingEntityListener.class)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CustomerScreeningLog {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "customer_id", nullable = false)
    private Long customerId;

    @Column(name = "screening_type", nullable = false, length = 30)
    private String screeningType; // SANCTION / AML / ANNUAL_CHECK

    @Column(nullable = false, length = 20)
    private String result; // CLEAR / FLAGGED / BLOCKED

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(columnDefinition = "jsonb")
    private String details;

    @Column(name = "screened_at", nullable = false)
    private LocalDateTime screenedAt;

    @Column(name = "screened_by", nullable = false)
    private Long screenedBy;
}
