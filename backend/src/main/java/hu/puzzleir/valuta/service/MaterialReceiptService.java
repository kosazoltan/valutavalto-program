package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.ertektar.MaterialReceiptLineDto;
import hu.puzzleir.valuta.dto.ertektar.MaterialReceiptRequestDto;
import hu.puzzleir.valuta.dto.ertektar.MaterialReceiptResponseDto;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CurrencyStockRepository;
import hu.puzzleir.valuta.repository.MaterialReceiptRepository;
import hu.puzzleir.valuta.repository.VaultTerritoryRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Anyag bevételi / kiadási bizonylat — legacy MATBIZONYLAT megfelelő.
 *
 * B (bevétel): készlet növelés — pl. bankból érkező szállítmány nyilvántartása.
 * K (kiadás): készlet csökkentés — pl. bankba történő visszaszállítás dokumentálása.
 *
 * Workflow: DRAFT → FINALIZED
 * A FINALIZED állapotba lépéskor hajtjuk végre a készletmozgást.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class MaterialReceiptService {

    private static final DateTimeFormatter NUM_FORMAT = DateTimeFormatter.ofPattern("yyyyMMdd");

    private final MaterialReceiptRepository materialReceiptRepository;
    private final CurrencyStockRepository currencyStockRepository;
    private final VaultTerritoryRepository vaultTerritoryRepository;
    private final BranchRepository branchRepository;

    @Transactional(readOnly = true)
    public List<MaterialReceiptResponseDto> getReceipts() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return materialReceiptRepository.findByCompanyIdOrderByCreatedAtDesc(companyId)
                .stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<MaterialReceiptResponseDto> getReceiptsByType(String type) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return materialReceiptRepository.findByCompanyIdAndReceiptTypeOrderByCreatedAtDesc(companyId, type)
                .stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    /**
     * Bizonylat létrehozása DRAFT állapotban.
     */
    @Transactional(rollbackFor = Exception.class)
    public MaterialReceiptResponseDto createReceipt(MaterialReceiptRequestDto request) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        Long workerId = SecurityUtils.getCurrentWorkerId();

        Long seq = materialReceiptRepository.getNextReceiptNumber();
        String receiptNumber = (request.getReceiptType().equals("B") ? "BEV-" : "KIA-")
                + LocalDateTime.now().format(NUM_FORMAT) + "-" + String.format("%04d", seq);

        VaultTerritory territory = null;
        if (request.getVaultTerritoryId() != null) {
            territory = vaultTerritoryRepository.findById(request.getVaultTerritoryId())
                    .orElseThrow(() -> new ResourceNotFoundException(
                            "Értéktári terület nem található: " + request.getVaultTerritoryId()));
        }

        MaterialReceipt receipt = MaterialReceipt.builder()
                .companyId(companyId)
                .receiptNumber(receiptNumber)
                .receiptType(request.getReceiptType())
                .vaultTerritory(territory)
                .branchCode(request.getBranchCode())
                .counterpartName(request.getCounterpartName())
                .note(request.getNote())
                .status("DRAFT")
                .createdAt(LocalDateTime.now())
                .createdBy(workerId)
                .build();

        for (MaterialReceiptLineDto lineDto : request.getLines()) {
            MaterialReceiptLine line = MaterialReceiptLine.builder()
                    .receipt(receipt)
                    .currencyCode(lineDto.getCurrencyCode())
                    .amount(lineDto.getAmount())
                    .exchangeRate(lineDto.getExchangeRate())
                    .hufEquivalent(lineDto.getHufEquivalent())
                    .build();
            receipt.getLines().add(line);
        }

        MaterialReceipt saved = materialReceiptRepository.save(receipt);
        log.info("Bizonylat létrehozva: {} ({} tétel), company={}",
                receiptNumber, request.getLines().size(), companyId);

        return toDto(saved);
    }

    /**
     * Bizonylat véglegesítése — készletmozgás végrehajtása.
     * B (bevétel): készlet nő a bizonylat tételsorai szerint.
     * K (kiadás): készlet csökken.
     */
    @Transactional(rollbackFor = Exception.class)
    public MaterialReceiptResponseDto finalizeReceipt(Long id) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        MaterialReceipt receipt = materialReceiptRepository.findById(id)
                .filter(r -> r.getCompanyId().equals(companyId))
                .orElseThrow(() -> new ResourceNotFoundException("Bizonylat nem található: " + id));

        if (!"DRAFT".equals(receipt.getStatus())) {
            throw new IllegalStateException("Csak DRAFT állapotú bizonylat véglegesíthető!");
        }

        // Cél entitás meghatározása
        String entityType;
        String entityId;
        if (receipt.getVaultTerritory() != null) {
            entityType = "VAULT";
            entityId = receipt.getVaultTerritory().getId().toString();
        } else if (receipt.getBranchCode() != null) {
            entityType = "CASHIER";
            // FKH-029 FR-4: az entity_id a branch UUID-ja, NEM a fiókkód. Minden olvasó
            // (DailyBalanceService:222, MonthlyClosingService:119,
            // CurrencyStockRepository.findByBranchIdAndCurrencyCode / findAllByBranchIds)
            // UUID-val keres — a korábbi branchCode-os írás olvashatatlan árva sort hozott
            // volna létre. Fail-closed: ismeretlen fiókkódra nem írunk sort.
            entityId = branchRepository.findByCompanyIdAndCode(companyId, receipt.getBranchCode())
                    .orElseThrow(() -> new ResourceNotFoundException(
                            "Iroda nem található a bizonylat véglegesítéséhez: " + receipt.getBranchCode()))
                    .getId().toString();
        } else {
            // Alapértelmezett: első aktív terület
            VaultTerritory territory = vaultTerritoryRepository.findByCompanyIdAndActiveTrue(companyId)
                    .stream().findFirst()
                    .orElseThrow(() -> new ResourceNotFoundException("Nincs aktív értéktári terület!"));
            entityType = "VAULT";
            entityId = territory.getId().toString();
        }

        boolean isBevétel = "B".equals(receipt.getReceiptType());

        for (MaterialReceiptLine line : receipt.getLines()) {
            if (isBevétel) {
                CurrencyStock stock = getOrCreateStock(companyId, entityType, entityId, line.getCurrencyCode());
                // Bevétel: készlet nő
                BigDecimal costPerUnit = line.getExchangeRate() != null
                        ? line.getExchangeRate()
                        : stock.getWeightedAvgCost(); // ha nincs árfolyam, régi WAC-ot használjuk
                if (costPerUnit.compareTo(BigDecimal.ZERO) == 0) {
                    costPerUnit = BigDecimal.ONE; // fallback
                }
                stock.receiveStock(line.getAmount(), costPerUnit);
            } else {
                // Kiadás: készlet csökken; FK-054 business pre-gate az entity invariáns előtt.
                CurrencyStock stock = currencyStockRepository
                        .findForUpdate(companyId, entityType, entityId, line.getCurrencyCode())
                        .orElseThrow(() -> VaultStockCoverageGate.insufficientStockException(
                                entityType, entityId, line.getCurrencyCode(), BigDecimal.ZERO, line.getAmount()));
                VaultStockCoverageGate.requireSufficientStock(
                        entityType, entityId, line.getCurrencyCode(), stock.getQuantity(), line.getAmount());
                stock.issueStock(line.getAmount());
            }
        }

        receipt.setStatus("FINALIZED");
        receipt.setFinalizedAt(LocalDateTime.now());

        log.info("Bizonylat véglegesítve: {} ({}), {} tétel, entity={}/{}",
                receipt.getReceiptNumber(), receipt.getReceiptType(),
                receipt.getLines().size(), entityType, entityId);

        return toDto(materialReceiptRepository.save(receipt));
    }

    private CurrencyStock getOrCreateStock(UUID companyId, String entityType, String entityId, String currencyCode) {
        return currencyStockRepository.findForUpdate(companyId, entityType, entityId, currencyCode)
                .orElseGet(() -> {
                    CurrencyStock stock = CurrencyStock.builder()
                            .company(Company.builder().id(companyId).build())
                            .entityType(entityType)
                            .entityId(entityId)
                            .currencyCode(currencyCode)
                            .quantity(BigDecimal.ZERO)
                            .weightedAvgCost(BigDecimal.ZERO)
                            .lastUpdated(LocalDateTime.now())
                            .build();
                    return currencyStockRepository.save(stock);
                });
    }

    private MaterialReceiptResponseDto toDto(MaterialReceipt entity) {
        List<MaterialReceiptLineDto> lineDtos = entity.getLines().stream()
                .map(line -> MaterialReceiptLineDto.builder()
                        .currencyCode(line.getCurrencyCode())
                        .amount(line.getAmount())
                        .exchangeRate(line.getExchangeRate())
                        .hufEquivalent(line.getHufEquivalent())
                        .build())
                .collect(Collectors.toList());

        return MaterialReceiptResponseDto.builder()
                .id(entity.getId())
                .receiptNumber(entity.getReceiptNumber())
                .receiptType(entity.getReceiptType())
                .vaultTerritoryId(entity.getVaultTerritory() != null ? entity.getVaultTerritory().getId() : null)
                .vaultTerritoryName(entity.getVaultTerritory() != null ? entity.getVaultTerritory().getName() : null)
                .branchCode(entity.getBranchCode())
                .counterpartName(entity.getCounterpartName())
                .note(entity.getNote())
                .status(entity.getStatus())
                .createdAt(entity.getCreatedAt())
                .finalizedAt(entity.getFinalizedAt())
                .lines(lineDtos)
                .build();
    }
}
