package hu.puzzleir.valuta.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * EXCMD b9-korlevelek FR-03: pénztárosi gyanú-bejelentés (pl. bankkártyás-csalás gyanú,
 * PIN papírról olvasása, sorozatos kártyás váltások). A bejelentés a
 * {@code customer_screening_log}-ba kerül és a felsővezetők URGENT értesítést kapnak —
 * a pénztáros ezután telefonon egyeztet a területi vezetővel (a folyamat emberi lépése).
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SuspicionReportRequest {

    /** Belső ügyfél-azonosító, ha az ügyfél törzsbeli (opcionális — ismeretlen ügyfélnél null). */
    private Long customerId;

    /** Ügyfél neve a bejelentés pillanatában (kötelező, ha nincs customerId). */
    @Size(max = 255)
    private String customerName;

    /** Az érintett (felfüggesztett) ügylet HUF összege, ha értelmezhető. */
    private BigDecimal hufAmount;

    /** A gyanús jelek leírása — kötelező (Pmt. szerinti megőrzés). */
    @NotBlank(message = "A gyanús jelek leírása kötelező")
    @Size(max = 1000, message = "A leírás legfeljebb 1000 karakter")
    private String suspicionSigns;
}
