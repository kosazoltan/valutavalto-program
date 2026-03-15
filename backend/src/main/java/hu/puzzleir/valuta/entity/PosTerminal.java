package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * POS terminál entity — kártyás fizetési terminálok nyilvántartása.
 */
@Entity
@Table(name = "pos_terminal")
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class PosTerminal {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "terminal_id", nullable = false, unique = true, length = 50)
    private String terminalId;

    @Column(name = "terminal_name", length = 200)
    private String terminalName;

    /**
     * Terminál típusa: MOCK, OTP, INGENICO, VERIFONE, PAX
     */
    @Column(name = "terminal_type", length = 30)
    @Builder.Default
    private String terminalType = "MOCK";

    /**
     * Terminál IP cím (Legacy: HARDWARE.POSHOST)
     */
    @Column(name = "ip_address", length = 50)
    private String ipAddress;

    /**
     * Terminál port (Legacy: HARDWARE.POSPORT)
     */
    @Column(name = "port")
    private Integer port;

    @Column(name = "branch_id", nullable = false)
    private UUID branchId;

    @Column(name = "is_active", nullable = false)
    @Builder.Default
    private Boolean isActive = true;

    @Column(name = "last_transaction_at")
    private LocalDateTime lastTransactionAt;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
