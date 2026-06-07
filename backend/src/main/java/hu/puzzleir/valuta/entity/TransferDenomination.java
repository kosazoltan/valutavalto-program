package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.util.UUID;

/**
 * Értéktári átadás-átvétel bizonylat opcionális címletezése (darab × névleges érték).
 *
 * Szabad bevitel — nincs előre rögzített címletlista. Egy átadáshoz több sor is tartozhat
 * (pl. 5×100€ + 3×50€). Ha van legalább egy sor, a sorok összege kötelezően egyezik az átadás
 * összegével (FR-20b). Ha nincs sor, a bizonylaton nem jelenik meg a címletezés.
 */
@Entity
@Table(name = "transfer_denomination")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TransferDenomination {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "company_id", nullable = false)
    private UUID companyId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "transfer_id", nullable = false)
    private Transfer transfer;

    /** Darabszám (pozitív). */
    @Column(name = "quantity", nullable = false)
    private Integer quantity;

    /** Névleges érték (pozitív). */
    @Column(name = "face_value", nullable = false, precision = 18, scale = 4)
    private BigDecimal faceValue;

    @Column(name = "currency_code", nullable = false, length = 3)
    private String currencyCode;

    /** quantity × faceValue (a service számolja és validálja). */
    @Column(name = "line_total", nullable = false, precision = 18, scale = 4)
    private BigDecimal lineTotal;
}
