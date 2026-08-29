package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.levy.TransactionLevyReportDto;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.TransactionLevyRateHistoryRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.UUID;

/**
 * FK-099 — pénzügyi tranzakciós illeték riport (read-only use case).
 * RBAC + ACCESS_DENIED audit a service-ben (D10), hogy a megtagadás audit-sort
 * kapjon, ne csak a Spring filter 403-at.
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
@Slf4j
public class TransactionLevyReportService {

    /** FK-099 hibakód: az illeték-riport szerep-megtagadása. */
    public static final String ERR_REPORT_ROLE = "VV-AUTH-006";
    public static final String ACTION_ACCESS_DENIED = "ACCESS_DENIED";
    private static final String AUDIT_ENTITY_TYPE = "TRANSACTION_LEVY_REPORT";

    private final TransactionRepository transactionRepository;
    private final TransactionLevyRateHistoryRepository rateHistoryRepository;
    private final BranchRepository branchRepository;
    private final AuditLogService auditLogService;

    /**
     * Riport számítása a megadott (inclusive) időszakra, opcionális iroda-szűréssel.
     *
     * @param branchId nullable; idegen tenant iroda → 404 VV-TENANT-001 (FR-19)
     * @param from     időszak kezdete (inclusive)
     * @param to       időszak vége (inclusive)
     */
    public TransactionLevyReportDto getReport(UUID branchId, LocalDate from, LocalDate to) {
        throw new UnsupportedOperationException("FK-099 RED");
    }
}
