package hu.puzzleir.valuta.entity;

import hu.puzzleir.valuta.config.EncryptedStringConverter;
import jakarta.persistence.Column;
import jakarta.persistence.Convert;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "bank_api_config")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class BankApiConfig {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "provider_name", nullable = false, unique = true, length = 40)
    private String providerName;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 40)
    @Builder.Default
    private BankApiMode mode = BankApiMode.HTML_SCRAPING_FALLBACK;

    @Column(name = "endpoint_url", columnDefinition = "TEXT")
    private String endpointUrl;

    @Enumerated(EnumType.STRING)
    @Column(name = "auth_type", nullable = false, length = 40)
    @Builder.Default
    private BankApiAuthType authType = BankApiAuthType.NONE;

    @Column(name = "client_id", length = 255)
    private String clientId;

    @Convert(converter = EncryptedStringConverter.class)
    @Column(name = "client_secret_encrypted", columnDefinition = "TEXT")
    private String clientSecret;

    @Column(name = "mtls_certificate_alias", length = 255)
    private String mtlsCertificateAlias;

    @Column(name = "update_frequency", nullable = false, length = 120)
    @Builder.Default
    private String updateFrequency = "0 0 8 * * MON-FRI";

    @Column(nullable = false)
    @Builder.Default
    private Boolean enabled = true;

    @Column(name = "last_run_timestamp")
    private LocalDateTime lastRunTimestamp;

    @Enumerated(EnumType.STRING)
    @Column(name = "last_run_status", nullable = false, length = 30)
    @Builder.Default
    private BankApiRunStatus lastRunStatus = BankApiRunStatus.NEVER_RUN;

    @Column(name = "last_run_message", columnDefinition = "TEXT")
    private String lastRunMessage;

    @Column(name = "created_at", nullable = false)
    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "updated_at", nullable = false)
    @Builder.Default
    private LocalDateTime updatedAt = LocalDateTime.now();

    @PrePersist
    void prePersist() {
        LocalDateTime now = LocalDateTime.now();
        if (createdAt == null) {
            createdAt = now;
        }
        updatedAt = now;
    }

    @PreUpdate
    void preUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
