package hu.puzzleir.valuta.dto.currency;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/** FS-9: címletkép meta-DTO — BÁJTOK NÉLKÜL (a bájtok a /image és /thumbnail endpointon). */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CurrencyDenominationImageDto {
    private UUID id;
    private Long currencyId;
    private BigDecimal faceValue;
    private String denominationType;
    private String side;
    private String mimeType;
    private Long fileSizeBytes;
    private Boolean active;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
