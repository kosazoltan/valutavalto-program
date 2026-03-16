package hu.puzzleir.valuta.dto.led;

import lombok.*;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * LED kijelző konfiguráció DTO.
 *
 * V38 alapmezők + V98 soros port bővítés.
 */
@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class LedDisplayConfigDto {

    // ===== V38 alapmezők =====
    private UUID id;
    private UUID branchId;
    private String displayType;
    private String connectionString;
    private Boolean isActive;
    private Integer refreshIntervalSeconds;
    private String displayedCurrencies;
    private LocalDateTime lastUpdatedAt;

    // ===== V98 soros port mezők =====
    /** LedSerialDisplayType neve (pl. "STANDARD", "DUAL_SAME") */
    private String serialDisplayType;
    /** Vesszővel elválasztott COM portok (pl. "COM1" vagy "COM1,COM2") */
    private String comPorts;
    /** Vesszővel elválasztott valuták (pl. "EUR,USD,GBP,CHF") */
    private String currencies;
    private boolean showBankCard;
    private boolean speedCommand;
    private int speed;
    /** Záró bájtok vesszővel (pl. "254" vagy "254,255") */
    private String endMarkers;
    /** Tizedes elválasztó: ',' vagy '.' */
    private char decimalSeparator;
    private String customText;
    private String displayIds;
    private LocalDateTime updatedAt;
}
