package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;
import java.util.UUID;

/**
 * Auto-sorszám tracker per körlevél típus prefix.
 * Legacy: FZS001, FZS002, BT008, KI001 stb.
 * Minden prefix-hez külön számláló.
 */
@Entity
@Table(name = "circular_sequence", uniqueConstraints = {
    @UniqueConstraint(columnNames = {"company_id", "prefix"})
})
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor
@Builder
public class CircularSequence {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @Column(name = "company_id", nullable = false)
    private UUID companyId;

    @Column(nullable = false, length = 10)
    private String prefix;

    @Column(name = "last_number", nullable = false)
    @Builder.Default
    private Integer lastNumber = 0;
}
