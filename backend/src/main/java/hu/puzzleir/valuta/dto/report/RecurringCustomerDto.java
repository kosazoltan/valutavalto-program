package hu.puzzleir.valuta.dto.report;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * Időszakos (visszatérő) ügyfél riport sor — legacy ugyfelcontrol/idoszakos parity.
 *
 * <p>v2.5.74 Sprint P3.3: AML frequent-customer detection. Azon ügyfelek, akik egy
 * adott időszakban a megadott küszöbnél többször tranzaktáltak — enhanced due diligence
 * (Pmt. 16. § fokozott ügyfél-átvilágítás) jelölthöz.</p>
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RecurringCustomerDto {

    /** Ügyfél-azonosító (Transaction.customerId — okmányszám-alapú string). */
    private String customerId;

    /**
     * Ügyfél neve a tranzakciókból (JPQL {@code MAX(customerName)} — lexikografikusan
     * legnagyobb, NEM idő szerinti utolsó; az AML-monitoring szempontjából elég az azonosítható név).
     */
    private String customerName;

    /** Tranzakciók száma az időszakban (COMPLETED + financial_effective). */
    private Long transactionCount;

    /** Összes HUF forgalom az időszakban. */
    private BigDecimal totalHufAmount;

    /** Időszak kezdete. */
    private LocalDate periodStart;

    /** Időszak vége. */
    private LocalDate periodEnd;
}
