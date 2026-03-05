package com.puzzleir.backend.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "evening_closing")
@EntityListeners(AuditingEntityListener.class)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class EveningClosing {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "company_id", nullable = false)
    private UUID companyId;

    @Column(name = "branch_id", nullable = false)
    private UUID branchId;

    @Column(name = "closing_date", nullable = false)
    private LocalDate closingDate;

    @Column(nullable = false, length = 20)
    private String status; // PREPARING / READY / SENT / CONFIRMED

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "package_data", columnDefinition = "jsonb")
    private String packageData;

    @Column(name = "transaction_count", nullable = false)
    private Integer transactionCount;

    @Column(name = "total_buy_huf", nullable = false, precision = 15, scale = 2)
    private BigDecimal totalBuyHuf;

    @Column(name = "total_sell_huf", nullable = false, precision = 15, scale = 2)
    private BigDecimal totalSellHuf;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "inventory_snapshot", columnDefinition = "jsonb")
    private String inventorySnapshot;

    @Column(name = "sent_at")
    private LocalDateTime sentAt;

    @Column(name = "confirmed_at")
    private LocalDateTime confirmedAt;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
