package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Gépenként izolált konfigurációs rekord (EXCMD b6-beallitasok FR-14).
 *
 * <p>A {@code config} mező szabad JSONB — a kliensoldali {@code PenztarSettings} értékeit
 * (FR-02..FR-13: machineRole, displayColor, serverIp, futofény, stb.) tartalmazza.
 * A napi-jelentés jelszava ({@code dailyReportPasswordHash}) külön oszlopban tárolódik,
 * hogy a GET endpoint soha ne adja vissza a hash-t (csak {@code dailyReportPasswordSet: true/false}).
 *
 * <p>Multi-tenant: {@code companyId} + {@code workstationCode} egyedi pár. A workstationCode
 * a Electron-kliens {@code VITE_BRANCH_CODE} env-értéke (pl. BR039), amelyet a kliens az
 * {@code electronAPI.getConfig("branch_code")} hívással olvas ki.</p>
 */
@Entity
@Table(
    name = "machine_config",
    uniqueConstraints = @UniqueConstraint(
        name = "uq_machine_config_tenant",
        columnNames = {"company_id", "workstation_code"}
    )
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MachineConfig {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    @Column(columnDefinition = "uuid", updatable = false, nullable = false)
    private UUID id;

    /** Multi-tenant: SOHA ne kérd le company_id szűrés nélkül. */
    @Column(name = "company_id", nullable = false)
    private UUID companyId;

    /**
     * A gép azonosítója (branch_code a Electron env-ből, pl. BR039).
     * NEM UUID — a branch kód string.
     */
    @Column(name = "workstation_code", nullable = false, length = 100)
    private String workstationCode;

    /**
     * Szabad JSONB settings payload (FR-02..FR-13 értékek).
     * Postgres {@code jsonb} típusra leképezve String-ként; a service/controller
     * JSON-t vár és ad vissza.
     */
    @Column(name = "config", nullable = false, columnDefinition = "jsonb")
    @Builder.Default
    private String config = "{}";

    /**
     * BCrypt hash a napi-jelentés jelszaváról (FR-06).
     * {@code null} = nincs beállítva.
     * GET-ben SOHA nem adható vissza — csak a {@code dailyReportPasswordSet} boolean jön ki.
     */
    @Column(name = "daily_report_password_hash", length = 255)
    private String dailyReportPasswordHash;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    /** Az utolsó módosítást végző worker kódja (audit trail). */
    @Column(name = "updated_by", length = 100)
    private String updatedBy;
}
