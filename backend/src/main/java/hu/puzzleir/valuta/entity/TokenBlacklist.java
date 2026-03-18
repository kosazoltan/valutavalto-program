package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

/**
 * Token blacklist — kijelentkezéskor ide kerül a JWT tokenId,
 * hogy a filter elutasítsa a már visszavont tokeneket.
 */
@Entity
@Table(name = "token_blacklist")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TokenBlacklist {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "token_id", nullable = false, unique = true, length = 64)
    private String tokenId;

    @Column(name = "worker_id", nullable = false)
    private Long workerId;

    @Column(name = "blacklisted_at", nullable = false)
    private LocalDateTime blacklistedAt;

    @Column(name = "reason", nullable = false, length = 50)
    @Builder.Default
    private String reason = "LOGOUT";

    @Column(name = "expires_at", nullable = false)
    private LocalDateTime expiresAt;
}
