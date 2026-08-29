package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.levy.TransactionLevyRateCreateRequest;
import hu.puzzleir.valuta.dto.levy.TransactionLevyRateDto;
import hu.puzzleir.valuta.repository.TransactionLevyRateHistoryRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * FK-099 — append-only illeték-ráta history írása/olvasása.
 * RBAC: olvasás bővebb kör (IRODAVEZETO nélkül), írás szűkebb (FR-18);
 * a megtagadás ACCESS_DENIED audit-sort kap (D10).
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class TransactionLevyRateService {

    /** FK-099 hibakód: az illeték-ráta művelet szerep-megtagadása. */
    public static final String ERR_RATE_ROLE = "VV-AUTH-007";
    public static final String ACTION_ACCESS_DENIED = "ACCESS_DENIED";
    private static final String AUDIT_ENTITY_TYPE = "TRANSACTION_LEVY_RATE";

    private final TransactionLevyRateHistoryRepository rateHistoryRepository;
    private final AuditLogService auditLogService;

    /** A cég teljes ráta-historyja, effectiveFrom DESC, derived küszöbbel. */
    public List<TransactionLevyRateDto> list() {
        throw new UnsupportedOperationException("FK-099 RED");
    }

    /** Új append-only ráta-sor (jövőbeli és monoton effective_from). */
    public TransactionLevyRateDto create(TransactionLevyRateCreateRequest request) {
        throw new UnsupportedOperationException("FK-099 RED");
    }
}
