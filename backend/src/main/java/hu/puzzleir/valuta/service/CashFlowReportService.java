package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.report.CashFlowReportDto;
import hu.puzzleir.valuta.dto.report.CashFlowReportRowDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Dictionary;
import hu.puzzleir.valuta.entity.ShipmentRequest;
import hu.puzzleir.valuta.entity.ShipmentRequestItem;
import hu.puzzleir.valuta.entity.ShipmentRequestStatus;
import hu.puzzleir.valuta.entity.Transfer;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.ShipmentRequestRepository;
import hu.puzzleir.valuta.repository.TransferRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * FKH-030: Pénzforgalom riport — Transfer és Shipment tételek egyesítve, bizonylatonkénti
 * sorokban, tetszőleges dátumtartományra, a felhasználó teljes körzetére.
 *
 * <p>A {@link HufDaybookService} merge- és partner-feloldó logikáját veszi alapul, de három
 * ponton szándékosan eltér:
 * <ul>
 *   <li><b>tartomány</b> egy nap helyett (FR-2),</li>
 *   <li><b>branch-halmaz</b> egy fiók helyett (FR-9),</li>
 *   <li><b>AT/AV prefix is</b> az FF/UF mellett a Transfer oldalon (FR-6).</li>
 * </ul>
 * A KK (kezelési díj) tételek kimaradnak (FR-7): a shipment-lekérdezés csak FF/UF
 * {@code serialPrefix}-et enged, a KK pedig nem az.</p>
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class CashFlowReportService {

    private static final String VAULT_COUNTERPARTY_TYPE = "VAULT_COUNTERPARTY";

    /**
     * FR-8: Bank kategóriába sorolt VAULT_COUNTERPARTY betűkódok.
     *
     * <p>Az {@code UPT}/{@code TH}/{@code FOP1} besorolása megrendelői döntés (TBD-2):
     * ezek szigorúan véve nem bankok, de a riport szempontjából a Bank oszlopban
     * jelennek meg. Ha ez üzletileg változik, KIZÁRÓLAG ezt a halmazt kell módosítani.</p>
     */
    private static final Set<String> BANK_PARTNER_CODES = Set.of(
            "PRB", "ERB", "FRB", "RB", "JRB", "MNB", "UPT", "TH", "FOP1");

    /** FR-8: Terület kategória — jelenleg egyetlen betűkód. */
    private static final Set<String> TERRITORY_PARTNER_CODES = Set.of("TRB");

    static final String CATEGORY_BANK = "Bank";
    static final String CATEGORY_TERRITORY = "Terület";
    static final String CATEGORY_CASHIER = "Pénztár";
    static final String CATEGORY_OTHER = "Egyéb";

    /** NFR-5: a UI figyelmeztet 1 év felett; a backend fail-closed módon el is utasítja. */
    private static final int MAX_RANGE_DAYS = 366;

    private final TransferRepository transferRepository;
    private final ShipmentRequestRepository shipmentRequestRepository;
    private final BranchRepository branchRepository;
    private final hu.puzzleir.valuta.repository.CurrencyRepository currencyRepository;
    private final AccessScopeService accessScopeService;

    @Transactional(readOnly = true)
    public CashFlowReportDto getReport(LocalDate from, LocalDate to) {
        validateRange(from, to);

        UUID companyId = SecurityUtils.getCurrentCompanyId();

        // FR-9: terület-szűrés. A régiós értéktáros a saját körzetére szűkül; cégszintű
        // szerepkörnél (pl. Főértéktáros) a scope null → a cég MINDEN aktív fiókja.
        Set<UUID> scope = accessScopeService.vaultRegionBranchScopeOrNull();
        Set<UUID> branchIds = scope != null ? scope : allActiveBranchIds(companyId);
        if (branchIds.isEmpty()) {
            log.debug("FKH-030: ures branch-scope (company={}) — ures riport", companyId);
            return emptyReport(from, to);
        }

        List<Transfer> transfers =
                transferRepository.findCashFlowReportTransfers(companyId, branchIds, from, to);
        List<ShipmentRequest> shipments =
                shipmentRequestRepository.findCashFlowReportShipments(companyId, branchIds, from, to);

        Map<UUID, Branch> partnerBranches = loadPartnerBranches(transfers, shipments, companyId);
        Map<Long, String> currencyCodes = loadCurrencyCodes(shipments);

        List<SortableRow> rows = new ArrayList<>();
        for (Transfer transfer : transfers) {
            rows.addAll(toTransferRows(transfer, branchIds, companyId));
        }
        for (ShipmentRequest shipment : shipments) {
            rows.addAll(toShipmentRows(shipment, branchIds, partnerBranches, currencyCodes));
        }

        // FR-4: dátum szerint rendezett lista; azonos időpontnál determinisztikus tie-break.
        rows.sort(Comparator
                .comparing(SortableRow::date)
                .thenComparing(SortableRow::eventTime, Comparator.nullsLast(Comparator.naturalOrder()))
                .thenComparing(SortableRow::receiptNumber, Comparator.nullsLast(Comparator.naturalOrder())));

        return CashFlowReportDto.builder()
                .from(from.toString())
                .to(to.toString())
                .rows(rows.stream().map(SortableRow::row).toList())
                .build();
    }

    // ============================ VALIDACIO ============================

    private void validateRange(LocalDate from, LocalDate to) {
        if (from == null || to == null) {
            throw new ValidationException("A TŐL és IG dátum megadása kötelező.");
        }
        if (to.isBefore(from)) {
            throw new ValidationException("Az IG dátum nem lehet korábbi, mint a TŐL dátum.");
        }
        if (from.plusDays(MAX_RANGE_DAYS).isBefore(to)) {
            throw new ValidationException(
                    "A lekérdezett időszak nem haladhatja meg az 1 évet (teljesítmény-védelem).");
        }
    }

    private CashFlowReportDto emptyReport(LocalDate from, LocalDate to) {
        return CashFlowReportDto.builder()
                .from(from.toString())
                .to(to.toString())
                .rows(List.of())
                .build();
    }

    private Set<UUID> allActiveBranchIds(UUID companyId) {
        return branchRepository.findByCompanyIdAndIsActiveTrue(companyId).stream()
                .map(Branch::getId)
                .collect(Collectors.toSet());
    }

    // ============================ SOR-KEPZES ============================

    /** Rendezo-kulcsos sor: datum + esemeny-idopont + bizonylatszam. */
    private record SortableRow(LocalDate date, LocalDateTime eventTime, String receiptNumber,
                               CashFlowReportRowDto row) {
    }

    /**
     * Egy Transfer-bizonylatból képzett sorok.
     *
     * <p>Az irány a SCOPE-hoz képest értendő: ha a küldő fiók van a körzetünkben, a tétel
     * ÁTADÁS; ha a fogadó, ÁTVÉTEL. Ha MINDKETTŐ a körzetünkben van (belső mozgás), a
     * bizonylat KÉT sort kap — a pénz tényleg kétszer mozdult a körzeten belül, és a
     * riport bizonylatonkénti-soros elve (FR-3) ezt így tükrözi helyesen.</p>
     */
    private List<SortableRow> toTransferRows(Transfer transfer, Set<UUID> scope, UUID companyId) {
        List<SortableRow> result = new ArrayList<>();
        boolean fromInScope = transfer.getFromBranch() != null
                && scope.contains(transfer.getFromBranch().getId());
        boolean toInScope = transfer.getToBranch() != null
                && scope.contains(transfer.getToBranch().getId());

        if (fromInScope) {
            result.add(transferRow(transfer, companyId, transfer.getToBranch(), true, false));
        }
        if (toInScope) {
            result.add(transferRow(transfer, companyId, transfer.getFromBranch(), false, false));
        }

        // FR-11 (TBD-3): a sztornó-pár a Naplókönyv mintájára külön, előjeles sorként jelenik meg.
        if (Boolean.TRUE.equals(transfer.getIsCancelled()) && transfer.getCancellationReason() != null) {
            if (fromInScope) {
                result.add(transferRow(transfer, companyId, transfer.getToBranch(), true, true));
            }
            if (toInScope) {
                result.add(transferRow(transfer, companyId, transfer.getFromBranch(), false, true));
            }
        }
        return result;
    }

    private SortableRow transferRow(Transfer transfer, UUID companyId, Branch partner,
                                    boolean handedOver, boolean storno) {
        BigDecimal amount = transfer.getAmount() != null ? transfer.getAmount() : BigDecimal.ZERO;
        if (storno) {
            amount = amount.negate();
        }
        Branch scopedPartner = tenantScopedPartner(partner, companyId);
        String code = partnerCode(scopedPartner);
        String receiptNumber = transfer.getTransferNumber() != null ? transfer.getTransferNumber() : "";

        CashFlowReportRowDto row = CashFlowReportRowDto.builder()
                .date(transfer.getTransferDate() != null ? transfer.getTransferDate().toString() : null)
                .receiptNumber(storno ? receiptNumber + "-SZ" : receiptNumber)
                .partnerCode(code)
                .partnerCategory(partnerCategory(scopedPartner, code))
                .currency(transfer.getCurrency() != null ? transfer.getCurrency().getCode() : null)
                .receivedAmount(handedOver ? null : amount)
                .handedOverAmount(handedOver ? amount : null)
                .storno(storno)
                .build();

        LocalDateTime eventTime = storno ? transfer.getCancelledAt() : transfer.getCreatedAt();
        return new SortableRow(transfer.getTransferDate(), eventTime, row.getReceiptNumber(), row);
    }

    /**
     * Egy Shipment-bizonylatból képzett sorok — TÉTELENKÉNT (valutánként) egy sor, mert
     * egy szállítmány több valutát is tartalmazhat, a riportnak pedig valuta-oszlopa van (FR-5).
     */
    private List<SortableRow> toShipmentRows(ShipmentRequest shipment, Set<UUID> scope,
                                             Map<UUID, Branch> partnerBranches,
                                             Map<Long, String> currencyCodes) {
        boolean handedOver = "FF".equalsIgnoreCase(shipment.getSerialPrefix());
        UUID ownBranchId = handedOver ? shipment.getFromBranchId() : shipment.getToBranchId();
        if (ownBranchId == null || !scope.contains(ownBranchId)) {
            // A bizonylat a partner-oldalról került be a lekérdezésbe — a mi körzetünk
            // szempontjából ez a másik irány, amit a partner sorában már megjelenítünk.
            return List.of();
        }

        UUID partnerId = handedOver ? shipment.getToBranchId() : shipment.getFromBranchId();
        Branch partner = partnerBranches.get(partnerId);
        String code = partnerCode(partner);
        String category = partnerCategory(partner, code);
        String receiptNumber = shipment.getRequestNumber() != null ? shipment.getRequestNumber() : "";

        // FR-11: a sztornó-ág a shipment oldalon a cancelledAt kitöltöttségén él. A
        // ShipmentRequest-nek nincs isCancelled logikai mezője (a transfer-rel ellentétben):
        // a visszavonás jelölése a status=CANCELLED + cancelledAt pár. A REJECTED (elutasítás)
        // SZÁNDÉKOSAN nem sztornó — az külön folyamat (rejectionReason/rejectedByWorkerId),
        // és nem tölt cancelledAt-ot, tehát ide nem is esik be.
        boolean storno = shipment.getCancelledAt() != null
                && ShipmentRequestStatus.CANCELLED.equals(shipment.getStatus());

        List<SortableRow> result = new ArrayList<>();
        for (ShipmentRequestItem item : shipmentItems(shipment)) {
            BigDecimal amount = shipmentItemAmount(item);
            result.add(shipmentRow(shipment, item, currencyCodes, receiptNumber, code, category,
                    handedOver, amount, false));
            if (storno) {
                // A sztornó-pár a Naplókönyv és a fenti transfer-ág mintájára külön, ELŐJELES
                // sorként jelenik meg — enélkül a visszavont szállítmány az eredeti, pozitív
                // összegével felfelé torzítaná a pénzforgalmi összesítőt.
                result.add(shipmentRow(shipment, item, currencyCodes, receiptNumber, code, category,
                        handedOver, amount.negate(), true));
            }
        }
        return result;
    }

    private SortableRow shipmentRow(ShipmentRequest shipment, ShipmentRequestItem item,
                                    Map<Long, String> currencyCodes, String receiptNumber,
                                    String code, String category, boolean handedOver,
                                    BigDecimal amount, boolean storno) {
        CashFlowReportRowDto row = CashFlowReportRowDto.builder()
                .date(shipment.getRequestDate() != null ? shipment.getRequestDate().toString() : null)
                .receiptNumber(storno ? receiptNumber + "-SZ" : receiptNumber)
                .partnerCode(code)
                .partnerCategory(category)
                .currency(currencyCodes.get(item.getCurrencyId()))
                .receivedAmount(handedOver ? null : amount)
                .handedOverAmount(handedOver ? amount : null)
                .storno(storno)
                .build();
        LocalDateTime eventTime = storno ? shipment.getCancelledAt() : shipment.getCreatedAt();
        return new SortableRow(shipment.getRequestDate(), eventTime, row.getReceiptNumber(), row);
    }

    private static List<ShipmentRequestItem> shipmentItems(ShipmentRequest shipment) {
        return shipment.getItems() != null ? shipment.getItems() : List.of();
    }

    /**
     * A tétel tényleges összege: a LESZÁLLÍTOTT mennyiség a mérvadó, mert a riport a valóban
     * megtörtént pénzmozgást mutatja. Ha még nincs kiszállítva, a jóváhagyott, végül az igényelt
     * összegre esünk vissza — így egy folyamatban lévő szállítmány sem tűnik el a listából.
     */
    private static BigDecimal shipmentItemAmount(ShipmentRequestItem item) {
        if (item.getDeliveredAmount() != null) {
            return item.getDeliveredAmount();
        }
        if (item.getApprovedAmount() != null) {
            return item.getApprovedAmount();
        }
        return item.getRequestedAmount() != null ? item.getRequestedAmount() : BigDecimal.ZERO;
    }

    // ============================ PARTNER (FR-8) ============================

    /**
     * FR-8: Bank / Terület / Pénztár kategorizálás a VAULT_COUNTERPARTY betűkód alapján.
     *
     * <p>A besorolás a partner TÍPUSÁBÓL indul: csak VAULT_COUNTERPARTY fióknál nézzük a
     * betűkódot, minden más (numerikus kódú) fiók Pénztár. Ismeretlen betűkódnál "Egyéb" —
     * fail-closed: inkább látszik ismeretlenként, mint hogy tévesen Bankként összegződjön.</p>
     */
    static String partnerCategory(Branch partner, String code) {
        if (partner == null || code == null) {
            return CATEGORY_OTHER;
        }
        Dictionary type = partner.getBranchType();
        boolean counterparty = type != null && VAULT_COUNTERPARTY_TYPE.equalsIgnoreCase(type.getCode());
        if (!counterparty) {
            return CATEGORY_CASHIER;
        }
        String normalized = code.trim().toUpperCase(java.util.Locale.ROOT);
        if (BANK_PARTNER_CODES.contains(normalized)) {
            return CATEGORY_BANK;
        }
        if (TERRITORY_PARTNER_CODES.contains(normalized)) {
            return CATEGORY_TERRITORY;
        }
        return CATEGORY_OTHER;
    }

    /** A {@code HufDaybookService.partnerCode()} logikájával azonos (FR-8). */
    private static String partnerCode(Branch partner) {
        if (partner == null) {
            return null;
        }
        Dictionary type = partner.getBranchType();
        if (type != null && VAULT_COUNTERPARTY_TYPE.equalsIgnoreCase(type.getCode())) {
            return partner.getCode();
        }
        return numericBranchCode(partner.getCode());
    }

    private static String numericBranchCode(String code) {
        if (code == null || code.isBlank()) {
            return "000";
        }
        String digits = code.replaceAll("[^0-9]", "");
        if (!digits.isEmpty()) {
            try {
                return String.format("%03d", Integer.parseInt(digits) % 1000);
            } catch (NumberFormatException e) {
                // Tul hosszu szamsor — determinisztikus hash-fallback (lenti ag).
            }
        }
        return String.format("%03d", Math.abs(code.hashCode()) % 1000);
    }

    /** Multi-tenant guard: idegen tenant partner-fiókja NEM szivároghat ki (§1). */
    private Branch tenantScopedPartner(Branch partner, UUID companyId) {
        if (partner == null) {
            return null;
        }
        if (partner.getCompany() == null || !companyId.equals(partner.getCompany().getId())) {
            log.warn("FKH-030: a partner-fiok ({}) nem a hivo tenant-hez tartozik — "
                    + "a partner-kod kimarad (VV-TENANT guard)", partner.getId());
            return null;
        }
        return partner;
    }

    /** A shipment-tetelek valuta-kodjainak feloldasa egy lekerdezessel (N+1 elkerulese). */
    private Map<Long, String> loadCurrencyCodes(List<ShipmentRequest> shipments) {
        Set<Long> ids = new HashSet<>();
        for (ShipmentRequest shipment : shipments) {
            for (ShipmentRequestItem item : shipmentItems(shipment)) {
                if (item.getCurrencyId() != null) {
                    ids.add(item.getCurrencyId());
                }
            }
        }
        if (ids.isEmpty()) {
            return Map.of();
        }
        return currencyRepository.findAllById(ids).stream()
                .collect(Collectors.toMap(hu.puzzleir.valuta.entity.Currency::getId,
                        hu.puzzleir.valuta.entity.Currency::getCode, (a, b) -> a));
    }

    private Map<UUID, Branch> loadPartnerBranches(List<Transfer> transfers,
                                                  List<ShipmentRequest> shipments,
                                                  UUID companyId) {
        Set<UUID> ids = new HashSet<>();
        for (ShipmentRequest shipment : shipments) {
            if (shipment.getFromBranchId() != null) {
                ids.add(shipment.getFromBranchId());
            }
            if (shipment.getToBranchId() != null) {
                ids.add(shipment.getToBranchId());
            }
        }
        // A Transfer partnerei JOIN FETCH-csel mar betoltottek — csak a shipment-oldal kell.
        if (ids.isEmpty()) {
            return Map.of();
        }
        return branchRepository.findAllById(ids).stream()
                .filter(b -> b.getCompany() != null && companyId.equals(b.getCompany().getId()))
                .collect(Collectors.toMap(Branch::getId, Function.identity(), (a, b) -> a));
    }
}
