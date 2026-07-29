package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.daybook.HufDaybookDto;
import hu.puzzleir.valuta.dto.daybook.HufDaybookRowDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Dictionary;
import hu.puzzleir.valuta.entity.ShipmentRequest;
import hu.puzzleir.valuta.entity.ShipmentRequestItem;
import hu.puzzleir.valuta.entity.Transfer;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
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
import java.time.format.DateTimeFormatter;
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
 * HUF naplókönyv (FF/UF bizonylatok napi listája).
 *
 * <p>FKH-022 kiegészítés (FR-K6): a napló EGYESÍTETT — a {@code shipment_request} ÉS a
 * {@code transfer} tábla FF-/UF- bizonylatai közös listában, a {@code createdAt} szerinti
 * időrendben (sztornó-sor: {@code cancelledAt}) jelennek meg. Tie-break azonos időbélyegnél:
 * esemény-idő → forrás-tábla ('shipment' &lt; 'transfer') → id (Kósa-direktíva, 2026-07-29) —
 * a backfill-migrációval (V366) azonos szabály.</p>
 *
 * <p>FR-K3: minden sor {@code partnerCode}-ot kap — FF-nél a cél- (toBranch), UF-nél a
 * forrás- (fromBranch) oldal; fizikai pénztárnál numerikus pénztárszám (BR076 → "076"),
 * VAULT_COUNTERPARTY partnernél (PRB, ERB, ...) a betűkód változatlanul.</p>
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
@Slf4j
public class HufDaybookService {

    private static final DateTimeFormatter TS_FORMAT = DateTimeFormatter.ofPattern("HH:mm:ss");

    /** BRANCH_TYPE dictionary-kód a virtuális banki/speciális partnerekhez (V277). */
    private static final String VAULT_COUNTERPARTY_TYPE = "VAULT_COUNTERPARTY";

    private final ShipmentRequestRepository shipmentRequestRepository;
    private final TransferRepository transferRepository;
    private final BranchRepository branchRepository;
    private final AccessScopeService accessScopeService;

    public HufDaybookDto getDaybook(UUID branchId, LocalDate date) {
        Branch branch = requireAccessibleBranch(branchId);
        UUID companyId = SecurityUtils.getCurrentCompanyId();

        LocalDateTime from = date.atStartOfDay();
        LocalDateTime to = date.plusDays(1).atStartOfDay();

        List<ShipmentRequest> shipmentOriginals =
                shipmentRequestRepository.findHufDaybookShipmentsForDate(companyId, branchId, date);
        List<ShipmentRequest> shipmentStornos =
                shipmentRequestRepository.findCancelledHufDaybookShipmentsForDate(companyId, branchId, from, to);
        List<Transfer> transferOriginals =
                transferRepository.findHufDaybookTransfersForDate(companyId, branchId, date);
        List<Transfer> transferStornos =
                transferRepository.findCancelledHufDaybookTransfersForDate(companyId, branchId, from, to);

        // A shipment-partnerek batch-betöltése (a shipment from/to csak UUID-oszlop, nem asszociáció).
        // FR-K12 tenant-guard: a betöltés companyId-szűrt — idegen tenant branch-e fel sem oldódik.
        Map<UUID, Branch> partnerBranches =
                loadShipmentPartnerBranches(shipmentOriginals, shipmentStornos, companyId);

        List<SortableRow> rows = new ArrayList<>();
        for (ShipmentRequest shipment : shipmentOriginals) {
            rows.add(toShipmentOriginalRow(shipment, partnerBranches));
        }
        for (ShipmentRequest shipment : shipmentStornos) {
            rows.add(toShipmentStornoRow(shipment, partnerBranches));
        }
        for (Transfer transfer : transferOriginals) {
            rows.add(toTransferOriginalRow(transfer, companyId));
        }
        for (Transfer transfer : transferStornos) {
            rows.add(toTransferStornoRow(transfer, companyId));
        }

        // FR-K6: közös időrend + rögzített tie-break (esemény-idő, forrás-tábla, id).
        rows.sort(Comparator
                .comparing(SortableRow::eventTime, Comparator.nullsLast(Comparator.naturalOrder()))
                .thenComparing(SortableRow::source)
                .thenComparing(SortableRow::idText));

        List<HufDaybookRowDto> dtoRows = rows.stream().map(SortableRow::row).toList();

        BigDecimal totalAtadas = dtoRows.stream()
                .map(HufDaybookRowDto::getAtadasHuf)
                .filter(v -> v != null)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        BigDecimal totalAtvetel = dtoRows.stream()
                .map(HufDaybookRowDto::getAtvetelHuf)
                .filter(v -> v != null)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        return HufDaybookDto.builder()
                .branchId(branch.getId().toString())
                .branchName(branch.getName())
                .date(date.toString())
                .rows(dtoRows)
                .totalAtadasHuf(totalAtadas)
                .totalAtvetelHuf(totalAtvetel)
                .build();
    }

    private Branch requireAccessibleBranch(UUID branchId) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        Branch branch = branchRepository.findByIdAndCompanyId(branchId, companyId)
                .orElseThrow(() -> new ResourceNotFoundException("Iroda nem található: " + branchId));

        UUID currentBranchId = SecurityUtils.getCurrentBranchIdOrNull();
        if (accessScopeService.vaultRegionBranchScopeOrNull() != null
                && currentBranchId != null
                && !currentBranchId.equals(branchId)) {
            throw new ResourceNotFoundException("Iroda nem található: " + branchId);
        }

        return branch;
    }

    // ============================ SOR-KÉPZÉS ============================

    /** Rendező-kulcsos sor: eventTime (orig: createdAt, sztornó: cancelledAt) + forrás + id. */
    private record SortableRow(LocalDateTime eventTime, String source, String idText, HufDaybookRowDto row) {
    }

    private SortableRow toShipmentOriginalRow(ShipmentRequest shipment, Map<UUID, Branch> partnerBranches) {
        BigDecimal amount = shipmentTotalHuf(shipment);
        boolean atadas = "FF".equalsIgnoreCase(shipment.getSerialPrefix());
        HufDaybookRowDto row = HufDaybookRowDto.builder()
                .annualSequence(shipment.getAnnualJournalSequence())
                .receiptNumber(shipment.getRequestNumber())
                .partnerCode(partnerCode(partnerBranches.get(shipmentPartnerBranchId(shipment))))
                .timestamp(formatDateTime(shipment.getCreatedAt()))
                .atadasHuf(atadas ? amount : null)
                .atvetelHuf(!atadas ? amount : null)
                .storno(false)
                .build();
        return new SortableRow(shipment.getCreatedAt(), "shipment", String.valueOf(shipment.getId()), row);
    }

    private SortableRow toShipmentStornoRow(ShipmentRequest shipment, Map<UUID, Branch> partnerBranches) {
        BigDecimal amount = shipmentTotalHuf(shipment).negate();
        boolean atadas = "FF".equalsIgnoreCase(shipment.getSerialPrefix());
        HufDaybookRowDto row = HufDaybookRowDto.builder()
                // FR-K2/3: a sztornó-sor a SAJÁT sorszámát mutatja, nem az eredetiét.
                .annualSequence(shipment.getStornoJournalSequence())
                .receiptNumber((shipment.getRequestNumber() != null ? shipment.getRequestNumber() : "") + "-SZ")
                .partnerCode(partnerCode(partnerBranches.get(shipmentPartnerBranchId(shipment))))
                .timestamp(formatDateTime(shipment.getCancelledAt()))
                .atadasHuf(atadas ? amount : null)
                .atvetelHuf(!atadas ? amount : null)
                .storno(true)
                .build();
        return new SortableRow(shipment.getCancelledAt(), "shipment", String.valueOf(shipment.getId()), row);
    }

    private SortableRow toTransferOriginalRow(Transfer transfer, UUID companyId) {
        BigDecimal amount = transferHuf(transfer);
        boolean atadas = isAtadasNumber(transfer.getTransferNumber());
        HufDaybookRowDto row = HufDaybookRowDto.builder()
                .annualSequence(transfer.getAnnualJournalSequence())
                .receiptNumber(transfer.getTransferNumber())
                .partnerCode(partnerCode(tenantScopedPartner(transferPartnerBranch(transfer), companyId)))
                // FR-K6/7: a timestamp a createdAt-ból képződik (NEM transferDate/transferTime).
                .timestamp(formatDateTime(transfer.getCreatedAt()))
                .atadasHuf(atadas ? amount : null)
                .atvetelHuf(!atadas ? amount : null)
                .storno(false)
                .build();
        return new SortableRow(transfer.getCreatedAt(), "transfer", String.valueOf(transfer.getId()), row);
    }

    private SortableRow toTransferStornoRow(Transfer transfer, UUID companyId) {
        BigDecimal amount = transferHuf(transfer).negate();
        boolean atadas = isAtadasNumber(transfer.getTransferNumber());
        HufDaybookRowDto row = HufDaybookRowDto.builder()
                .annualSequence(transfer.getStornoJournalSequence())
                .receiptNumber((transfer.getTransferNumber() != null ? transfer.getTransferNumber() : "") + "-SZ")
                .partnerCode(partnerCode(tenantScopedPartner(transferPartnerBranch(transfer), companyId)))
                .timestamp(formatDateTime(transfer.getCancelledAt()))
                .atadasHuf(atadas ? amount : null)
                .atvetelHuf(!atadas ? amount : null)
                .storno(true)
                .build();
        return new SortableRow(transfer.getCancelledAt(), "transfer", String.valueOf(transfer.getId()), row);
    }

    // ============================ PARTNER-AZONOSÍTÓ (FR-K3) ============================

    /** FF: a partner a cél- (toBranch), UF: a forrás- (fromBranch) oldal. */
    private static UUID shipmentPartnerBranchId(ShipmentRequest shipment) {
        return "FF".equalsIgnoreCase(shipment.getSerialPrefix())
                ? shipment.getToBranchId()
                : shipment.getFromBranchId();
    }

    private static Branch transferPartnerBranch(Transfer transfer) {
        return isAtadasNumber(transfer.getTransferNumber())
                ? transfer.getToBranch()
                : transfer.getFromBranch();
    }

    private Map<UUID, Branch> loadShipmentPartnerBranches(List<ShipmentRequest> originals,
                                                          List<ShipmentRequest> stornos,
                                                          UUID companyId) {
        Set<UUID> partnerIds = new HashSet<>();
        for (ShipmentRequest shipment : originals) {
            partnerIds.add(shipmentPartnerBranchId(shipment));
        }
        for (ShipmentRequest shipment : stornos) {
            partnerIds.add(shipmentPartnerBranchId(shipment));
        }
        partnerIds.remove(null);
        if (partnerIds.isEmpty()) {
            return Map.of();
        }
        // FR-K12 tenant-guard: cég-szűrt batch-betöltés — idegen tenant branch-rekordja
        // korrupt/legacy referencia esetén sem kerülhet a feloldási térképbe.
        Map<UUID, Branch> found = branchRepository.findByIdInAndCompanyId(partnerIds, companyId).stream()
                .collect(Collectors.toMap(Branch::getId, Function.identity()));
        if (found.size() < partnerIds.size()) {
            log.warn("HUF naplókönyv: {} partner-fiók nem oldható fel a hívó tenant-en belül "
                            + "(idegen tenant-ű vagy törölt branch-referencia) — a partner-kód "
                            + "ezeknél kimarad (VV-TENANT guard)",
                    partnerIds.size() - found.size());
        }
        return found;
    }

    /**
     * FR-K12 tenant-guard (defenzív ág): ha a transfer partner-branch-e nem a hívó
     * tenant-hez tartozik (korrupt/legacy cross-tenant referencia), a partner nem
     * oldódik fel — a sor a naplóban marad, de idegen branch-adat nem kerül a DTO-ba.
     */
    private static Branch tenantScopedPartner(Branch partner, UUID companyId) {
        if (partner == null) {
            return null;
        }
        if (partner.getCompany() == null || !companyId.equals(partner.getCompany().getId())) {
            log.warn("HUF naplókönyv: a transfer partner-fiók ({}) nem a hívó tenant-hez "
                    + "tartozik — a partner-kód kimarad (VV-TENANT guard)", partner.getId());
            return null;
        }
        return partner;
    }

    /**
     * FR-K3 típus-elágazás: VAULT_COUNTERPARTY partnernél a betűkód VÁLTOZATLANUL
     * (PRB, ERB, ...), különben numerikus pénztárszám a Branch.code-ból (BR076 → "076";
     * a ReceiptSequenceService legacy pénztárszám-mintája szerint, hash-fallbackkel).
     */
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
                // Túl hosszú számsor — determinisztikus hash-fallback (lenti ág).
            }
        }
        return String.format("%03d", Math.abs(code.hashCode()) % 1000);
    }

    // ============================ ÖSSZEG / FORMÁZÁS ============================

    /** Az FF/UF prefix az irányt kódolja: FF = átadás, UF = átvétel (bizonylatszám-alapú). */
    private static boolean isAtadasNumber(String documentNumber) {
        return documentNumber != null && documentNumber.toUpperCase().startsWith("FF-");
    }

    private static BigDecimal shipmentTotalHuf(ShipmentRequest shipment) {
        if (shipment.getItems() == null) {
            return BigDecimal.ZERO;
        }
        return shipment.getItems().stream()
                .map(ShipmentRequestItem::getHufValue)
                .filter(v -> v != null)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
    }

    private static BigDecimal transferHuf(Transfer transfer) {
        if (transfer.getHufValue() != null) {
            return transfer.getHufValue();
        }
        return transfer.getAmount() != null ? transfer.getAmount() : BigDecimal.ZERO;
    }

    private static String formatDateTime(LocalDateTime value) {
        return value != null ? value.format(TS_FORMAT) : "";
    }
}
