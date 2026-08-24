package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.ShipmentRequest;
import hu.puzzleir.valuta.entity.ShipmentRequestStatus;
import hu.puzzleir.valuta.entity.ShipmentVatSupplyItem;
import hu.puzzleir.valuta.entity.VatSupplyStock;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.ShipmentVatSupplyItemRepository;
import hu.puzzleir.valuta.repository.VatSupplyStockRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * FKH-040: az ÁFA átadás-átvétel napló státusz-tükrözése és a folyamatosan vezetett
 * {@code vat_supply_stock} egyenleg könyvelése.
 *
 * <p>Irány-derivált könyvelés (a klienstől nem manipulálható):
 * ha az ÁTVEVŐ értéktár (Bank→Értéktár), a területi egyenleg NŐ;
 * ha az ÁTADÓ értéktár (Értéktár→Pénztár), CSÖKKEN. Ha egyik oldal sem értéktár,
 * a tétel nem könyvelhető (ValidationException).</p>
 *
 * <p>A mozgás egyszer fut le: az első APPROVED vagy DELIVERED státuszban, a
 * {@code stockApplied} idempotencia-flag védelme alatt (SUBMITTED→DELIVERED közvetlen
 * átvételnél is pontosan egyszer).</p>
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class ShipmentVatSupplySyncService {

    public static final String ACTION_VAT_SUPPLY_APPROVED = "SHIPMENT_VAT_SUPPLY_APPROVED";
    public static final String ACTION_VAT_SUPPLY_STOCK_APPLIED = "SHIPMENT_VAT_SUPPLY_STOCK_APPLIED";

    private final ShipmentVatSupplyItemRepository vatSupplyRepository;
    private final VatSupplyStockRepository vatSupplyStockRepository;
    private final BranchRepository branchRepository;
    private final AuditLogService auditLogService;

    @Transactional(propagation = Propagation.REQUIRED)
    public void syncFromShipment(ShipmentRequest shipment) {
        vatSupplyRepository.findByShipmentRequestIdAndCompanyId(shipment.getId(), shipment.getCompanyId())
                .ifPresent(item -> syncExistingItem(shipment, item));
    }

    private void syncExistingItem(ShipmentRequest shipment, ShipmentVatSupplyItem item) {
        boolean newlyApproved = shipment.getStatus() == ShipmentRequestStatus.APPROVED
                && item.getApprovedAt() == null;
        item.setStatus(shipment.getStatus());
        // A készlet-könyvelés ELŐBB fut: ha elbukik (negatív egyenleg, nem-értéktári oldal),
        // ne szülessen félrevezető "jóváhagyva" audit-nyom a REQUIRES_NEW audit-tranzakcióban.
        if (requiresStockApply(shipment.getStatus()) && !item.isStockApplied()) {
            applyStock(item);
            item.setStockApplied(true);
        }
        if (newlyApproved) {
            item.setApprovedAt(LocalDateTime.now());
            auditLogService.log(
                    ACTION_VAT_SUPPLY_APPROVED,
                    "ShipmentVatSupplyItem",
                    item.getId().toString(),
                    String.valueOf(SecurityUtils.getCurrentWorkerId()),
                    SecurityUtils.getCurrentWorkerCode(),
                    item.getFromBranchId().toString(),
                    null,
                    String.format(
                            "{\"KAT\":\"TX\",\"shipment_request_id\":\"%s\",\"huf_amount\":%s}",
                            shipment.getId(), item.getHufAmount().toPlainString()),
                    null,
                    null);
            log.info("Shipment ÁFA-ellátmány jóváhagyva: shipment={}", shipment.getId());
        }
        vatSupplyRepository.save(item);
    }

    private static boolean requiresStockApply(ShipmentRequestStatus status) {
        return status == ShipmentRequestStatus.APPROVED || status == ShipmentRequestStatus.DELIVERED;
    }

    /**
     * A területi ÁFA-HUF egyenleg mozgatása. Az irányt a from/to fiók
     * {@link Branch#getIsVault()} flagje határozza meg — szerveroldalon, tenant-szűrt
     * branch-ekből.
     */
    private void applyStock(ShipmentVatSupplyItem item) {
        UUID companyId = item.getCompanyId();
        Branch fromBranch = findBranch(item.getFromBranchId(), companyId);
        Branch toBranch = findBranch(item.getToBranchId(), companyId);

        boolean credit;
        Branch vaultBranch;
        if (toBranch != null && Boolean.TRUE.equals(toBranch.getIsVault())) {
            credit = true;
            vaultBranch = toBranch;
        } else if (fromBranch != null && Boolean.TRUE.equals(fromBranch.getIsVault())) {
            credit = false;
            vaultBranch = fromBranch;
        } else {
            throw new ValidationException(
                    "Az ÁFA-ellátmány mozgás egyik oldala sem értéktár, ezért nem könyvelhető: shipment="
                            + item.getShipmentRequestId());
        }
        if (vaultBranch.getVaultTerritoryId() == null) {
            throw new ValidationException(
                    "Az értéktári fiókhoz nincs vault_territory_id rendelve: branch=" + vaultBranch.getId());
        }
        Integer territoryId = vaultBranch.getVaultTerritoryId();

        VatSupplyStock stock = vatSupplyStockRepository
                .findByCompanyIdAndVaultTerritoryId(companyId, territoryId)
                .orElseGet(() -> VatSupplyStock.builder()
                        .companyId(companyId)
                        .vaultTerritoryId(territoryId)
                        .currentBalance(BigDecimal.ZERO)
                        .build());

        BigDecimal current = stock.getCurrentBalance() == null ? BigDecimal.ZERO : stock.getCurrentBalance();
        BigDecimal newBalance = credit
                ? current.add(item.getHufAmount())
                : current.subtract(item.getHufAmount());
        if (newBalance.signum() < 0) {
            throw new ValidationException(String.format(
                    "Az ÁFA-ellátmány egyenleg nem mehet negatívba: terület=%s, egyenleg=%s, igényelt=%s",
                    territoryId, current.toPlainString(), item.getHufAmount().toPlainString()));
        }
        stock.setCurrentBalance(newBalance);
        stock.setUpdatedAt(LocalDateTime.now());
        vatSupplyStockRepository.save(stock);

        auditLogService.log(
                ACTION_VAT_SUPPLY_STOCK_APPLIED,
                "VatSupplyStock",
                territoryId.toString(),
                String.valueOf(SecurityUtils.getCurrentWorkerId()),
                SecurityUtils.getCurrentWorkerCode(),
                vaultBranch.getId().toString(),
                null,
                String.format(
                        "{\"KAT\":\"TX\",\"shipment_request_id\":\"%s\",\"vault_territory_id\":%s,"
                                + "\"direction\":\"%s\",\"huf_amount\":%s,\"new_balance\":%s}",
                        item.getShipmentRequestId(),
                        territoryId,
                        credit ? "CREDIT" : "DEBIT",
                        item.getHufAmount().toPlainString(),
                        newBalance.toPlainString()),
                null,
                null);
        log.info("ÁFA-ellátmány készlet könyvelve: terület={}, irány={}, összeg={}, egyenleg={}",
                territoryId, credit ? "CREDIT" : "DEBIT", item.getHufAmount(), newBalance);
    }

    private Branch findBranch(UUID branchId, UUID companyId) {
        if (branchId == null || companyId == null) {
            return null;
        }
        return branchRepository.findByIdAndCompanyId(branchId, companyId).orElse(null);
    }

    /**
     * AS-jel: egy shipment akkor ÁFA-ellátmány típusú, ha tartozik hozzá
     * shipment_vat_supply_item sor (tenant-szűrt). Ugyanez a jel vezérli a
     * syncFromShipment-et és a currency_stock-könyvelés kihagyását (ShipmentService).
     */
    @Transactional(readOnly = true)
    public boolean isVatSupplyShipment(ShipmentRequest shipment) {
        return vatSupplyRepository.findByShipmentRequestIdAndCompanyId(
                shipment.getId(), shipment.getCompanyId()).isPresent();
    }

    @Transactional(readOnly = true)
    public void assertNotVatSupplyShipment(ShipmentRequest shipment) {
        if (isVatSupplyShipment(shipment)) {
            throw new ValidationException(
                    "ÁFA-ellátmány tétel a generikus szállítmány-módosítással nem szerkeszthető.");
        }
    }
}
