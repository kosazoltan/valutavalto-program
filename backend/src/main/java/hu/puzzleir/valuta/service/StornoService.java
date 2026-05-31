package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.dto.storno.StornoApprovalDto;
import hu.puzzleir.valuta.dto.storno.StornoCheckResultDto;
import hu.puzzleir.valuta.dto.storno.StornoRequestDto;
import hu.puzzleir.valuta.entity.ExchangeRate;
import hu.puzzleir.valuta.entity.StornoApproval;
import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.entity.TransactionStatus;
import hu.puzzleir.valuta.entity.TransactionType;
import hu.puzzleir.valuta.repository.ExchangeRateRepository;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.mapper.TransactionMapper;
import hu.puzzleir.valuta.repository.StornoApprovalRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.entity.Dictionary;
import hu.puzzleir.valuta.repository.DictionaryRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * Sztornó szolgáltatás.
 * Sztornó ellenőrzés, jóváhagyás kérés, jóváhagyás, végrehajtás.
 */
@Service
@RequiredArgsConstructor
@Transactional(rollbackFor = Exception.class)
@Slf4j
public class StornoService {

    private final TransactionRepository transactionRepository;
    private final StornoApprovalRepository stornoApprovalRepository;
    private final WorkerRepository workerRepository;
    private final BranchRepository branchRepository;
    private final TransactionService transactionService;
    private final DictionaryRepository dictionaryRepository;
    private final ExchangeRateRepository exchangeRateRepository;
    private final NotificationService notificationService;
    private final ApplicationEventPublisher eventPublisher;

    // Napi sztornó limit supervisor jóváhagyás nélkül — iroda szinten
    private static final int DAILY_STORNO_LIMIT_BRANCH = 3;

    // Napi sztornó limit supervisor jóváhagyás nélkül — pénztáros szinten
    // Legacy: a limit irodánként ÉS pénztárosonként is érvényes
    private static final int DAILY_STORNO_LIMIT_CASHIER = 2;

    /**
     * PR #115: Sztornó ellenőrzés receipt_number-rel VAGY id-vel.
     *
     * A frontend és Penztar-client a `tx.receiptNumber || tx.id` fallback-et
     * használja URL path param-ban — mindkét forma működik.
     */
    @Transactional(readOnly = true)
    public StornoCheckResultDto checkStorno(String transactionIdOrReceipt, Long workerId) {
        Transaction transaction = resolveTransaction(transactionIdOrReceipt);
        return doCheckStorno(transaction, workerId);
    }

    /**
     * Backward-compat overload: régi Long id-s hívás.
     */
    @Transactional(readOnly = true)
    public StornoCheckResultDto checkStorno(Long transactionId, Long workerId) {
        Transaction transaction = transactionRepository.findById(transactionId)
                .orElseThrow(() -> new ResourceNotFoundException("Tranzakció nem található: " + transactionId));
        return doCheckStorno(transaction, workerId);
    }

    /**
     * Tranzakció feloldás id (numerikus) VAGY receipt_number (string) alapján.
     */
    private Transaction resolveTransaction(String idOrReceipt) {
        if (idOrReceipt == null || idOrReceipt.isBlank()) {
            throw new ResourceNotFoundException("Tranzakció azonosító hiányzik");
        }
        try {
            Long id = Long.parseLong(idOrReceipt);
            return transactionRepository.findById(id)
                    .orElseThrow(() -> new ResourceNotFoundException("Tranzakció nem található: " + id));
        } catch (NumberFormatException e) {
            // Multi-tenant: receipt_number csak cégen belül egyedi.
            java.util.UUID companyId = hu.puzzleir.valuta.security.SecurityUtils.getCurrentCompanyId();
            return transactionRepository.findByReceiptNumberAndCompanyId(idOrReceipt, companyId)
                    .orElseThrow(() -> new ResourceNotFoundException(
                            "Tranzakció nem található bizonylat szám alapján: " + idOrReceipt));
        }
    }

    private StornoCheckResultDto doCheckStorno(Transaction transaction, Long workerId) {
        Long transactionId = transaction.getId();

        UUID branchId = SecurityUtils.getCurrentBranchId();

        // IDOR védelem: csak saját iroda tranzakciója ellenőrizhető
        if (!transaction.getBranch().getId().equals(branchId)) {
            throw new ValidationException("Nincs jogosultság más iroda tranzakciójához!");
        }

        // 2026-04-29 v2.3.30 (Sourcery PR #293 P2): companyId egyszer extract,
        // NEM ismétlődő SecurityUtils.getCurrentCompanyId() inline minden hívásnál.
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        LocalDate today = LocalDate.now();
        // Napi sztornó számok — iroda szinten ÉS pénztáros szinten
        int dailyCountBranch = (int) transactionRepository.countReversalsByBranchAndDate(companyId, branchId, today);
        int dailyCountCashier = (int) transactionRepository.countReversalsByBranchAndWorkerAndDate(
                companyId, branchId, workerId, today);

        // HIGH FIX #8: Ha a tranzakció ALREADY_REVERSED → dobjon hibát, ne engedje tovább
        if (transaction.isReversed()) {
            throw new ValidationException("Ez a tranzakció már sztornózva lett (REVERSED státusz)!");
        }
        if (transaction.isReversal()) {
            throw new ValidationException("Sztornó tranzakció nem sztornózható!");
        }

        // Audit #2 (2026-05-31, user-direktiva): a korabbi napi tranzakcio VISSZAMENOLEG SOHA nem
        // sztornozhato (sem supervisorral) — lasd TransactionReversalService.executeReversal. A precheck
        // (UI-elonezet) NEM jelezhet "supervisor jovahagyas eleg"-et, kulonben a kliens egy lehetetlen
        // jovahagyas-folyamatba kuldene a penztarost, amit az execute ugyis elutasitana (nem-informatikus
        // vegfelhasznalo alapelv: ne igerjunk olyat, amit a backend megtilt). Ezert a precheck is dob.
        if (!transaction.getTransactionDate().equals(LocalDate.now())) {
            throw new ValidationException(
                "Csak az aznapi tranzakcio sztornozhato — korabbi nap visszamenoleg nem sztornozhato. Tranzakcio datuma: "
                + transaction.getTransactionDate());
        }

        // Codex P2 (2026-05-31, #944 review): a precheck (UI-elonezet) a KIKENYSZERITESSEL
        // (TransactionReversalService.executeReversal) AZONOS branch-szintu plafon-szemantikat
        // tukrozze, kulonben a UI vagy ATUGORJA a supervisor-flow-t (3. sztornonal), vagy
        // HASZNALHATATLAN jovahagyas-kerest mutat (4.+, amit az execute amugy is tilt). Az execute:
        //   - branch count >= limit (3)      -> ABSZOLUT plafon, supervisorral SEM
        //   - branch count == limit-1 (a 3.) -> supervisori jovahagyas szukseges
        // A DAILY_STORNO_LIMIT_BRANCH (3) szandekosan egyezik az execute DAILY_REVERSAL_LIMIT-jevel,
        // a count-bazis is azonos (transaction REVERSAL/branch/ma == DailySession.reversalCount).
        //
        // 4.+ : a precheck DOB (mint a korabbi-napi agnal) — a nem-informatikus vegfelhasznalo NE
        // kapjon olyan jovahagyas-folyamatot, amit a backend ugyis elutasitana.
        if (dailyCountBranch >= DAILY_STORNO_LIMIT_BRANCH) {
            throw new ValidationException(String.format(
                "Napi sztorno plafon (%d) elerve — ma tobb sztorno nem lehetseges, supervisori jovahagyassal sem!",
                DAILY_STORNO_LIMIT_BRANCH));
        }

        // A 3. (utolso engedelyezett) irodai sztorno mar jovahagyast igenyel (count == limit-1).
        boolean branchApprovalRequired = dailyCountBranch >= DAILY_STORNO_LIMIT_BRANCH - 1;
        // Legacy: a limit penztarosonkent is ervenyes (advisory). MEGJEGYZES (self-review P2,
        // 2026-05-31): jelenleg DAILY_STORNO_LIMIT_CASHIER (2) == DAILY_STORNO_LIMIT_BRANCH-1 (2),
        // es cashierCount <= branchCount, ezert ez az ag a branch-ag NELKUL onmagaban sosem dont
        // (a requiresApproval-t a branchApprovalRequired amugy is igazza teszi). SZANDEKOSAN
        // megtartva: (a) a legacy per-penztaros uzleti szabaly explicit dokumentacioja, (b) ha a
        // ket kuszob jovoben eltervalik (pl. szigorubb penztaros-limit), azonnal ervenyre jut. Az
        // execute (TransactionReversalService) csak branch-szinten kenyszerit; ez advisory marad.
        boolean cashierLimitReached = dailyCountCashier >= DAILY_STORNO_LIMIT_CASHIER;

        boolean requiresApproval = branchApprovalRequired || cashierLimitReached;

        String message;
        if (requiresApproval) {
            List<String> reasons = new ArrayList<>();
            if (branchApprovalRequired) {
                reasons.add(String.format("irodai napi sztornó szám (%d) elérte a jóváhagyási küszöböt (%d)",
                        dailyCountBranch, DAILY_STORNO_LIMIT_BRANCH - 1));
            }
            if (cashierLimitReached) {
                reasons.add(String.format("pénztáros napi sztornó szám (%d) elérte a limitet (%d)",
                        dailyCountCashier, DAILY_STORNO_LIMIT_CASHIER));
            }
            message = "Supervisor jóváhagyás szükséges: " + String.join("; ", reasons) + ".";
        } else {
            message = "Sztornó végrehajtható.";
        }

        // Árfolyam-eltérés ellenőrzés (Felmérés: sztorno.docx követelmény)
        BigDecimal originalRate = transaction.getExchangeRate();
        BigDecimal currentRate = originalRate; // Default: eredeti
        BigDecimal rateDifference = BigDecimal.ZERO;
        boolean rateChanged = false;

        if (transaction.getCurrency() != null && originalRate != null) {
            // Aktuális árfolyam lekérése az ExchangeRateRepository-ból
            // 2026-04-29 v2.3.30: a `companyId` már a metódus elején extract,
            // NEM duplikál (Sourcery PR #293 P2 — companyId extract egyszer).
            try {
                var latestRateOpt = exchangeRateRepository.findLatestRate(
                        companyId, transaction.getCurrency().getId(), branchId);
                if (latestRateOpt.isPresent()) {
                    ExchangeRate latest = latestRateOpt.get();
                    // A tranzakció típusától és összegsávjától függően válasszuk az aktuális árfolyamot
                    BigDecimal latestApplicableRate = transaction.getTransactionType() == TransactionType.BUY
                            ? latest.getBuyRateForAmount(transaction.getHufAmount())
                            : latest.getSellRateForAmount(transaction.getHufAmount());
                    if (latestApplicableRate != null && latestApplicableRate.compareTo(BigDecimal.ZERO) > 0) {
                        currentRate = latestApplicableRate;
                        rateDifference = currentRate.subtract(originalRate);
                        rateChanged = rateDifference.abs().compareTo(BigDecimal.valueOf(0.01)) > 0;
                    }
                }
            } catch (Exception e) {
                log.warn("Árfolyam-eltérés ellenőrzés sikertelen: {}", e.getMessage());
            }
        }

        return StornoCheckResultDto.builder()
                .requiresApproval(requiresApproval)
                .dailyStornoCount(dailyCountBranch)
                .transactionId(String.valueOf(transactionId))
                .transactionNumber(transaction.getReceiptNumber())
                .message(message)
                .originalRate(originalRate)
                .currentRate(currentRate)
                .rateDifference(rateDifference)
                .rateChanged(rateChanged)
                .build();
    }

    /**
     * Sztornó jóváhagyás kérése
     */
    public StornoApprovalDto requestApproval(Long transactionId, Long workerId, String reason) {
        Transaction transaction = transactionRepository.findById(transactionId)
                .orElseThrow(() -> new ResourceNotFoundException("Tranzakció nem található: " + transactionId));

        Worker worker = workerRepository.findById(workerId)
                .orElseThrow(() -> new ResourceNotFoundException("Pénztáros nem található: " + workerId));

        UUID branchId = SecurityUtils.getCurrentBranchId();

        // IDOR védelem: csak saját iroda tranzakciója sztornózható
        if (!transaction.getBranch().getId().equals(branchId)) {
            throw new ValidationException("Nincs jogosultság más iroda tranzakciójához!");
        }
        Branch branch = branchRepository.findById(branchId)
                .orElseThrow(() -> new ResourceNotFoundException("Iroda nem található: " + branchId));

        // Audit #2 (2026-05-31): korabbi napra NINCS ertelme jovahagyast kerni — az execute SOHA
        // nem hajtja vegre. Ne hozzunk letre elarvult jovahagyas-kerest (a precheck mar tiltja, de
        // a kozvetlen API-hivas ellen is vedunk).
        if (!transaction.getTransactionDate().equals(LocalDate.now())) {
            throw new ValidationException(
                "Korabbi napi tranzakciora nem kerheto sztorno-jovahagyas — csak az aznapi sztornozhato. Tranzakcio datuma: "
                + transaction.getTransactionDate());
        }

        int dailyCount = (int) transactionRepository.countReversalsByBranchAndDate(SecurityUtils.getCurrentCompanyId(), branchId, LocalDate.now());

        // Codex P2 (2026-05-31, #944 review): a napi sztorno-plafon (DAILY_STORNO_LIMIT_BRANCH)
        // felett a sztorno supervisorral SEM hajthato vegre (executeReversal abszolut tilt). Ezert
        // jovahagyast kerni ertelmetlen — ne hozzunk letre elarvult jovahagyas-kerest (a precheck
        // mar tiltja, de a kozvetlen API-hivas ellen is vedunk, a korabbi-napi aggal egyezoen).
        if (dailyCount >= DAILY_STORNO_LIMIT_BRANCH) {
            throw new ValidationException(String.format(
                "Napi sztorno plafon (%d) elerve — ma tobb sztorno nem lehetseges, supervisori jovahagyassal sem!",
                DAILY_STORNO_LIMIT_BRANCH));
        }

        StornoApproval approval = StornoApproval.builder()
                .transaction(transaction)
                .worker(worker)
                .branch(branch)
                .dailyStornoCount(dailyCount)
                .requestReason(reason)
                .build();

        StornoApproval saved = stornoApprovalRepository.save(approval);
        log.info("Sztornó jóváhagyás kérve: tranzakció={}, pénztáros={}", transactionId, workerId);

        // G12: aktív értesítés az iroda dolgozóinak (köztük a jóváhagyásra jogosult
        // supervisoroknak) — eddig csak log volt, a kérés némán elveszhetett.
        // AFTER_COMMIT eseménnyel küldjük (Copilot/Sourcery #770/#772): így az értesítés
        // (DB/e-mail) hibája SEMMIKÉPP nem görgetheti vissza a már mentett jóváhagyás-kérést
        // (a try-catch önmagában nem véd a tranzakció rollback-only jelölése ellen).
        String notifMessage = String.format(
                "Sztornó jóváhagyás kérés — bizonylat: %s, pénztáros: %s, ok: %s (mai sztornó: %d)",
                transaction.getReceiptNumber(), worker.getName(), reason, dailyCount);
        eventPublisher.publishEvent(
                new StornoApprovalNotificationEvent(branchId, "Sztornó jóváhagyás kérés", notifMessage));

        return toApprovalDto(saved);
    }

    /**
     * Sztornó jóváhagyása/elutasítása supervisor által
     */
    public StornoApprovalDto approve(UUID approvalId, Long approvedByWorkerId, boolean approved, String reason) {
        StornoApproval approval = stornoApprovalRepository.findById(approvalId)
                .orElseThrow(() -> new ResourceNotFoundException("Jóváhagyási kérés nem található: " + approvalId));

        // IDOR védelem: csak saját iroda jóváhagyási kérése kezelhető
        UUID branchId = SecurityUtils.getCurrentBranchId();
        if (!approval.getBranch().getId().equals(branchId)) {
            throw new ValidationException("Nincs jogosultság más iroda jóváhagyási kéréséhez!");
        }

        Worker approver = workerRepository.findById(approvedByWorkerId)
                .orElseThrow(() -> new ResourceNotFoundException("Jóváhagyó pénztáros nem található: " + approvedByWorkerId));

        approval.setApprovedByWorker(approver);
        approval.setApprovedAt(LocalDateTime.now());

        // M-3: ApprovalStatus beállítása
        String statusCode = approved ? "APPROVED" : "REJECTED";
        approval.setApprovalStatus(dictionaryRepository
                .findByCategoryAndCode("STORNO_APPROVAL_STATUS", statusCode)
                .orElseThrow(() -> new IllegalStateException(
                        "Hiányzó dictionary bejegyzés: STORNO_APPROVAL_STATUS/" + statusCode)));

        if (!approved) {
            approval.setRejectionReason(reason);
        }

        StornoApproval saved = stornoApprovalRepository.save(approval);
        log.info("Sztornó jóváhagyás {}: approvalId={}, által={}", approved ? "ELFOGADVA" : "ELUTASÍTVA", approvalId, approvedByWorkerId);

        return toApprovalDto(saved);
    }

    /**
     * Sztornó végrehajtása
     */
    public Transaction executeStorno(StornoRequestDto request, Long workerId) {
        Long transactionId = Long.parseLong(request.getTransactionId());

        Transaction original = transactionRepository.findById(transactionId)
                .orElseThrow(() -> new ResourceNotFoundException("Tranzakció nem található: " + transactionId));

        // IDOR védelem: csak saját iroda tranzakciója sztornózható
        UUID branchId = SecurityUtils.getCurrentBranchId();
        if (!original.getBranch().getId().equals(branchId)) {
            throw new ValidationException("Nincs jogosultság más iroda tranzakciójához!");
        }

        if (original.isReversed()) {
            throw new ValidationException("Ez a tranzakció már sztornózva lett!");
        }
        if (original.isReversal()) {
            throw new ValidationException("Sztornó tranzakció nem sztornózható!");
        }

        // Codex P2 (2026-05-31, #944 review): a napi sztornó-plafon 3. (limit-1) sztornójához
        // supervisori jóváhagyás kell. A dokumentált flow: a pénztáros jóváhagyást kér, a supervisor
        // megadja (StornoApproval → APPROVED), majd a PÉNZTÁROS hajtja végre az approvalId-vel. A
        // jóváhagyást ITT, SZERVER-OLDALON verifikáljuk (a kliens-küldte flaget sosem hisszük el), és
        // csak verifikáltan adjuk tovább supervisorApproved=true-ként az executeReversal kapujához.
        boolean supervisorApproved = isValidGrantedApproval(request.getApprovalId(), transactionId, branchId);

        // Sztornó végrehajtás a TransactionService reversal metódusával
        TransactionService.ReversalRequest reversalRequest = TransactionService.ReversalRequest.builder()
                .originalTransactionId(transactionId)
                .reason(request.getReason())
                .approvedBy(String.valueOf(workerId))
                .useCurrentRate(request.getUseCurrentRate())
                .customExchangeRate(request.getCustomExchangeRate())
                .supervisorApproved(supervisorApproved)
                .build();

        Transaction reversal = transactionService.executeReversal(reversalRequest);
        log.info("Sztornó végrehajtva: eredeti={}, sztornó={}", original.getReceiptNumber(), reversal.getReceiptNumber());

        return reversal;
    }

    /**
     * Codex P2 (2026-05-31, #944 review): a kliens-küldte {@code approvalId} SZERVER-OLDALI
     * verifikációja — csak akkor jogosít a (limit-1)-edik sztornóra, ha a jóváhagyás:
     *   (1) létezik, (2) PONTOSAN ehhez a tranzakcióhoz tartozik (nem hordozható át másik tranzakcióra),
     *   (3) ehhez az irodához tartozik (IDOR), (4) státusza APPROVED (PENDING/REJECTED nem ad jogot).
     * Bármelyik feltétel sérül vagy az id hiányzik/hibás formátumú → {@code false} (a végrehajtó
     * ekkor csak supervisorként mehet tovább). A kliens-flaget SOHA nem hisszük el.
     */
    private boolean isValidGrantedApproval(String approvalIdStr, Long transactionId, UUID branchId) {
        if (approvalIdStr == null || approvalIdStr.isBlank()) {
            return false;
        }
        final UUID approvalId;
        try {
            approvalId = UUID.fromString(approvalIdStr);
        } catch (IllegalArgumentException e) {
            log.warn("Érvénytelen approvalId formátum a sztornó-végrehajtáskor: {}", approvalIdStr);
            return false;
        }
        return stornoApprovalRepository.findById(approvalId)
                .filter(a -> a.getTransaction() != null && transactionId.equals(a.getTransaction().getId()))
                .filter(a -> a.getBranch() != null && branchId.equals(a.getBranch().getId()))
                .filter(a -> a.getApprovalStatus() != null && "APPROVED".equals(a.getApprovalStatus().getCode()))
                .isPresent();
    }

    /**
     * POS sztornó végrehajtása
     */
    public Transaction executePosStorno(String posTransactionId, Long workerId, String reason) {
        Long transactionId = Long.parseLong(posTransactionId);

        // IDOR védelem: csak saját iroda tranzakcióját lehet POS-sztornózni
        Transaction original = transactionRepository.findById(transactionId)
                .orElseThrow(() -> new ResourceNotFoundException("Tranzakció nem található: " + transactionId));
        UUID branchId = SecurityUtils.getCurrentBranchId();
        if (!original.getBranch().getId().equals(branchId)) {
            throw new ValidationException("Nincs jogosultság más iroda tranzakciójához!");
        }

        TransactionService.ReversalRequest reversalRequest = TransactionService.ReversalRequest.builder()
                .originalTransactionId(transactionId)
                .reason(reason)
                .approvedBy(String.valueOf(workerId))
                .build();

        Transaction reversal = transactionService.executeReversal(reversalRequest);
        log.info("POS sztornó végrehajtva: eredeti={}, sztornó={}", posTransactionId, reversal.getReceiptNumber());

        return reversal;
    }

    // ============ OTP TERMINÁL INTEGRÁCIÓ (Legacy: STORNO.DLL + OTP terminál) ============

    /**
     * OTP terminál sztornó végrehajtása.
     * Legacy: VTEMP.OTPFUNCTYPE=100 → OtpTermStorno
     *
     * Ha a tranzakció bankkártyás volt (PaymentMethod.CARD),
     * az OTP terminálon is sztornózni kell.
     * A terminál POS referencia szám alapján azonosítja a tranzakciót.
     */
    public Transaction executeOtpTerminalStorno(Long transactionId, Long workerId, String reason) {
        Transaction original = transactionRepository.findById(transactionId)
                .orElseThrow(() -> new ResourceNotFoundException("Tranzakció nem található: " + transactionId));

        UUID branchId = SecurityUtils.getCurrentBranchId();
        if (!original.getBranch().getId().equals(branchId)) {
            throw new ValidationException("Nincs jogosultság más iroda tranzakciójához!");
        }

        if (original.isReversed()) {
            throw new ValidationException("Ez a tranzakció már sztornózva lett!");
        }

        // Ellenőrzés: bankkártyás tranzakció volt-e
        if (original.getPaymentMethod() != hu.puzzleir.valuta.entity.PaymentMethod.CARD) {
            throw new ValidationException("OTP terminál sztornó csak bankkártyás tranzakcióra alkalmazható!");
        }

        if (original.getPosAuthorizationCode() == null || original.getPosAuthorizationCode().isBlank()) {
            throw new ValidationException("Hiányzó POS autorizációs kód — OTP terminál sztornó nem végrehajtható!");
        }

        // Napi sztornó számláló ellenőrzés (Legacy: NAPISTORNO > 2 → supervisor)
        int dailyCount = (int) transactionRepository.countReversalsByBranchAndDate(SecurityUtils.getCurrentCompanyId(), branchId, LocalDate.now());
        if (dailyCount >= DAILY_STORNO_LIMIT_BRANCH) {
            log.warn("OTP terminál sztornó: napi limit ({}) elérve, supervisor jóváhagyás szükséges!",
                    DAILY_STORNO_LIMIT_BRANCH);
            throw new ValidationException(
                String.format("Napi OTP sztornó limit (%d) elérve — supervisor jóváhagyás szükséges!",
                    DAILY_STORNO_LIMIT_BRANCH));
        }

        // Sztornó végrehajtás
        TransactionService.ReversalRequest reversalRequest = TransactionService.ReversalRequest.builder()
                .originalTransactionId(transactionId)
                .reason("OTP_TERMINAL_STORNO: " + reason)
                .approvedBy(String.valueOf(workerId))
                .build();

        Transaction reversal = transactionService.executeReversal(reversalRequest);

        // POS terminál adatok másolása a sztornó tranzakcióra
        reversal.setPosAuthorizationCode(original.getPosAuthorizationCode());
        reversal.setPosReferenceNumber(original.getPosReferenceNumber());
        reversal.setPosTerminalId(original.getPosTerminalId());
        reversal.setPaymentMethod(hu.puzzleir.valuta.entity.PaymentMethod.CARD);
        transactionRepository.save(reversal);

        log.info("OTP terminál sztornó végrehajtva: eredeti={}, sztornó={}, POS ref={}",
                original.getReceiptNumber(), reversal.getReceiptNumber(), original.getPosReferenceNumber());

        return reversal;
    }

    /**
     * OTP áruvisszavét (árustornó).
     * Legacy: VTEMP.OTPFUNCTYPE=4 → OtpAruvisszavet
     *
     * Különbség a normál OTP sztornóhoz:
     * - Ha refundAmount == null VAGY refundAmount == originalHufAmount → teljes sztornó (backward compat)
     * - Ha 0 < refundAmount < originalHufAmount → részleges visszatérítés (PARTIAL_REFUND)
     *
     * P3-15 fix: a régi implementáció mindig executeReversal()-t hívott, figyelmen kívül hagyva
     * a refundAmount paramétert részleges esetben.
     */
    public Transaction executeOtpRefund(Long transactionId, Long workerId,
                                         BigDecimal refundAmount, String reason) {
        Transaction original = transactionRepository.findById(transactionId)
                .orElseThrow(() -> new ResourceNotFoundException("Tranzakció nem található: " + transactionId));

        UUID branchId = SecurityUtils.getCurrentBranchId();
        if (!original.getBranch().getId().equals(branchId)) {
            throw new ValidationException("Nincs jogosultság más iroda tranzakciójához!");
        }

        if (original.getPaymentMethod() != hu.puzzleir.valuta.entity.PaymentMethod.CARD) {
            throw new ValidationException("OTP áruvisszavét csak bankkártyás tranzakcióra alkalmazható!");
        }

        // 0 összeg nem megengedett
        if (refundAmount != null && refundAmount.compareTo(BigDecimal.ZERO) <= 0) {
            throw new ValidationException("Visszatérítés összege pozitív kell legyen!");
        }

        // Refund összeg nem haladhatja meg az eredetit
        if (refundAmount != null && refundAmount.compareTo(original.getHufAmount()) > 0) {
            throw new ValidationException(
                String.format("Visszatérítés összege (%s Ft) nem haladhatja meg az eredeti összeget (%s Ft)!",
                    refundAmount.toPlainString(), original.getHufAmount().toPlainString()));
        }

        boolean isPartial = refundAmount != null
                && refundAmount.compareTo(original.getHufAmount()) < 0;

        if (isPartial) {
            // Részleges visszatérítés: PARTIAL_REFUND tranzakció, kassza csak részleges korrekcióval,
            // az eredeti tranzakció NEM kerül REVERSED státuszba
            TransactionService.PartialRefundRequest partialRequest = TransactionService.PartialRefundRequest.builder()
                    .originalTransactionId(transactionId)
                    .refundHufAmount(refundAmount)
                    .reason("OTP_ARUVISSZAVET_RESZLEGES: " + reason)
                    .approvedBy(String.valueOf(workerId))
                    .build();

            Transaction partialRefundTx = transactionService.executePartialRefund(partialRequest);

            partialRefundTx.setPosAuthorizationCode(original.getPosAuthorizationCode());
            partialRefundTx.setPosReferenceNumber(original.getPosReferenceNumber());
            partialRefundTx.setPosTerminalId(original.getPosTerminalId());
            partialRefundTx.setPaymentMethod(hu.puzzleir.valuta.entity.PaymentMethod.CARD);
            transactionRepository.save(partialRefundTx);

            log.info("OTP részleges áruvisszavét végrehajtva: eredeti={}, visszatérítés={}, összeg={} Ft",
                    original.getReceiptNumber(), partialRefundTx.getReceiptNumber(), refundAmount.toPlainString());

            return partialRefundTx;
        } else {
            // Teljes sztornó (refundAmount == null VAGY refundAmount == originalHufAmount)
            TransactionService.ReversalRequest reversalRequest = TransactionService.ReversalRequest.builder()
                    .originalTransactionId(transactionId)
                    .reason("OTP_ARUVISSZAVET: " + reason)
                    .approvedBy(String.valueOf(workerId))
                    .build();

            Transaction reversal = transactionService.executeReversal(reversalRequest);

            reversal.setPosAuthorizationCode(original.getPosAuthorizationCode());
            reversal.setPosReferenceNumber(original.getPosReferenceNumber());
            reversal.setPosTerminalId(original.getPosTerminalId());
            reversal.setPaymentMethod(hu.puzzleir.valuta.entity.PaymentMethod.CARD);
            transactionRepository.save(reversal);

            log.info("OTP teljes áruvisszavét végrehajtva: eredeti={}, sztornó={}, összeg={}",
                    original.getReceiptNumber(), reversal.getReceiptNumber(),
                    refundAmount != null ? refundAmount.toPlainString() : "teljes");

            return reversal;
        }
    }

    /**
     * Supervisor jóváhagyás szükséges-e OTP sztornóhoz.
     * Legacy: NAPISTORNO > 2 → supervisor jelszó kell
     */
    @Transactional(readOnly = true)
    public boolean requiresOtpSupervisor(UUID branchId) {
        int dailyCount = (int) transactionRepository.countReversalsByBranchAndDate(SecurityUtils.getCurrentCompanyId(), branchId, LocalDate.now());
        return dailyCount >= DAILY_STORNO_LIMIT_BRANCH;
    }

    // ============ HELPER ============

    private StornoApprovalDto toApprovalDto(StornoApproval entity) {
        return StornoApprovalDto.builder()
                .id(entity.getId().toString())
                .transactionId(String.valueOf(entity.getTransaction().getId()))
                .workerId(String.valueOf(entity.getWorker().getId()))
                .branchId(entity.getBranch().getId().toString())
                .dailyStornoCount(entity.getDailyStornoCount())
                .approvalStatusDid(entity.getApprovalStatus() != null ? entity.getApprovalStatus().getId().toString() : null)
                // #868 (Codex P2): a frontend a KÓD-ot hasonlítja ('APPROVED'/'REJECTED'), nem az UUID-t.
                .approvalStatusCode(entity.getApprovalStatus() != null ? entity.getApprovalStatus().getCode() : null)
                .requestReason(entity.getRequestReason())
                .rejectionReason(entity.getRejectionReason())
                .approvedByWorkerId(entity.getApprovedByWorker() != null ? String.valueOf(entity.getApprovedByWorker().getId()) : null)
                .approvedAt(entity.getApprovedAt())
                .build();
    }

    /**
     * G12: sztornó jóváhagyás-kérés értesítési esemény (AFTER_COMMIT-on dolgozzuk fel).
     */
    public record StornoApprovalNotificationEvent(UUID branchId, String title, String message) {}

    /**
     * G12: az értesítést a jóváhagyás-kérés tranzakciójának COMMITJA UTÁN küldjük, külön
     * (REQUIRES_NEW) tranzakcióban — így az értesítés (DB/e-mail) hibája nem görgetheti
     * vissza a már mentett jóváhagyás-kérést (Copilot/Sourcery #770/#772). A hibát teljes
     * stacktrace-szel naplózzuk, de elnyeljük (best-effort).
     */
    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void onStornoApprovalNotification(StornoApprovalNotificationEvent ev) {
        try {
            notificationService.sendToBranch(ev.branchId(), ev.title(), ev.message());
        } catch (Exception e) {
            log.warn("Sztornó jóváhagyás-kérés értesítés sikertelen (a kérés mentve maradt): {}",
                    e.getMessage(), e);
        }
    }
}
