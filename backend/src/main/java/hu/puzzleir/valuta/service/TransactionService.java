package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.dto.pos.PosResultStatus;
import hu.puzzleir.valuta.dto.pos.PosTransactionResult;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.repository.*;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.util.HungarianRounding;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import jakarta.annotation.PostConstruct;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.UUID;

/**
 * NOTE: Calculation logic (rate resolution, discount, HUF amount) delegated to
 * {@link TransactionCalculationService}.  Validation helpers (identification,
 * AML, stock, session, multi-line) delegated to
 * {@link TransactionValidationService}.  Export logic lives in
 * {@link TransactionExportService}.
 */

/**
 * Tranzakci├│ szolg├íltat├ís.
 *
 * Legacy: VASARLAS.DLL, ELADAS.DLL, STORNO.DLL funkci├│k
 * - V├ętel: ├ťgyf├ęl valut├ít ad el, c├ęg HUF-ot ad
 * - Elad├ís: ├ťgyf├ęl HUF-ot ad, c├ęg valut├ít ad
 * - Sztorn├│: Kor├íbbi tranzakci├│ visszavon├ísa
 */
@Service
@RequiredArgsConstructor
@Transactional(rollbackFor = Exception.class)
@Slf4j
public class TransactionService {

    private final TransactionRepository transactionRepository;
    private final TransactionLineRepository transactionLineRepository;
    private final CurrencyRepository currencyRepository;
    private final ExchangeRateRepository exchangeRateRepository;
    private final CashBalanceRepository cashBalanceRepository;
    private final WorkerRepository workerRepository;
    private final CompanyRepository companyRepository;
    private final BranchRepository branchRepository;
    private final DailySessionService dailySessionService;
    private final ExchangeRateService exchangeRateService;
    private final ReceiptSequenceService receiptSequenceService;
    private final HandlingFeeCalculator handlingFeeCalculator;
    private final AmlService amlService;
    private final PosTerminalService posTerminalService;
    private final ObjectProvider<CameraTransactionLinker> cameraTransactionLinkerProvider;
    private final TransactionCalculationService calculationService;

    // Delegate services — @Lazy to avoid circular dependency (they import inner DTOs from this class)
    private final @org.springframework.context.annotation.Lazy TransactionReversalService reversalService;
    private final @org.springframework.context.annotation.Lazy TransactionConversionService conversionService;
    private final @org.springframework.context.annotation.Lazy TransactionMultiLineService multiLineService;

    // Sztorn├│ limit supervisor n├ęlk├╝l (3 db/nap)
    private static final int DAILY_REVERSAL_LIMIT = 3;

    // Azonos├şt├ís n├ęlk├╝li limit HUF-ban (300.000 Ft - NAV szab├ílyoz├ís)
    private static final BigDecimal IDENTIFICATION_LIMIT = new BigDecimal("300000");

    // Max tetelsorok szama bizonylaton (Legacy: BLOKKTETEL limit)
    private static final int MAX_TRANSACTION_LINES = 6;

    // HUF currency ID cache - startup-kor bet├Âltve, ne kelljen minden tranzakci├│n├íl DB-t k├ęrdezni
    private volatile Long cachedHufCurrencyId;

    @PostConstruct
    void initHufCurrencyId() {
        try {
            cachedHufCurrencyId = currencyRepository.findByCode("HUF")
                    .map(c -> c.getId())
                    .orElse(null);
            if (cachedHufCurrencyId != null) {
                log.info("HUF currency ID cached: {}", cachedHufCurrencyId);
            } else {
                log.warn("HUF currency not found in DB - cash balance operations may fail until seeded");
            }
        } catch (Exception e) {
            log.error("Failed to cache HUF currency ID (DB type mismatch?): {}", e.getMessage());
            cachedHufCurrencyId = null;
        }
    }

    private void linkCameraEvidence(Transaction transaction) {
        if (cameraTransactionLinkerProvider == null) {
            return;
        }

        CameraTransactionLinker linker = cameraTransactionLinkerProvider.getIfAvailable();
        if (linker == null || transaction == null || transaction.getId() == null || transaction.getBranch() == null) {
            return;
        }

        LocalDate txDate = transaction.getTransactionDate();
        LocalTime txTime = transaction.getTransactionTime();
        if (txDate == null || txTime == null) {
            log.debug("Kamera linkeles kihagyva hianyzo datum/ido miatt: tx={}", transaction.getId());
            return;
        }

        try {
            linker.linkTransaction(
                    transaction.getId(),
                    transaction.getBranch().getId(),
                    txDate.atTime(txTime),
                    transaction.getReceiptNumber());
        } catch (Exception e) {
            log.error("Kamera-tranzakcio linkeles sikertelen: tx={}, receipt={}",
                    transaction.getId(), transaction.getReceiptNumber(), e);
        }
    }

    /**
     * V├ętel tranzakci├│ v├ęgrehajt├ísa
     * (├ťgyf├ęl valut├ít ad el, c├ęg HUF-ot fizet)
     *
     * Legacy: VASARLAS.DLL - VETEL funkci├│
     */
    public Transaction executeBuy(BuyRequest request) {
        // Multi-line delegalas ha vannak tetelsorok
        if (request.getLines() != null && !request.getLines().isEmpty()) {
            return executeMultiLineBuy(request);
        }

        validateOpenSession();

        UUID companyId = SecurityUtils.getCurrentCompanyId();
        UUID branchId = SecurityUtils.getCurrentBranchId();
        Long workerId = SecurityUtils.getCurrentWorkerId();

        // Entit├ísok bet├Âlt├ęse
        Company company = companyRepository.findById(companyId)
                .orElseThrow(() -> new ResourceNotFoundException("Company nem tal├ílhat├│"));
        Branch branch = branchRepository.findById(branchId)
                .orElseThrow(() -> new ResourceNotFoundException("Iroda nem tal├ílhat├│"));
        Worker worker = workerRepository.findById(workerId)
                .orElseThrow(() -> new ResourceNotFoundException("P├ęnzt├íros nem tal├ílhat├│"));
        Long currencyId = resolveCurrencyId(request.getCurrencyId(), request.getCurrencyCode());
        Currency currency = currencyRepository.findById(currencyId)
                .orElseThrow(() -> new ResourceNotFoundException("Valuta nem tal├ílhat├│"));

        // ├ürfolyam meghat├íroz├ísa
        ExchangeRate rate = exchangeRateService.getCurrentRate(currencyId);

        // Kedvezm├ęny valid├íl├ís (EL┼ÉBB, miel┼Ĺtt b├írmilyen sz├ím├şt├ís t├Ârt├ęnne)
        if (request.getDiscountPercent() != null && request.getDiscountPercent().compareTo(BigDecimal.ZERO) > 0) {
            calculationService.validateDiscount(request.getDiscountPercent());
        }

        BigDecimal appliedRate = calculationService.resolveBuyRate(rate, request.getCurrencyAmount(), request.getCustomExchangeRate());
        BigDecimal fullHufBeforeDiscount = request.getCurrencyAmount()
            .multiply(appliedRate).setScale(0, RoundingMode.HALF_UP);
        BigDecimal hufAmount = calculationService.applyBuyDiscount(fullHufBeforeDiscount, request.getDiscountPercent());

        // Kezel├ęsi d├şj szerver oldali sz├ím├şt├ís (kliens ├ęrt├ęk├ęt fel├╝l├şrjuk)
        BigDecimal serverHandlingFee = handlingFeeCalculator.calculate(
                hufAmount, TransactionType.BUY, request.getHandlingFee());

        // Brutt├│: v├ęteln├ęl nett├│ - d├şj (a c├ęg levonja a kezel├ęsi d├şjat)
        BigDecimal grossAmount = handlingFeeCalculator.calculateBuyGross(hufAmount, serverHandlingFee);

        // Magyar 5 Ft-os kerek├şt├ęs a fizetend┼Ĺ ├Âsszegre
        BigDecimal payableAmount = HungarianRounding.roundToFive(grossAmount);
        BigDecimal roundingDifference = payableAmount.subtract(grossAmount);

        // 300K+ tranzakcio eseten ugyfelazonositas kotelezo.
        validateIdentification(payableAmount, request.getCustomerName(), request.getCustomerDocumentNumber());

        // AML ellen┼Ĺrz├ęs (Pmt. 2017. ├ęvi LIII. tv.)
        performAmlCheck(payableAmount, request.getCustomerId(), request.getCustomerName(),
                request.getCustomerDocumentNumber(), currency.getCode());

        // Bizonylat sz├ím gener├íl├ísa (├║j szekvencia rendszer)
        String receiptNumber = receiptSequenceService.generateReceiptNumber(branchId, TransactionType.BUY);

        // Kedvezm├ęny ├Âsszeg a PRE-DISCOUNT ├ęrt├ękb┼Ĺl (nem a m├ír cs├Âkkentett hufAmount-b├│l!)
        BigDecimal discountAmount = calculationService.calculateDiscountAmount(fullHufBeforeDiscount, request.getDiscountPercent());

        // POS termin├íl integr├íci├│ - bankk├írty├ís fizet├ęsn├ęl
        PaymentMethod paymentMethod = request.getPaymentMethod() != null ? request.getPaymentMethod() : PaymentMethod.CASH;
        String posAuthCode = null;
        String posRefNumber = null;
        String posTerminalId = request.getPosTerminalId();

        if (paymentMethod == PaymentMethod.CARD) {
            if (posTerminalId == null || posTerminalId.isBlank()) {
                throw new ValidationException("Bankk├írty├ís fizet├ęshez POS termin├íl azonos├şt├│ k├Âtelez┼Ĺ!");
            }
            PosTransactionResult posResult = posTerminalService.initiatePayment(
                    payableAmount, "HUF", posTerminalId);
            if (!posResult.approved()) {
                throw new ValidationException("Bankk├írty├ís fizet├ęs elutas├ştva: " + posResult.errorMessage());
            }
            posAuthCode = posResult.authorizationCode();
            posRefNumber = posResult.referenceNumber();
            log.info("POS fizet├ęs elfogadva: auth={}, ref={}", posAuthCode, posRefNumber);
        }

        // Tranzakci├│ l├ętrehoz├ísa
        Transaction transaction = Transaction.builder()
                .company(company)
                .branch(branch)
                .worker(worker)
                .receiptNumber(receiptNumber)
                .transactionType(TransactionType.BUY)
                .status(TransactionStatus.COMPLETED)
                .transactionDate(LocalDate.now())
                .transactionTime(LocalTime.now())
                .currency(currency)
                .currencyAmount(request.getCurrencyAmount())
                .exchangeRate(appliedRate)
                .hufAmount(payableAmount)
                .handlingFee(serverHandlingFee)
                .discountPercent(request.getDiscountPercent() != null ? request.getDiscountPercent() : BigDecimal.ZERO)
                .discountAmount(discountAmount)
                .roundingAmount(roundingDifference)
                .paymentMethod(paymentMethod)
                .posAuthorizationCode(posAuthCode)
                .posReferenceNumber(posRefNumber)
                .posTerminalId(posTerminalId)
                .customerId(request.getCustomerId())
                .customerName(request.getCustomerName())
                .customerAddress(request.getCustomerAddress())
                .customerDocumentNumber(request.getCustomerDocumentNumber())
                .customerNationality(request.getCustomerNationality())
                .notes(request.getNotes())
                .build();

        Transaction saved = transactionRepository.save(transaction);
        linkCameraEvidence(saved);

        // Kassza friss├şt├ęse - HUF cs├Âkken, valuta n┼Ĺ
        updateCashBalance(branchId, currency.getId(), request.getCurrencyAmount(), true);  // valuta +
        updateCashBalance(branchId, getHufCurrencyId(), payableAmount.negate(), false);    // HUF -

        // Napi statisztika friss├şt├ęse
        dailySessionService.updateSessionStats(
            TransactionType.BUY,
            payableAmount,
            transaction.getHandlingFee()
        );

        log.info("V├ętel tranzakci├│: {} - {} {} @ {} = {} HUF (kerek├şt├ęs: {} Ft, d├şj: {} Ft)",
                receiptNumber, request.getCurrencyAmount(), currency.getCode(),
                appliedRate, payableAmount, roundingDifference, serverHandlingFee);

        return saved;
    }

    /**
     * Elad├ís tranzakci├│ v├ęgrehajt├ísa
     * (├ťgyf├ęl HUF-ot ad, c├ęg valut├ít ad)
     *
     * Legacy: ELADAS.DLL - ELADAS funkci├│
     */
    public Transaction executeSell(SellRequest request) {
        // Multi-line delegalas ha vannak tetelsorok
        if (request.getLines() != null && !request.getLines().isEmpty()) {
            return executeMultiLineSell(request);
        }

        validateOpenSession();

        UUID companyId = SecurityUtils.getCurrentCompanyId();
        UUID branchId = SecurityUtils.getCurrentBranchId();
        Long workerId = SecurityUtils.getCurrentWorkerId();

        // Entit├ísok bet├Âlt├ęse
        Company company = companyRepository.findById(companyId)
                .orElseThrow(() -> new ResourceNotFoundException("Company nem tal├ílhat├│"));
        Branch branch = branchRepository.findById(branchId)
                .orElseThrow(() -> new ResourceNotFoundException("Iroda nem tal├ílhat├│"));
        Worker worker = workerRepository.findById(workerId)
                .orElseThrow(() -> new ResourceNotFoundException("P├ęnzt├íros nem tal├ílhat├│"));
        Long currencyId = resolveCurrencyId(request.getCurrencyId(), request.getCurrencyCode());
        Currency currency = currencyRepository.findById(currencyId)
                .orElseThrow(() -> new ResourceNotFoundException("Valuta nem tal├ílhat├│"));

        // ├ürfolyam meghat├íroz├ísa
        ExchangeRate rate = exchangeRateService.getCurrentRate(currencyId);

        // Kedvezm├ęny valid├íl├ís (EL┼ÉBB, miel┼Ĺtt b├írmilyen sz├ím├şt├ís t├Ârt├ęnne)
        if (request.getDiscountPercent() != null && request.getDiscountPercent().compareTo(BigDecimal.ZERO) > 0) {
            calculationService.validateDiscount(request.getDiscountPercent());
        }

        BigDecimal appliedRate = calculationService.resolveSellRate(rate, request.getCurrencyAmount(), request.getCustomExchangeRate());
        BigDecimal fullHufBeforeDiscount = request.getCurrencyAmount()
            .multiply(appliedRate).setScale(0, RoundingMode.HALF_UP);
        BigDecimal hufAmount = calculationService.applySellDiscount(fullHufBeforeDiscount, request.getDiscountPercent());

        // K├ęszlet ellen┼Ĺrz├ęse
        validateCurrencyStock(branchId, currency.getId(), request.getCurrencyAmount());

        // Kezel├ęsi d├şj szerver oldali sz├ím├şt├ís (kliens ├ęrt├ęk├ęt fel├╝l├şrjuk)
        BigDecimal serverHandlingFee = handlingFeeCalculator.calculate(
                hufAmount, TransactionType.SELL, request.getHandlingFee());

        // Brutt├│: elad├ísn├íl nett├│ + d├şj
        BigDecimal grossAmount = handlingFeeCalculator.calculateSellGross(hufAmount, serverHandlingFee);

        // Magyar 5 Ft-os kerek├şt├ęs a fizetend┼Ĺ ├Âsszegre
        BigDecimal payableAmount = HungarianRounding.roundToFive(grossAmount);
        BigDecimal roundingDifference = payableAmount.subtract(grossAmount);

        // 300K+ tranzakci├│ eset├ęn ├╝gyf├ęl-azonos├şt├ís k├Âtelez┼Ĺ (NAV jogi k├Âvetelm├ęny).
        validateIdentification(payableAmount, request.getCustomerName(), request.getCustomerDocumentNumber());

        // AML ellen┼Ĺrz├ęs (Pmt. 2017. ├ęvi LIII. tv.)
        performAmlCheck(payableAmount, request.getCustomerId(), request.getCustomerName(),
                request.getCustomerDocumentNumber(), currency.getCode());

        // Bizonylat sz├ím gener├íl├ísa (├║j szekvencia rendszer)
        String receiptNumber = receiptSequenceService.generateReceiptNumber(branchId, TransactionType.SELL);

        // Kedvezm├ęny ├Âsszeg a PRE-DISCOUNT ├ęrt├ękb┼Ĺl (nem a m├ír cs├Âkkentett hufAmount-b├│l!)
        BigDecimal discountAmount = calculationService.calculateDiscountAmount(fullHufBeforeDiscount, request.getDiscountPercent());

        // POS termin├íl integr├íci├│ - bankk├írty├ís fizet├ęsn├ęl
        PaymentMethod paymentMethod = request.getPaymentMethod() != null ? request.getPaymentMethod() : PaymentMethod.CASH;
        String posAuthCode = null;
        String posRefNumber = null;
        String posTerminalId = request.getPosTerminalId();

        if (paymentMethod == PaymentMethod.CARD) {
            if (posTerminalId == null || posTerminalId.isBlank()) {
                throw new ValidationException("Bankk├írty├ís fizet├ęshez POS termin├íl azonos├şt├│ k├Âtelez┼Ĺ!");
            }
            PosTransactionResult posResult = posTerminalService.initiatePayment(
                    payableAmount, "HUF", posTerminalId);
            if (!posResult.approved()) {
                throw new ValidationException("Bankk├írty├ís fizet├ęs elutas├ştva: " + posResult.errorMessage());
            }
            posAuthCode = posResult.authorizationCode();
            posRefNumber = posResult.referenceNumber();
            log.info("POS fizet├ęs elfogadva: auth={}, ref={}", posAuthCode, posRefNumber);
        }

        // Tranzakci├│ l├ętrehoz├ísa
        Transaction transaction = Transaction.builder()
                .company(company)
                .branch(branch)
                .worker(worker)
                .receiptNumber(receiptNumber)
                .transactionType(TransactionType.SELL)
                .status(TransactionStatus.COMPLETED)
                .transactionDate(LocalDate.now())
                .transactionTime(LocalTime.now())
                .currency(currency)
                .currencyAmount(request.getCurrencyAmount())
                .exchangeRate(appliedRate)
                .hufAmount(payableAmount)
                .handlingFee(serverHandlingFee)
                .discountPercent(request.getDiscountPercent() != null ? request.getDiscountPercent() : BigDecimal.ZERO)
                .discountAmount(discountAmount)
                .roundingAmount(roundingDifference)
                .paymentMethod(paymentMethod)
                .posAuthorizationCode(posAuthCode)
                .posReferenceNumber(posRefNumber)
                .posTerminalId(posTerminalId)
                .customerId(request.getCustomerId())
                .customerName(request.getCustomerName())
                .customerAddress(request.getCustomerAddress())
                .customerDocumentNumber(request.getCustomerDocumentNumber())
                .customerNationality(request.getCustomerNationality())
                .notes(request.getNotes())
                .build();

        Transaction saved = transactionRepository.save(transaction);
        linkCameraEvidence(saved);

        // Kassza friss├şt├ęse - HUF n┼Ĺ, valuta cs├Âkken
        updateCashBalance(branchId, currency.getId(), request.getCurrencyAmount().negate(), false); // valuta -
        updateCashBalance(branchId, getHufCurrencyId(), payableAmount, true);                       // HUF +

        // Napi statisztika friss├şt├ęse
        dailySessionService.updateSessionStats(
            TransactionType.SELL,
            payableAmount,
            transaction.getHandlingFee()
        );

        log.info("Elad├ís tranzakci├│: {} - {} {} @ {} = {} HUF (kerek├şt├ęs: {} Ft, d├şj: {} Ft)",
                receiptNumber, request.getCurrencyAmount(), currency.getCode(),
                appliedRate, payableAmount, roundingDifference, serverHandlingFee);

        return saved;
    }

    // ============ DELEGÁLT MŰVELETEK ============
    // Reversal, Conversion, MultiLine logika kiszervezve:
    // - TransactionReversalService (sztornó + részleges visszatérítés)
    // - TransactionConversionService (valuta-valuta csere)
    // - TransactionMultiLineService (multi-line bizonylatok)

    public Transaction executeReversal(ReversalRequest request) {
        return reversalService.executeReversal(request);
    }

    public Transaction executePartialRefund(PartialRefundRequest request) {
        return reversalService.executePartialRefund(request);
    }

    public Transaction executeConversion(ConversionRequest request) {
        return conversionService.executeConversion(request);
    }

    private Transaction executeMultiLineBuy(BuyRequest request) {
        return multiLineService.executeMultiLineBuy(request);
    }

    private Transaction executeMultiLineSell(SellRequest request) {
        return multiLineService.executeMultiLineSell(request);
    }

    @Transactional(readOnly = true)
    public java.util.List<TransactionLine> getTransactionLines(Long transactionId) {
        return multiLineService.getTransactionLines(transactionId);
    }

    // ============ LEKÉRDEZÉSEK ============
    // ============ LEK├ëRDEZ├ëSEK ============

    /**
     * Tranzakci├│ keres├ęse bizonylat sz├ím alapj├ín
     */
    @Transactional(readOnly = true)
    public Transaction findByReceiptNumber(String receiptNumber) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return transactionRepository.findByReceiptNumberAndCompanyId(receiptNumber, companyId)
                .orElseThrow(() -> new ResourceNotFoundException("Bizonylat nem tal├ílhat├│: " + receiptNumber));
    }

    /**
     * Napi tranzakci├│k lek├ęr├ęse
     */
    @Transactional(readOnly = true)
    public List<Transaction> getDailyTransactions() {
        UUID branchId = SecurityUtils.getCurrentBranchId();
        return transactionRepository.findByBranchAndDate(branchId, LocalDate.now());
    }

    /**
     * Tranzakci├│k sz┼▒r├ęse ├ęs lapoz├ís
     */
    @Transactional(readOnly = true)
    public Page<Transaction> searchTransactions(
            UUID branchId,
            LocalDate startDate,
            LocalDate endDate,
            TransactionType type,
            Pageable pageable) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return transactionRepository.findWithFilters(companyId, branchId, startDate, endDate, type, pageable);
    }

    /**
     * Napi forgalom ├Âsszes├şt├ęs
     */
    @Transactional(readOnly = true)
    public DailyTurnoverSummary getDailyTurnover() {
        UUID branchId = SecurityUtils.getCurrentBranchId();
        LocalDate today = LocalDate.now();

        BigDecimal buyTotal = transactionRepository.sumDailyTurnover(branchId, today, TransactionType.BUY);
        BigDecimal sellTotal = transactionRepository.sumDailyTurnover(branchId, today, TransactionType.SELL);
        long reversalCount = transactionRepository.countReversalsByBranchAndDate(branchId, today);

        // B┼Ĺv├ştett mez┼Ĺk: count ├ęs handling fees
        long buyCount = transactionRepository.countByBranchIdAndTransactionDateAndTransactionType(branchId, today, TransactionType.BUY);
        long sellCount = transactionRepository.countByBranchIdAndTransactionDateAndTransactionType(branchId, today, TransactionType.SELL);
        BigDecimal totalHandlingFees = transactionRepository.sumDailyHandlingFees(branchId, today);

        return DailyTurnoverSummary.builder()
                .date(today)
                .buyTotal(buyTotal != null ? buyTotal : BigDecimal.ZERO)
                .sellTotal(sellTotal != null ? sellTotal : BigDecimal.ZERO)
                .netTotal((sellTotal != null ? sellTotal : BigDecimal.ZERO)
                        .subtract(buyTotal != null ? buyTotal : BigDecimal.ZERO))
                .reversalCount(reversalCount)
                // B┼Ĺv├ştett mez┼Ĺk
                .totalBuyCount(buyCount)
                .totalSellCount(sellCount)
                .totalBuyHuf(buyTotal != null ? buyTotal : BigDecimal.ZERO)
                .totalSellHuf(sellTotal != null ? sellTotal : BigDecimal.ZERO)
                .totalHandlingFees(totalHandlingFees != null ? totalHandlingFees : BigDecimal.ZERO)
                .totalReversalCount(reversalCount)
                .build();
    }

    // ============ HELPER MET├ôDUSOK ============

    private void validateOpenSession() {
        if (!dailySessionService.hasOpenSession()) {
            throw new ValidationException("Nincs nyitott napi munkamenet! El┼Ĺsz├Âr nyissa meg a napot.");
        }
    }

    /**
     * Teljes AML ellen┼Ĺrz├ęs a tranzakci├│ el┼Ĺtt (Pmt. 2017. ├ęvi LIII. tv.).
     *
     * H├şvja az AmlService.checkTransaction()-t az alapszint┼▒ ellen┼Ĺrz├ęshez
     * (azonos├şt├ís, ├ęves g├Ângy├Âl├ęs, napi gyan├║s├ígi limit), valamint a
     * checkAllThresholds()-t a legacy BIGCTRL.DLL klasszifik├íci├│hoz (TranzTipus).
     */
    private void performAmlCheck(BigDecimal hufAmount, String customerId,
                                 String customerName, String documentNumber, String currencyCode) {
        // 1. Alapszint┼▒ AML ellen┼Ĺrz├ęs (azonos├şt├ís + g├Ângy├Âl├ęs + gyan├║s├ígi flag)
        AmlService.AmlBasicCheckResult basicResult = amlService.checkTransaction(
                hufAmount, customerId, customerName, documentNumber);

        if (basicResult == null) {
            log.error("AML checkTransaction null eredmenyt adott, tranzakcio blokkolva");
            throw new ValidationException("AML ellen┼Ĺrz├ęs nem el├ęrhet┼Ĺ, a tranzakci├│ nem hajthat├│ v├ęgre!");
        }

        if (!basicResult.isApproved()) {
            throw new ValidationException(basicResult.getRejectionReason() != null
                    ? basicResult.getRejectionReason()
                    : "AML ellen┼Ĺrz├ęs sikertelen!");
        }

        if (basicResult.isRequiresApproval()) {
            throw new ValidationException(basicResult.getApprovalReason() != null
                    ? basicResult.getApprovalReason()
                    : "Supervisor j├│v├íhagy├ís sz├╝ks├ęges (AML limit)!");
        }

        // 2. Legacy BIGCTRL.DLL klasszifik├íci├│ - blokkol├│ TranzTipus -1 ellen┼Ĺrz├ęs
        if (customerId != null && !customerId.isBlank()) {
            var thresholdResult = amlService.checkAllThresholds(customerId, hufAmount, currencyCode);
            if (thresholdResult != null && thresholdResult.isBlocked()) {
                String warnings = thresholdResult.getWarnings() != null && !thresholdResult.getWarnings().isEmpty()
                        ? String.join("; ", thresholdResult.getWarnings())
                        : "AML szab├íly alapj├ín blokkolva";
                throw new ValidationException(warnings);
            }
        }

        // 3. R├ęszletes azonos├şt├ís logol├ísa (1.5M+ Ft)
        if (basicResult.isRequiresDetailedId()) {
            log.warn("AML: R├ęszletes azonos├şt├ís sz├╝ks├ęges - {} Ft, ├╝gyf├ęl: {}", hufAmount, customerId);
        }
    }

    private void validateIdentification(BigDecimal hufAmount, String customerName, String documentNumber) {
        if (hufAmount.compareTo(IDENTIFICATION_LIMIT) >= 0) {
            if (customerName == null || customerName.isBlank()) {
                throw new ValidationException(
                    String.format("%s Ft feletti tranzakci├│hoz ├╝gyf├ęl azonos├şt├ís k├Âtelez┼Ĺ!",
                        IDENTIFICATION_LIMIT.toPlainString()));
            }
            if (documentNumber == null || documentNumber.isBlank()) {
                throw new ValidationException(
                    String.format("%s Ft feletti tranzakci├│hoz igazolv├íny sz├ím k├Âtelez┼Ĺ!",
                        IDENTIFICATION_LIMIT.toPlainString()));
            }
        }
    }

    private void validateCurrencyStock(UUID branchId, Long currencyId, BigDecimal amount) {
        CashBalance balance = cashBalanceRepository.findByBranchIdAndCurrencyIdForUpdate(branchId, currencyId)
                .orElse(null);

        if (balance == null || balance.getCurrentBalance().compareTo(amount) < 0) {
            throw new ValidationException("Nincs elegend┼Ĺ valuta k├ęszlet!");
        }
    }

    private void updateCashBalance(UUID branchId, Long currencyId, BigDecimal amount, boolean isIncoming) {
        // Pessimistic lock haszn├ílata race condition elker├╝l├ęs├ęre
        CashBalance balance = cashBalanceRepository.findByBranchIdAndCurrencyIdForUpdate(branchId, currencyId)
                .orElseThrow(() -> new ResourceNotFoundException("Kassza egyenleg nem tal├ílhat├│"));

        balance.updateBalance(amount.abs(), isIncoming);
        cashBalanceRepository.save(balance);
    }

    /**
     * @deprecated Haszn├íld a {@link ReceiptSequenceService#generateReceiptNumber} met├│dust.
     * Ez a met├│dus a r├ęgi E+MMDD+5sz├ím form├ítumot gener├ílja - csak backward compatibility-hez.
     */
    @Deprecated
    private String generateReceiptNumber(UUID branchId, String prefix) {
        LocalDate today = LocalDate.now();
        String datePrefix = prefix + String.format("%02d%02d", today.getMonthValue(), today.getDayOfMonth());

        String maxReceipt = transactionRepository.findMaxReceiptNumber(branchId, today, datePrefix)
                .orElse(datePrefix + "00000");

        int lastNumber = Integer.parseInt(maxReceipt.substring(datePrefix.length()));
        return datePrefix + String.format("%05d", lastNumber + 1);
    }

    private Long getHufCurrencyId() {
        if (cachedHufCurrencyId == null) {
            // ├Üjrapr├│b├íl├ís: lehet hogy a DB-ben k├ęsve ker├╝lt be a HUF valuta
            cachedHufCurrencyId = currencyRepository.findByCode("HUF")
                    .map(c -> c.getId())
                    .orElse(null);
            if (cachedHufCurrencyId == null) {
                throw new ValidationException("HUF valuta nem tal├ílhat├│ az adatb├ízisban! K├ęrj├╝k inicializ├ílja a valuta t├íbl├ít.");
            }
        }
        return cachedHufCurrencyId;
    }

    /**
     * Currency ID felold├ísa: ha currencyId megvan, azt haszn├íljuk, egy├ębk├ęnt currencyCode alapj├ín.
     */
    private Long resolveCurrencyId(Long currencyId, String currencyCode) {
        if (currencyId != null && currencyId > 0) {
            return currencyId;
        }
        if (currencyCode != null && !currencyCode.isBlank()) {
            return currencyRepository.findByCode(currencyCode.toUpperCase())
                    .map(c -> c.getId())
                    .orElseThrow(() -> new ResourceNotFoundException("Ismeretlen valuta k├│d: " + currencyCode));
        }
        throw new ValidationException("Valuta azonos├şt├│ (currencyId) vagy valuta k├│d (currencyCode) k├Âtelez┼Ĺ!");
    }

    // ============ REQUEST/RESPONSE DTO-k ============

    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class BuyRequest {
        private Long currencyId;
        private String currencyCode;
        private BigDecimal currencyAmount;
        private BigDecimal discountPercent;
        private BigDecimal handlingFee;
        private BigDecimal customExchangeRate;
        private String customerId;
        private String customerName;
        private String customerAddress;
        private String customerDocumentNumber;
        private String customerNationality;
        private String notes;
        /** Fizet├ęsi m├│d: CASH (alap├ęrtelmezett) vagy CARD (bankk├írtya) */
        private PaymentMethod paymentMethod;
        /** POS termin├íl azonos├şt├│ (csak CARD fizet├ęsn├ęl k├Âtelez┼Ĺ) */
        private String posTerminalId;
        /** Multi-line bizonylat tetelsorai (max 6). Ha nem ures, multi-line feldolgozas. */
        private java.util.List<LineRequest> lines;
    }

    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class SellRequest {
        private Long currencyId;
        private String currencyCode;
        private BigDecimal currencyAmount;
        private BigDecimal discountPercent;
        private BigDecimal handlingFee;
        private BigDecimal customExchangeRate;
        private String customerId;
        private String customerName;
        private String customerAddress;
        private String customerDocumentNumber;
        private String customerNationality;
        private String notes;
        /** Fizet├ęsi m├│d: CASH (alap├ęrtelmezett) vagy CARD (bankk├írtya) */
        private PaymentMethod paymentMethod;
        /** POS termin├íl azonos├şt├│ (csak CARD fizet├ęsn├ęl k├Âtelez┼Ĺ) */
        private String posTerminalId;
        /** Multi-line bizonylat tetelsorai (max 6). Ha nem ures, multi-line feldolgozas. */
        private java.util.List<LineRequest> lines;
    }

    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class ReversalRequest {
        private Long originalTransactionId;
        private String reason;
        private String approvedBy;
    }

    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class PartialRefundRequest {
        private Long originalTransactionId;
        /** Visszat├ęr├ştend┼Ĺ HUF ├Âsszeg */
        private BigDecimal refundHufAmount;
        /** Visszat├ęr├ştend┼Ĺ valuta├Âsszeg - ha null, ar├ínyosan sz├ím├ştjuk */
        private BigDecimal refundCurrencyAmount;
        private String reason;
        private String approvedBy;
    }

    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class ConversionRequest {
        private Long fromCurrencyId;
        private String fromCurrencyCode;
        private Long toCurrencyId;
        private String toCurrencyCode;
        private BigDecimal fromAmount;
        private BigDecimal handlingFee;
        private String customerId;
        private String customerName;
        private String customerDocumentNumber;
    }

    /**
     * Egy tetelsor request multi-line bizonylathoz.
     */
    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class LineRequest {
        private Long currencyId;
        private String currencyCode;
        /** Bankjegy darabszam / valuta osszeg */
        private BigDecimal banknoteCount;
        /** Egyedi arfolyam (opcionalis) */
        private BigDecimal customExchangeRate;
        /** Sor kedvezmeny tipus (0=nincs, 4=VIP, stb.) */
        private Integer discountType;
    }

    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class DailyTurnoverSummary {
        private LocalDate date;
        private BigDecimal buyTotal;
        private BigDecimal sellTotal;
        private BigDecimal netTotal;
        private long reversalCount;
        // B┼Ĺv├ştett mez┼Ĺk - frontend kompatibilit├ís
        private long totalBuyCount;
        private long totalSellCount;
        private BigDecimal totalBuyHuf;
        private BigDecimal totalSellHuf;
        private BigDecimal totalHandlingFees;
        private long totalReversalCount;
    }
}
