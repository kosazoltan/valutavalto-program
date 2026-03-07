package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * FEOR kód referencia entity.
 * Foglalkozások Egységes Osztályozási Rendszere.
 */
@Entity
@Table(name = "feor_code")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class FeorCode {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** FEOR kód (pl. "4211") */
    @Column(nullable = false, unique = true, length = 10)
    private String code;

    /** FEOR megnevezés (pl. "Banki pénztáros") */
    @Column(nullable = false)
    private String title;
}
