package hu.puzzleir.valuta.dto.auth;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * FK-ÉRTÉKTÁR (V285, 2026-06-02): a kétlépcsős értéktári belépés dolgozóválasztó listájának
 * egy eleme. Csak a kiválasztáshoz minimálisan szükséges adat (id + név) — NINCS jelszó-hash,
 * email vagy egyéb PII a válaszban.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class VaultWorkerOptionDto {
    private Long id;
    private String name;
}
