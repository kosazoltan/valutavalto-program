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
 * Tranzakció szolgáltatás.
 *
 * Legacy: VASARLAS.DLL, ELADAS.DLL, STORNO.DLL funkciók
 * - Vétel: Ügyfél valutát ad el, cég HUF-ot ad
 * - Eladás: Ügyfél HUF-ot ad, cég valutát ad
 * - Sztornó: Korábbi tranzakció visszavonása
 */
@Service
@RequiredArgsConstructor
@Transactional
@Slf4j
public class TransactionService {

    private final TransactionRepository transactionRepository;
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

    // Sztornó limit supervisor nélkül (3 db/nap)
    private static final int DAILY_REVERSAL_LIMIT = 3;

    // Azonosítás nélküli limit HUF-ban (300.000 Ft - NAV szabályozás)
    private static final BigDecimal IDENTIFICATION_LIMIT = new BigDecimal("300000");

    // HUF currency ID cache — startup-kor betöltve, ne kelljen minden tranzakciónál DB-t kérdezni
    private Long cachedHufCurrencyId;

    @PostConstruct
    void initHufCurrencyId() {
        try {
            cachedHufCurrencyId = currencyRepository.findByCode("HUF")
                    .map(c -> c.getId())
                    .orElse(null);
            if (cachedHufCurrencyId != null) {
                log.info("HUF currency ID cached: {}", cachedHufCurrencyId);
            } else {
                log.warn("HUF currency not found in DB — cash balance operations may fail until seeded");
            }
        } catch (Exception e) {
            log.error("Failed to cache HUF currency ID (DB type mismatch?): {}", e.getMessage());
            cachedHufCurrencyId = null;
        }
    }

    /**
     * Vétel tranzakció végrehajtása
     * (Ügyfél valutát ad el, cég HUF-ot fizet)
     *
     * Legacy: VASARLAS.DLL - VETEL funkció
     */
    public Transaction executeBuy(BuyRequest request) {
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
        Currency currency = currencyRepository.findById(request.getCurrencyId())
                .orElseThrow(() -> new ResourceNotFoundException("Valuta nem található"));

        // Árfolyam meghatározása
        ExchangeRate rate = exchangeRateService.getCurrentRate(request.getCurrencyId());

        // HUF összeg számítása (helper kezeli a kedvezményt is)
        BigDecimal hufAmount = calculateBuyHufAmount(
            request.getCurrencyAmount(),
            rate,
            request.getDiscountPercent()
        );

        // Kedvezmény validálás
        if (request.getDiscountPercent() != null && request.getDiscountPercent().compareTo(BigDecimal.ZERO) > 0) {
            validateDiscount(request.getDiscountPercent());
        }

        // Kezelési díj szerver oldali számítás (kliens értékét felülírjuk)
        BigDecimal serverHandlingFee = handlingFeeCalculator.calculate(
                hufAmount, TransactionType.BUY, request.getHandlingFee());

        // Bruttó: vételnél nettó - díj (a cég levonja a kezelési díjat)
        BigDecimal grossAmount = handlingFeeCalculator.calculateBuyGross(hufAmount, serverHandlingFee);

        // Magyar 5 Ft-os kerekítés a fizetendő összegre
        BigDecimal payableAmount = HungarianRounding.roundToFive(grossAmount);
        BigDecimal roundingDifference = payableAmount.subtract(grossAmount);

        // Azonosítás ellenőrzése
        validateIdentification(payableAmount, request.getCustomerName(), request.getCustomerDocumentNumber());

        // Bizonylat szám generálása (új szekvencia rendszer)
        String receiptNumber = receiptSequenceService.generateReceiptNumber(branchId, TransactionType.BUY);

        // Alkalmazott árfolyam (discount NÉLKÜL a pre-discount hufAmount alapján)
        BigDecimal preDiscountHufAmount = request.getCurrencyAmount()
                .multiply(rate.getBaseBuyRate()).setScale(0, RoundingMode.HALF_UP);
        BigDecimal appliedRate = rate.getBuyRateForAmount(preDiscountHufAmount);

        // Kedvezmény összeg a PRE-DISCOUNT értékből (nem a már csökkentett hufAmount-ból!)
        BigDecimal fullHufBeforeDiscount = request.getCurrencyAmount()
                .multiply(appliedRate).setScale(0, RoundingMode.HALF_UP);
        BigDecimal discountAmount = calculateDiscountAmount(fullHufBeforeDiscount, request.getDiscountPercent());

        // POS terminál integráció — bankkártyás fizetésnél
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
        Currency currency = currencyRepository.findById(request.getCurrencyId())
                .orElseThrow(() -> new ResourceNotFoundException("Valuta nem található"));

        // Árfolyam meghatározása
        ExchangeRate rate = exchangeRateService.getCurrentRate(request.getCurrencyId());

        // HUF összeg számítása (helper kezeli a kedvezményt is)
        BigDecimal hufAmount = calculateSellHufAmount(
            request.getCurrencyAmount(),
            rate,
            request.getDiscountPercent()
        );

        // Kedvezmény validálás
        if (request.getDiscountPercent() != null && request.getDiscountPercent().compareTo(BigDecimal.ZERO) > 0) {
            validateDiscount(request.getDiscountPercent());
        }

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

        // Azonosítás ellenőrzése
        validateIdentification(payableAmount, request.getCustomerName(), request.getCustomerDocumentNumber());

        // Bizonylat szám generálása (új szekvencia rendszer)
        String receiptNumber = receiptSequenceService.generateReceiptNumber(branchId, TransactionType.SELL);

        // Alkalmazott árfolyam (discount NÉLKÜL a pre-discount hufAmount alapján)
        BigDecimal preDiscountHufAmount = request.getCurrencyAmount()
                .multiply(rate.getBaseSellRate()).setScale(0, RoundingMode.HALF_UP);
        BigDecimal appliedRate = rate.getSellRateForAmount(preDiscountHufAmount);

        // Kedvezmény összeg a PRE-DISCOUNT értékből (nem a már csökkentett hufAmount-ból!)
        BigDecimal fullHufBeforeDiscount = request.getCurrencyAmount()
                .multiply(appliedRate).setScale(0, RoundingMode.HALF_UP);
        BigDecimal discountAmount = calculateDiscountAmount(fullHufBeforeDiscount, request.getDiscountPercent());

        // POS terminál integráció — bankkártyás fizetésnél
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

        // POS terminál sztornó — ha az eredeti tranzakció bankkártyás volt
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

        // Bizonylat szám generálása — az EREDETI típus számlálójából (NEM külön S prefix!)
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

        Currency fromCurrency = currencyRepository.findById(request.getFromCurrencyId())
                .orElseThrow(() -> new ResourceNotFoundException("Forrás valuta nem található"));
        Currency toCurrency = currencyRepository.findById(request.getToCurrencyId())
                .orElseThrow(() -> new ResourceNotFoundException("Cél valuta nem található"));

        // Árfolyamok lekérése
        ExchangeRate fromRate = exchangeRateService.getCurrentRate(request.getFromCurrencyId());
        ExchangeRate toRate = exchangeRateService.getCurrentRate(request.getToCurrencyId());

        // HUF-on keresztül konvertálás
        BigDecimal hufAmount = request.getFromAmount().multiply(fromRate.getBaseBuyRate())
                .setScale(0, RoundingMode.HALF_UP);

        // Magyar 5 Ft-os kerekítés a köztes HUF összegre
        BigDecimal roundedHufAmount = HungarianRounding.roundToFive(hufAmount);
        BigDecimal roundingDifference = roundedHufAmount.subtract(hufAmount);

        BigDecimal toAmount = roundedHufAmount.divide(toRate.getBaseSellRate(), 2, RoundingMode.HALF_UP);

        // Készlet ellenőrzése
        validateCurrencyStock(branchId, toCurrency.getId(), toAmount);

        // Kezelési díj szerver oldali számítás
        BigDecimal serverHandlingFee = handlingFeeCalculator.calculate(
                roundedHufAmount, TransactionType.CONVERSION, request.getHandlingFee());

        // Bizonylat szám generálása (új szekvencia rendszer)
        String receiptNumber = receiptSequenceService.generateReceiptNumber(branchId, TransactionType.CONVERSION);

        // Konverziós árfolyam számítása
        BigDecimal conversionRate = fromRate.getBaseBuyRate().divide(toRate.getBaseSellRate(), 6, RoundingMode.HALF_UP);

        Transaction transaction = Transaction.builder()
                .company(company)
                .branch(branch)
                .worker(worker)
                .receiptNumber(receiptNumber)
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

        // Kassza frissítése
        updateCashBalance(branchId, fromCurrency.getId(), request.getFromAmount(), true);  // forrás valuta +
        updateCashBalance(branchId, toCurrency.getId(), toAmount.negate(), false);         // cél valuta -

        log.info("Konverzió: {} - {} {} -> {} {} (HUF köztes: {}, kerekítés: {})",
                receiptNumber, request.getFromAmount(), fromCurrency.getCode(),
                toAmount, toCurrency.getCode(), roundedHufAmount, roundingDifference);

        return saved;
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

    private BigDecimal calculateBuyHufAmount(BigDecimal currencyAmount, ExchangeRate rate, BigDecimal discountPercent) {
        // Alap hufAmount discount NÉLKÜL (tier meghatározáshoz)
        BigDecimal baseAmount = currencyAmount.multiply(rate.getBaseBuyRate());
        BigDecimal appliedRate = rate.getBuyRateForAmount(baseAmount);
        BigDecimal hufAmount = currencyAmount.multiply(appliedRate).setScale(0, RoundingMode.HALF_UP);

        // Kedvezmény alkalmazása a VÉGSŐ hufAmount-ra (egyszer!)
        // BUY: ügyfél valutát ad el → kedvezmény = TÖBB forintot kap (spread csökkentés)
        if (discountPercent != null && discountPercent.compareTo(BigDecimal.ZERO) > 0) {
            BigDecimal discount = hufAmount.multiply(discountPercent).divide(new BigDecimal("100"), 0, RoundingMode.HALF_UP);
            hufAmount = hufAmount.add(discount);
        }

        return hufAmount;
    }

    private BigDecimal calculateSellHufAmount(BigDecimal currencyAmount, ExchangeRate rate, BigDecimal discountPercent) {
        // Alap hufAmount discount NÉLKÜL (tier meghatározáshoz)
        BigDecimal baseAmount = currencyAmount.multiply(rate.getBaseSellRate());
        BigDecimal appliedRate = rate.getSellRateForAmount(baseAmount);
        BigDecimal hufAmount = currencyAmount.multiply(appliedRate).setScale(0, RoundingMode.HALF_UP);

        // Kedvezmény alkalmazása a VÉGSŐ hufAmount-ra (egyszer!)
        if (discountPercent != null && discountPercent.compareTo(BigDecimal.ZERO) > 0) {
            BigDecimal discount = hufAmount.multiply(discountPercent).divide(new BigDecimal("100"), 0, RoundingMode.HALF_UP);
            hufAmount = hufAmount.subtract(discount);
        }

        return hufAmount;
    }

    private BigDecimal calculateDiscountAmount(BigDecimal hufAmount, BigDecimal discountPercent) {
        if (discountPercent == null || discountPercent.compareTo(BigDecimal.ZERO) == 0) {
            return BigDecimal.ZERO;
        }
        return hufAmount.multiply(discountPercent).divide(new BigDecimal("100"), 0, RoundingMode.HALF_UP);
    }

    private void validateDiscount(BigDecimal discountPercent) {
        if (discountPercent.compareTo(new BigDecimal("2.0")) > 0 && !SecurityUtils.isSupervisorOrAbove()) {
            throw new ValidationException("2% feletti kedvezményhez supervisor jogosultság szükséges!");
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
        CashBalance balance = cashBalanceRepository.findByBranchIdAndCurrencyId(branchId, currencyId)
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
     * Ez a metódus a régi E+MMDD+5szám formátumot generálja — csak backward compatibility-hez.
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

    // ============ REQUEST/RESPONSE DTO-k ============

    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class BuyRequest {
        private Long currencyId;
        private BigDecimal currencyAmount;
        private BigDecimal discountPercent;
        private BigDecimal handlingFee;
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
    }

    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class SellRequest {
        private Long currencyId;
        private BigDecimal currencyAmount;
        private BigDecimal discountPercent;
        private BigDecimal handlingFee;
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
    public static class ConversionRequest {
        private Long fromCurrencyId;
        private Long toCurrencyId;
        private BigDecimal fromAmount;
        private BigDecimal handlingFee;
        private String customerId;
        private String customerName;
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
        // Bővített mezők — frontend kompatibilitás
        private long totalBuyCount;
        private long totalSellCount;
        private BigDecimal totalBuyHuf;
        private BigDecimal totalSellHuf;
        private BigDecimal totalHandlingFees;
        private long totalReversalCount;
    }
}
