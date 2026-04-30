package hu.puzzleir.valuta.dto.inventory;

import lombok.Builder;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Értéktár (VAULT) készlet egy valutára: nyitó / átvett / átadott / záró + különbség.
 *
 * v2.4.9: az "Értéktári készlet" oldal soronkénti adatszerkezete.
 *  - opening: napi nyitókészlet (a daily snapshot vagy null, ha még nincs)
 *  - received: napközben átvett mennyiség (Collection / BankWithdraw összesen)
 *  - issued: napközben átadott mennyiség (Distribution / BankDeposit összesen)
 *  - closing: jelenlegi készlet (= currency_stock.quantity, entity_type=VAULT)
 *  - difference: closing - (opening + received - issued); 0 ha minden mozgás könyvelve van
 */
@Data
@Builder
public class VaultStockRowDto {
    private String currencyCode;
    private String currencyName;
    private BigDecimal opening;
    private BigDecimal received;
    private BigDecimal issued;
    private BigDecimal closing;
    private BigDecimal difference;
    private LocalDateTime lastUpdated;
}
