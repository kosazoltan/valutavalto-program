package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.ertektar.VaultTransferRequestDto;
import hu.puzzleir.valuta.dto.ertektar.VaultTransferResponseDto;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.CurrencyStockRepository;
import hu.puzzleir.valuta.repository.VaultTerritoryRepository;
import hu.puzzleir.valuta.repository.VaultTransferRepository;
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
 * Értéktárközi / irodaközi áttétel — legacy ATADVET megfelelő.
 *
 * Workflow:
 * 1. REQUESTED — kérelem létrehozva
 * 2. IN_PROGRESS — szupervisor jóváhagyta (ha szükséges), szállítás alatt
 * 3. COMPLETED — átvevő fél átvette
 * 4. REJECTED — elutasítva
 *
 * WAC kezelés: kiadáskor az aktuális WAC-on adjuk ki,
 * átvételkor az átvevő WAC-ja frissül az átadó WAC-jával.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class VaultTransferService {

    private static final DateTimeFormatter NUM_FORMAT = DateTimeFormatter.ofPattern("yyyyMMdd");
    private static final BigDecimal SUPERVISOR_THRESHOLD = new BigDecimal("5000000"); // 5M HUF felett szupervisor kell

    private final VaultTransferRepository vaultTransferRepository;
    private final CurrencyStockRepository currencyStockRepository;
    private final VaultTerritoryRepository vaultTerritoryRepository;
    private final VaultStockFlowService vaultStockFlowService;  // v2.2.2 hotfix

    @Transactional(readOnly = true)
    public List<VaultTransferResponseDto> getTransfers() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return vaultTransferRepository.findByCompanyIdOrderByCreatedAtDesc(companyId)
                .stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<VaultTransferResponseDto> getPendingTransfers() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return vaultTransferRepository.findByCompanyIdAndStatusOrderByCreatedAtDesc(companyId, VaultOperationStatus.REQUESTED)
                .stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    /**
     * Áttétel kérelem létrehozása.
     * A forrás készletét még NEM vonjuk le — csak COMPLETED állapotban.
     */
    @Transactional(rollbackFor = Exception.class)
    public VaultTransferResponseDto createTransfer(VaultTransferRequestDto request) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        Long workerId = SecurityUtils.getCurrentWorkerId();

        // Irány validáció: forrás ÉS cél oldal kötelező (vault_id VAGY branch_code)
        boolean hasSource = request.getSourceVaultId() != null || (request.getSourceBranchCode() != null && !request.getSourceBranchCode().isBlank());
        boolean hasTarget = request.getTargetVaultId() != null || (request.getTargetBranchCode() != null && !request.getTargetBranchCode().isBlank());
        if (!hasSource || !hasTarget) {
            throw new hu.puzzleir.valuta.exception.ValidationException(
                "Forrás és cél megadása kötelező (sourceVaultId/sourceBranchCode ÉS targetVaultId/targetBranchCode)");
        }

        // Sorszám generálás
        Long seq = vaultTransferRepository.getNextTransferNumber();
        String transferNumber = "VT-" + LocalDateTime.now().format(NUM_FORMAT) + "-" + String.format("%04d", seq);

        VaultTerritory sourceVault = null;
        VaultTerritory targetVault = null;
        if (request.getSourceVaultId() != null) {
            sourceVault = vaultTerritoryRepository.findById(request.getSourceVaultId())
                    .orElseThrow(() -> new ResourceNotFoundException("Forrás értéktár nem található: " + request.getSourceVaultId()));
        }
        if (request.getTargetVaultId() != null) {
            targetVault = vaultTerritoryRepository.findById(request.getTargetVaultId())
                    .orElseThrow(() -> new ResourceNotFoundException("Cél értéktár nem található: " + request.getTargetVaultId()));
        }

        // Szupervisor szükséges-e? (legacy: nagy összeg felett igen)
        boolean needsSupervisor = request.getAmount().compareTo(SUPERVISOR_THRESHOLD) > 0;

        VaultTransfer transfer = VaultTransfer.builder()
                .companyId(companyId)
                .transferNumber(transferNumber)
                .sourceVault(sourceVault)
                .targetVault(targetVault)
                .sourceBranchCode(request.getSourceBranchCode())
                .targetBranchCode(request.getTargetBranchCode())
                .currencyCode(request.getCurrencyCode())
                .amount(request.getAmount())
                .status(VaultOperationStatus.REQUESTED)
                .requiresSupervisor(needsSupervisor)
                .note(request.getNote())
                .createdAt(LocalDateTime.now())
                .createdBy(workerId)
                .build();

        VaultTransfer saved = vaultTransferRepository.save(transfer);
        log.info("Áttétel létrehozva: {} - {} {} (szupervisor: {}), company={}",
                transferNumber, request.getAmount(), request.getCurrencyCode(), needsSupervisor, companyId);

        return toDto(saved);
    }

    /**
     * Szupervisor jóváhagyás (nagy összegű áttételeknél).
     * Legacy SUPER modul — jelszóval történt, modern rendszerben RBAC.
     */
    @Transactional(rollbackFor = Exception.class)
    public VaultTransferResponseDto supervisorApprove(Long id) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        Long workerId = SecurityUtils.getCurrentWorkerId();

        VaultTransfer transfer = findTransfer(companyId, id);
        if (transfer.getStatus() != VaultOperationStatus.REQUESTED) {
            throw new IllegalStateException("Csak REQUESTED státuszú áttétel hagyható jóvá!");
        }

        transfer.setSupervisorApprovedBy(workerId);
        transfer.setSupervisorApprovedAt(LocalDateTime.now());
        transfer.setStatus(VaultOperationStatus.IN_PROGRESS);

        log.info("Áttétel szupervisor jóváhagyva: {} (worker={})", transfer.getTransferNumber(), workerId);
        return toDto(vaultTransferRepository.save(transfer));
    }

    /**
     * Áttétel végrehajtása / átvétele.
     * WAC kezelés: forrásból kivesszük az aktuális WAC-on, célba betesszük ugyanazon a WAC-on.
     */
    @Transactional(rollbackFor = Exception.class)
    public VaultTransferResponseDto completeTransfer(Long id) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        Long workerId = SecurityUtils.getCurrentWorkerId();

        VaultTransfer transfer = findTransfer(companyId, id);

        // Szupervisor ellenőrzés
        if (transfer.getRequiresSupervisor() && transfer.getSupervisorApprovedBy() == null) {
            throw new IllegalStateException("Szupervisor jóváhagyás szükséges az áttétel végrehajtásához!");
        }
        if (transfer.getStatus() != VaultOperationStatus.REQUESTED
                && transfer.getStatus() != VaultOperationStatus.IN_PROGRESS) {
            throw new IllegalStateException("Csak REQUESTED vagy IN_PROGRESS státuszú áttétel hajtható végre!");
        }

        // === KÉSZLETMOZGÁS ===
        // Forrás: entity_type + entity_id meghatározása
        String sourceType;
        String sourceId;
        if (transfer.getSourceVault() != null) {
            sourceType = "VAULT";
            sourceId = transfer.getSourceVault().getId().toString();
        } else {
            sourceType = "CASHIER";
            sourceId = transfer.getSourceBranchCode();
        }

        String targetType;
        String targetId;
        if (transfer.getTargetVault() != null) {
            targetType = "VAULT";
            targetId = transfer.getTargetVault().getId().toString();
        } else {
            targetType = "CASHIER";
            targetId = transfer.getTargetBranchCode();
        }

        // v2.2.2 hotfix: branch -> branch eseten a CashBalance-t hasznaljuk (nem CurrencyStock-ot),
        // mert a penztar szintjen a CashBalance a hivatalos nyilvantartas,
        // nem a WAC-alapu CurrencyStock. A VAULT resztveszos atteteleknel
        // marad az eredeti WAC logika.
        boolean isBranchToBranch = "CASHIER".equals(sourceType) && "CASHIER".equals(targetType);

        if (isBranchToBranch) {
            // CashBalance alapu transfer (nem WAC)
            vaultStockFlowService.applyTransfer(
                    companyId,
                    transfer.getSourceBranchCode(),
                    transfer.getTargetBranchCode(),
                    transfer.getCurrencyCode(),
                    transfer.getAmount()
            );
            // WAC tracking nem ertelmes branch-branch-en, 0-ra allitjuk
            transfer.setWacAtTransfer(BigDecimal.ZERO);
        } else {
            // Eredeti VAULT-CASHIER / VAULT-VAULT logika (CurrencyStock + WAC)
            CurrencyStock sourceStock = currencyStockRepository.findForUpdate(
                    companyId, sourceType, sourceId, transfer.getCurrencyCode())
                    .orElseThrow(() -> new IllegalStateException(
                            "Forrás készlet nem található: " + sourceType + "/" + sourceId + "/" + transfer.getCurrencyCode()));

            BigDecimal wacAtIssue = sourceStock.issueStock(transfer.getAmount());
            transfer.setWacAtTransfer(wacAtIssue);

            CurrencyStock targetStock = getOrCreateStock(companyId, targetType, targetId, transfer.getCurrencyCode());
            targetStock.receiveStock(transfer.getAmount(), wacAtIssue);
        }

        // Státusz frissítés
        transfer.setStatus(VaultOperationStatus.COMPLETED);
        transfer.setCompletedAt(LocalDateTime.now());
        transfer.setReceivedBy(workerId);
        transfer.setReceivedAt(LocalDateTime.now());

        log.info("Áttétel végrehajtva: {} - {} {} (WAC: {}), {} → {}",
                transfer.getTransferNumber(), transfer.getAmount(), transfer.getCurrencyCode(),
                transfer.getWacAtTransfer(), sourceType + "/" + sourceId, targetType + "/" + targetId);

        return toDto(vaultTransferRepository.save(transfer));
    }

    @Transactional(rollbackFor = Exception.class)
    public VaultTransferResponseDto rejectTransfer(Long id) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        VaultTransfer transfer = findTransfer(companyId, id);

        if (transfer.getStatus() == VaultOperationStatus.COMPLETED) {
            throw new IllegalStateException("Végrehajtott áttétel nem utasítható el!");
        }

        transfer.setStatus(VaultOperationStatus.REJECTED);
        log.info("Áttétel elutasítva: {}", transfer.getTransferNumber());
        return toDto(vaultTransferRepository.save(transfer));
    }

    private VaultTransfer findTransfer(UUID companyId, Long id) {
        return vaultTransferRepository.findById(id)
                .filter(t -> t.getCompanyId().equals(companyId))
                .orElseThrow(() -> new ResourceNotFoundException("Áttétel nem található: " + id));
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

    private VaultTransferResponseDto toDto(VaultTransfer entity) {
        return VaultTransferResponseDto.builder()
                .id(entity.getId())
                .transferNumber(entity.getTransferNumber())
                .sourceVaultId(entity.getSourceVault() != null ? entity.getSourceVault().getId() : null)
                .sourceVaultName(entity.getSourceVault() != null ? entity.getSourceVault().getName() : null)
                .targetVaultId(entity.getTargetVault() != null ? entity.getTargetVault().getId() : null)
                .targetVaultName(entity.getTargetVault() != null ? entity.getTargetVault().getName() : null)
                .sourceBranchCode(entity.getSourceBranchCode())
                .targetBranchCode(entity.getTargetBranchCode())
                .currencyCode(entity.getCurrencyCode())
                .amount(entity.getAmount())
                .wacAtTransfer(entity.getWacAtTransfer())
                .status(entity.getStatus().name())
                .requiresSupervisor(entity.getRequiresSupervisor())
                .note(entity.getNote())
                .createdAt(entity.getCreatedAt())
                .completedAt(entity.getCompletedAt())
                .receivedAt(entity.getReceivedAt())
                .build();
    }
}
