package hu.puzzleir.valuta.dto.inventory;

import lombok.*;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * FR-3 (2026-06-17): WebSocket/STOMP invalidációs jelzés az "Értéktári készlet" nézethez.
 *
 * <p>Akkor publikálódik a {@code /topic/vault-stock/{companyId}} topicra, amikor egy átadás-átvétel
 * COMPLETED esemény ténylegesen módosította a vault {@code currency_stock} egyenleget
 * ({@code VaultStockFlowService}). A frontend erre re-fetchel (change-detectionnel).</p>
 *
 * <p><b>Szándékosan minimális payload</b> — nem tartalmaz összeget/egyenleget: a WS SUBSCRIBE nincs
 * topic-szinten korlátozva, a tényleges (territory-scope-olt) adat a szerver-oldalon authorizált
 * {@code GET /api/v1/inventory/vault-stock} hívásból jön. A {@code territoryId} csak diagnosztikai/
 * jövőbeli szűrési célt szolgál.</p>
 */
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class VaultStockChangedMessage {
    private UUID companyId;
    private Integer territoryId;
    private LocalDateTime changedAt;
}
