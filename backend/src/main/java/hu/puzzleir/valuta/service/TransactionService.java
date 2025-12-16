package hu.puzzleir.valuta.service;

import com.puzzleir.backend.entity.Branch;
import com.puzzleir.backend.entity.Company;
import com.puzzleir.backend.exception.ResourceNotFoundException;
import com.puzzleir.backend.exception.ValidationException;
import com.puzzleir.backend.repository.BranchRepository;
import com.puzzleir.backend.repository.CompanyRepository;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.repository.*;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

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

    // Sztornó limit supervisor nélkül (3 db/nap)
    private static final int DAILY_REVERSAL_LIMIT = 3;

    // Azonosítás nélküli limit HUF-ban (300.000 Ft - NAV szabályozás)
    private static final BigDecimal IDENTIFICATION_LIMIT = new BigDecimal("300000");

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

        // HUF összeg számítása
        BigDecimal hufAmount = calculateBuyHufAmount(
            request.getCurrencyAmount(),
            rate,
            request.getDiscountPercent()
        );

        // Azonosítás ellenőrzése
        validateIdentification(hufAmount, request.getCustomerName(), request.getCustomerDocumentNumber());

        // Bizonylat szám generálása
        String receiptNumber = generateReceiptNumber(branchId, "V");

        // Alkalmazott árfolyam (limit alapján)
        BigDecimal appliedRate = rate.getBuyRateForAmount(hufAmount);
        if (request.getDiscountPercent() != null && request.getDiscountPercent().compareTo(BigDecimal.ZERO) > 0) {
            // Kedvezmény ellenőrzése
            validateDiscount(request.getDiscountPercent());
            BigDecimal multiplier = BigDecimal.ONE.subtract(request.getDiscountPercent().divide(new BigDecimal("100")));
            appliedRate = appliedRate.multiply(multiplier);
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
                .hufAmount(hufAmount)
                .handlingFee(request.getHandlingFee() != null ? request.getHandlingFee() : BigDecimal.ZERO)
                .discountPercent(request.getDiscountPercent() != null ? request.getDiscountPercent() : BigDecimal.ZERO)
                .discountAmount(calculateDiscountAmount(hufAmount, request.getDiscountPercent()))
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
        updateCashBalance(branchId, getHufCurrencyId(), hufAmount.negate(), false);        // HUF -

        // Napi statisztika frissítése
        dailySessionService.updateSessionStats(
            TransactionType.BUY,
            hufAmount,
            transaction.getHandlingFee()
        );

        log.info("Vétel tranzakció: {} - {} {} @ {} = {} HUF",
                receiptNumber, request.getCurrencyAmount(), currency.getCode(),
                appliedRate, hufAmount);

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

        // HUF összeg számítása
        BigDecimal hufAmount = calculateSellHufAmount(
            request.getCurrencyAmount(),
            rate,
            request.getDiscountPercent()
        );

        // Készlet ellenőrzése
        validateCurrencyStock(branchId, currency.getId(), request.getCurrencyAmount());

        // Azonosítás ellenőrzése
        validateIdentification(hufAmount, request.getCustomerName(), request.getCustomerDocumentNumber());

        // Bizonylat szám generálása
        String receiptNumber = generateReceiptNumber(branchId, "E");

        // Alkalmazott árfolyam (limit alapján)
        BigDecimal appliedRate = rate.getSellRateForAmount(hufAmount);
        if (request.getDiscountPercent() != null && request.getDiscountPercent().compareTo(BigDecimal.ZERO) > 0) {
            validateDiscount(request.getDiscountPercent());
            BigDecimal multiplier = BigDecimal.ONE.subtract(request.getDiscountPercent().divide(new BigDecimal("100")));
            appliedRate = appliedRate.multiply(multiplier);
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
                .hufAmount(hufAmount)
                .handlingFee(request.getHandlingFee() != null ? request.getHandlingFee() : BigDecimal.ZERO)
                .discountPercent(request.getDiscountPercent() != null ? request.getDiscountPercent() : BigDecimal.ZERO)
                .discountAmount(calculateDiscountAmount(hufAmount, request.getDiscountPercent()))
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
        updateCashBalance(branchId, getHufCurrencyId(), hufAmount, true);                            // HUF +

        // Napi statisztika frissítése
        dailySessionService.updateSessionStats(
            TransactionType.SELL,
            hufAmount,
            transaction.getHandlingFee()
        );

        log.info("Eladás tranzakció: {} - {} {} @ {} = {} HUF",
                receiptNumber, request.getCurrencyAmount(), currency.getCode(),
                appliedRate, hufAmount);

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

        // Bizonylat szám generálása
        String receiptNumber = generateReceiptNumber(branchId, "S");

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
        BigDecimal toAmount = hufAmount.divide(toRate.getBaseSellRate(), 2, RoundingMode.HALF_UP);

        // Készlet ellenőrzése
        validateCurrencyStock(branchId, toCurrency.getId(), toAmount);

        // Bizonylat szám generálása
        String receiptNumber = generateReceiptNumber(branchId, "K");

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
                .hufAmount(hufAmount)
                .handlingFee(request.getHandlingFee() != null ? request.getHandlingFee() : BigDecimal.ZERO)
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

        log.info("Konverzió: {} - {} {} -> {} {}",
                receiptNumber, request.getFromAmount(), fromCurrency.getCode(),
                toAmount, toCurrency.getCode());

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

        return DailyTurnoverSummary.builder()
                .date(today)
                .buyTotal(buyTotal)
                .sellTotal(sellTotal)
                .netTotal(sellTotal.subtract(buyTotal))
                .reversalCount(reversalCount)
                .build();
    }

    // ============ HELPER METÓDUSOK ============

    private void validateOpenSession() {
        if (!dailySessionService.hasOpenSession()) {
            throw new ValidationException("Nincs nyitott napi munkamenet! Először nyissa meg a napot.");
        }
    }

    private BigDecimal calculateBuyHufAmount(BigDecimal currencyAmount, ExchangeRate rate, BigDecimal discountPercent) {
        BigDecimal baseAmount = currencyAmount.multiply(rate.getBaseBuyRate());
        BigDecimal appliedRate = rate.getBuyRateForAmount(baseAmount);
        BigDecimal hufAmount = currencyAmount.multiply(appliedRate).setScale(0, RoundingMode.HALF_UP);

        if (discountPercent != null && discountPercent.compareTo(BigDecimal.ZERO) > 0) {
            BigDecimal discount = hufAmount.multiply(discountPercent).divide(new BigDecimal("100"), 0, RoundingMode.HALF_UP);
            hufAmount = hufAmount.subtract(discount);
        }

        return hufAmount;
    }

    private BigDecimal calculateSellHufAmount(BigDecimal currencyAmount, ExchangeRate rate, BigDecimal discountPercent) {
        BigDecimal baseAmount = currencyAmount.multiply(rate.getBaseSellRate());
        BigDecimal appliedRate = rate.getSellRateForAmount(baseAmount);
        BigDecimal hufAmount = currencyAmount.multiply(appliedRate).setScale(0, RoundingMode.HALF_UP);

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
        CashBalance balance = cashBalanceRepository.findByBranchIdAndCurrencyId(branchId, currencyId)
                .orElseThrow(() -> new ResourceNotFoundException("Kassza egyenleg nem található"));

        balance.updateBalance(amount.abs(), isIncoming);
        cashBalanceRepository.save(balance);
    }

    private String generateReceiptNumber(UUID branchId, String prefix) {
        LocalDate today = LocalDate.now();
        String datePrefix = prefix + String.format("%02d%02d", today.getMonthValue(), today.getDayOfMonth());

        String maxReceipt = transactionRepository.findMaxReceiptNumber(branchId, today, datePrefix)
                .orElse(datePrefix + "00000");

        int lastNumber = Integer.parseInt(maxReceipt.substring(datePrefix.length()));
        return datePrefix + String.format("%05d", lastNumber + 1);
    }

    private Long getHufCurrencyId() {
        return currencyRepository.findByCode("HUF")
                .orElseThrow(() -> new ResourceNotFoundException("HUF valuta nem található"))
                .getId();
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
    }
}
