package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.*;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.util.HungarianRounding;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import hu.puzzleir.valuta.service.TransactionService.ConversionRequest;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.UUID;

/**
 * Valuta konverzio tranzakciok kezelese.
 * Legacy: valuta-valuta csere HUF-on keresztul, 2 bizonylat (GAP 4).
 */
@Service
@RequiredArgsConstructor
@Transactional(rollbackFor = Exception.class)
@Slf4j
public class TransactionConversionService {

    private final TransactionRepository transactionRepository;
    private final CompanyRepository companyRepository;
    private final BranchRepository branchRepository;
    private final WorkerRepository workerRepository;
    private final CurrencyRepository currencyRepository;
    private final ExchangeRateService exchangeRateService;
    private final ReceiptSequenceService receiptSequenceService;
    private final HandlingFeeCalculator handlingFeeCalculator;
    private final DailySessionService dailySessionService;
    private final TransactionOperationHelper helper;

    /**
     * Konverzio vegrehajtasa (valuta-valuta csere).
     */
    public Transaction executeConversion(ConversionRequest request) {
        helper.validateOpenSession();

        UUID companyId = SecurityUtils.getCurrentCompanyId();
        UUID branchId = SecurityUtils.getCurrentBranchId();
        Long workerId = SecurityUtils.getCurrentWorkerId();

        Company company = companyRepository.findById(companyId)
                .orElseThrow(() -> new ResourceNotFoundException("Company nem talalhato"));
        Branch branch = branchRepository.findById(branchId)
                .orElseThrow(() -> new ResourceNotFoundException("Iroda nem talalhato"));
        Worker worker = workerRepository.findById(workerId)
                .orElseThrow(() -> new ResourceNotFoundException("Penztaros nem talalhato"));

        Long fromCurrencyId = helper.resolveCurrencyId(request.getFromCurrencyId(), request.getFromCurrencyCode());
        Long toCurrencyId = helper.resolveCurrencyId(request.getToCurrencyId(), request.getToCurrencyCode());

        Currency fromCurrency = currencyRepository.findById(fromCurrencyId)
                .orElseThrow(() -> new ResourceNotFoundException("Forras valuta nem talalhato"));
        Currency toCurrency = currencyRepository.findById(toCurrencyId)
                .orElseThrow(() -> new ResourceNotFoundException("Cel valuta nem talalhato"));

        if (fromCurrencyId.equals(toCurrencyId)) {
            throw new ValidationException("Azonos valutanemek kozotti konverzio nem lehetseges!");
        }
        if ("HUF".equals(fromCurrency.getCode()) || "HUF".equals(toCurrency.getCode())) {
            throw new ValidationException("HUF konverzio nem lehetseges! Hasznalja a vetel/eladas funkciot.");
        }

        ExchangeRate fromRate = exchangeRateService.getCurrentRate(fromCurrencyId);
        ExchangeRate toRate = exchangeRateService.getCurrentRate(toCurrencyId);

        // HUF-on keresztul konvertalas
        BigDecimal hufAmount = request.getFromAmount().multiply(fromRate.getBaseBuyRate())
                .setScale(0, RoundingMode.HALF_UP);
        BigDecimal roundedHufAmount = HungarianRounding.roundToFive(hufAmount);
        BigDecimal roundingDifference = roundedHufAmount.subtract(hufAmount);

        BigDecimal toAmountRaw = roundedHufAmount.divide(toRate.getBaseSellRate(), 2, RoundingMode.HALF_UP);
        BigDecimal toAmount = toAmountRaw.setScale(2, RoundingMode.FLOOR);

        // AML ellenorzes
        helper.performAmlCheck(roundedHufAmount, request.getCustomerId(), request.getCustomerName(),
                request.getCustomerDocumentNumber(), fromCurrency.getCode());

        // Keszlet ellenorzes
        helper.validateCurrencyStock(branchId, toCurrency.getId(), toAmount);

        // Kezelesi dij
        BigDecimal serverHandlingFee = handlingFeeCalculator.calculate(
                roundedHufAmount, TransactionType.CONVERSION, request.getHandlingFee());

        // GAP 4: konverzio = 2 bizonylat
        String buyReceiptNumber = receiptSequenceService.generateReceiptNumber(branchId, TransactionType.BUY);
        String sellReceiptNumber = receiptSequenceService.generateReceiptNumber(branchId, TransactionType.SELL);

        BigDecimal conversionRate = fromRate.getBaseBuyRate().divide(toRate.getBaseSellRate(), 6, RoundingMode.HALF_UP);

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
                .notes(String.format("Konverzio: %s %s -> %s %s",
                    request.getFromAmount(), fromCurrency.getCode(),
                    toAmount, toCurrency.getCode()))
                .build();

        Transaction saved = transactionRepository.save(transaction);
        helper.linkCameraEvidence(saved);

        // Konverzios vetel bizonylat
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
                .notes(String.format("Konverzios vetel: %s %s -> %s HUF (par: %s)",
                    request.getFromAmount(), fromCurrency.getCode(),
                    roundedHufAmount, sellReceiptNumber))
                .build();
        convBuy = transactionRepository.save(convBuy);
        helper.linkCameraEvidence(convBuy);

        // Konverzios eladas bizonylat
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
                .notes(String.format("Konverzios eladas: %s HUF -> %s %s (par: %s)",
                    roundedHufAmount, toAmount, toCurrency.getCode(),
                    buyReceiptNumber))
                .build();
        convSell = transactionRepository.save(convSell);
        helper.linkCameraEvidence(convSell);

        // Kassza frissites
        helper.updateCashBalance(branchId, fromCurrency.getId(), request.getFromAmount(), true);
        helper.updateCashBalance(branchId, toCurrency.getId(), toAmount.negate(), false);

        // Napi statisztika
        dailySessionService.updateSessionStats(TransactionType.BUY, roundedHufAmount, BigDecimal.ZERO);
        dailySessionService.updateSessionStats(TransactionType.SELL, roundedHufAmount, serverHandlingFee);

        log.info("Konverzio: {} - {} {} -> {} {} (HUF koztes: {}, kerekites: {}, bizonylatok: {} + {})",
                conversionReceiptNumber, request.getFromAmount(), fromCurrency.getCode(),
                toAmount, toCurrency.getCode(), roundedHufAmount, roundingDifference,
                buyReceiptNumber, sellReceiptNumber);

        return saved;
    }
}
