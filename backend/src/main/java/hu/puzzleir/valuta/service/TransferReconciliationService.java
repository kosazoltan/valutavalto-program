package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.central.TransferReconciliationResultDto;
import hu.puzzleir.valuta.dto.central.TransferReconciliationRowDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Transfer;
import hu.puzzleir.valuta.entity.TransferLine;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.TransferRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Clock;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * FK-003: Pénztárak/értéktárak közötti pénzmozgások egyeztetése (Beérkezett adatok menü).
 *
 * <p>Az új adatmodellben egy {@link Transfer} EGY rekord, amely a küldött ({@code amount})
 * és a fogadott ({@code receivedAmount}) oldalt is hordozza — tehát az egyeztetés a
 * küldött vs. fogadott összeg összevetése (és hogy a fogadó megerősítette-e). A több-valutás
 * átadólap soronként ({@link TransferLine}) ad egy-egy egyeztetési sort.</p>
 *
 * <p>Az ellenőrzést Kasza Helga (főértéktár) MANUÁLISAN indítja — nem fut automatikusan.
 * Eltérés esetén az érintett értéktár idempotens (nem spamelő) in-app + email értesítést kap.</p>
 */
@Service
@Slf4j
public class TransferReconciliationService {

    public static final String STATUS_MATCH = "EGYEZIK";
    public static final String STATUS_MISMATCH = "ELTERES";
    /** FK-090 FR-2: Feladó-irányú, még nem lezárt átadólap — se egyezés, se eltérés. */
    public static final String STATUS_IN_PROGRESS = "FOLYAMATBAN";

    private static final String NOTE_MISSING_RECEIVER = "Hiányzó bejegyzés a fogadó oldalon";
    private static final String NOTE_AWAITING_RECEIVER = "Fogadó megerősítésére vár";
    private static final String NOTIF_ENTITY_TYPE = "TransferReconciliation";
    private static final String NOTIF_TYPE = "TRANSFER_DISCREPANCY";
    static final ZoneId BUSINESS_ZONE = ZoneId.of("Europe/Budapest");

    private final TransferRepository transferRepository;
    private final NotificationService notificationService;
    private final Clock clock;

    public TransferReconciliationService(
            TransferRepository transferRepository,
            NotificationService notificationService) {
        this(transferRepository, notificationService, Clock.system(BUSINESS_ZONE));
    }

    TransferReconciliationService(
            TransferRepository transferRepository,
            NotificationService notificationService,
            Clock clock) {
        this.transferRepository = transferRepository;
        this.notificationService = notificationService;
        this.clock = clock;
    }

    @Transactional
    public TransferReconciliationResultDto reconcile(LocalDate startDate, LocalDate endDate) {
        if (startDate == null || endDate == null) {
            throw new ValidationException("Az egyeztetéshez kötelező a -tól és -ig dátum megadása.");
        }
        if (endDate.isBefore(startDate)) {
            throw new ValidationException("A -ig dátum nem lehet korábbi a -tól dátumnál.");
        }

        final UUID companyId = SecurityUtils.getCurrentCompanyId();
        List<Transfer> transfers = transferRepository.findForReconciliation(companyId, startDate, endDate);

        List<TransferReconciliationRowDto> rows = new ArrayList<>();
        int matched = 0;
        int discrepancy = 0;
        int notified = 0;

        for (Transfer t : transfers) {
            // FK-090 FR-1: a RECEIVED státusz soha nem íródik (TransferService csak
            // PENDING / IN_TRANSIT / COMPLETED / REJECTED / CANCELLED). Csak COMPLETED
            // számít fogadó-megerősítésnek.
            boolean receiverConfirmed = t.getStatus() == Transfer.TransferStatus.COMPLETED;

            List<TransferReconciliationRowDto> transferRows = buildRows(t, receiverConfirmed);
            boolean hasDiscrepancy = false;
            for (TransferReconciliationRowDto row : transferRows) {
                if (STATUS_MATCH.equals(row.getStatus())) {
                    matched++;
                } else if (STATUS_MISMATCH.equals(row.getStatus())) {
                    discrepancy++;
                    hasDiscrepancy = true;
                }
                // FOLYAMATBAN: sem matched, sem discrepancy, nincs értesítés.
            }
            rows.addAll(transferRows);

            if (hasDiscrepancy && notifyDiscrepancy(t, transferRows, companyId)) {
                notified++;
            }
        }

        return TransferReconciliationResultDto.builder()
                .startDate(startDate)
                .endDate(endDate)
                .totalRows(rows.size())
                .matchedRows(matched)
                .discrepancyRows(discrepancy)
                .notifiedBranches(notified)
                .generatedAt(LocalDateTime.now())
                .rows(rows)
                .build();
    }

    private List<TransferReconciliationRowDto> buildRows(Transfer t, boolean receiverConfirmed) {
        List<TransferReconciliationRowDto> result = new ArrayList<>();
        List<TransferLine> lines = t.getLines();

        if (lines != null && !lines.isEmpty()) {
            for (TransferLine line : lines) {
                String currencyCode = line.getCurrency() != null ? line.getCurrency().getCode() : "?";
                result.add(buildRow(t, currencyCode, line.getAmount(), line.getReceivedAmount(), receiverConfirmed));
            }
        } else {
            String currencyCode = t.getCurrency() != null ? t.getCurrency().getCode() : "?";
            result.add(buildRow(t, currencyCode, t.getAmount(), t.getReceivedAmount(), receiverConfirmed));
        }
        return result;
    }

    private TransferReconciliationRowDto buildRow(Transfer t, String currencyCode,
                                                  BigDecimal sent, BigDecimal received, boolean receiverConfirmed) {
        Transfer.TransferDirection direction =
                t.getDirection() != null ? t.getDirection() : Transfer.TransferDirection.UF;
        String status;
        String note = null;
        BigDecimal displayReceived = received;

        if (isCreateSettled(direction)) {
            // FK-090 FR-3: Vevő (U) / Korrekció (FF) — a pénzmozgás create-kor teljes.
            // Az egyeztetés OLVASÁSI logikája a rögzített összeget használja mindkét oldalon;
            // a transfer_lines.received_amount-ot nem írjuk.
            status = STATUS_MATCH;
            displayReceived = sent;
        } else if (direction == Transfer.TransferDirection.F && !receiverConfirmed) {
            // FK-090 FR-2: Feladó-irány, fogadó még nem erősített — semleges.
            status = STATUS_IN_PROGRESS;
            note = NOTE_AWAITING_RECEIVER;
        } else if (received == null || !receiverConfirmed) {
            status = STATUS_MISMATCH;
            note = NOTE_MISSING_RECEIVER;
        } else if (sent == null || received.compareTo(sent) != 0) {
            status = STATUS_MISMATCH;
            note = String.format("Eltérő összeg: küldött %s, fogadott %s",
                    plain(sent), plain(received));
        } else {
            status = STATUS_MATCH;
        }

        Branch from = t.getFromBranch();
        Branch to = t.getToBranch();
        return TransferReconciliationRowDto.builder()
                .transferId(t.getId())
                .transferNumber(t.getTransferNumber())
                .date(t.getTransferDate())
                .fromBranchCode(from != null ? from.getCode() : null)
                .fromBranchName(from != null ? from.getName() : null)
                .toBranchCode(to != null ? to.getCode() : null)
                .toBranchName(to != null ? to.getName() : null)
                .currencyCode(currencyCode)
                .sentAmount(sent)
                .receivedAmount(displayReceived)
                .status(status)
                .discrepancyNote(note)
                .build();
    }

    /**
     * U (Vevő) és FF (Korrekció): create-kor, egyetlen fél összegével elszámolt irány.
     * UF (Teljes körforgás) NEM ide tartozik — ott a meglévő összeg-összehasonlítás marad (FR-4).
     */
    private static boolean isCreateSettled(Transfer.TransferDirection direction) {
        return direction == Transfer.TransferDirection.U
                || direction == Transfer.TransferDirection.FF;
    }

    /**
     * Az érintett értéktárat értesíti az eltérésről (idempotens, csak ennek az értéktárnak).
     * Az értéktár-oldal a {@code isVault=true} fél; ha egyik fél sem értéktár (pénztár-pénztár
     * mozgás), a fogadó iroda kapja az értesítést (neki kell javítania).
     */
    private boolean notifyDiscrepancy(Transfer t, List<TransferReconciliationRowDto> transferRows, UUID companyId) {
        Branch target = resolveAffectedVault(t, companyId);
        if (target == null || target.getId() == null) {
            return false;
        }
        String title = "Egyeztetési eltérés — javítás szükséges";
        StringBuilder body = new StringBuilder();
        body.append("Pénztárak közötti pénzmozgás eltérés (").append(t.getTransferNumber()).append("): ")
                .append(t.getTransferDate()).append(" — ")
                .append(branchLabel(t.getFromBranch())).append(" → ").append(branchLabel(t.getToBranch()));
        for (TransferReconciliationRowDto row : transferRows) {
            if (STATUS_MISMATCH.equals(row.getStatus())) {
                body.append("\n• ").append(row.getCurrencyCode())
                        .append(": küldött ").append(plain(row.getSentAmount()))
                        .append(", fogadott ").append(plain(row.getReceivedAmount()))
                        .append(" (").append(row.getDiscrepancyNote()).append(")");
            }
        }
        String entityId = companyId + ":" + t.getTransferNumber() + ":" + LocalDate.now(clock);
        return notificationService.notifyBranchOnce(
                target.getId(), title, body.toString(),
                "WARNING", NOTIF_ENTITY_TYPE, entityId, NOTIF_TYPE);
    }

    private Branch resolveAffectedVault(Transfer t, UUID companyId) {
        Branch to = t.getToBranch();
        Branch from = t.getFromBranch();
        // Multi-tenant védelem: KIZÁRÓLAG a saját cég irodáját szabad értesíteni — egy
        // cégek közötti átadásnál NEM mehet értesítés a másik bérlő dolgozóinak.
        boolean toOwn = belongsToCompany(to, companyId);
        boolean fromOwn = belongsToCompany(from, companyId);
        if (toOwn && Boolean.TRUE.equals(to.getIsVault())) {
            return to;
        }
        if (fromOwn && Boolean.TRUE.equals(from.getIsVault())) {
            return from;
        }
        if (toOwn) {
            return to;
        }
        if (fromOwn) {
            return from;
        }
        return null;
    }

    private static boolean belongsToCompany(Branch branch, UUID companyId) {
        return branch != null && branch.getCompany() != null
                && companyId.equals(branch.getCompany().getId());
    }

    private static String branchLabel(Branch b) {
        if (b == null) {
            return "?";
        }
        return b.getCode() != null ? b.getCode() : (b.getName() != null ? b.getName() : "?");
    }

    private static String plain(BigDecimal value) {
        return value == null ? "-" : value.stripTrailingZeros().toPlainString();
    }
}
