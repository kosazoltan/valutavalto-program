package hu.puzzleir.valuta.entity;

import hu.puzzleir.valuta.entity.Branch;
import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * LED kijelző konfiguráció entity.
 *
 * A fizikai LED kijelző beállításai: csatlakozás típus, kapcsolat,
 * megjelenített valuták + soros port (RS-232) protokoll paraméterei.
 *
 * V38 alapmezők + V98 soros port bővítés.
 */
@Entity
@Table(name = "led_display_config", indexes = {
    @Index(name = "idx_led_display_config_branch", columnList = "branch_id")
})
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class LedDisplayConfig {

    // ===== V38: alap mezők =====

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "branch_id", nullable = false)
    private Branch branch;

    @Enumerated(EnumType.STRING)
    @Column(name = "display_type", nullable = false, length = 30)
    @Builder.Default
    private LedDisplayConnectionType displayType = LedDisplayConnectionType.NETWORK;

    @Column(name = "connection_string", length = 255)
    private String connectionString;

    @Column(name = "is_active", nullable = false)
    @Builder.Default
    private Boolean isActive = true;

    @Column(name = "refresh_interval_seconds", nullable = false)
    @Builder.Default
    private Integer refreshIntervalSeconds = 60;

    /** Megjelenített valuták JSON array, pl. ["EUR","USD","GBP"] */
    @Column(name = "displayed_currencies", columnDefinition = "TEXT")
    private String displayedCurrencies;

    @Column(name = "last_updated_at")
    private LocalDateTime lastUpdatedAt;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    // ===== V98: soros port (RS-232) protokoll mezők =====

    /**
     * Soros port kijelző típus.
     * Null, ha az iroda nem soros port-alapú LED kijelzőt használ.
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "serial_display_type", length = 30)
    private LedSerialDisplayType serialDisplayType;

    /**
     * Vesszővel elválasztott COM portok.
     * Pl. "COM1" vagy "COM1,COM2" (kettős kijelzőhöz).
     */
    @Column(name = "com_ports", length = 100)
    @Builder.Default
    private String comPorts = "COM1";

    /**
     * Vesszővel elválasztott valuták a kijelzőn.
     * Pl. "EUR,USD,GBP,CHF"
     */
    @Column(name = "currencies", length = 200)
    @Builder.Default
    private String currencies = "EUR,USD,GBP,CHF";

    /** Bankkártya felirat megjelenítése. */
    @Column(name = "show_bank_card", nullable = false)
    @Builder.Default
    private boolean showBankCard = false;

    /** Sebesség parancs elküldése a kijelzőnek. */
    @Column(name = "speed_command", nullable = false)
    @Builder.Default
    private boolean speedCommand = true;

    /** Görgetési sebesség (1–10). */
    @Column(name = "speed", nullable = false)
    @Builder.Default
    private int speed = 5;

    /**
     * Záró bájtok vesszővel.
     * Pl. "254" (0xFE) vagy "254,255" (0xFE, 0xFF).
     */
    @Column(name = "end_markers", length = 20)
    @Builder.Default
    private String endMarkers = "254";

    /** Tizedes elválasztó a kijelzőn: ',' (magyar) vagy '.' */
    @Column(name = "decimal_separator", length = 1)
    @Builder.Default
    private char decimalSeparator = ',';

    /** Egyéni szöveg (TEXT_ONLY / MIXED / DUAL_DIFF típusokhoz). */
    @Column(name = "custom_text", columnDefinition = "TEXT")
    private String customText;

    /** Kijelző azonosítók (opcionális, vesszővel). */
    @Column(name = "display_ids", length = 50)
    private String displayIds;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    // ===== Segédmetódusok =====

    /**
     * COM portok tömbje.
     * Pl. "COM1,COM2" → ["COM1", "COM2"]
     */
    public String[] getComPortArray() {
        if (comPorts == null || comPorts.isBlank()) return new String[0];
        String[] parts = comPorts.split(",");
        for (int i = 0; i < parts.length; i++) {
            parts[i] = parts[i].trim();
        }
        return parts;
    }

    /**
     * Valuták tömbje.
     * Pl. "EUR,USD,GBP,CHF" → ["EUR", "USD", "GBP", "CHF"]
     */
    public String[] getCurrencyArray() {
        if (currencies == null || currencies.isBlank()) return new String[0];
        String[] parts = currencies.split(",");
        for (int i = 0; i < parts.length; i++) {
            parts[i] = parts[i].trim();
        }
        return parts;
    }

    /**
     * Záró bájt értékek tömbje.
     * Pl. "254,255" → [254, 255]
     */
    public int[] getEndMarkerBytes() {
        if (endMarkers == null || endMarkers.isBlank()) return new int[]{254};
        String[] parts = endMarkers.split(",");
        int[] result = new int[parts.length];
        for (int i = 0; i < parts.length; i++) {
            try {
                int value = Integer.parseInt(parts[i].trim());
                if (value < 0 || value > 255) {
                    throw new IllegalArgumentException(
                            "Záró bájt érték 0-255 között kell legyen, kapott: " + value);
                }
                result[i] = value;
            } catch (NumberFormatException e) {
                throw new IllegalArgumentException(
                        "Érvénytelen záró bájt érték: '" + parts[i].trim() + "' — egész szám szükséges (0-255)");
            }
        }
        return result;
    }

    @PreUpdate
    public void preUpdate() {
        this.updatedAt = LocalDateTime.now();
    }
}
