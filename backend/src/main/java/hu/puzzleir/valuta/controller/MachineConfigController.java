package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.entity.MachineConfig;
import hu.puzzleir.valuta.service.MachineConfigService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

/**
 * EXCMD b6-beallitasok FR-14 — gépenként izolált konfigurációs rekordok REST API.
 *
 * <h3>Jogosultság</h3>
 * <p>{@code isAuthenticated()} — a bejelentkezett worker (bármely szerepkör) elérheti a
 * SAJÁT gépéhez tartozó konfigurációt. A company-izoláció a service rétegben történik:
 * a {@code companyId} MINDIG a SecurityContext-ből jön, soha nem a klienstől.</p>
 *
 * <h3>Jelszó kezelés</h3>
 * <p>A PUT payload {@code dailyReportPassword} mezőjét a service BCrypt-tel hash-eli.
 * A GET válaszban a hash SOHA nem szerepel — csak a {@code dailyReportPasswordSet: true/false}
 * jelző. Ez megfelel a b9 NFR-02 és a security-standards maszkolási követelményének.</p>
 *
 * <h3>Workstation code forrása</h3>
 * <p>A kliens az Electron {@code electronAPI.getConfig("branch_code")} értékét adja át
 * ({@code workstationCode}). Ez a Setup Wizard által az SQLite config-ba írt branch kód
 * (pl. BR039), ami a {@code VITE_BRANCH_CODE} env-változóból származik.</p>
 */
@RestController
@RequestMapping("/api/v1/machine-config")
@RequiredArgsConstructor
@Slf4j
public class MachineConfigController {

    private final MachineConfigService machineConfigService;

    /**
     * Konfigurációs rekord lekérése.
     *
     * <p>Visszaad: {@code { config: {...}, dailyReportPasswordSet: boolean, updatedAt, updatedBy }}</p>
     * <p>Ha még nincs mentett rekord, üres config-ot ad vissza (nem 404).</p>
     *
     * @param workstationCode a gép kódja (branch_code, pl. BR039)
     */
    @GetMapping("/{workstationCode}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<Map<String, Object>> getConfig(@PathVariable String workstationCode) {
        MachineConfig mc = machineConfigService.getConfig(workstationCode);
        Map<String, Object> resp = new HashMap<>();
        if (mc == null) {
            resp.put("config", "{}");
            resp.put("dailyReportPasswordSet", false);
            resp.put("updatedAt", null);
            resp.put("updatedBy", null);
        } else {
            resp.put("config", mc.getConfig());
            // SOHA nem adjuk vissza a hash-t — csak a "van-e beállítva" jelzőt.
            resp.put("dailyReportPasswordSet", mc.getDailyReportPasswordHash() != null);
            resp.put("updatedAt", mc.getUpdatedAt() != null ? mc.getUpdatedAt().toString() : null);
            resp.put("updatedBy", mc.getUpdatedBy());
        }
        return ResponseEntity.ok(resp);
    }

    /**
     * Konfiguráció mentése (upsert).
     *
     * <p>Elvárja: {@code { config: "{...}", dailyReportPassword?: "..." }}</p>
     * <ul>
     *   <li>{@code config}: a teljes settings JSON string (PenztarSettings serialized)</li>
     *   <li>{@code dailyReportPassword}: ha jelen van és nem üres, a service BCrypt-tel hash-eli.
     *       Ha nincs megadva vagy üres, a meglévő jelszó-hash változatlan marad.</li>
     * </ul>
     *
     * @param workstationCode a gép kódja (branch_code, pl. BR039)
     * @param body            a kérés törzse
     */
    @PutMapping("/{workstationCode}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<Map<String, Object>> upsertConfig(
            @PathVariable String workstationCode,
            @RequestBody Map<String, Object> body) {

        String configJson = body.get("config") instanceof String s ? s : "{}";
        // dailyReportPassword plain-text — a service hash-eli, soha nem tároljuk plain-ben.
        String plainPassword = body.get("dailyReportPassword") instanceof String p ? p : null;

        MachineConfig saved = machineConfigService.upsert(workstationCode, configJson, plainPassword);

        Map<String, Object> resp = new HashMap<>();
        resp.put("workstationCode", saved.getWorkstationCode());
        resp.put("dailyReportPasswordSet", saved.getDailyReportPasswordHash() != null);
        resp.put("updatedAt", saved.getUpdatedAt() != null ? saved.getUpdatedAt().toString() : null);
        log.info("[MachineConfig] Konfiguráció mentve: workstation={}", workstationCode);
        return ResponseEntity.ok(resp);
    }
}
