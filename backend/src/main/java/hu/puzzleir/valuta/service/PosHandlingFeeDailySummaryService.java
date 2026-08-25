package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.handlingfee.PosHandlingFeeDailySummaryDto;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Set;
import java.util.UUID;

/** FK-059: read-only daily POS net and handling-fee report. */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
@Slf4j
public class PosHandlingFeeDailySummaryService {

    public static final String ERR_REPORT_ROLE = "VV-AUTH-005";
    public static final String ACTION_ACCESS_DENIED = "ACCESS_DENIED";
    private static final String AUDIT_ENTITY_TYPE = "POS_HANDLING_FEE_DAILY_SUMMARY";

    private static final Set<String> ALLOWED_ROLES = Set.of(
            "ROLE_FOERTEKTAR",
            "ROLE_UGYVEZETO",
            "ROLE_IRODAVEZETO",
            "ROLE_BELSO_ELLENOR",
            "ROLE_TERULETI_VEZETO",
            "ROLE_PENZUGYI_VEZETO");

    private final TransactionRepository transactionRepository;
    private final BranchService branchService;
    private final AuditLogService auditLogService;

    public PosHandlingFeeDailySummaryDto getDailySummary(
            UUID branchId, LocalDate startDate, LocalDate endDate) {
        assertAuthorized(branchId);
        if (startDate.isAfter(endDate)) {
            throw new ValidationException("A kezdő dátum nem lehet a záró dátum után.");
        }

        List<Object[]> sourceRows;
        if (branchId != null) {
            branchService.findById(branchId);
            sourceRows = transactionRepository.findDailyPosHandlingFee(branchId, startDate, endDate);
        } else {
            UUID companyId = SecurityUtils.getCurrentCompanyId();
            sourceRows = transactionRepository
                    .findDailyPosHandlingFeeForCompany(companyId, startDate, endDate);
        }

        List<PosHandlingFeeDailySummaryDto.DailyRow> rows = sourceRows.stream()
                .map(sourceRow -> PosHandlingFeeDailySummaryDto.DailyRow.builder()
                        .date((LocalDate) sourceRow[0])
                        .bankCode(nullToEmpty(sourceRow[1]))
                        .code(nullToEmpty(sourceRow[2]))
                        .netAmount(amountOrZero(sourceRow[3]))
                        .feeAmount(amountOrZero(sourceRow[4]))
                        .build())
                .toList();
        BigDecimal totalNetAmount = rows.stream()
                .map(PosHandlingFeeDailySummaryDto.DailyRow::getNetAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        BigDecimal totalFeeAmount = rows.stream()
                .map(PosHandlingFeeDailySummaryDto.DailyRow::getFeeAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        return PosHandlingFeeDailySummaryDto.builder()
                .startDate(startDate)
                .endDate(endDate)
                .totalNetAmount(totalNetAmount)
                .totalFeeAmount(totalFeeAmount)
                .rows(rows)
                .build();
    }

    private static String nullToEmpty(Object value) {
        return value == null ? "" : (String) value;
    }

    private BigDecimal amountOrZero(Object value) {
        return value != null ? (BigDecimal) value : BigDecimal.ZERO;
    }

    private void assertAuthorized(UUID branchId) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        boolean allowed = authentication != null && authentication.getAuthorities().stream()
                .map(GrantedAuthority::getAuthority)
                .anyMatch(ALLOWED_ROLES::contains);
        if (allowed) {
            return;
        }

        auditLogService.logInNewTransaction(
                ACTION_ACCESS_DENIED,
                AUDIT_ENTITY_TYPE,
                branchId != null ? branchId.toString() : null,
                workerIdOrNull(),
                null,
                null,
                null,
                String.format(
                        "{\"KAT\":\"AUTH\",\"error_code\":\"%s\",\"endpoint\":\"/handling-fees/pos-daily-summary\"}",
                        ERR_REPORT_ROLE));
        log.warn("FK-059 riport-hozzáférés megtagadva: branchId={}", branchId);
        throw new AccessDeniedException(
                ERR_REPORT_ROLE + ": nincs jogosultsága a POS kezelési díj napi riporthoz.");
    }

    private String workerIdOrNull() {
        try {
            return SecurityUtils.getCurrentWorkerId().toString();
        } catch (ValidationException e) {
            log.debug("FK-059 hozzáférés-megtagadás audit worker-azonosító nélkül: {}", e.getMessage());
            return null;
        }
    }
}
