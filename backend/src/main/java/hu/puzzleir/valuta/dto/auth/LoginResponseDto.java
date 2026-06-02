package hu.puzzleir.valuta.dto.auth;

import hu.puzzleir.valuta.dto.worker.WorkerDto;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * Login response DTO - JWT token + worker adatok.
 * 
 * Ha a worker-nek több operatív szerepköre van:
 * - roles lista nem üres
 * - roleSelectionRequired = true
 * - token ideiglenes (role nélküli)
 * - A frontend /api/v1/auth/login/select-role hívással választ role-t
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class LoginResponseDto {
    private String token;
    @Builder.Default
    private String tokenType = "Bearer";
    private WorkerDto worker;

    // Frontend compatibility: expiresAt as ISO string
    private String expiresAt;

    // Legacy: expiresIn in milliseconds (for backward compatibility)
    private Long expiresIn;

    /**
     * Operatív szerepkör lista (role code-ok).
     * Ha 2+ elem → roleSelectionRequired = true.
     */
    private List<String> roles;

    /**
     * Az aktív (kiválasztott) operatív szerepkör kódja.
     * Null ha roleSelectionRequired = true.
     */
    private String activeRole;

    /**
     * Az aktív role-hoz tartozó permission kódok.
     */
    private List<String> permissions;

    /**
     * true ha a worker-nek több role-ja van és választania kell.
     */
    @Builder.Default
    private Boolean roleSelectionRequired = false;

    /**
     * true ha a worker jelszava még soha nem volt megváltoztatva (seed default jelszó).
     * Frontend: kötelező jelszóváltoztatás dialógus megjelenítése.
     */
    @Builder.Default
    private Boolean passwordChangeRequired = false;

    /**
     * v2.1.4: A dolgozo canonical role-jaibol szarmazo engedelyezett Electron
     * appMode-ok. A frontend login utan ellenorzi: ha az aktualis Electron
     * appMode nincs a listaban -> 'Hozzaferes megtagadva' hiba.
     *
     * Lehetseges ertekek:
     *   penztar       - ha a worker 'penztar' role-lal rendelkezik
     *   ertektar      - ha a worker 'ertektar' role-lal rendelkezik
     *   full          - ha a worker barmely szerver role-lal rendelkezik
     */
    private List<String> validAppModes;

    /**
     * Kozponti iranyitokozpont modulmanifest.
     * A frontend nem talalgat role-okbol: a szerver kuldi, hogy az aktiv
     * szerepkor mely kozponti modulokat jelenitheti meg.
     */
    private List<String> centralModules;

    // ============ FK-ÉRTÉKTÁR (V285, 2026-06-02): kétlépcsős értéktári belépés ============

    /**
     * true ha intézményi (közös) Google-fiókkal léptünk be, és a felhasználónak ki kell
     * választania a SAJÁT személyes workerét + jelszót (kétlépcsős belépés 1. fázis vége).
     * Ilyenkor NINCS végleges token/session — a frontend a dolgozóválasztót mutatja, majd a
     * POST /auth/google-vault/select-worker endpointtal véglegesít.
     */
    @Builder.Default
    private Boolean vaultWorkerSelectionRequired = false;

    /**
     * A kiválasztható személyes értéktári dolgozók (id + név) — csak ha
     * vaultWorkerSelectionRequired = true.
     */
    private List<VaultWorkerOptionDto> vaultWorkers;

    /** Az intézményi értéktár fiók (branch) neve — a dolgozóválasztó fejlécéhez. */
    private String vaultBranchName;
}
