package hu.puzzleir.valuta.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * Bali Henriett / Kasza Helga FK-013 (2026-05-28): az egységes értéktári átadás-átvétel
 * menüpont "Cél iroda" legördülő tartalma, három csoportban.
 *
 * <ul>
 *   <li>{@code territorialCashiers} — a saját régió aktív lakossági pénztárai
 *       (FK-005/B4, AccessScopeService.vaultRegionBranchScopeOrNull). Pénztáros user
 *       NEM hív erre, csak értéktáros / főértéktáros.</li>
 *   <li>{@code peerVaults} — a cég többi értéktára (saját értéktár-branch kihagyva),
 *       hogy a területek közti átadás-átvétel ide menjen.</li>
 *   <li>{@code fixedCounterparties} — a 10 fix banki és speciális partner
 *       (PRB/UPT/TRB/ERB/FRB/RB/JRB/MNB/TH/FOP1), seed-elve a V277 migrációval,
 *       branch_type='VAULT_COUNTERPARTY'. Minden értéktárnál ugyanaz.</li>
 * </ul>
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class VaultCounterpartiesDto {
    /** Saját régió aktív lakossági pénztárai (értéktáros user perspektívájából). */
    private List<BranchDto> territorialCashiers;
    /** A cég többi értéktára (a saját kivételével). */
    private List<BranchDto> peerVaults;
    /** A 10 fix banki és speciális partner (cégenként 1 példány). */
    private List<BranchDto> fixedCounterparties;
}
