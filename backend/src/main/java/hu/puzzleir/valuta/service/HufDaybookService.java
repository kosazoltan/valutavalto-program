package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.daybook.HufDaybookDto;
import hu.puzzleir.valuta.dto.daybook.HufDaybookRowDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.ShipmentRequest;
import hu.puzzleir.valuta.entity.ShipmentRequestItem;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.ShipmentRequestRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class HufDaybookService {

    private static final DateTimeFormatter TS_FORMAT = DateTimeFormatter.ofPattern("HH:mm:ss");

    private final ShipmentRequestRepository shipmentRequestRepository;
    private final BranchRepository branchRepository;
    private final AccessScopeService accessScopeService;

    public HufDaybookDto getDaybook(UUID branchId, LocalDate date) {
        Branch branch = requireAccessibleBranch(branchId);
        UUID companyId = SecurityUtils.getCurrentCompanyId();

        List<HufDaybookRowDto> rows = new ArrayList<>();
        List<ShipmentRequest> originals =
                shipmentRequestRepository.findHufDaybookShipmentsForDate(companyId, branchId, date);
        for (ShipmentRequest shipment : originals) {
            rows.add(toOriginalRow(shipment));
        }

        LocalDateTime from = date.atStartOfDay();
        LocalDateTime to = date.plusDays(1).atStartOfDay();
        List<ShipmentRequest> stornoShipments =
                shipmentRequestRepository.findCancelledHufDaybookShipmentsForDate(companyId, branchId, from, to);
        for (ShipmentRequest shipment : stornoShipments) {
            rows.add(toStornoRow(shipment));
        }

        rows.sort(Comparator.comparing(HufDaybookRowDto::getTimestamp, Comparator.nullsLast(String::compareTo))
                .thenComparing(HufDaybookRowDto::getReceiptNumber, Comparator.nullsLast(String::compareTo)));

        BigDecimal totalAtadas = rows.stream()
                .map(HufDaybookRowDto::getAtadasHuf)
                .filter(v -> v != null)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        BigDecimal totalAtvetel = rows.stream()
                .map(HufDaybookRowDto::getAtvetelHuf)
                .filter(v -> v != null)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        return HufDaybookDto.builder()
                .branchId(branch.getId().toString())
                .branchName(branch.getName())
                .date(date.toString())
                .rows(rows)
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

    private HufDaybookRowDto toOriginalRow(ShipmentRequest shipment) {
        BigDecimal amount = shipmentTotalHuf(shipment);
        return HufDaybookRowDto.builder()
                .annualSequence(shipment.getAnnualJournalSequence())
                .receiptNumber(shipment.getRequestNumber())
                .timestamp(formatDateTime(shipment.getCreatedAt()))
                .atadasHuf("FF".equalsIgnoreCase(shipment.getSerialPrefix()) ? amount : null)
                .atvetelHuf("UF".equalsIgnoreCase(shipment.getSerialPrefix()) ? amount : null)
                .storno(false)
                .build();
    }

    private HufDaybookRowDto toStornoRow(ShipmentRequest shipment) {
        BigDecimal amount = shipmentTotalHuf(shipment).negate();
        return HufDaybookRowDto.builder()
                .annualSequence(shipment.getAnnualJournalSequence())
                .receiptNumber((shipment.getRequestNumber() != null ? shipment.getRequestNumber() : "") + "-SZ")
                .timestamp(formatDateTime(shipment.getCancelledAt()))
                .atadasHuf("FF".equalsIgnoreCase(shipment.getSerialPrefix()) ? amount : null)
                .atvetelHuf("UF".equalsIgnoreCase(shipment.getSerialPrefix()) ? amount : null)
                .storno(true)
                .build();
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

    private static String formatDateTime(LocalDateTime value) {
        return value != null ? value.format(TS_FORMAT) : "";
    }
}
