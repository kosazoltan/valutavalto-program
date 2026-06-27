package hu.puzzleir.valuta.dto.inventory;

import lombok.Builder;
import lombok.Data;

import java.math.BigDecimal;
import java.util.UUID;

/**
 * Értéktár (VAULT) készlet egy valutára: nyitó / átvett / átadott / záró.
 *
 * v2.4.9: az "Értéktári készlet" oldal soronkénti adatszerkezete.
 *  - opening: napi nyitókészlet (a daily snapshot vagy null, ha még nincs)
 *  - received: napközben átvett mennyiség (Collection / BankWithdraw összesen)
 *  - issued: napközben átadott mennyiség (Distribution / BankDeposit összesen)
 *  - closing: jelenlegi készlet (= currency_stock.quantity, entity_type=VAULT)
 *
 * 2026-06-17 (FR-1/FR-2): a `difference` (hardcode 0, üzleti értelme nincs) és a `lastUpdated`
 * (automatikus frissítésnél felesleges) mezők eltávolítva.
 */
@Data
@Builder
public class VaultStockRowDto {
    private String currencyCode;
    private String currencyName;
    private String vaultTerritoryId;
    private UUID branchId;
    private BigDecimal opening;
    private BigDecimal received;
    private BigDecimal issued;
    private BigDecimal closing;
}
