package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.ertektar.BankTransactionRequestDto;
import hu.puzzleir.valuta.dto.ertektar.BankTransactionResponseDto;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.CurrencyStockRepository;
import hu.puzzleir.valuta.repository.VaultBankTransactionRepository;
import hu.puzzleir.valuta.repository.VaultTerritoryRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Banki valuta vétel/eladás — legacy MATPTAR megfelelő.
 *
 * BUY: bankból valutát vásárolunk → értéktár valutakészlet nő, HUF készlet csökken.
 * SELL: banknak valutát eladunk → értéktár valutakészlet csökken, HUF készlet nő.
 *
 * WAC frissítés: BUY-nál a bekerülési ár az árfolyam,
 * SELL-nél a WAC nem változik (kiadás).
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class VaultBankTransactionService {

    private final VaultBankTransactionRepository bankTransactionRepository;
    private final CurrencyStockRepository currencyStockRepository;
    private final VaultTerritoryRepository vaultTerritoryRepository;

    @Transactional(readOnly = true)
    public List<BankTransactionResponseDto> getBankTransactions() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return bankTransactionRepository.findByCompanyIdOrderByCreatedAtDesc(companyId)
                .stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<BankTransactionResponseDto> getBankTransactionsByType(String type) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return bankTransactionRepository.findByCompanyIdAndTransactionTypeOrderByCreatedAtDesc(companyId, type)
                .stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    /**
     * Banki tranzakció létrehozása és azonnali végrehajtása.
     * Legacy MATPTAR: egylépéses végrehajtás.
     */
    @Transactional(rollbackFor = Exception.class)
    public BankTransactionResponseDto createBankTransaction(BankTransactionRequestDto request) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        Long workerId = SecurityUtils.getCurrentWorkerId();

        // HUF ellenérték kiszámítása
        BigDecimal hufAmount = request.getAmount()
                .multiply(request.getExchangeRate())
                .setScale(2, RoundingMode.HALF_UP);

        VaultTerritory territory = null;
        String entityId;
        if (request.getVaultTerritoryId() != null) {
            territory = vaultTerritoryRepository.findByIdAndCompanyId(request.getVaultTerritoryId(), companyId)
                    .orElseThrow(() -> new ResourceNotFoundException(
                            "Értéktári terület nem található: " + request.getVaultTerritoryId()));
            entityId = territory.getId().toString();
        } else {
            // Alapértelmezett: az első aktív terület
            territory = vaultTerritoryRepository.findByCompanyIdAndActiveTrue(companyId)
                    .stream().findFirst()
                    .orElseThrow(() -> new ResourceNotFoundException("Nincs aktív értéktári terület!"));
            entityId = territory.getId().toString();
        }

        VaultBankTransaction tx = VaultBankTransaction.builder()
                .companyId(companyId)
                .vaultTerritory(territory)
                .transactionType(request.getTransactionType())
                .currencyCode(request.getCurrencyCode())
                .amount(request.getAmount())
                .exchangeRate(request.getExchangeRate())
                .hufAmount(hufAmount)
                .bankName(request.getBankName())
                .bankReference(request.getBankReference())
                .status(VaultOperationStatus.COMPLETED)
                .note(request.getNote())
                .createdAt(LocalDateTime.now())
                .completedAt(LocalDateTime.now())
                .createdBy(workerId)
                .approvedBy(workerId)
                .build();

        // === KÉSZLETMOZGÁS ===
        if ("BUY".equals(request.getTransactionType())) {
            // Bankból valutát veszünk → valutakészlet nő, HUF csökken
            CurrencyStock hufStock = currencyStockRepository.findForUpdate(companyId, "VAULT", entityId, "HUF")
                    .orElseThrow(() -> VaultStockCoverageGate.insufficientStockException(
                            "VAULT", entityId, "HUF", BigDecimal.ZERO, hufAmount));
            VaultStockCoverageGate.requireSufficientStock("VAULT", entityId, "HUF", hufStock.getQuantity(), hufAmount);

            CurrencyStock foreignStock = getOrCreateStock(companyId, "VAULT", entityId, request.getCurrencyCode());
            foreignStock.receiveStock(request.getAmount(), request.getExchangeRate());
            hufStock.issueStock(hufAmount);

            log.info("Banki vétel: {} {} @ {} = {} HUF, vault={}",
                    request.getAmount(), request.getCurrencyCode(), request.getExchangeRate(), hufAmount, entityId);

        } else if ("SELL".equals(request.getTransactionType())) {
            // Banknak valutát eladunk → valutakészlet csökken, HUF nő
            CurrencyStock foreignStock = currencyStockRepository
                    .findForUpdate(companyId, "VAULT", entityId, request.getCurrencyCode())
                    .orElseThrow(() -> VaultStockCoverageGate.insufficientStockException(
                            "VAULT", entityId, request.getCurrencyCode(), BigDecimal.ZERO, request.getAmount()));
            VaultStockCoverageGate.requireSufficientStock(
                    "VAULT", entityId, request.getCurrencyCode(), foreignStock.getQuantity(), request.getAmount());
            foreignStock.issueStock(request.getAmount());

            CurrencyStock hufStock = getOrCreateStock(companyId, "VAULT", entityId, "HUF");
            hufStock.receiveStock(hufAmount, BigDecimal.ONE); // HUF WAC mindig 1

            log.info("Banki eladás: {} {} @ {} = {} HUF, vault={}",
                    request.getAmount(), request.getCurrencyCode(), request.getExchangeRate(), hufAmount, entityId);
        }

        VaultBankTransaction saved = bankTransactionRepository.save(tx);
        return toDto(saved);
    }

    @Transactional(rollbackFor = Exception.class)
    public BankTransactionResponseDto updateStatus(Long id, VaultOperationStatus newStatus) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        VaultBankTransaction tx = bankTransactionRepository.findById(id)
                .filter(t -> t.getCompanyId().equals(companyId))
                .orElseThrow(() -> new ResourceNotFoundException("Banki tranzakció nem található: " + id));

        tx.setStatus(newStatus);
        if (newStatus == VaultOperationStatus.COMPLETED) {
            tx.setCompletedAt(LocalDateTime.now());
            tx.setApprovedBy(SecurityUtils.getCurrentWorkerId());
        }

        return toDto(bankTransactionRepository.save(tx));
    }

    /**
     * Deviza oldali megerositese — a bankunktol beerkezett a deviza.
     * Ha a HUF oldal is megerositve van, a tranzakcio COMPLETED lesz.
     */
    @Transactional(rollbackFor = Exception.class)
    public BankTransactionResponseDto confirmReceived(Long id) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        Long workerId = SecurityUtils.getCurrentWorkerId();
        VaultBankTransaction tx = bankTransactionRepository.findById(id)
                .filter(t -> t.getCompanyId().equals(companyId))
                .orElseThrow(() -> new ResourceNotFoundException("Banki tranzakcio nem talalhato: " + id));

        tx.setReceivedAt(LocalDateTime.now());
        tx.setReceivedBy(workerId);
        maybeCompleteIfBothSidesDone(tx);
        return toDto(bankTransactionRepository.save(tx));
    }

    /**
     * HUF oldali megerositese — atutaltuk a banknak a HUF-ot.
     * Ha a deviza oldal is megerositve van, a tranzakcio COMPLETED lesz.
     */
    @Transactional(rollbackFor = Exception.class)
    public BankTransactionResponseDto confirmPaid(Long id) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        Long workerId = SecurityUtils.getCurrentWorkerId();
        VaultBankTransaction tx = bankTransactionRepository.findById(id)
                .filter(t -> t.getCompanyId().equals(companyId))
                .orElseThrow(() -> new ResourceNotFoundException("Banki tranzakcio nem talalhato: " + id));

        tx.setPaidAt(LocalDateTime.now());
        tx.setPaidBy(workerId);
        maybeCompleteIfBothSidesDone(tx);
        return toDto(bankTransactionRepository.save(tx));
    }

    /**
     * Ha mindket oldal (deviza + HUF) megerositve van, a tranzakcio COMPLETED-re megy.
     */
    private void maybeCompleteIfBothSidesDone(VaultBankTransaction tx) {
        if (tx.getReceivedAt() != null && tx.getPaidAt() != null
                && tx.getStatus() != VaultOperationStatus.COMPLETED) {
            tx.setStatus(VaultOperationStatus.COMPLETED);
            tx.setCompletedAt(LocalDateTime.now());
            tx.setApprovedBy(SecurityUtils.getCurrentWorkerId());
        }
    }

    private CurrencyStock getOrCreateStock(UUID companyId, String entityType, String entityId, String currencyCode) {
        return currencyStockRepository.findForUpdate(companyId, entityType, entityId, currencyCode)
                .orElseGet(() -> {
                    CurrencyStock stock = CurrencyStock.builder()
                            .company(hu.puzzleir.valuta.entity.Company.builder().id(companyId).build())
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

    private BankTransactionResponseDto toDto(VaultBankTransaction entity) {
        return BankTransactionResponseDto.builder()
                .id(entity.getId())
                .transactionType(entity.getTransactionType())
                .currencyCode(entity.getCurrencyCode())
                .amount(entity.getAmount())
                .exchangeRate(entity.getExchangeRate())
                .hufAmount(entity.getHufAmount())
                .bankName(entity.getBankName())
                .bankReference(entity.getBankReference())
                .status(entity.getStatus().name())
                .note(entity.getNote())
                .createdAt(entity.getCreatedAt())
                .completedAt(entity.getCompletedAt())
                .receivedAt(entity.getReceivedAt())
                .receivedBy(entity.getReceivedBy())
                .paidAt(entity.getPaidAt())
                .paidBy(entity.getPaidBy())
                .vaultTerritoryId(entity.getVaultTerritory() != null ? entity.getVaultTerritory().getId() : null)
                .vaultTerritoryName(entity.getVaultTerritory() != null ? entity.getVaultTerritory().getName() : null)
                .build();
    }
}
