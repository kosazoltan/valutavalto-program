package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.handlingfee.HandlingFeeDailySummaryDto;
import hu.puzzleir.valuta.entity.TransactionType;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
@Slf4j
public class HandlingFeeDailySummaryService {

    /** FK-053 hibakód: a napi kezelésidíj-riport szerep-megtagadása. */
    public static final String ERR_REPORT_ROLE = "VV-AUTH-005";
    public static final String ACTION_ACCESS_DENIED = "ACCESS_DENIED";
    private static final String AUDIT_ENTITY_TYPE = "HANDLING_FEE_DAILY_SUMMARY";

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

    public HandlingFeeDailySummaryDto getDailySummary(
            UUID branchId, LocalDate startDate, LocalDate endDate) {
        assertAuthorized(branchId);
        if (startDate.isAfter(endDate)) {
            throw new ValidationException("A kezdő dátum nem lehet a záró dátum után.");
        }

        List<Object[]> sourceRows;
        if (branchId != null) {
            branchService.findById(branchId);
            sourceRows = transactionRepository
                    .findDailyCashHandlingFeeByType(branchId, startDate, endDate);
        } else {
            // FK-055: cég-szintű összesítés; a companyId a SecurityContext-ből jön, nem kliens-input.
            UUID companyId = SecurityUtils.getCurrentCompanyId();
            sourceRows = transactionRepository
                    .findDailyCashHandlingFeeByTypeForCompany(companyId, startDate, endDate);
        }
        Map<RowKey, HandlingFeeDailySummaryDto.DailyRow> rowsByKey = new LinkedHashMap<>();

        for (Object[] sourceRow : sourceRows) {
            LocalDate date = (LocalDate) sourceRow[0];
            String bankCode = nullToEmpty(sourceRow[1]);
            String code = nullToEmpty(sourceRow[2]);
            TransactionType transactionType = (TransactionType) sourceRow[3];
            BigDecimal fee = (BigDecimal) sourceRow[4];
            if (transactionType != TransactionType.BUY && transactionType != TransactionType.SELL) {
                log.debug(
                        "FK-053 napi riport: nem BUY/SELL tranzakciótípus eldobva: date={}, bankCode={}, code={}, type={}",
                        date,
                        bankCode,
                        code,
                        transactionType);
                continue;
            }

            HandlingFeeDailySummaryDto.DailyRow dailyRow = rowsByKey.computeIfAbsent(
                    new RowKey(date, bankCode, code),
                    key -> HandlingFeeDailySummaryDto.DailyRow.builder()
                            .date(key.date())
                            .bankCode(key.bankCode())
                            .code(key.code())
                            .buyFee(BigDecimal.ZERO)
                            .sellFee(BigDecimal.ZERO)
                            .build());
            if (transactionType == TransactionType.BUY) {
                dailyRow.setBuyFee(dailyRow.getBuyFee().add(fee));
            } else {
                dailyRow.setSellFee(dailyRow.getSellFee().add(fee));
            }
        }

        List<HandlingFeeDailySummaryDto.DailyRow> rows = List.copyOf(rowsByKey.values());
        BigDecimal totalBuyFee = rows.stream()
                .map(HandlingFeeDailySummaryDto.DailyRow::getBuyFee)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        BigDecimal totalSellFee = rows.stream()
                .map(HandlingFeeDailySummaryDto.DailyRow::getSellFee)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        return HandlingFeeDailySummaryDto.builder()
                .startDate(startDate)
                .endDate(endDate)
                .totalBuyFee(totalBuyFee)
                .totalSellFee(totalSellFee)
                .rows(rows)
                .build();
    }

    /** FK-095 fold key: one row per (date, bankCode, code) — records give equals/hashCode. */
    private record RowKey(LocalDate date, String bankCode, String code) {}

    private static String nullToEmpty(Object value) {
        return value == null ? "" : (String) value;
    }

    /**
     * FR-6 (b): explicit kód-szintű RBAC, hogy a megtagadás ACCESS_DENIED audit-sort kapjon.
     * Ismeretlen vagy hiányzó szerep esetén fail-closed.
     */
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
                        "{\"KAT\":\"AUTH\",\"error_code\":\"%s\",\"endpoint\":\"/handling-fees/daily-summary\"}",
                        ERR_REPORT_ROLE));
        log.warn("FK-053 riport-hozzáférés megtagadva: branchId={}", branchId);
        throw new AccessDeniedException(
                ERR_REPORT_ROLE + ": nincs jogosultsága a kezelési díj napi riporthoz.");
    }

    private String workerIdOrNull() {
        try {
            return SecurityUtils.getCurrentWorkerId().toString();
        } catch (ValidationException e) {
            log.debug("FK-053 hozzáférés-megtagadás audit worker-azonosító nélkül: {}", e.getMessage());
            return null;
        }
    }
}
