package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Árfolyamkészítő munkaív (rate-maker working sheet) szerver-oldali authoritatív replikája.
 *
 * <p>A vékony kliens (árfolyamkészítő) Local-First igazságforrása a szerkesztési munkaív: a 0. ív
 * (elszámoló A–I) + munkacsoport-overlayek + képletek. Ezt kétirányban szinkronizáljuk a központi
 * modullal. A {@code sheetJson} a munkaív teljes, kliens-átlátszó JSON-snapshotja; cégenként egy
 * aktív munkaív (lásd {@code uq_rate_maker_sheet_company}). A nemzeti TERÍTÉS továbbra is a
 * publish-flow-n megy (rate_template/exchange_rate); ez a tábla CSAK a szerkesztési munkaív sync-je.
 *
 * <p>Konfliktus: a vékony kliens az igazságforrás aktív szerkesztéskor; megnyitáskor a kliens a
 * szerver verzióját olvassa be alapként (version-összevetés). A {@code version} minden PUT-nál nő.
 */
@Entity
@Table(name = "rate_maker_sheet", indexes = {
        @Index(name = "uq_rate_maker_sheet_company", columnList = "company_id", unique = true)
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RateMakerSheet {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "company_id", nullable = false)
    private UUID companyId;

    /** A munkaív teljes JSON-snapshotja (0. ív + munkacsoport-overlay + képletek). */
    @Column(name = "sheet_json", nullable = false, columnDefinition = "jsonb")
    @JdbcTypeCode(SqlTypes.JSON)
    private String sheetJson;

    /** Sync-verzió: minden szerver-oldali írásnál nő; a kliens ebből látja a más gépről történt változást. */
    @Column(name = "version", nullable = false)
    @Builder.Default
    private Long version = 1L;

    /** A legutóbbi írás forrása: 'rate-maker' (vékony kliens) vagy 'central' (központi modul). */
    @Column(name = "source", length = 32, nullable = false)
    @Builder.Default
    private String source = "rate-maker";

    @Column(name = "device_id", length = 128)
    private String deviceId;

    @Column(name = "updated_by")
    private Long updatedBy;

    @Column(name = "updated_at", nullable = false)
    @Builder.Default
    private LocalDateTime updatedAt = LocalDateTime.now();

    @Column(name = "created_at", nullable = false)
    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();
}
