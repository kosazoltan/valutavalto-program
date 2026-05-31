package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.*;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.dto.pos.PosTransactionResult;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import hu.puzzleir.valuta.service.TransactionService.ReversalRequest;
import hu.puzzleir.valuta.service.TransactionService.PartialRefundRequest;
import hu.puzzleir.valuta.util.HungarianRounding;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.UUID;

/**
 * Sztorno es reszleges visszaterites tranzakciok kezelese.
 */
@Service
@RequiredArgsConstructor
@Transactional(rollbackFor = Exception.class)
@Slf4j
public class TransactionReversalService {

    private final TransactionRepository transactionRepository;
    private final CompanyRepository companyRepository;
    private final BranchRepository branchRepository;
    private final WorkerRepository workerRepository;
    private final ReceiptSequenceService receiptSequenceService;
    private final DailySessionService dailySessionService;
    private final PosTerminalService posTerminalService;
    private final AmlService amlService;
    private final CashBalanceRepository cashBalanceRepository;
    private final TransactionOperationHelper helper;
    private final AuditLogService auditLogService;

    /**
     * Sztorno vegrehajtasa.
     */
    public Transaction executeReversal(ReversalRequest request) {
        helper.validateOpenSession();

        UUID companyId = SecurityUtils.getCurrentCompanyId();
        UUID branchId = SecurityUtils.getCurrentBranchId();
        Long workerId = SecurityUtils.getCurrentWorkerId();

        // Eredeti tranzakcio lekerese
        Transaction original = transactionRepository.findByIdForUpdate(request.getOriginalTransactionId())
                .orElseThrow(() -> new ResourceNotFoundException("Eredeti tranzakcio nem talalhato"));

        // Validaciok
        if (original.isReversed()) {
            throw new ValidationException("Ez a tranzakcio mar sztornozva lett!");
        }
        if (original.isReversal()) {
            throw new ValidationException("Sztorno tranzakcio nem sztornozhatoh!");
        }
        if (!original.getBranch().getId().equals(branchId)) {
            throw new ValidationException("Csak sajat iroda tranzakciojat lehet sztornozni!");
        }
        // Audit #2 (2026-05-31, user-direktiva) — DATUM-szabaly: a korabbi napi tranzakcio
        // VISSZAMENOLEG SOHA nem sztornozhato (sem supervisorral). Kulonben a lentebbi
        // original.setStatus(REVERSED) csendben csokkentene a korabbi nap forgalmat (a napi
        // forgalom-osszegzes COMPLETED-re szur), a kompenzacio pedig a MAI napon konyvelodne
        // -> a korabbi nap forgalma utolag, eszrevetlenul megvaltozna.
        // FONTOS: ez CSAK a korabbi-napi (P2.7, 2026-05-17) supervisor-override-ot szunteti meg;
        // az AZNAPI supervisor-funkcio a napi plafonnal (lent) valtozatlanul megmarad.
        if (!original.getTransactionDate().equals(LocalDate.now())) {
            throw new ValidationException(
                "Csak az aznapi tranzakcio sztornozhato — korabbi nap visszamenoleg nem sztornozhato. Tranzakcio datuma: "
                + original.getTransactionDate());
        }

        // Audit #2 (2026-05-31, user-direktiva) — AZNAPI DARABSZAM-szabaly: aznap MAXIMUM
        // `limit` (alapertelmezetten 3) sztorno lehetseges. Lebontva:
        //   - az elso (limit-1) sztorno supervisori jovahagyas nelkul,
        //   - a `limit`-edik (pl. 3.) sztorno CSAK supervisori jovahagyassal,
        //   - a plafon felett (pl. 4.+) SEMMIKEPP, supervisorral sem.
        // Korabban a plafon felett supervisorral KORLATLAN sztorno volt lehetseges (hibas).
        //
        // Codex P1 (2026-05-31, #944 review) — CONCURRENCY: a plafon-ellenorzes a napi
        // sztorno-szamlalot (DailySession.reversalCount) olvassa, a noveles viszont a tranzakcio
        // VEGEN tortenik (updateSessionStats). Lock-mentes olvasassal ket parhuzamos sztorno
        // ugyanazt a count-ot latta -> mindketto atment a >= limit ellenorzesen -> a nap a max-3
        // plafon FOLE kerulhetett. A getDailyReversalCountForUpdate() a daily_session SORAT
        // PESSIMISTIC_WRITE-tal lockolja (SELECT ... FOR UPDATE) MAR ITT, a plafon-ellenorzes es
        // barmilyen mellekhatas (POS-sztorno, bizonylatszam) ELOTT: a parhuzamos sztorno a lock
        // mogott sorba all, es a count olvasasa+novelese ugyanabban a write-tranzakcioban
        // szerializalodik. (A lock-mentes getDailyReversalCount() csak megjelenitesre marad.)
        //
        // LOCK-ORDERING KONVENCIO (deadlock-megelozes, self-review P2): ez a flow MINDIG ebben a
        // sorrendben szerez sor-lockot — (1) transaction (findByIdForUpdate, fent), (2) daily_session
        // (itt), (3) cash_balance (lentebb, updateCashBalance). Uj sztorno-kozeli kod ezt a sorrendet
        // KOVESSE (a daily_session-t SOHA ne lockold a transaction sor ELOTT), kulonben lock-ordering
        // deadlock keletkezhet. A normal vetel/eladas a daily_session-t lock NELKUL irja -> nincs kor.
        int dailyReversals = dailySessionService.getDailyReversalCountForUpdate();
        int reversalLimit = helper.getDailyReversalLimit();
        if (dailyReversals >= reversalLimit) {
            throw new ValidationException(String.format(
                "Napi sztorno plafon (%d) elerve — ma tobb sztorno nem lehetseges, supervisori jovahagyassal sem!",
                reversalLimit));
        }
        // Codex P2 (2026-05-31, #944 review): a 3. (limit-1) sztorno kapuja akkor nyilik, ha a
        // VEGREHAJTO supervisor VAGY ha van ERVENYES, MEGADOTT jovahagyas (request.supervisorApproved,
        // amit a StornoService verifikalt szerver-oldalon az approvalId alapjan). Kulonben a dokumentalt
        // flow — penztaros jovahagyast ker, supervisor megadja, PENZTAROS hajtja vegre — hasznalhatatlan
        // lenne (a penztaros jovahagyassal is elbukna). A 4.+ abszolut plafon (fent) ettol fuggetlenul tilt.
        if (dailyReversals >= reversalLimit - 1
                && !SecurityUtils.isSupervisorOrAbove()
                && !request.isSupervisorApproved()) {
            throw new ValidationException(String.format(
                "A(z) %d. napi sztornohoz supervisori jovahagyas szukseges!", reversalLimit));
        }

        // Entitasok betoltese
        Company company = companyRepository.findById(companyId)
                .orElseThrow(() -> new ResourceNotFoundException("Company nem talalhato"));
        Branch branch = branchRepository.findById(branchId)
                .orElseThrow(() -> new ResourceNotFoundException("Iroda nem talalhato"));
        Worker worker = workerRepository.findById(workerId)
                .orElseThrow(() -> new ResourceNotFoundException("Penztaros nem talalhato"));

        // POS terminal sztorno - ha az eredeti tranzakcio bankkartyas volt
        String posAuthCode = null;
        String posRefNumber = null;
        if (original.getPaymentMethod() == PaymentMethod.CARD
                && original.getPosTerminalId() != null && !original.getPosTerminalId().isBlank()) {
            String originalPosRef = original.getPosReferenceNumber() != null
                    ? original.getPosReferenceNumber()
                    : original.getReceiptNumber();
            PosTransactionResult posResult = posTerminalService.initiateReversal(
                    originalPosRef, original.getPosTerminalId());
            if (!posResult.approved()) {
                throw new ValidationException("POS sztorno elutasitva: " + posResult.errorMessage());
            }
            posAuthCode = posResult.authorizationCode();
            posRefNumber = posResult.referenceNumber();
            log.info("POS sztorno elfogadva: auth={}, ref={}", posAuthCode, posRefNumber);
        }

        // Árfolyam-eltérés naplózása (Felmérés: sztorno.docx követelmény)
        // A tényleges árfolyam-összehasonlítást és figyelmeztetést a StornoService.checkStorno() végzi
        // a frontend oldalon — a felhasználó ott dönt hogy az eredeti vagy aktuális árfolyammal sztornóz.
        // Az executeReversal mindig az EREDETI árfolyammal sztornóz (biztonságos default).
        if (request.getUseCurrentRate() != null && request.getUseCurrentRate()) {
            log.info("Sztornó: useCurrentRate=true jelzés érkezett (eredeti rate: {}). " +
                     "A tényleges árfolyam-váltás implementálása a StornoService.checkStorno-ban történik.",
                     original.getExchangeRate());
        }

        // Bizonylat szam generalas - az EREDETI tpus szamlalojabol (NEM kuzon S prefix!)
        String receiptNumber = receiptSequenceService.generateReversalReceiptNumber(
                branchId, original.getTransactionType());

        // G2: aktuális/egyedi árfolyamú sztornó. Ha a pénztáros a sztornó-felületen egyedi
        // (aktuális) árfolyamot adott meg (customExchangeRate > 0), a sztornó ezzel könyvel;
        // a díjakat/kerekítést megőrizzük, csak az árfolyam-különbözettel igazítunk.
        // Alapértelmezés (nincs egyedi árfolyam) = eredeti árfolyam → változatlan viselkedés.
        BigDecimal originalRate = original.getExchangeRate();
        BigDecimal appliedRate = originalRate;
        if (request.getCustomExchangeRate() != null
                && request.getCustomExchangeRate().signum() > 0) {
            appliedRate = request.getCustomExchangeRate();
        }
        BigDecimal hufRateDiff = HungarianRounding.roundToFive(
                original.getCurrencyAmount().multiply(appliedRate.subtract(originalRate)));
        BigDecimal reversalHufAmount = original.getHufAmount().add(hufRateDiff);
        boolean rateAdjusted = appliedRate.compareTo(originalRate) != 0;
        String reversalNotes = "Sztorno: " + original.getReceiptNumber() + " - " + request.getReason()
                + (rateAdjusted
                    ? String.format(" [aktualis arfolyam: %s (eredeti: %s), arfolyam-kulonbozet: %s HUF]",
                        appliedRate.toPlainString(), originalRate.toPlainString(), hufRateDiff.toPlainString())
                    : "");

        // Sztorno tranzakcio letrehozasa (ellentetes ertekekkel)
        Transaction reversal = Transaction.builder()
                .company(company)
                .branch(branch)
                .worker(worker)
                .receiptNumber(receiptNumber)
                .transactionType(TransactionType.REVERSAL)
                .status(TransactionStatus.COMPLETED)
                .transactionDate(LocalDate.now())
                .transactionTime(LocalTime.now())
                .currency(original.getCurrency())
                .currencyAmount(original.getCurrencyAmount())
                .exchangeRate(appliedRate)
                .hufAmount(reversalHufAmount)
                .handlingFee(original.getHandlingFee())
                .discountPercent(original.getDiscountPercent())
                .discountAmount(original.getDiscountAmount())
                .roundingAmount(original.getRoundingAmount())
                .paymentMethod(original.getPaymentMethod())
                .posAuthorizationCode(posAuthCode)
                .posReferenceNumber(posRefNumber)
                .posTerminalId(original.getPosTerminalId())
                .originalTransaction(original)
                .reversalReason(request.getReason())
                .approvedBy(request.getApprovedBy())
                .customerName(original.getCustomerName())
                .customerDocumentNumber(original.getCustomerDocumentNumber())
                .notes(reversalNotes)
                .build();

        Transaction savedReversal = transactionRepository.save(reversal);
        helper.linkCameraEvidence(savedReversal);

        // Eredeti tranzakcio statuszanak frissitese
        original.setStatus(TransactionStatus.REVERSED);
        transactionRepository.save(original);

        // Kassza visszaallitasa (eredeti tranzakcio ellentete)
        Long currencyId = original.getCurrency().getId();
        if (original.getTransactionType() == TransactionType.BUY) {
            // Eredeti vetel visszavonasa: valuta -, HUF +
            // Stock validation: van-e eleg valuta a kasszaban a visszavethez
            helper.validateCurrencyStock(branchId, currencyId, original.getCurrencyAmount());
            helper.updateCashBalance(branchId, currencyId, original.getCurrencyAmount().negate(), false);
            helper.updateCashBalance(branchId, helper.getHufCurrencyId(), reversalHufAmount, true);
        } else if (original.getTransactionType() == TransactionType.SELL) {
            // Eredeti eladas visszavonasa: valuta +, HUF -
            helper.updateCashBalance(branchId, currencyId, original.getCurrencyAmount(), true);
            helper.updateCashBalance(branchId, helper.getHufCurrencyId(), reversalHufAmount.negate(), false);
        }

        // Napi statisztika frissitese
        dailySessionService.updateSessionStats(
            TransactionType.REVERSAL,
            original.getHufAmount(),
            BigDecimal.ZERO
        );

        // AML gonyolodes visszavonasa (ha van ugyfel ID)
        if (original.getCustomerId() != null && !original.getCustomerId().isBlank()) {
            amlService.reverseAccumulation(
                original.getCustomerId(),
                original.getHufAmount(),
                original.getTransactionDate().atTime(original.getTransactionTime())
            );
        }

        log.info("Sztorno tranzakcio: {} - eredeti: {} - ok: {}",
                receiptNumber, original.getReceiptNumber(), request.getReason());

        auditLogService.logWithDetails(
                "TRANSACTION_STORNO",
                "TRANSACTION",
                original.getId().toString(),
                workerId != null ? workerId.toString() : null,
                worker != null ? worker.getName() : null,
                branchId != null ? branchId.toString() : null,
                branch != null ? branch.getName() : null,
                original.getReceiptNumber() + " (" + original.getTransactionType() + ")",
                savedReversal.getReceiptNumber() + " (REVERSAL)",
                request.getReason(),
                null);

        // LazyInitializationException fix (2026-05-27 live-API teszt; vö. #857 átadás-lista):
        // a reversal.currency az original.getCurrency() LAZY proxyja. OSIV=false mellett a
        // controller (StornoController.executeStorno) transactionMapper.toDto() hívása a lezárt
        // session-on "Could not initialize proxy [Currency] - no session" 500-at dobott — A SZTORNÓ
        // VÉGREHAJTÁSA UTÁN (a reversal commitált, de a válasz 500 lett → dupla-sztornó kockázat).
        // A tranzakción belül inicializáljuk, hogy a mapping a session után is működjön.
        org.hibernate.Hibernate.initialize(savedReversal.getCurrency());

        return savedReversal;
    }

    /**
     * Reszleges visszaterites vegrehajtasa.
     */
    public Transaction executePartialRefund(PartialRefundRequest request) {
        helper.validateOpenSession();

        UUID companyId = SecurityUtils.getCurrentCompanyId();
        UUID branchId = SecurityUtils.getCurrentBranchId();
        Long workerId = SecurityUtils.getCurrentWorkerId();

        // Eredeti tranzakcio lekerese
        Transaction original = transactionRepository.findByIdForUpdate(request.getOriginalTransactionId())
                .orElseThrow(() -> new ResourceNotFoundException("Eredeti tranzakcio nem talalhato"));

        // Validaciok
        if (original.isReversed()) {
            throw new ValidationException("Ez a tranzakcio mar sztornozva lett - reszleges visszaterites nem lehetséges!");
        }
        if (original.isReversal() || original.isPartialRefund()) {
            throw new ValidationException("Visszavonasi tranzakcio nem vonhato vissza reszlegesen!");
        }
        if (!original.getBranch().getId().equals(branchId)) {
            throw new ValidationException("Csak sajat iroda tranzakciojat lehet visszateriteni!");
        }

        BigDecimal refundHuf = request.getRefundHufAmount();
        if (refundHuf == null || refundHuf.compareTo(BigDecimal.ZERO) <= 0) {
            throw new ValidationException("Visszaterites osszege pozitiv kell legyen!");
        }
        if (refundHuf.compareTo(original.getHufAmount()) > 0) {
            throw new ValidationException(
                String.format("Visszaterites osszege (%s Ft) nem haladhatja meg az eredeti osszeget (%s Ft)!",
                    refundHuf.toPlainString(), original.getHufAmount().toPlainString()));
        }

        // Aryonos valutaosszeg kiszamitasa, ha nem adtak meg
        BigDecimal refundCurrency = request.getRefundCurrencyAmount();
        if (refundCurrency == null || refundCurrency.compareTo(BigDecimal.ZERO) <= 0) {
            if (original.getHufAmount().compareTo(BigDecimal.ZERO) > 0) {
                // arany: refundCurrency = originalCurrency * (refundHuf / originalHuf)
                refundCurrency = original.getCurrencyAmount()
                        .multiply(refundHuf)
                        .divide(original.getHufAmount(), 4, RoundingMode.HALF_UP);
            } else {
                refundCurrency = BigDecimal.ZERO;
            }
        }

        // Entitasok betoltese
        Company company = companyRepository.findById(companyId)
                .orElseThrow(() -> new ResourceNotFoundException("Company nem talalhato"));
        Branch branch = branchRepository.findById(branchId)
                .orElseThrow(() -> new ResourceNotFoundException("Iroda nem talalhato"));
        Worker worker = workerRepository.findById(workerId)
                .orElseThrow(() -> new ResourceNotFoundException("Penztaros nem talalhato"));

        // Bizonylat szam generalas (az eredeti tpus szamlalojabol)
        String receiptNumber = receiptSequenceService.generateReversalReceiptNumber(
                branchId, original.getTransactionType());

        // Reszleges visszateritesi tranzakcio letrehozasa
        Transaction partialRefund = Transaction.builder()
                .company(company)
                .branch(branch)
                .worker(worker)
                .receiptNumber(receiptNumber)
                .transactionType(TransactionType.PARTIAL_REFUND)
                .status(TransactionStatus.COMPLETED)
                .transactionDate(LocalDate.now())
                .transactionTime(LocalTime.now())
                .currency(original.getCurrency())
                .currencyAmount(refundCurrency)
                .exchangeRate(original.getExchangeRate())
                .hufAmount(refundHuf)
                .paymentMethod(original.getPaymentMethod())
                .originalTransaction(original)
                .partialRefundAmount(refundHuf)
                .reversalReason(request.getReason())
                .approvedBy(request.getApprovedBy())
                .customerName(original.getCustomerName())
                .customerDocumentNumber(original.getCustomerDocumentNumber())
                .notes("Reszleges visszaterites: " + original.getReceiptNumber()
                        + " - " + refundHuf.toPlainString() + " Ft - " + request.getReason())
                .build();

        Transaction saved = transactionRepository.save(partialRefund);
        helper.linkCameraEvidence(saved);

        // Kassza korrekcio: csak a visszateritett osszeggel
        Long currencyId = original.getCurrency().getId();
        if (original.getTransactionType() == TransactionType.BUY) {
            // Eredeti vetel reszleges visszavonasa: valuta -, HUF +
            // Stock validation: van-e eleg valuta a kasszaban a reszleges visszavethez
            helper.validateCurrencyStock(branchId, currencyId, refundCurrency);
            helper.updateCashBalance(branchId, currencyId, refundCurrency.negate(), false);
            helper.updateCashBalance(branchId, helper.getHufCurrencyId(), refundHuf, true);
        } else if (original.getTransactionType() == TransactionType.SELL) {
            // Eredeti eladas reszleges visszavonasa: valuta +, HUF -
            helper.updateCashBalance(branchId, currencyId, refundCurrency, true);
            helper.updateCashBalance(branchId, helper.getHufCurrencyId(), refundHuf.negate(), false);
        }

        // Napi statisztika frissitese
        dailySessionService.updateSessionStats(
            TransactionType.PARTIAL_REFUND,
            refundHuf,
            BigDecimal.ZERO
        );

        log.info("Reszleges visszaterites: {} - eredeti: {} - osszeg: {} Ft - ok: {}",
                receiptNumber, original.getReceiptNumber(), refundHuf.toPlainString(), request.getReason());

        auditLogService.logWithDetails(
                "TRANSACTION_PARTIAL_REFUND",
                "TRANSACTION",
                original.getId().toString(),
                workerId != null ? workerId.toString() : null,
                worker != null ? worker.getName() : null,
                branchId != null ? branchId.toString() : null,
                branch != null ? branch.getName() : null,
                original.getReceiptNumber() + " (teljes: " + original.getHufAmount().toPlainString() + " Ft)",
                saved.getReceiptNumber() + " (visszateritett: " + refundHuf.toPlainString() + " Ft)",
                request.getReason(),
                null);

        // LazyInitializationException fix (lásd executeReversal): a partial-refund currency-je
        // is az original lazy proxyja → OSIV=false controller-mappingnél 500. Init a tranzakción belül.
        org.hibernate.Hibernate.initialize(saved.getCurrency());

        return saved;
    }
}
