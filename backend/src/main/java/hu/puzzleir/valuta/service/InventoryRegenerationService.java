package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.dto.inventory.RegenerationResultDto;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

/**
 * Készlet regenerálás service.
 *
 * Legacy: regen.dll — készlet újraszámítás tranzakciók alapján (nulláról).
 * Összehasonlítja a jelenlegi készlettel és jelzi az eltéréseket.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class InventoryRegenerationService {

    private final InventoryRegenerationRepository regenerationRepository;
    private final BranchRepository branchRepository;
    private final TransactionRepository transactionRepository;
    private final CashBalanceRepository cashBalanceRepository;
    private final WorkerRepository workerRepository;

    /**
     * Készlet regenerálás — újraszámolja a készletet a tranzakciók alapján.
     */
    @Transactional
    public RegenerationResultDto regenerate(UUID branchId, Long workerId) {
        Branch branch = branchRepository.findById(branchId)
                .orElseThrow(() -> new ResourceNotFoundException("Iroda nem található: " + branchId));

        Worker worker = workerRepository.findById(workerId)
                .orElseThrow(() -> new ResourceNotFoundException("Dolgozó nem található: " + workerId));

        // Jelenlegi készletek
        List<CashBalance> currentBalances = cashBalanceRepository.findByBranchId(branchId);
        Map<String, BigDecimal> currentMap = new HashMap<>();
        for (CashBalance cb : currentBalances) {
            currentMap.put(cb.getCurrency().getCode(), cb.getCurrentBalance());
        }

        // Tranzakciók alapján számított készlet — összesítve
        // A teljes készletet nulláról számoljuk a tranzakciókból
        List<Transaction> allTransactions = transactionRepository.findByBranchId(branchId);

        Map<String, BigDecimal> calculatedMap = new HashMap<>();
        for (Transaction t : allTransactions) {
            if (t.getTransactionType() == null || t.getCurrency() == null) continue;
            if (t.getStatus() == TransactionStatus.CANCELLED || t.getStatus() == TransactionStatus.REVERSED) continue;

            String code = t.getCurrency().getCode();
            BigDecimal amount = t.getCurrencyAmount() != null ? t.getCurrencyAmount() : BigDecimal.ZERO;

            if (t.getTransactionType().isBuyType()) {
                // Vételnél: valuta bejön
                calculatedMap.merge(code, amount, BigDecimal::add);
            } else if (t.getTransactionType().isSellType()) {
                // Eladásnál: valuta kimegy
                calculatedMap.merge(code, amount.negate(), BigDecimal::add);
            }
        }

        // Eltérések
        List<RegenerationResultDto.DiscrepancyDto> discrepancies = new ArrayList<>();
        List<String> correctedCurrencies = new ArrayList<>();

        Set<String> allCurrencies = new HashSet<>();
        allCurrencies.addAll(currentMap.keySet());
        allCurrencies.addAll(calculatedMap.keySet());

        for (String currency : allCurrencies) {
            BigDecimal current = currentMap.getOrDefault(currency, BigDecimal.ZERO)
                    .setScale(2, RoundingMode.HALF_UP);
            BigDecimal calculated = calculatedMap.getOrDefault(currency, BigDecimal.ZERO)
                    .setScale(2, RoundingMode.HALF_UP);

            if (current.compareTo(calculated) != 0) {
                discrepancies.add(RegenerationResultDto.DiscrepancyDto.builder()
                        .currencyCode(currency)
                        .expectedAmount(calculated.toPlainString())
                        .actualAmount(current.toPlainString())
                        .difference(current.subtract(calculated).toPlainString())
                        .build());
                correctedCurrencies.add(currency);
            }
        }

        // Eredmény mentése
        StringBuilder resultJson = new StringBuilder("{\"discrepancies\":[");
        boolean first = true;
        for (RegenerationResultDto.DiscrepancyDto d : discrepancies) {
            if (!first) resultJson.append(",");
            resultJson.append("{\"currency\":\"").append(d.getCurrencyCode())
                    .append("\",\"expected\":").append(d.getExpectedAmount())
                    .append(",\"actual\":").append(d.getActualAmount())
                    .append(",\"diff\":").append(d.getDifference()).append("}");
            first = false;
        }
        resultJson.append("]}");

        InventoryRegeneration regen = InventoryRegeneration.builder()
                .branch(branch)
                .resultData(resultJson.toString())
                .discrepancyCount(discrepancies.size())
                .correctedCount(correctedCurrencies.size())
                .regeneratedAt(LocalDateTime.now())
                .regeneratedBy(worker)
                .build();

        regen = regenerationRepository.save(regen);
        log.info("Készlet regenerálás: branch={}, eltérések={}", branch.getCode(), discrepancies.size());

        return RegenerationResultDto.builder()
                .id(regen.getId())
                .branchId(branchId.toString())
                .discrepancies(discrepancies)
                .correctedCurrencies(correctedCurrencies)
                .discrepancyCount(discrepancies.size())
                .correctedCount(correctedCurrencies.size())
                .regeneratedAt(regen.getRegeneratedAt().toString())
                .regeneratedByName(worker.getName())
                .build();
    }

    /**
     * Utolsó regenerálás lekérdezése.
     */
    @Transactional(readOnly = true)
    public RegenerationResultDto getLastRegeneration(UUID branchId) {
        InventoryRegeneration regen = regenerationRepository
                .findTopByBranchIdOrderByRegeneratedAtDesc(branchId)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Nincs korábbi készlet regenerálás: branchId=" + branchId));

        return RegenerationResultDto.builder()
                .id(regen.getId())
                .branchId(branchId.toString())
                .discrepancyCount(regen.getDiscrepancyCount())
                .correctedCount(regen.getCorrectedCount())
                .regeneratedAt(regen.getRegeneratedAt().toString())
                .regeneratedByName(regen.getRegeneratedBy() != null ? regen.getRegeneratedBy().getName() : null)
                .build();
    }
}
