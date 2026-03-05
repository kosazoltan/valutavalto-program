package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Pénztár szünet entity.
 * Pénztárgép szüneteltetése (ebédszünet, technikai szünet, stb.)
 */
@Entity
@Table(name = "cash_desk_break", indexes = {
    @Index(name = "idx_cash_desk_break_desk", columnList = "cash_desk_id"),
    @Index(name = "idx_cash_desk_break_active", columnList = "is_active")
})
@EntityListeners(AuditingEntityListener.class)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CashDeskBreak {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    /**
     * Pénztárgép ID
     */
    @Column(name = "cash_desk_id", nullable = false)
    private UUID cashDeskId;

    /**
     * Szünet kezdete
     */
    @Column(name = "break_start", nullable = false)
    private LocalDateTime breakStart;

    /**
     * Szünet vége
     */
    @Column(name = "break_end")
    private LocalDateTime breakEnd;

    /**
     * Szünet típusa (LUNCH, TECHNICAL, PERSONAL, OTHER)
     */
    @Column(name = "break_type", nullable = false, length = 50)
    private String breakType;

    /**
     * Szünet oka
     */
    @Column(length = 500)
    private String reason;

    /**
     * Aktív-e a szünet
     */
    @Column(name = "is_active", nullable = false)
    @Builder.Default
    private Boolean isActive = true;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
}
