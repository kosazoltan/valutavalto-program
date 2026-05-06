package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

/**
 * P2-2 Supervisor PIN — rate-limit attempt log.
 *
 * <p>3 hibás próbálkozás 5 perc alatt → 5 perc lockout (per workerId).
 * V188 migráció.</p>
 */
@Entity
@Table(name = "supervisor_pin_attempt")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SupervisorPinAttempt {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "worker_id", nullable = false)
    private Worker worker;

    @Column(name = "attempt_at", nullable = false)
    private LocalDateTime attemptAt;

    @Column(name = "success", nullable = false)
    private boolean success;

    @Column(name = "client_ip", length = 45)
    private String clientIp;

    @Column(name = "user_agent", length = 300)
    private String userAgent;

    @PrePersist
    void prePersist() {
        if (attemptAt == null) attemptAt = LocalDateTime.now();
    }
}
