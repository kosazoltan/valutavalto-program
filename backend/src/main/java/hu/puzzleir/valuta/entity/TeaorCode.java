package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;

/**
 * TEÁOR'08 tevékenységi kód referencia-tábla (legacy: TEAORTABLA).
 *
 * <p>Jogi-személy ügyfél tevékenységi kódjának kereshető törzse. A {@code code}
 * a 4-jegyű TEÁOR'08 osztály, a {@code name} a magyar megnevezés. Globális lookup
 * (nem tenant-függő), kurált gyakori-kód-halmaz; szabad szöveg továbbra is engedett.</p>
 */
@Entity
@Table(name = "teaor_code", indexes = {
        @Index(name = "idx_teaor_code", columnList = "code", unique = true)
})
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class TeaorCode {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "code", nullable = false, length = 8, unique = true)
    private String code;

    @Column(name = "name", nullable = false, length = 255)
    private String name;
}
