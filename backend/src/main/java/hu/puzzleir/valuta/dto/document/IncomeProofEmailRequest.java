package hu.puzzleir.valuta.dto.document;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.ToString;

import java.math.BigDecimal;

/**
 * FS-7: 10M+ HUF vételhez jövedelemforrás-igazoló dokumentum email-küldés kérése.
 * ZERO-PERSISTENCE: a {@code imageBase64} bájtok soha nem perzisztálódnak —
 * a {@code @ToString} kizárja, hogy soha ne kerüljön logba/auditba.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@ToString(exclude = "imageBase64")
public class IncomeProofEmailRequest {

    @NotBlank(message = "A kép base64 kódolása kötelező")
    private String imageBase64;

    @NotBlank(message = "A fájltípus (MIME) megadása kötelező")
    private String mimeType;

    private String transactionRef;
    private String customerName;
    private BigDecimal hufAmount;
}
