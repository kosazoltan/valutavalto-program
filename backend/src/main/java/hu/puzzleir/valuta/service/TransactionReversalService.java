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
import hu.puzzleir.valuta.util.CashLockOrdering;
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
    private final WacService wacService;
    private final CustomerRepository customerRepository;

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

        // Validaciok — FKH-028 5. kor (Codex HIGH-1): a tulajdonjog-guard fut ELOSZOR,
        // kozvetlenul a betoltes utan, MINDEN allapot-ellenorzes (isReversed, isReversal,
        // V370-marker) ELOTT. Igy idegen iroda hivoja fele SEMMILYEN allapot-informacio
        // (sztornozva-e, V370-jelolt-e) nem szivarog: minden idegen kiserlet ugyanazt a
        // hibat kapja.
        if (!original.getBranch().getId().equals(branchId)) {
            throw new ValidationException("Csak sajat iroda tranzakciojat lehet sztornozni!");
        }
        if (original.isReversed()) {
            throw new ValidationException("Ez a tranzakcio mar sztornozva lett!");
        }
        if (original.isReversal()) {
            throw new ValidationException("Sztorno tranzakcio nem sztornozhatoh!");
        }
        // FKH-028 (V370-guard): a duplikátum-korrekcióval rendezett tranzakció nem sztornózható —
        // a V370 már visszaírta az egyenleget, az app-sztornó ezzel EGYÜTT dupla jóváírás lenne.
        if (original.getNotes() != null && original.getNotes()
                .contains(hu.puzzleir.valuta.exception.ValidationMessages.FKH028_V370_CORRECTION_MARKER)) {
            throw new hu.puzzleir.valuta.exception.ConflictException(
                    "VV-TX-005: Ezt a bizonylatot a V370 adat-korrekció már rendezte (duplikált tétel)"
                            + " — sztornó nem indítható rá: " + original.getReceiptNumber());
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

        // FS-2: kézi HIGH kockázati besorolású ügyfél sztornója engedélyköteles (fail-closed,
        // mellékhatások — lock/POS/könyvelés — ELŐTT). A supervisorApproved szerver-oldalon
        // verifikált (StornoService), lásd ReversalRequest javadoc.
        enforceHighRiskCustomerGate(original, companyId, request);

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
        // PESSIMISTIC_WRITE-tal lockolja (SELECT ... FOR UPDATE) a plafon-ellenorzes es barmilyen
        // mellekhatas (POS-sztorno, bizonylatszam) ELOTT: a parhuzamos sztorno a lock mogott sorba
        // all, a count olvasasa+novelese ugyanabban a write-tranzakcioban szerializalodik.
        //
        // LOCK-ORDERING (Codex P1, #944 round-3 review — daily_session <-> cash_balance deadlock-megelozes):
        // a normal vetel/eladas (TransactionService.executeBuy/executeSell) a cash_balance sorokat MAR a
        // daily_session-iras (updateSessionStats, a tranzakcio vegen) ELOTT lockolja -> reszsorrend
        // cash_balance -> daily_session. Ha a sztorno a daily_session-t a cash_balance ELOTT lockolna,
        // az ELLENTETES reszsorrend (daily_session -> cash_balance) egy parhuzamos normal tranzakcioval
        // keresztezve adatbazis-deadlockot okozhatna. Ezert a daily_session lock (lenti
        // getDailyReversalCountForUpdate) ELOTT ELO-LOCKOLJUK a majdan modositando cash_balance sorokat,
        // igy a sztorno reszsorrendje is cash_balance -> daily_session. A cap-check igy is a
        // POS/mellekhatasok ELOTT marad (nincs POS-then-rollback).
        //
        // CASH-VS-CASH LOCK-ORDERING (a fenti "kulon fokuszalt PR" itt megvalosul): a sztorno a
        // modositando cash_balance sorokat (deviza + HUF) GLOBALISAN egyseges, NOVEKVO currencyId
        // sorrendben elo-lockolja — egyezoen a BUY/SELL/konverzio/reszleges-visszateres aggal. Igy
        // megszunik a BUY (HUF-first) <-> sztorno (korabban currency-first) AB-BA deadlock-kockazat.
        // (A cash-lockok a lenti daily_session lock ELOTT vannak -> reszsorrend cash_balance ->
        // daily_session is megmarad.) A lenti updateCashBalance ugyanezeket a sorokat mar lockoltan
        // kapja (no-op re-lock). Lasd: CashLockOrdering.
        Long reversalCurrencyId = original.getCurrency().getId();
        CashLockOrdering.lockInAscendingCurrencyOrder(branchId, helper::lockCashBalance,
                reversalCurrencyId, helper.getHufCurrencyId());

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

        // Kassza visszaallitasa (eredeti tranzakcio ellentete). A cash_balance sorok (reversalCurrencyId,
        // HUF) MAR lockoltak (fentebb, a daily_session lock elott elo-lockoltuk) — ez no-op re-lock + mutacio.
        Long currencyId = reversalCurrencyId;
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
        } else if (original.getTransactionType() == TransactionType.TRANSFER_OUT) {
            // FKH-028: eredeti kimeno atadas visszavonasa — a valuta VISSZA a kasszaba.
            // A transfer-tranzakcio EGYLABU keszletmozgas (nincs HUF-ellenlaba), ezert a
            // BUY/SELL agakkal ellentetben itt HUF-mozgas nem tortenhet.
            helper.updateCashBalance(branchId, currencyId, original.getCurrencyAmount(), true);
        } else if (original.getTransactionType() == TransactionType.TRANSFER_IN) {
            // FKH-028: eredeti bejovo atvetel visszavonasa — keszlet-validacio utan a valuta KI.
            // HUF-ellenlab itt sincs (egylabu mozgas).
            helper.validateCurrencyStock(branchId, currencyId, original.getCurrencyAmount());
            helper.updateCashBalance(branchId, currencyId, original.getCurrencyAmount().negate(), false);
        }
        // FKH-028 follow-up (tudatosan scope-on kivul): a reszleges-visszavaltas utvonala
        // (executePartialRefund BUY/SELL aga lentebb) TRANSFER-tipusra ugyanigy nem mozgat
        // kasszat — kulon korben rendezendo.

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

        // A6 / b8 FR-8: ha az eredeti egy ELADÁS volt, a teljes sztornó a profit_log-ban is
        // ellensúlyozza a korábban rögzített realizált hasznot (flag-gated, commit után, best-effort).
        if (original.getTransactionType() == TransactionType.SELL) {
            final Long origId = original.getId();
            final Long compensationId = savedReversal.getId();
            final BigDecimal origQty = original.getCurrencyAmount();
            TransactionAfterCommit.run(
                    () -> wacService.recordReversalCompensationIfEnabled(origId, compensationId, origQty, origQty),
                    "WAC sztornó kompenzáció tx=" + origId);
        }

        return savedReversal;
    }

    private void enforceHighRiskCustomerGate(Transaction original, UUID companyId,
            ReversalRequest request) {
        String customerCode = original.getCustomerId();
        if (customerCode == null || customerCode.isBlank()) {
            return; // nincs ügyfél-kötés — kompat
        }
        Customer master = customerRepository
                .findByCustomerCodeAndCompanyId(customerCode, companyId).orElse(null);
        if (master == null || master.getRiskRating() != CustomerRiskRating.HIGH) {
            return;
        }
        if (SecurityUtils.isSupervisorOrAbove() || request.isSupervisorApproved()) {
            return;
        }
        throw new ValidationException("Magas kockázati besorolású (MAGAS) ügyfél tranzakciójának "
                + "sztornójához supervisori jóváhagyás szükséges!");
    }

    /**
     * Reszleges visszaterites vegrehajtasa (csak valuta vasarlasnal).
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

        // CASH-FIRST LOCK-ORDERING (Codex P2, #951 -> #952): a cash_balance sorokat a bizonylatszam-
        // generalas (ReceiptSequenceService per-branch PESSIMISTIC lock) ELOTT lockoljuk, igy minden
        // penzmozgato ut UGYANABBAN a sorrendben (cash -> receipt) szerez lockot (BUY/SELL/sztorno is).
        // Kulonben egy parhuzamos transfer/sztorno es ez a refund cash<->receipt_sequence AB-BA
        // deadlockot okozna. Egyben NOVEKVO currencyId (cash<->cash deadlock-megelozes). Lasd: CashLockOrdering.
        Long currencyId = original.getCurrency().getId();
        CashLockOrdering.lockInAscendingCurrencyOrder(branchId, helper::lockCashBalance,
                currencyId, helper.getHufCurrencyId());

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

        // Kassza korrekcio: csak a visszateritett osszeggel (a cash_balance sorok mar lockoltak, lasd fent)
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

        // A6 / b8 FR-8: ELADÁS részleges visszatérítésekor a profit_log-ban a visszatérített deviza
        // ARÁNYÁBAN ellensúlyozzuk a realizált hasznot (flag-gated, commit után, best-effort).
        if (original.getTransactionType() == TransactionType.SELL) {
            final Long origId = original.getId();
            final Long compensationId = saved.getId();
            final BigDecimal refundedQty = refundCurrency;
            final BigDecimal origQty = original.getCurrencyAmount();
            TransactionAfterCommit.run(
                    () -> wacService.recordReversalCompensationIfEnabled(origId, compensationId, refundedQty, origQty),
                    "WAC részleges visszatérítés kompenzáció tx=" + origId);
        }

        return saved;
    }
}
