package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;

/**
 * Átadás-átvétel valuta-sor (Kósa Zoltán #6): EGY átadólapon több valuta is rögzíthető.
 *
 * <p>Visszafelé kompat: a meglévő egy-valutás átadások NEM kapnak {@code TransferLine}-t
 * (a {@link Transfer#getCurrency()} + amount marad a forrás). Csak a multi-line átadások
 * használják a sorokat.
 */
@Entity
@Table(name = "transfer_lines")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class TransferLine {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "transfer_id", nullable = false)
    private Transfer transfer;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "currency_id", nullable = false)
    private Currency currency;

    @Column(name = "amount", nullable = false, precision = 18, scale = 2)
    private BigDecimal amount;

    @Column(name = "received_amount", precision = 18, scale = 2)
    private BigDecimal receivedAmount;

    @Column(name = "difference", precision = 18, scale = 2)
    private BigDecimal difference;

    @Column(name = "line_no", nullable = false)
    @Builder.Default
    private Integer lineNo = 1;
}
