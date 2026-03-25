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
 * Tranzakció szolgáltatás.
 *
 * Legacy: VASARLAS.DLL, ELADAS.DLL, STORNO.DLL funkciók
 * - Vétel: Ügyfél valutát ad el, cég HUF-ot ad
 * - Eladás: Ügyfél HUF-ot ad, cég valutát ad
 * - Sztornó: Korábbi tranzakció visszavonása
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

    // Sztornó limit supervisor nélkül (3 db/nap)
    private static final int DAILY_REVERSAL_LIMIT = 3;

    // Azonosítás nélküli limit HUF-ban (300.000 Ft - NAV szabályozás)
    private static final BigDecimal IDENTIFICATION_LIMIT = new BigDecimal("300000");

    // Max tetelsorok szama bizonylaton (Legacy: BLOKKTETEL limit)
    private static final int MAX_TRANSACTION_LINES = 6;

    // HUF currency ID cache - startup-kor betöltve, ne kelljen minden tranzakciónál DB-t kérdezni
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
     * Vétel tranzakció végrehajtása
     * (Ügyfél valutát ad el, cég HUF-ot fizet)
     *
     * Legacy: VASARLAS.DLL - VETEL funkció
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

        // Entitások betöltése
        Company company = companyRepository.findById(companyId)
                .orElseThrow(() -> new ResourceNotFoundException("Company nem található"));
        Branch branch = branchRepository.findById(branchId)
                .orElseThrow(() -> new ResourceNotFoundException("Iroda nem található"));
        Worker worker = workerRepository.findById(workerId)
                .orElseThrow(() -> new ResourceNotFoundException("Pénztáros nem található"));
        Long currencyId = resolveCurrencyId(request.getCurrencyId(), request.getCurrencyCode());
        Currency currency = currencyRepository.findById(currencyId)
                .orElseThrow(() -> new ResourceNotFoundException("Valuta nem található"));

        // Árfolyam meghatározása
        ExchangeRate rate = exchangeRateService.getCurrentRate(currencyId);

        // Kedvezmény validálás (ELŐBB, mielőtt bármilyen számítás történne)
        if (request.getDiscountPercent() != null && request.getDiscountPercent().compareTo(BigDecimal.ZERO) > 0) {
            calculationService.validateDiscount(request.getDiscountPercent());
        }

        BigDecimal appliedRate = calculationService.resolveBuyRate(rate, request.getCurrencyAmount(), request.getCustomExchangeRate());
        BigDecimal fullHufBeforeDiscount = request.getCurrencyAmount()
            .multiply(appliedRate).setScale(0, RoundingMode.HALF_UP);
        BigDecimal hufAmount = calculationService.applyBuyDiscount(fullHufBeforeDiscount, request.getDiscountPercent());

        // Kezelési díj szerver oldali számítás (kliens értékét felülírjuk)
        BigDecimal serverHandlingFee = handlingFeeCalculator.calculate(
                hufAmount, TransactionType.BUY, request.getHandlingFee());

        // Bruttó: vételnél nettó - díj (a cég levonja a kezelési díjat)
        BigDecimal grossAmount = handlingFeeCalculator.calculateBuyGross(hufAmount, serverHandlingFee);

        // Magyar 5 Ft-os kerekítés a fizetendő összegre
        BigDecimal payableAmount = HungarianRounding.roundToFive(grossAmount);
        BigDecimal roundingDifference = payableAmount.subtract(grossAmount);

        // 300K+ tranzakcio eseten ugyfelazonositas kotelezo.
        validateIdentification(payableAmount, request.getCustomerName(), request.getCustomerDocumentNumber());

        // AML ellenőrzés (Pmt. 2017. évi LIII. tv.)
        performAmlCheck(payableAmount, request.getCustomerId(), request.getCustomerName(),
                request.getCustomerDocumentNumber(), currency.getCode());

        // Bizonylat szám generálása (új szekvencia rendszer)
        String receiptNumber = receiptSequenceService.generateReceiptNumber(branchId, TransactionType.BUY);

        // Kedvezmény összeg a PRE-DISCOUNT értékből (nem a már csökkentett hufAmount-ból!)
        BigDecimal discountAmount = calculationService.calculateDiscountAmount(fullHufBeforeDiscount, request.getDiscountPercent());

        // POS terminál integráció - bankkártyás fizetésnél
        PaymentMethod paymentMethod = request.getPaymentMethod() != null ? request.getPaymentMethod() : PaymentMethod.CASH;
        String posAuthCode = null;
        String posRefNumber = null;
        String posTerminalId = request.getPosTerminalId();

        if (paymentMethod == PaymentMethod.CARD) {
            if (posTerminalId == null || posTerminalId.isBlank()) {
                throw new ValidationException("Bankkártyás fizetéshez POS terminál azonosító kötelező!");
            }
            PosTransactionResult posResult = posTerminalService.initiatePayment(
                    payableAmount, "HUF", posTerminalId);
            if (!posResult.approved()) {
                throw new ValidationException("Bankkártyás fizetés elutasítva: " + posResult.errorMessage());
            }
            posAuthCode = posResult.authorizationCode();
            posRefNumber = posResult.referenceNumber();
            log.info("POS fizetés elfogadva: auth={}, ref={}", posAuthCode, posRefNumber);
        }

        // Tranzakció létrehozása
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

        // Kassza frissítése - HUF csökken, valuta nő
        updateCashBalance(branchId, currency.getId(), request.getCurrencyAmount(), true);  // valuta +
        updateCashBalance(branchId, getHufCurrencyId(), payableAmount.negate(), false);    // HUF -

        // Napi statisztika frissítése
        dailySessionService.updateSessionStats(
            TransactionType.BUY,
            payableAmount,
            transaction.getHandlingFee()
        );

        log.info("Vétel tranzakció: {} - {} {} @ {} = {} HUF (kerekítés: {} Ft, díj: {} Ft)",
                receiptNumber, request.getCurrencyAmount(), currency.getCode(),
                appliedRate, payableAmount, roundingDifference, serverHandlingFee);

        return saved;
    }

    /**
     * Eladás tranzakció végrehajtása
     * (Ügyfél HUF-ot ad, cég valutát ad)
     *
     * Legacy: ELADAS.DLL - ELADAS funkció
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

        // Entitások betöltése
        Company company = companyRepository.findById(companyId)
                .orElseThrow(() -> new ResourceNotFoundException("Company nem található"));
        Branch branch = branchRepository.findById(branchId)
                .orElseThrow(() -> new ResourceNotFoundException("Iroda nem található"));
        Worker worker = workerRepository.findById(workerId)
                .orElseThrow(() -> new ResourceNotFoundException("Pénztáros nem található"));
        Long currencyId = resolveCurrencyId(request.getCurrencyId(), request.getCurrencyCode());
        Currency currency = currencyRepository.findById(currencyId)
                .orElseThrow(() -> new ResourceNotFoundException("Valuta nem található"));

        // Árfolyam meghatározása
        ExchangeRate rate = exchangeRateService.getCurrentRate(currencyId);

        // Kedvezmény validálás (ELŐBB, mielőtt bármilyen számítás történne)
        if (request.getDiscountPercent() != null && request.getDiscountPercent().compareTo(BigDecimal.ZERO) > 0) {
            calculationService.validateDiscount(request.getDiscountPercent());
        }

        BigDecimal appliedRate = calculationService.resolveSellRate(rate, request.getCurrencyAmount(), request.getCustomExchangeRate());
        BigDecimal fullHufBeforeDiscount = request.getCurrencyAmount()
            .multiply(appliedRate).setScale(0, RoundingMode.HALF_UP);
        BigDecimal hufAmount = calculationService.applySellDiscount(fullHufBeforeDiscount, request.getDiscountPercent());

        // Készlet ellenőrzése
        validateCurrencyStock(branchId, currency.getId(), request.getCurrencyAmount());

        // Kezelési díj szerver oldali számítás (kliens értékét felülírjuk)
        BigDecimal serverHandlingFee = handlingFeeCalculator.calculate(
                hufAmount, TransactionType.SELL, request.getHandlingFee());

        // Bruttó: eladásnál nettó + díj
        BigDecimal grossAmount = handlingFeeCalculator.calculateSellGross(hufAmount, serverHandlingFee);

        // Magyar 5 Ft-os kerekítés a fizetendő összegre
        BigDecimal payableAmount = HungarianRounding.roundToFive(grossAmount);
        BigDecimal roundingDifference = payableAmount.subtract(grossAmount);

        // 300K+ tranzakció esetén ügyfél-azonosítás kötelező (NAV jogi követelmény).
        validateIdentification(payableAmount, request.getCustomerName(), request.getCustomerDocumentNumber());

        // AML ellenőrzés (Pmt. 2017. évi LIII. tv.)
        performAmlCheck(payableAmount, request.getCustomerId(), request.getCustomerName(),
                request.getCustomerDocumentNumber(), currency.getCode());

        // Bizonylat szám generálása (új szekvencia rendszer)
        String receiptNumber = receiptSequenceService.generateReceiptNumber(branchId, TransactionType.SELL);

        // Kedvezmény összeg a PRE-DISCOUNT értékből (nem a már csökkentett hufAmount-ból!)
        BigDecimal discountAmount = calculationService.calculateDiscountAmount(fullHufBeforeDiscount, request.getDiscountPercent());

        // POS terminál integráció - bankkártyás fizetésnél
        PaymentMethod paymentMethod = request.getPaymentMethod() != null ? request.getPaymentMethod() : PaymentMethod.CASH;
        String posAuthCode = null;
        String posRefNumber = null;
        String posTerminalId = request.getPosTerminalId();

        if (paymentMethod == PaymentMethod.CARD) {
            if (posTerminalId == null || posTerminalId.isBlank()) {
                throw new ValidationException("Bankkártyás fizetéshez POS terminál azonosító kötelező!");
            }
            PosTransactionResult posResult = posTerminalService.initiatePayment(
                    payableAmount, "HUF", posTerminalId);
            if (!posResult.approved()) {
                throw new ValidationException("Bankkártyás fizetés elutasítva: " + posResult.errorMessage());
            }
            posAuthCode = posResult.authorizationCode();
            posRefNumber = posResult.referenceNumber();
            log.info("POS fizetés elfogadva: auth={}, ref={}", posAuthCode, posRefNumber);
        }

        // Tranzakció létrehozása
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

        // Kassza frissítése - HUF nő, valuta csökken
        updateCashBalance(branchId, currency.getId(), request.getCurrencyAmount().negate(), false); // valuta -
        updateCashBalance(branchId, getHufCurrencyId(), payableAmount, true);                       // HUF +

        // Napi statisztika frissítése
        dailySessionService.updateSessionStats(
            TransactionType.SELL,
            payableAmount,
            transaction.getHandlingFee()
        );

        log.info("Eladás tranzakció: {} - {} {} @ {} = {} HUF (kerekítés: {} Ft, díj: {} Ft)",
                receiptNumber, request.getCurrencyAmount(), currency.getCode(),
                appliedRate, payableAmount, roundingDifference, serverHandlingFee);

        return saved;
    }

    /**
     * Sztornó végrehajtása
     *
     * Legacy: STORNO.DLL - sztornó validálás, supervisor ellenőrzés
     */
    public Transaction executeReversal(ReversalRequest request) {
        validateOpenSession();

        UUID companyId = SecurityUtils.getCurrentCompanyId();
        UUID branchId = SecurityUtils.getCurrentBranchId();
        Long workerId = SecurityUtils.getCurrentWorkerId();

        // Eredeti tranzakció lekérése
        Transaction original = transactionRepository.findById(request.getOriginalTransactionId())
                .orElseThrow(() -> new ResourceNotFoundException("Eredeti tranzakció nem található"));

        // Validációk
        if (original.isReversed()) {
            throw new ValidationException("Ez a tranzakció már sztornózva lett!");
        }
        if (original.isReversal()) {
            throw new ValidationException("Sztornó tranzakció nem sztornózható!");
        }
        if (!original.getBranch().getId().equals(branchId)) {
            throw new ValidationException("Csak saját iroda tranzakcióját lehet sztornózni!");
        }
        // Csak aznapi tranzakció sztornózható supervisor nélkül
        if (!original.getTransactionDate().equals(LocalDate.now()) && !SecurityUtils.isSupervisorOrAbove()) {
            throw new ValidationException("Korábbi napi tranzakció sztornózásához supervisor jóváhagyás szükséges!");
        }

        // Napi sztornó limit ellenőrzése
        int dailyReversals = dailySessionService.getDailyReversalCount();
        if (dailyReversals >= DAILY_REVERSAL_LIMIT && !SecurityUtils.isSupervisorOrAbove()) {
            throw new ValidationException(
                String.format("Napi sztornó limit (%d) elérve! Supervisor jóváhagyás szükséges.", DAILY_REVERSAL_LIMIT));
        }

        // Entitások betöltése
        Company company = companyRepository.findById(companyId)
                .orElseThrow(() -> new ResourceNotFoundException("Company nem található"));
        Branch branch = branchRepository.findById(branchId)
                .orElseThrow(() -> new ResourceNotFoundException("Iroda nem található"));
        Worker worker = workerRepository.findById(workerId)
                .orElseThrow(() -> new ResourceNotFoundException("Pénztáros nem található"));

        // POS terminál sztornó - ha az eredeti tranzakció bankkártyás volt
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
                throw new ValidationException("POS sztornó elutasítva: " + posResult.errorMessage());
            }
            posAuthCode = posResult.authorizationCode();
            posRefNumber = posResult.referenceNumber();
            log.info("POS sztornó elfogadva: auth={}, ref={}", posAuthCode, posRefNumber);
        }

        // Bizonylat szám generálása - az EREDETI típus számlálójából (NEM külön S prefix!)
        String receiptNumber = receiptSequenceService.generateReversalReceiptNumber(
                branchId, original.getTransactionType());

        // Sztornó tranzakció létrehozása (ellentétes értékekkel)
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
                .exchangeRate(original.getExchangeRate())
                .hufAmount(original.getHufAmount())
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
                .notes("Sztornó: " + original.getReceiptNumber() + " - " + request.getReason())
                .build();

        Transaction savedReversal = transactionRepository.save(reversal);
        linkCameraEvidence(savedReversal);

        // Eredeti tranzakció státuszának frissítése
        original.setStatus(TransactionStatus.REVERSED);
        transactionRepository.save(original);

        // Kassza visszaállítása (eredeti tranzakció ellentéte)
        Long currencyId = original.getCurrency().getId();
        if (original.getTransactionType() == TransactionType.BUY) {
            // Eredeti vétel visszavonása: valuta -, HUF +
            updateCashBalance(branchId, currencyId, original.getCurrencyAmount().negate(), false);
            updateCashBalance(branchId, getHufCurrencyId(), original.getHufAmount(), true);
        } else if (original.getTransactionType() == TransactionType.SELL) {
            // Eredeti eladás visszavonása: valuta +, HUF -
            updateCashBalance(branchId, currencyId, original.getCurrencyAmount(), true);
            updateCashBalance(branchId, getHufCurrencyId(), original.getHufAmount().negate(), false);
        }

        // Napi statisztika frissítése
        dailySessionService.updateSessionStats(
            TransactionType.REVERSAL,
            original.getHufAmount(),
            BigDecimal.ZERO
        );

        // AML göngyölés visszavonása (ha van ügyfél ID)
        if (original.getCustomerId() != null && !original.getCustomerId().isBlank()) {
            amlService.reverseAccumulation(
                original.getCustomerId(),
                original.getHufAmount(),
                original.getTransactionDate().atTime(original.getTransactionTime())
            );
        }

        log.info("Sztornó tranzakció: {} - eredeti: {} - ok: {}",
                receiptNumber, original.getReceiptNumber(), request.getReason());

        return savedReversal;
    }

    /**
     * Részleges visszatérítés végrehajtása.
     *
     * Különbség a teljes sztornótól:
     * - Csak részleges HUF/valuta egyenleg-korrekció történik
     * - Az eredeti tranzakció NEM kerül REVERSED státuszba
     * - Új PARTIAL_REFUND típusú tranzakció jön létre, linkkel az eredetire
     *
     * Legacy: OtpAruvisszavet részleges eset (VTEMP.OTPFUNCTYPE=4, refundAmount < originalAmount)
     */
    public Transaction executePartialRefund(PartialRefundRequest request) {
        validateOpenSession();

        UUID companyId = SecurityUtils.getCurrentCompanyId();
        UUID branchId = SecurityUtils.getCurrentBranchId();
        Long workerId = SecurityUtils.getCurrentWorkerId();

        // Eredeti tranzakció lekérése
        Transaction original = transactionRepository.findById(request.getOriginalTransactionId())
                .orElseThrow(() -> new ResourceNotFoundException("Eredeti tranzakció nem található"));

        // Validációk
        if (original.isReversed()) {
            throw new ValidationException("Ez a tranzakció már sztornózva lett - részleges visszatérítés nem lehetséges!");
        }
        if (original.isReversal() || original.isPartialRefund()) {
            throw new ValidationException("Visszavonási tranzakció nem vonható vissza részlegesen!");
        }
        if (!original.getBranch().getId().equals(branchId)) {
            throw new ValidationException("Csak saját iroda tranzakcióját lehet visszatéríteni!");
        }

        BigDecimal refundHuf = request.getRefundHufAmount();
        if (refundHuf == null || refundHuf.compareTo(BigDecimal.ZERO) <= 0) {
            throw new ValidationException("Visszatérítés összege pozitív kell legyen!");
        }
        if (refundHuf.compareTo(original.getHufAmount()) > 0) {
            throw new ValidationException(
                String.format("Visszatérítés összege (%s Ft) nem haladhatja meg az eredeti összeget (%s Ft)!",
                    refundHuf.toPlainString(), original.getHufAmount().toPlainString()));
        }

        // Arányos valutaösszeg kiszámítása, ha nem adták meg
        BigDecimal refundCurrency = request.getRefundCurrencyAmount();
        if (refundCurrency == null || refundCurrency.compareTo(BigDecimal.ZERO) <= 0) {
            if (original.getHufAmount().compareTo(BigDecimal.ZERO) > 0) {
                // arány: refundCurrency = originalCurrency * (refundHuf / originalHuf)
                refundCurrency = original.getCurrencyAmount()
                        .multiply(refundHuf)
                        .divide(original.getHufAmount(), 4, RoundingMode.HALF_UP);
            } else {
                refundCurrency = BigDecimal.ZERO;
            }
        }

        // Entitások betöltése
        Company company = companyRepository.findById(companyId)
                .orElseThrow(() -> new ResourceNotFoundException("Company nem található"));
        Branch branch = branchRepository.findById(branchId)
                .orElseThrow(() -> new ResourceNotFoundException("Iroda nem található"));
        Worker worker = workerRepository.findById(workerId)
                .orElseThrow(() -> new ResourceNotFoundException("Pénztáros nem található"));

        // Bizonylat szám generálása (az eredeti típus számlálójából)
        String receiptNumber = receiptSequenceService.generateReversalReceiptNumber(
                branchId, original.getTransactionType());

        // Részleges visszatérítési tranzakció létrehozása
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
                .notes("Részleges visszatérítés: " + original.getReceiptNumber()
                        + " - " + refundHuf.toPlainString() + " Ft - " + request.getReason())
                .build();

        Transaction saved = transactionRepository.save(partialRefund);
        linkCameraEvidence(saved);

        // Kassza korrekció: csak a visszatérített összeggel
        Long currencyId = original.getCurrency().getId();
        if (original.getTransactionType() == TransactionType.BUY) {
            // Eredeti vétel részleges visszavonása: valuta -, HUF +
            updateCashBalance(branchId, currencyId, refundCurrency.negate(), false);
            updateCashBalance(branchId, getHufCurrencyId(), refundHuf, true);
        } else if (original.getTransactionType() == TransactionType.SELL) {
            // Eredeti eladás részleges visszavonása: valuta +, HUF -
            updateCashBalance(branchId, currencyId, refundCurrency, true);
            updateCashBalance(branchId, getHufCurrencyId(), refundHuf.negate(), false);
        }

        // Napi statisztika frissítése
        dailySessionService.updateSessionStats(
            TransactionType.PARTIAL_REFUND,
            refundHuf,
            BigDecimal.ZERO
        );

        log.info("Részleges visszatérítés: {} - eredeti: {} - összeg: {} Ft - ok: {}",
                receiptNumber, original.getReceiptNumber(), refundHuf.toPlainString(), request.getReason());

        return saved;
    }

    /**
     * Konverzió végrehajtása (valuta-valuta csere)
     *
     * Legacy: KONVERZIO funkció
     */
    public Transaction executeConversion(ConversionRequest request) {
        validateOpenSession();

        UUID companyId = SecurityUtils.getCurrentCompanyId();
        UUID branchId = SecurityUtils.getCurrentBranchId();
        Long workerId = SecurityUtils.getCurrentWorkerId();

        // Entitások betöltése
        Company company = companyRepository.findById(companyId)
                .orElseThrow(() -> new ResourceNotFoundException("Company nem található"));
        Branch branch = branchRepository.findById(branchId)
                .orElseThrow(() -> new ResourceNotFoundException("Iroda nem található"));
        Worker worker = workerRepository.findById(workerId)
                .orElseThrow(() -> new ResourceNotFoundException("Pénztáros nem található"));

        Long fromCurrencyId = resolveCurrencyId(request.getFromCurrencyId(), request.getFromCurrencyCode());
        Long toCurrencyId = resolveCurrencyId(request.getToCurrencyId(), request.getToCurrencyCode());

        Currency fromCurrency = currencyRepository.findById(fromCurrencyId)
                .orElseThrow(() -> new ResourceNotFoundException("Forrás valuta nem található"));
        Currency toCurrency = currencyRepository.findById(toCurrencyId)
                .orElseThrow(() -> new ResourceNotFoundException("Cél valuta nem található"));

        // Azonos valuta konverzió tiltása
        if (fromCurrencyId.equals(toCurrencyId)) {
            throw new ValidationException("Azonos valutanemek közötti konverzió nem lehetséges!");
        }

        // HUF konverzió tiltása - HUF-ra/HUF-ról vétel/eladás használandó
        if ("HUF".equals(fromCurrency.getCode()) || "HUF".equals(toCurrency.getCode())) {
            throw new ValidationException("HUF konverzió nem lehetséges! Használja a vétel/eladás funkciót.");
        }

        // Árfolyamok lekérése
        ExchangeRate fromRate = exchangeRateService.getCurrentRate(fromCurrencyId);
        ExchangeRate toRate = exchangeRateService.getCurrentRate(toCurrencyId);

        // HUF-on keresztül konvertálás
        BigDecimal hufAmount = request.getFromAmount().multiply(fromRate.getBaseBuyRate())
                .setScale(0, RoundingMode.HALF_UP);

        // Magyar 5 Ft-os kerekítés a köztes HUF összegre
        BigDecimal roundedHufAmount = HungarianRounding.roundToFive(hufAmount);
        BigDecimal roundingDifference = roundedHufAmount.subtract(hufAmount);

        BigDecimal toAmountRaw = roundedHufAmount.divide(toRate.getBaseSellRate(), 2, RoundingMode.HALF_UP);
        BigDecimal toAmount = toAmountRaw.setScale(2, RoundingMode.FLOOR);

        // AML ellenőrzés konverziónál is (HUF egyenértéken)
        performAmlCheck(roundedHufAmount, request.getCustomerId(), request.getCustomerName(),
                request.getCustomerDocumentNumber(), fromCurrency.getCode());

        // Készlet ellenőrzése
        validateCurrencyStock(branchId, toCurrency.getId(), toAmount);

        // Kezelési díj szerver oldali számítás
        BigDecimal serverHandlingFee = handlingFeeCalculator.calculate(
                roundedHufAmount, TransactionType.CONVERSION, request.getHandlingFee());

        // GAP 4: Magyar jogszabályi követelmény - konverzió = 2 bizonylat
        // 1. "Konverziós vétel" bizonylat (forrás valuta → HUF)
        // 2. "Konverziós eladás" bizonylat (HUF → cél valuta)
        String buyReceiptNumber = receiptSequenceService.generateReceiptNumber(branchId, TransactionType.BUY);
        String sellReceiptNumber = receiptSequenceService.generateReceiptNumber(branchId, TransactionType.SELL);

        // Konverziós árfolyam számítása (megmarad a fő CONVERSION rekordon is)
        BigDecimal conversionRate = fromRate.getBaseBuyRate().divide(toRate.getBaseSellRate(), 6, RoundingMode.HALF_UP);

        // Fő konverziós tranzakció (a logikai rekord)
        String conversionReceiptNumber = receiptSequenceService.generateReceiptNumber(branchId, TransactionType.CONVERSION);

        Transaction transaction = Transaction.builder()
                .company(company)
                .branch(branch)
                .worker(worker)
                .receiptNumber(conversionReceiptNumber)
                .transactionType(TransactionType.CONVERSION)
                .status(TransactionStatus.COMPLETED)
                .transactionDate(LocalDate.now())
                .transactionTime(LocalTime.now())
                .currency(fromCurrency)
                .currencyAmount(request.getFromAmount())
                .exchangeRate(conversionRate)
                .hufAmount(roundedHufAmount)
                .handlingFee(serverHandlingFee)
                .roundingAmount(roundingDifference)
                .customerId(request.getCustomerId())
                .customerName(request.getCustomerName())
                .notes(String.format("Konverzió: %s %s -> %s %s",
                    request.getFromAmount(), fromCurrency.getCode(),
                    toAmount, toCurrency.getCode()))
                .build();

        Transaction saved = transactionRepository.save(transaction);
        linkCameraEvidence(saved);

        // GAP 4: Konverziós vétel bizonylat (forrás valuta → HUF)
        Transaction convBuy = Transaction.builder()
                .company(company)
                .branch(branch)
                .worker(worker)
                .receiptNumber(buyReceiptNumber)
                .transactionType(TransactionType.BUY)
                .status(TransactionStatus.COMPLETED)
                .transactionDate(LocalDate.now())
                .transactionTime(LocalTime.now())
                .currency(fromCurrency)
                .currencyAmount(request.getFromAmount())
                .exchangeRate(fromRate.getBaseBuyRate())
                .hufAmount(roundedHufAmount)
                .handlingFee(BigDecimal.ZERO)
                .roundingAmount(roundingDifference)
                .linkedReceiptNumber(sellReceiptNumber)
                .customerId(request.getCustomerId())
                .customerName(request.getCustomerName())
                .notes(String.format("Konverziós vétel: %s %s → %s HUF (pár: %s)",
                    request.getFromAmount(), fromCurrency.getCode(),
                    roundedHufAmount, sellReceiptNumber))
                .build();
        convBuy = transactionRepository.save(convBuy);
        linkCameraEvidence(convBuy);

        // GAP 4: Konverziós eladás bizonylat (HUF → cél valuta)
        Transaction convSell = Transaction.builder()
                .company(company)
                .branch(branch)
                .worker(worker)
                .receiptNumber(sellReceiptNumber)
                .transactionType(TransactionType.SELL)
                .status(TransactionStatus.COMPLETED)
                .transactionDate(LocalDate.now())
                .transactionTime(LocalTime.now())
                .currency(toCurrency)
                .currencyAmount(toAmount)
                .exchangeRate(toRate.getBaseSellRate())
                .hufAmount(roundedHufAmount)
                .handlingFee(serverHandlingFee)
                .roundingAmount(BigDecimal.ZERO)
                .linkedReceiptNumber(buyReceiptNumber)
                .customerId(request.getCustomerId())
                .customerName(request.getCustomerName())
                .notes(String.format("Konverziós eladás: %s HUF → %s %s (pár: %s)",
                    roundedHufAmount, toAmount, toCurrency.getCode(),
                    buyReceiptNumber))
                .build();
        convSell = transactionRepository.save(convSell);
        linkCameraEvidence(convSell);

        // Kassza frissítése
        updateCashBalance(branchId, fromCurrency.getId(), request.getFromAmount(), true);  // forrás valuta +
        updateCashBalance(branchId, toCurrency.getId(), toAmount.negate(), false);         // cél valuta -

        // Konverzió napi statisztikája a két valós pénzmozgó lábon jelenjen meg.
        dailySessionService.updateSessionStats(TransactionType.BUY, roundedHufAmount, BigDecimal.ZERO);
        dailySessionService.updateSessionStats(TransactionType.SELL, roundedHufAmount, serverHandlingFee);

        log.info("Konverzió: {} - {} {} -> {} {} (HUF köztes: {}, kerekítés: {}, bizonylatok: {} + {})",
                conversionReceiptNumber, request.getFromAmount(), fromCurrency.getCode(),
                toAmount, toCurrency.getCode(), roundedHufAmount, roundingDifference,
                buyReceiptNumber, sellReceiptNumber);

        return saved;
    }

    // ============ MULTI-LINE TRANZAKCIÓK ============

    /**
     * Multi-line vetel tranzakcio (tobb valutasor egy bizonylaton).
     * Legacy: BLOKKTETEL tabla - max 6 kulonbozo valutasor.
     *
     * A fejlec (Transaction) az elso sor valutajaval jon letre, de a fo osszegek
     * (hufAmount, currencyAmount) a sorok aggregaltjai.
     */
    private Transaction executeMultiLineBuy(BuyRequest request) {
        validateOpenSession();
        validateMultiLineRequest(request.getLines());

        UUID companyId = SecurityUtils.getCurrentCompanyId();
        UUID branchId = SecurityUtils.getCurrentBranchId();
        Long workerId = SecurityUtils.getCurrentWorkerId();

        Company company = companyRepository.findById(companyId)
                .orElseThrow(() -> new ResourceNotFoundException("Company nem található"));
        Branch branch = branchRepository.findById(branchId)
                .orElseThrow(() -> new ResourceNotFoundException("Iroda nem található"));
        Worker worker = workerRepository.findById(workerId)
                .orElseThrow(() -> new ResourceNotFoundException("Pénztáros nem található"));

        // Kedvezmeny validalas
        if (request.getDiscountPercent() != null && request.getDiscountPercent().compareTo(BigDecimal.ZERO) > 0) {
            calculationService.validateDiscount(request.getDiscountPercent());
        }

        // Elso sor valutaja a fejlec valutaja (legacy konvencio)
        LineRequest firstLine = request.getLines().get(0);
        Long firstCurrencyId = resolveCurrencyId(firstLine.getCurrencyId(), firstLine.getCurrencyCode());
        Currency firstCurrency = currencyRepository.findById(firstCurrencyId)
                .orElseThrow(() -> new ResourceNotFoundException("Valuta nem található"));

        // Soronkenti feldolgozas: arfolyam + HUF szamitas
        BigDecimal totalHuf = BigDecimal.ZERO;
        BigDecimal totalCurrencyAmount = BigDecimal.ZERO;
        java.util.List<TransactionLine> transactionLines = new java.util.ArrayList<>();

        for (int i = 0; i < request.getLines().size(); i++) {
            final int lineIdx = i;
            LineRequest lineReq = request.getLines().get(i);
            Long lineCurrencyId = resolveCurrencyId(lineReq.getCurrencyId(), lineReq.getCurrencyCode());
            Currency lineCurrency = currencyRepository.findById(lineCurrencyId)
                    .orElseThrow(() -> new ResourceNotFoundException("Valuta nem található: sor " + (lineIdx + 1)));

            ExchangeRate lineRate = exchangeRateService.getCurrentRate(lineCurrencyId);
            BigDecimal appliedRate = calculationService.resolveBuyRate(lineRate, lineReq.getBanknoteCount(), lineReq.getCustomExchangeRate());

            TransactionLine line = TransactionLine.builder()
                    .lineNumber(lineIdx + 1)
                    .currency(lineCurrency)
                    .appliedRate(appliedRate)
                    .originalRate(lineRate.getBaseBuyRate())
                    .settlementRate(lineRate.getBaseBuyRate())
                    .banknoteCount(lineReq.getBanknoteCount())
                    .discountType(lineReq.getDiscountType() != null ? lineReq.getDiscountType() : 0)
                    .build();

            // Forint ertek szamitas (calculateHufValue hasznalja a currency entity-t)
            BigDecimal lineHuf = line.calculateHufValue();
            line.setHufValue(lineHuf);

            totalHuf = totalHuf.add(lineHuf);
            totalCurrencyAmount = totalCurrencyAmount.add(lineReq.getBanknoteCount());
            transactionLines.add(line);
        }

        // Kedvezmeny az osszes sorra
        BigDecimal hufAfterDiscount = calculationService.applyBuyDiscount(totalHuf, request.getDiscountPercent());

        // Kezelesi dij
        BigDecimal serverHandlingFee = handlingFeeCalculator.calculate(
                hufAfterDiscount, TransactionType.BUY, request.getHandlingFee());
        BigDecimal grossAmount = handlingFeeCalculator.calculateBuyGross(hufAfterDiscount, serverHandlingFee);

        // Magyar 5 Ft kerekites
        BigDecimal payableAmount = HungarianRounding.roundToFive(grossAmount);
        BigDecimal roundingDifference = payableAmount.subtract(grossAmount);

        // 300K+ ugyfelazonositas
        validateIdentification(payableAmount, request.getCustomerName(), request.getCustomerDocumentNumber());

        // AML ellenorzes az aggregalt osszegre
        performAmlCheck(payableAmount, request.getCustomerId(), request.getCustomerName(),
                request.getCustomerDocumentNumber(), firstCurrency.getCode());

        // Bizonylat szam generalas
        String receiptNumber = receiptSequenceService.generateReceiptNumber(branchId, TransactionType.BUY);

        BigDecimal discountAmount = calculationService.calculateDiscountAmount(totalHuf, request.getDiscountPercent());

        // POS terminal kezeles
        PaymentMethod paymentMethod = request.getPaymentMethod() != null ? request.getPaymentMethod() : PaymentMethod.CASH;
        String posAuthCode = null;
        String posRefNumber = null;
        String posTerminalId = request.getPosTerminalId();

        if (paymentMethod == PaymentMethod.CARD) {
            if (posTerminalId == null || posTerminalId.isBlank()) {
                throw new ValidationException("Bankkártyás fizetéshez POS terminál azonosító kötelező!");
            }
            PosTransactionResult posResult = posTerminalService.initiatePayment(
                    payableAmount, "HUF", posTerminalId);
            if (!posResult.approved()) {
                throw new ValidationException("Bankkártyás fizetés elutasítva: " + posResult.errorMessage());
            }
            posAuthCode = posResult.authorizationCode();
            posRefNumber = posResult.referenceNumber();
        }

        // Atlagos arfolyam a fejlechez (sulyozott atlag)
        BigDecimal avgRate = totalCurrencyAmount.compareTo(BigDecimal.ZERO) > 0
                ? totalHuf.divide(totalCurrencyAmount, 4, RoundingMode.HALF_UP)
                : BigDecimal.ZERO;

        // Tranzakcio fejlec letrehozasa
        Transaction transaction = Transaction.builder()
                .company(company)
                .branch(branch)
                .worker(worker)
                .receiptNumber(receiptNumber)
                .transactionType(TransactionType.BUY)
                .status(TransactionStatus.COMPLETED)
                .transactionDate(LocalDate.now())
                .transactionTime(LocalTime.now())
                .currency(firstCurrency)
                .currencyAmount(totalCurrencyAmount)
                .exchangeRate(avgRate)
                .hufAmount(payableAmount)
                .handlingFee(serverHandlingFee)
                .discountPercent(request.getDiscountPercent() != null ? request.getDiscountPercent() : BigDecimal.ZERO)
                .discountAmount(discountAmount)
                .roundingAmount(roundingDifference)
                .multiLine(true)
                .lineCount(request.getLines().size())
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

        // Tetelsorok mentese
        for (TransactionLine line : transactionLines) {
            line.setTransaction(saved);
        }
        saved.getLines().addAll(transactionLines);
        saved = transactionRepository.save(saved);
        linkCameraEvidence(saved);

        // Kassza frissites - soronkent valuta +, ossz HUF -
        for (TransactionLine line : transactionLines) {
            updateCashBalance(branchId, line.getCurrency().getId(), line.getBanknoteCount(), true);
        }
        updateCashBalance(branchId, getHufCurrencyId(), payableAmount.negate(), false);

        // Napi statisztika
        dailySessionService.updateSessionStats(TransactionType.BUY, payableAmount, serverHandlingFee);

        log.info("Multi-line vétel: {} - {} sor, összesen {} HUF (kerekítés: {} Ft, díj: {} Ft)",
                receiptNumber, request.getLines().size(), payableAmount, roundingDifference, serverHandlingFee);

        return saved;
    }

    /**
     * Multi-line eladas tranzakcio (tobb valutasor egy bizonylaton).
     */
    private Transaction executeMultiLineSell(SellRequest request) {
        validateOpenSession();
        validateMultiLineRequest(request.getLines());

        UUID companyId = SecurityUtils.getCurrentCompanyId();
        UUID branchId = SecurityUtils.getCurrentBranchId();
        Long workerId = SecurityUtils.getCurrentWorkerId();

        Company company = companyRepository.findById(companyId)
                .orElseThrow(() -> new ResourceNotFoundException("Company nem található"));
        Branch branch = branchRepository.findById(branchId)
                .orElseThrow(() -> new ResourceNotFoundException("Iroda nem található"));
        Worker worker = workerRepository.findById(workerId)
                .orElseThrow(() -> new ResourceNotFoundException("Pénztáros nem található"));

        // Kedvezmeny validalas
        if (request.getDiscountPercent() != null && request.getDiscountPercent().compareTo(BigDecimal.ZERO) > 0) {
            calculationService.validateDiscount(request.getDiscountPercent());
        }

        // Elso sor valutaja a fejlec valutaja
        LineRequest firstLine = request.getLines().get(0);
        Long firstCurrencyId = resolveCurrencyId(firstLine.getCurrencyId(), firstLine.getCurrencyCode());
        Currency firstCurrency = currencyRepository.findById(firstCurrencyId)
                .orElseThrow(() -> new ResourceNotFoundException("Valuta nem található"));

        BigDecimal totalHuf = BigDecimal.ZERO;
        BigDecimal totalCurrencyAmount = BigDecimal.ZERO;
        java.util.List<TransactionLine> transactionLines = new java.util.ArrayList<>();

        for (int i = 0; i < request.getLines().size(); i++) {
            final int lineIdx = i;
            LineRequest lineReq = request.getLines().get(i);
            Long lineCurrencyId = resolveCurrencyId(lineReq.getCurrencyId(), lineReq.getCurrencyCode());
            Currency lineCurrency = currencyRepository.findById(lineCurrencyId)
                    .orElseThrow(() -> new ResourceNotFoundException("Valuta nem található: sor " + (lineIdx + 1)));

            ExchangeRate lineRate = exchangeRateService.getCurrentRate(lineCurrencyId);
            BigDecimal appliedRate = calculationService.resolveSellRate(lineRate, lineReq.getBanknoteCount(), lineReq.getCustomExchangeRate());

            // Keszlet ellenorzes soronkent
            validateCurrencyStock(branchId, lineCurrency.getId(), lineReq.getBanknoteCount());

            TransactionLine line = TransactionLine.builder()
                    .lineNumber(lineIdx + 1)
                    .currency(lineCurrency)
                    .appliedRate(appliedRate)
                    .originalRate(lineRate.getBaseSellRate())
                    .settlementRate(lineRate.getBaseSellRate())
                    .banknoteCount(lineReq.getBanknoteCount())
                    .discountType(lineReq.getDiscountType() != null ? lineReq.getDiscountType() : 0)
                    .build();

            BigDecimal lineHuf = line.calculateHufValue();
            line.setHufValue(lineHuf);

            totalHuf = totalHuf.add(lineHuf);
            totalCurrencyAmount = totalCurrencyAmount.add(lineReq.getBanknoteCount());
            transactionLines.add(line);
        }

        // Kedvezmeny az osszes sorra
        BigDecimal hufAfterDiscount = calculationService.applySellDiscount(totalHuf, request.getDiscountPercent());

        // Kezelesi dij
        BigDecimal serverHandlingFee = handlingFeeCalculator.calculate(
                hufAfterDiscount, TransactionType.SELL, request.getHandlingFee());
        BigDecimal grossAmount = handlingFeeCalculator.calculateSellGross(hufAfterDiscount, serverHandlingFee);

        // Magyar 5 Ft kerekites
        BigDecimal payableAmount = HungarianRounding.roundToFive(grossAmount);
        BigDecimal roundingDifference = payableAmount.subtract(grossAmount);

        // 300K+ ugyfelazonositas
        validateIdentification(payableAmount, request.getCustomerName(), request.getCustomerDocumentNumber());

        // AML ellenorzes
        performAmlCheck(payableAmount, request.getCustomerId(), request.getCustomerName(),
                request.getCustomerDocumentNumber(), firstCurrency.getCode());

        String receiptNumber = receiptSequenceService.generateReceiptNumber(branchId, TransactionType.SELL);
        BigDecimal discountAmount = calculationService.calculateDiscountAmount(totalHuf, request.getDiscountPercent());

        // POS terminal kezeles
        PaymentMethod paymentMethod = request.getPaymentMethod() != null ? request.getPaymentMethod() : PaymentMethod.CASH;
        String posAuthCode = null;
        String posRefNumber = null;
        String posTerminalId = request.getPosTerminalId();

        if (paymentMethod == PaymentMethod.CARD) {
            if (posTerminalId == null || posTerminalId.isBlank()) {
                throw new ValidationException("Bankkártyás fizetéshez POS terminál azonosító kötelező!");
            }
            PosTransactionResult posResult = posTerminalService.initiatePayment(
                    payableAmount, "HUF", posTerminalId);
            if (!posResult.approved()) {
                throw new ValidationException("Bankkártyás fizetés elutasítva: " + posResult.errorMessage());
            }
            posAuthCode = posResult.authorizationCode();
            posRefNumber = posResult.referenceNumber();
        }

        BigDecimal avgRate = totalCurrencyAmount.compareTo(BigDecimal.ZERO) > 0
                ? totalHuf.divide(totalCurrencyAmount, 4, RoundingMode.HALF_UP)
                : BigDecimal.ZERO;

        Transaction transaction = Transaction.builder()
                .company(company)
                .branch(branch)
                .worker(worker)
                .receiptNumber(receiptNumber)
                .transactionType(TransactionType.SELL)
                .status(TransactionStatus.COMPLETED)
                .transactionDate(LocalDate.now())
                .transactionTime(LocalTime.now())
                .currency(firstCurrency)
                .currencyAmount(totalCurrencyAmount)
                .exchangeRate(avgRate)
                .hufAmount(payableAmount)
                .handlingFee(serverHandlingFee)
                .discountPercent(request.getDiscountPercent() != null ? request.getDiscountPercent() : BigDecimal.ZERO)
                .discountAmount(discountAmount)
                .roundingAmount(roundingDifference)
                .multiLine(true)
                .lineCount(request.getLines().size())
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

        for (TransactionLine line : transactionLines) {
            line.setTransaction(saved);
        }
        saved.getLines().addAll(transactionLines);
        saved = transactionRepository.save(saved);
        linkCameraEvidence(saved);

        // Kassza frissites - soronkent valuta -, ossz HUF +
        for (TransactionLine line : transactionLines) {
            updateCashBalance(branchId, line.getCurrency().getId(), line.getBanknoteCount().negate(), false);
        }
        updateCashBalance(branchId, getHufCurrencyId(), payableAmount, true);

        // Napi statisztika
        dailySessionService.updateSessionStats(TransactionType.SELL, payableAmount, serverHandlingFee);

        log.info("Multi-line eladás: {} - {} sor, összesen {} HUF (kerekítés: {} Ft, díj: {} Ft)",
                receiptNumber, request.getLines().size(), payableAmount, roundingDifference, serverHandlingFee);

        return saved;
    }

    /**
     * Multi-line request validacio.
     * Legacy: BLOKKTETEL - max 6 kulonbozo valutasor bizonylaton.
     */
    private void validateMultiLineRequest(java.util.List<LineRequest> lines) {
        if (lines == null || lines.isEmpty()) {
            throw new ValidationException("Multi-line bizonylathoz legalabb egy tetelsor szukseges!");
        }
        if (lines.size() > MAX_TRANSACTION_LINES) {
            throw new ValidationException(
                String.format("Egy bizonylaton maximum %d tetelsor lehet (BLOKKTETEL limit)!", MAX_TRANSACTION_LINES));
        }
        for (int i = 0; i < lines.size(); i++) {
            LineRequest line = lines.get(i);
            if (line.getBanknoteCount() == null || line.getBanknoteCount().compareTo(BigDecimal.ZERO) <= 0) {
                throw new ValidationException(
                    String.format("Tetelsor %d: bankjegy darabszam kotelezo es pozitiv kell legyen!", i + 1));
            }
            if ((line.getCurrencyId() == null || line.getCurrencyId() <= 0)
                    && (line.getCurrencyCode() == null || line.getCurrencyCode().isBlank())) {
                throw new ValidationException(
                    String.format("Tetelsor %d: valuta azonosito (currencyId) vagy kod (currencyCode) kotelezo!", i + 1));
            }
        }
    }

    /**
     * Tranzakcio tetelsorainak lekerdezese.
     */
    @Transactional(readOnly = true)
    public java.util.List<TransactionLine> getTransactionLines(Long transactionId) {
        return transactionLineRepository.findByTransactionIdOrderByLineNumber(transactionId);
    }

    // ============ LEKÉRDEZÉSEK ============

    /**
     * Tranzakció keresése bizonylat szám alapján
     */
    @Transactional(readOnly = true)
    public Transaction findByReceiptNumber(String receiptNumber) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return transactionRepository.findByReceiptNumberAndCompanyId(receiptNumber, companyId)
                .orElseThrow(() -> new ResourceNotFoundException("Bizonylat nem található: " + receiptNumber));
    }

    /**
     * Napi tranzakciók lekérése
     */
    @Transactional(readOnly = true)
    public List<Transaction> getDailyTransactions() {
        UUID branchId = SecurityUtils.getCurrentBranchId();
        return transactionRepository.findByBranchAndDate(branchId, LocalDate.now());
    }

    /**
     * Tranzakciók szűrése és lapozás
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
     * Napi forgalom összesítés
     */
    @Transactional(readOnly = true)
    public DailyTurnoverSummary getDailyTurnover() {
        UUID branchId = SecurityUtils.getCurrentBranchId();
        LocalDate today = LocalDate.now();

        BigDecimal buyTotal = transactionRepository.sumDailyTurnover(branchId, today, TransactionType.BUY);
        BigDecimal sellTotal = transactionRepository.sumDailyTurnover(branchId, today, TransactionType.SELL);
        long reversalCount = transactionRepository.countReversalsByBranchAndDate(branchId, today);

        // Bővített mezők: count és handling fees
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
                // Bővített mezők
                .totalBuyCount(buyCount)
                .totalSellCount(sellCount)
                .totalBuyHuf(buyTotal != null ? buyTotal : BigDecimal.ZERO)
                .totalSellHuf(sellTotal != null ? sellTotal : BigDecimal.ZERO)
                .totalHandlingFees(totalHandlingFees != null ? totalHandlingFees : BigDecimal.ZERO)
                .totalReversalCount(reversalCount)
                .build();
    }

    // ============ HELPER METÓDUSOK ============

    private void validateOpenSession() {
        if (!dailySessionService.hasOpenSession()) {
            throw new ValidationException("Nincs nyitott napi munkamenet! Először nyissa meg a napot.");
        }
    }

    /**
     * Teljes AML ellenőrzés a tranzakció előtt (Pmt. 2017. évi LIII. tv.).
     *
     * Hívja az AmlService.checkTransaction()-t az alapszintű ellenőrzéshez
     * (azonosítás, éves göngyölés, napi gyanúsági limit), valamint a
     * checkAllThresholds()-t a legacy BIGCTRL.DLL klasszifikációhoz (TranzTipus).
     */
    private void performAmlCheck(BigDecimal hufAmount, String customerId,
                                 String customerName, String documentNumber, String currencyCode) {
        // 1. Alapszintű AML ellenőrzés (azonosítás + göngyölés + gyanúsági flag)
        AmlService.AmlBasicCheckResult basicResult = amlService.checkTransaction(
                hufAmount, customerId, customerName, documentNumber);

        if (basicResult == null) {
            log.error("AML checkTransaction null eredmenyt adott, tranzakcio blokkolva");
            throw new ValidationException("AML ellenőrzés nem elérhető, a tranzakció nem hajtható végre!");
        }

        if (!basicResult.isApproved()) {
            throw new ValidationException(basicResult.getRejectionReason() != null
                    ? basicResult.getRejectionReason()
                    : "AML ellenőrzés sikertelen!");
        }

        if (basicResult.isRequiresApproval()) {
            throw new ValidationException(basicResult.getApprovalReason() != null
                    ? basicResult.getApprovalReason()
                    : "Supervisor jóváhagyás szükséges (AML limit)!");
        }

        // 2. Legacy BIGCTRL.DLL klasszifikáció - blokkoló TranzTipus -1 ellenőrzés
        if (customerId != null && !customerId.isBlank()) {
            var thresholdResult = amlService.checkAllThresholds(customerId, hufAmount, currencyCode);
            if (thresholdResult != null && thresholdResult.isBlocked()) {
                String warnings = thresholdResult.getWarnings() != null && !thresholdResult.getWarnings().isEmpty()
                        ? String.join("; ", thresholdResult.getWarnings())
                        : "AML szabály alapján blokkolva";
                throw new ValidationException(warnings);
            }
        }

        // 3. Részletes azonosítás logolása (1.5M+ Ft)
        if (basicResult.isRequiresDetailedId()) {
            log.warn("AML: Részletes azonosítás szükséges - {} Ft, ügyfél: {}", hufAmount, customerId);
        }
    }

    private void validateIdentification(BigDecimal hufAmount, String customerName, String documentNumber) {
        if (hufAmount.compareTo(IDENTIFICATION_LIMIT) >= 0) {
            if (customerName == null || customerName.isBlank()) {
                throw new ValidationException(
                    String.format("%s Ft feletti tranzakcióhoz ügyfél azonosítás kötelező!",
                        IDENTIFICATION_LIMIT.toPlainString()));
            }
            if (documentNumber == null || documentNumber.isBlank()) {
                throw new ValidationException(
                    String.format("%s Ft feletti tranzakcióhoz igazolvány szám kötelező!",
                        IDENTIFICATION_LIMIT.toPlainString()));
            }
        }
    }

    private void validateCurrencyStock(UUID branchId, Long currencyId, BigDecimal amount) {
        CashBalance balance = cashBalanceRepository.findByBranchIdAndCurrencyIdForUpdate(branchId, currencyId)
                .orElse(null);

        if (balance == null || balance.getCurrentBalance().compareTo(amount) < 0) {
            throw new ValidationException("Nincs elegendő valuta készlet!");
        }
    }

    private void updateCashBalance(UUID branchId, Long currencyId, BigDecimal amount, boolean isIncoming) {
        // Pessimistic lock használata race condition elkerülésére
        CashBalance balance = cashBalanceRepository.findByBranchIdAndCurrencyIdForUpdate(branchId, currencyId)
                .orElseThrow(() -> new ResourceNotFoundException("Kassza egyenleg nem található"));

        balance.updateBalance(amount.abs(), isIncoming);
        cashBalanceRepository.save(balance);
    }

    /**
     * @deprecated Használd a {@link ReceiptSequenceService#generateReceiptNumber} metódust.
     * Ez a metódus a régi E+MMDD+5szám formátumot generálja - csak backward compatibility-hez.
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
            // Újrapróbálás: lehet hogy a DB-ben késve került be a HUF valuta
            cachedHufCurrencyId = currencyRepository.findByCode("HUF")
                    .map(c -> c.getId())
                    .orElse(null);
            if (cachedHufCurrencyId == null) {
                throw new ValidationException("HUF valuta nem található az adatbázisban! Kérjük inicializálja a valuta táblát.");
            }
        }
        return cachedHufCurrencyId;
    }

    /**
     * Currency ID feloldása: ha currencyId megvan, azt használjuk, egyébként currencyCode alapján.
     */
    private Long resolveCurrencyId(Long currencyId, String currencyCode) {
        if (currencyId != null && currencyId > 0) {
            return currencyId;
        }
        if (currencyCode != null && !currencyCode.isBlank()) {
            return currencyRepository.findByCode(currencyCode.toUpperCase())
                    .map(c -> c.getId())
                    .orElseThrow(() -> new ResourceNotFoundException("Ismeretlen valuta kód: " + currencyCode));
        }
        throw new ValidationException("Valuta azonosító (currencyId) vagy valuta kód (currencyCode) kötelező!");
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
        /** Fizetési mód: CASH (alapértelmezett) vagy CARD (bankkártya) */
        private PaymentMethod paymentMethod;
        /** POS terminál azonosító (csak CARD fizetésnél kötelező) */
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
        /** Fizetési mód: CASH (alapértelmezett) vagy CARD (bankkártya) */
        private PaymentMethod paymentMethod;
        /** POS terminál azonosító (csak CARD fizetésnél kötelező) */
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
        /** Visszatérítendő HUF összeg */
        private BigDecimal refundHufAmount;
        /** Visszatérítendő valutaösszeg - ha null, arányosan számítjuk */
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
        // Bővített mezők - frontend kompatibilitás
        private long totalBuyCount;
        private long totalSellCount;
        private BigDecimal totalBuyHuf;
        private BigDecimal totalSellHuf;
        private BigDecimal totalHandlingFees;
        private long totalReversalCount;
    }
}
