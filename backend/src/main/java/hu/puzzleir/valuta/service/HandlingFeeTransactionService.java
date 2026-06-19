package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.dto.handlingfee.HandlingFeeReportDto;
import hu.puzzleir.valuta.dto.handlingfee.HandlingFeeTransactionDto;
import hu.puzzleir.valuta.entity.HandlingFeeTransaction;
import hu.puzzleir.valuta.entity.HandlingFeeTransaction.HandlingFeeTransactionType;
import hu.puzzleir.valuta.repository.HandlingFeeTransactionRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Kezelési díj tranzakció részletes szolgáltatás.
 * Sáv alapú díjszámítás:
 * 0-50K = 0%, 50K-300K = 1.5%, 300K-1M = 1%, 1M+ = 0.5%
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class HandlingFeeTransactionService {

    private final HandlingFeeTransactionRepository repository;
    private final TransactionRepository transactionRepository;

    private static final BigDecimal FIFTY_K = new BigDecimal("50000");
    private static final BigDecimal THREE_HUNDRED_K = new BigDecimal("300000");
    private static final BigDecimal ONE_MILLION = new BigDecimal("1000000");

    /**
     * Sávos díj számítás: tiered fee.
     */
    @Transactional(rollbackFor = Exception.class)
    public HandlingFeeTransactionDto calculateFee(Long transactionId, BigDecimal hufAmount) {
        BigDecimal fee;
        if (hufAmount.compareTo(FIFTY_K) <= 0) {
            fee = BigDecimal.ZERO;
        } else if (hufAmount.compareTo(THREE_HUNDRED_K) <= 0) {
            fee = hufAmount.multiply(new BigDecimal("0.015")).setScale(0, RoundingMode.HALF_UP);
        } else if (hufAmount.compareTo(ONE_MILLION) <= 0) {
            fee = hufAmount.multiply(new BigDecimal("0.01")).setScale(0, RoundingMode.HALF_UP);
        } else {
            fee = hufAmount.multiply(new BigDecimal("0.005")).setScale(0, RoundingMode.HALF_UP);
        }

        HandlingFeeTransaction hft = HandlingFeeTransaction.builder()
            .transactionId(transactionId)
            .feeType(HandlingFeeTransactionType.TIERED)
            .amount(fee)
            .netFee(fee)
            .discountPercent(0)
            .workerCommissionShare(BigDecimal.ZERO)
            .build();

        if (transactionId != null) {
            hft = repository.save(hft);
        }

        return toDto(hft);
    }

    /**
     * Kedvezmény alkalmazása: törzsvásárlói -10%, nagytételes -20%.
     */
    @Transactional(rollbackFor = Exception.class)
    public HandlingFeeTransactionDto applyDiscount(UUID feeId, int discountPercent, String reason) {
        HandlingFeeTransaction hft = repository.findById(feeId)
            .orElseThrow(() -> new ResourceNotFoundException("Kezelési díj nem található: " + feeId));

        // IDOR-guard: a kezelési díj tenancy-je a parent Transaction-ön él (a HFT csak transactionId-t
        // hordoz, companyId-t nem). Ownership-check a cég-szűrt Transaction-lekéréssel — más cég
        // tranzakciója és a nem létező tranzakció ugyanazt az üres eredményt adja (nincs txId-enumeráció).
        transactionRepository.findByIdAndCompanyId(hft.getTransactionId(), SecurityUtils.getCurrentCompanyId())
            .orElseThrow(() -> new ResourceNotFoundException("Kezelési díj nem található: " + feeId));

        hft.setDiscountPercent(discountPercent);
        hft.setDiscountReason(reason);

        BigDecimal discount = hft.getAmount()
            .multiply(new BigDecimal(discountPercent))
            .divide(new BigDecimal(100), 0, RoundingMode.HALF_UP);
        hft.setNetFee(hft.getAmount().subtract(discount));

        hft = repository.save(hft);
        log.info("Kezelési díj kedvezmény: feeId={}, discount={}%, reason={}", feeId, discountPercent, reason);

        return toDto(hft);
    }

    /**
     * Díj összesítő riport iroda és időszak szerint.
     */
    @Transactional(readOnly = true)
    public HandlingFeeReportDto getFeeReport(UUID branchId, LocalDate from, LocalDate to) {
        LocalDateTime fromDt = from.atStartOfDay();
        LocalDateTime toDt = to.atTime(LocalTime.MAX);

        List<HandlingFeeTransaction> items = repository.findByBranchAndPeriod(branchId, fromDt, toDt);

        BigDecimal totalGross = BigDecimal.ZERO;
        BigDecimal totalDiscount = BigDecimal.ZERO;
        BigDecimal totalNet = BigDecimal.ZERO;
        BigDecimal totalCommission = BigDecimal.ZERO;

        for (HandlingFeeTransaction hft : items) {
            totalGross = totalGross.add(hft.getAmount());
            totalDiscount = totalDiscount.add(hft.getAmount().subtract(hft.getNetFee()));
            totalNet = totalNet.add(hft.getNetFee());
            totalCommission = totalCommission.add(hft.getWorkerCommissionShare());
        }

        Map<Long, String> paymentMethods = loadPaymentMethods(items);

        return HandlingFeeReportDto.builder()
            .dateFrom(from.toString())
            .dateTo(to.toString())
            .totalGrossFee(totalGross)
            .totalDiscount(totalDiscount)
            .totalNetFee(totalNet)
            .totalCommissionShare(totalCommission)
            .transactionCount(items.size())
            .items(items.stream()
                .map(item -> toDto(item, paymentMethods.get(item.getTransactionId())))
                .toList())
            .build();
    }

    private HandlingFeeTransactionDto toDto(HandlingFeeTransaction entity) {
        return toDto(entity, loadPaymentMethod(entity.getTransactionId()));
    }

    private HandlingFeeTransactionDto toDto(HandlingFeeTransaction entity, String paymentMethod) {
        return HandlingFeeTransactionDto.builder()
            .id(entity.getId())
            .transactionId(entity.getTransactionId())
            .paymentMethod(paymentMethod)
            .feeType(entity.getFeeType().name())
            .amount(entity.getAmount())
            .discountPercent(entity.getDiscountPercent())
            .discountReason(entity.getDiscountReason())
            .netFee(entity.getNetFee())
            .workerCommissionShare(entity.getWorkerCommissionShare())
            .createdAt(entity.getCreatedAt())
            .build();
    }

    private String loadPaymentMethod(Long transactionId) {
        if (transactionId == null) {
            return null;
        }
        return repository.findPaymentMethodsByTransactionIds(List.of(transactionId)).stream()
            .findFirst()
            .map(HandlingFeeTransactionRepository.TransactionPaymentMethodProjection::getPaymentMethod)
            .map(Enum::name)
            .orElse(null);
    }

    private Map<Long, String> loadPaymentMethods(List<HandlingFeeTransaction> items) {
        List<Long> transactionIds = items.stream()
            .map(HandlingFeeTransaction::getTransactionId)
            .filter(Objects::nonNull)
            .distinct()
            .toList();
        if (transactionIds.isEmpty()) {
            return Map.of();
        }
        return repository.findPaymentMethodsByTransactionIds(transactionIds).stream()
            .filter(projection -> projection.getPaymentMethod() != null)
            .collect(Collectors.toMap(
                HandlingFeeTransactionRepository.TransactionPaymentMethodProjection::getTransactionId,
                projection -> projection.getPaymentMethod().name(),
                (left, right) -> left));
    }
}
