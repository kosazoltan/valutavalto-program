package hu.puzzleir.valuta.entity;

import hu.puzzleir.valuta.config.EncryptedStringConverter;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * NAV technikai credential-ek.
 *
 * A credential mezok titkositva tarolodnak az adatbazisban
 * az EncryptedStringConverter + JPA @Convert mechanizmussal.
 */
@Entity
@Table(name = "qr_parameters")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class NavCredential {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "branch_id", nullable = false)
    private Branch branch;

    @Column(name = "tax_number", nullable = false, length = 20)
    private String taxNumber;

    @Column(name = "software_id", nullable = false, length = 50)
    private String softwareId;

    @Column(name = "software_version", nullable = false, length = 20)
    private String softwareVersion;

    @Column(name = "nav_technical_user", length = 50)
    private String navTechnicalUser;

    @Convert(converter = EncryptedStringConverter.class)
    @Column(name = "nav_technical_password", length = 255)
    private String navTechnicalPassword;

    @Convert(converter = EncryptedStringConverter.class)
    @Column(name = "nav_signature_key", length = 255)
    private String navSignatureKey;

    @Convert(converter = EncryptedStringConverter.class)
    @Column(name = "nav_exchange_key", length = 255)
    private String navExchangeKey;

    @Column(name = "is_active")
    @Builder.Default
    private Boolean isActive = true;

    @Column(name = "created_at")
    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
