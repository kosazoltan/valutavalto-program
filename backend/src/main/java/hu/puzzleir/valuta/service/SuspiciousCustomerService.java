package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.compliance.SuspiciousCustomerDto;
import hu.puzzleir.valuta.exception.BusinessException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * FS-12: gyanús ügyfél lekérdezés (3 minta) + hatályos értéksávot elért ügyfelek exportja.
 * Cég-scope kizárólag a SecurityContextből; az exportküszöb a hatályos ValueBandConfigból jön.
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class SuspiciousCustomerService {

    static final int DEFAULT_MIN_TRANSACTION_COUNT = 10;
    static final int DEFAULT_MIN_BRANCH_COUNT = 3;
    static final int DEFAULT_PERIOD_DAYS = 30;
    static final int EXPORT_MAX_ROWS = 10_000;

    private final TransactionRepository transactionRepository;
    private final ValueBandService valueBandService;

    public Page<SuspiciousCustomerDto> search(LocalDate startDate, LocalDate endDate,
            boolean byTransactionCount, Integer minTransactionCount,
            boolean byTotalValue, BigDecimal minTotalHuf,
            boolean byBranchCount, Integer minBranchCount,
            Pageable pageable) {
        if (!byTransactionCount && !byTotalValue && !byBranchCount) {
            throw new ValidationException("Legalább egy szűrőfeltételt be kell kapcsolni!");
        }
        Period period = resolvePeriod(startDate, endDate);
        long minTx = resolvePositive(minTransactionCount, DEFAULT_MIN_TRANSACTION_COUNT,
                "A minimum tranzakciószámnak pozitívnak kell lennie!");
        long minBranches = resolvePositive(minBranchCount, DEFAULT_MIN_BRANCH_COUNT,
                "A minimum váltópont-számnak pozitívnak kell lennie!");
        BigDecimal minTotal = minTotalHuf != null ? minTotalHuf : incomeProofLimit();
        if (minTotal.signum() <= 0) {
            throw new ValidationException("A minimum össz-értéknek pozitívnak kell lennie!");
        }

        UUID companyId = SecurityUtils.getCurrentCompanyId();
        List<Object[]> rows = transactionRepository.findSuspiciousCustomerAggregates(
                companyId, period.start(), period.end(), byTransactionCount, minTx,
                byTotalValue, minTotal, byBranchCount, minBranches);
        List<SuspiciousCustomerDto> all = new ArrayList<>(rows.size());
        for (Object[] row : rows) {
            all.add(toDto(row, minTx, minTotal, minBranches));
        }

        if (pageable == null || pageable.isUnpaged()) {
            return new PageImpl<>(all);
        }
        // D4: memória-lapozás — a HAVING miatt a sorhalmaz korlátos (küszöb-átlépő ügyfelek).
        int from = (int) Math.min(pageable.getOffset(), all.size());
        int to = (int) Math.min(pageable.getOffset() + pageable.getPageSize(), all.size());
        return new PageImpl<>(all.subList(from, to), pageable, all.size());
    }

    /** FS-12 export: a hatályos értéksávot (incomeProofLimitHuf) elért ügyfelek. Fail-closed cap. */
    public List<SuspiciousCustomerDto> listValueBandReachedForExport(LocalDate startDate, LocalDate endDate) {
        Period period = resolvePeriod(startDate, endDate);
        BigDecimal bandLimit = incomeProofLimit();
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        List<Object[]> rows = transactionRepository.findSuspiciousCustomerAggregates(
                companyId, period.start(), period.end(), false, Long.MAX_VALUE,
                true, bandLimit, false, Long.MAX_VALUE);
        if (rows.size() > EXPORT_MAX_ROWS) {
            throw new BusinessException(
                    "Az export túl nagy (" + rows.size() + " sor, limit " + EXPORT_MAX_ROWS + ") — szűkítsd az időszakot",
                    "SUSPICIOUS_EXPORT_TOO_LARGE");
        }
        List<SuspiciousCustomerDto> result = new ArrayList<>(rows.size());
        for (Object[] row : rows) {
            result.add(toDto(row, Long.MAX_VALUE, bandLimit, Long.MAX_VALUE));
        }
        return result;
    }

    private BigDecimal incomeProofLimit() {
        return ValueBandService.resolve(valueBandService).incomeProofLimitHuf();
    }

    private static Period resolvePeriod(LocalDate startDate, LocalDate endDate) {
        LocalDate end = endDate != null ? endDate : LocalDate.now();
        LocalDate start = startDate != null ? startDate : end.minusDays(DEFAULT_PERIOD_DAYS);
        if (start.isAfter(end)) {
            throw new ValidationException("Az időszak kezdete nem lehet a vége után!");
        }
        return new Period(start, end);
    }

    private static long resolvePositive(Integer value, int defaultValue, String message) {
        if (value == null) {
            return defaultValue;
        }
        if (value <= 0) {
            throw new ValidationException(message);
        }
        return value;
    }

    private static SuspiciousCustomerDto toDto(Object[] row, long minTx, BigDecimal minTotal, long minBranches) {
        String customerId = (String) row[0];
        String customerName = (String) row[1];
        long count = ((Number) row[2]).longValue();
        BigDecimal total = row[3] != null ? (BigDecimal) row[3] : BigDecimal.ZERO;
        long branches = ((Number) row[4]).longValue();
        return SuspiciousCustomerDto.builder()
                .customerId(customerId)
                .customerName(customerName)
                .transactionCount(count)
                .totalHufAmount(total)
                .branchCount(branches)
                .highTransactionCount(count >= minTx)
                .highTotalValue(total.compareTo(minTotal) >= 0)
                .manyBranches(branches >= minBranches)
                .build();
    }

    private record Period(LocalDate start, LocalDate end) {}
}
