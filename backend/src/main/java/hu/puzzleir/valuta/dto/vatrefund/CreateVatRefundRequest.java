package hu.puzzleir.valuta.dto.vatrefund;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalTime;

/**
 * ÁFA visszatérítés létrehozási kérelem.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CreateVatRefundRequest {

    /** Bizonylat típus: AK, AB, AV */
    @NotBlank
    private String voucherType;

    /** Tranzakció dátuma (opcionális — ha null: ma) */
    private LocalDate transactionDate;

    /** Tranzakció időpontja (opcionális — ha null: most) */
    private LocalTime transactionTime;

    /** Főegység: 3=Innova, 4=pénztár, 6=ügyfél */
    private Integer mainUnit;

    /** Ellátmány összeg (AV típushoz) */
    private BigDecimal supplyAmount;

    /** Bruttó összeg */
    @NotNull
    @DecimalMin("0.01")
    private BigDecimal grossAmount;

    /** ÁFA összeg */
    @NotNull
    @DecimalMin("0.00")
    private BigDecimal vatAmount;

    /** ÁFA százalék */
    private BigDecimal vatPercentage;

    /** Ügyfél neve */
    private String customerName;

    /** Ügyfél lakcíme */
    private String customerAddress;

    /** Ügyfél azonosítója */
    private String customerIdentifier;

    /** Bankszámlaszám */
    private String bankAccountNumber;

    /** Cég neve (jogi személy esetén) */
    private String companyName;

    /** Telephely cím */
    private String siteAddress;

    /** Okiratszám */
    private String deedNumber;
}
