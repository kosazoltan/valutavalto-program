package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.report.DailyReportDto;
import hu.puzzleir.valuta.dto.report.DailyReportFullDto;
import hu.puzzleir.valuta.dto.treasury.SubmissionStatusDto;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.exception.BusinessException;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.*;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.*;
import java.util.stream.Collectors;

/**
 * Napi riport specializalt szolgaltatas.
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
@Slf4j
public class DailyReportService {

    private final ReportService reportService;
    private final DailyReportRepository dailyReportRepository;
    private final BranchRepository branchRepository;
    private final WorkerRepository workerRepository;
    private final DailyBalanceRepository dailyBalanceRepository;
    private final TransactionRepository transactionRepository;
    private final DenominationBalanceRepository denominationBalanceRepository;
    private final DailySubledgerSnapshotRepository subledgerSnapshotRepository;
    private final ExchangeRateRepository exchangeRateRepository;

    /**
     * Napi zaras riport lekerese (ReportService-bol).
     */
    public ReportService.DailyClosingReport generateDailyClosingReport(LocalDate date) {
        return reportService.generateDailyClosingReport(date);
    }

    /**
     * Napi jelentes lekerese iroda + datum alapjan.
     */
    public DailyReportDto getReport(UUID branchId, LocalDate date) {
        DailyReport report = dailyReportRepository.findByBranchIdAndReportDate(branchId, date)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Napi jelentes nem talalhato: " + branchId + " / " + date));
        return toDto(report);
    }

    /**
     * Napi jelentes generalasa (ha meg nincs, letrehozza).
     */
    @Transactional(rollbackFor = Exception.class)
    public DailyReportDto generateReport(UUID branchId, LocalDate date) {
        DailyReport existing = dailyReportRepository.findByBranchIdAndReportDate(branchId, date)
                .orElse(null);
        if (existing != null) {
            return toDto(existing);
        }

        Branch branch = branchRepository.findById(branchId)
                .orElseThrow(() -> new ResourceNotFoundException("Iroda nem talalhato: " + branchId));

        DailyReport report = DailyReport.builder()
                .branch(branch)
                .reportDate(date)
                .submitted(false)
                .build();

        DailyReport saved = dailyReportRepository.save(report);
        log.info("Napi jelentes generalva: branch={}, date={}", branchId, date);
        return toDto(saved);
    }

    /**
     * Napi jelentes bekuldese (lezarasa).
     */
    @Transactional(rollbackFor = Exception.class)
    public DailyReportDto submitReport(Long reportId, Long workerId) {
        DailyReport report = dailyReportRepository.findById(reportId)
                .orElseThrow(() -> new ResourceNotFoundException("Napi jelentes nem talalhato: " + reportId));

        if (Boolean.TRUE.equals(report.getSubmitted())) {
            throw new BusinessException("A napi jelentes mar be van kuldve", "REPORT_ALREADY_SUBMITTED");
        }

        Worker worker = workerRepository.findById(workerId)
                .orElseThrow(() -> new ResourceNotFoundException("Dolgozo nem talalhato: " + workerId));

        report.setSubmitted(true);
        report.setSubmittedAt(LocalDateTime.now());
        report.setSubmittedBy(worker);

        DailyReport saved = dailyReportRepository.save(report);
        log.info("Napi jelentes bekuldve: reportId={}, workerId={}", reportId, workerId);
        return toDto(saved);
    }

    /**
     * Bekuldesi statusz lekerese (osszes iroda, adott datum).
     */
    public List<SubmissionStatusDto> getSubmissionStatus(LocalDate date) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        List<DailyReport> reports = dailyReportRepository.findByCompanyIdAndReportDate(companyId, date);

        return reports.stream()
                .map(r -> SubmissionStatusDto.builder()
                        .branchId(r.getBranch().getId().toString())
                        .branchCode(r.getBranch().getCode())
                        .branchName(r.getBranch().getName())
                        .submitted(r.getSubmitted())
                        .submittedAt(r.getSubmittedAt() != null ? r.getSubmittedAt().toString() : null)
                        .build())
                .collect(Collectors.toList());
    }

    /**
     * Teljes napi jelentés generálása (Delphi: NAPIJELENTES DataKibonto + DataLapDisplay).
     *
     * <p>Összegyűjti egy iroda adott napi teljes jelentését: záró készletek, valutanem bontás,
     * DE/DU forgalom, címletek, WU/ÁFA készlet, kedvezmények, kezelési díj, e-kereskedelem,
     * pénztáros nevek, memo.</p>
     */
    @Transactional(readOnly = true)
    public DailyReportFullDto generateFullReport(UUID branchId, LocalDate date) {
        log.info("S2-01 teljes napi jelentés: branchId={}, date={}", branchId, date);

        Branch branch = branchRepository.findById(branchId)
                .orElseThrow(() -> new ResourceNotFoundException("Iroda nem talalhato: " + branchId));

        // 1. Záró készletek — DailyBalance
        List<DailyBalance> balances = dailyBalanceRepository.findByBranchIdAndBalanceDate(branchId, date);
        BigDecimal closingHuf = BigDecimal.ZERO;
        BigDecimal closingForeign = BigDecimal.ZERO;

        // Árfolyam map: currencyCode -> ExchangeRate
        List<ExchangeRate> activeRates = exchangeRateRepository.findActiveByDateAndBranch(date, branchId);
        Map<String, ExchangeRate> rateMap = new HashMap<>();
        for (ExchangeRate er : activeRates) {
            if (er.getCurrency() != null) {
                rateMap.putIfAbsent(er.getCurrency().getCode(), er);
            }
        }

        List<DailyReportFullDto.CurrencyLineDto> currencyLines = new ArrayList<>();
        for (DailyBalance bal : balances) {
            BigDecimal closing = bal.getClosingBalance() != null ? bal.getClosingBalance() : BigDecimal.ZERO;

            if ("HUF".equals(bal.getCurrencyCode())) {
                closingHuf = closingHuf.add(closing);
            } else {
                closingForeign = closingForeign.add(closing);
            }

            // Árfolyam lekérdezés
            BigDecimal buyRate = BigDecimal.ZERO;
            BigDecimal sellRate = BigDecimal.ZERO;
            BigDecimal settlementRate = BigDecimal.ZERO;
            ExchangeRate rate = rateMap.get(bal.getCurrencyCode());
            if (rate != null) {
                buyRate = rate.getBaseBuyRate() != null ? rate.getBaseBuyRate() : BigDecimal.ZERO;
                sellRate = rate.getBaseSellRate() != null ? rate.getBaseSellRate() : BigDecimal.ZERO;
            }

            currencyLines.add(DailyReportFullDto.CurrencyLineDto.builder()
                    .currencyCode(bal.getCurrencyCode())
                    .closingStock(closing)
                    .buyAmount(bal.getPurchases() != null ? bal.getPurchases() : BigDecimal.ZERO)
                    .sellAmount(bal.getSales() != null ? bal.getSales() : BigDecimal.ZERO)
                    .buyHuf(BigDecimal.ZERO) // TODO: HUF ekvivalens külön kalkuláció
                    .sellHuf(BigDecimal.ZERO)
                    .buyRate(buyRate)
                    .sellRate(sellRate)
                    .settlementRate(settlementRate)
                    .build());
        }

        // 2. DE/DU forgalom — Transaction idő alapján bontva
        List<Transaction> dayTx = transactionRepository.findActiveByBranchAndDate(branchId, date);

        LocalTime noon = LocalTime.of(12, 0);
        BigDecimal morningBuy = BigDecimal.ZERO;
        BigDecimal morningSell = BigDecimal.ZERO;
        BigDecimal afternoonBuy = BigDecimal.ZERO;
        BigDecimal afternoonSell = BigDecimal.ZERO;
        int buyCount = 0, sellCount = 0, reversalCount = 0;
        BigDecimal totalHandlingFee = BigDecimal.ZERO;
        List<DailyReportFullDto.DiscountLineDto> discountLines = new ArrayList<>();

        for (Transaction tx : dayTx) {
            BigDecimal huf = tx.getHufAmount() != null ? tx.getHufAmount().abs() : BigDecimal.ZERO;
            boolean isMorning = tx.getTransactionTime() != null && tx.getTransactionTime().isBefore(noon);
            TransactionType type = tx.getTransactionType();

            if (type == TransactionType.BUY) {
                buyCount++;
                if (isMorning) morningBuy = morningBuy.add(huf);
                else afternoonBuy = afternoonBuy.add(huf);
            } else if (type == TransactionType.SELL) {
                sellCount++;
                if (isMorning) morningSell = morningSell.add(huf);
                else afternoonSell = afternoonSell.add(huf);
            } else if (type == TransactionType.REVERSAL) {
                reversalCount++;
            }

            // Kezelési díj aggregálás
            if (tx.getHandlingFee() != null && tx.getHandlingFee().compareTo(BigDecimal.ZERO) > 0) {
                totalHandlingFee = totalHandlingFee.add(tx.getHandlingFee());
            }

            // Kedvezmény: egyedi árfolyamú tranzakciók (appliedRate != baseBuyRate/baseSellRate)
            if (tx.getExchangeRate() != null && tx.getCurrency() != null) {
                ExchangeRate baseRate = rateMap.get(tx.getCurrency().getCode());
                if (baseRate != null) {
                    BigDecimal base = (type == TransactionType.BUY)
                            ? baseRate.getBaseBuyRate() : baseRate.getBaseSellRate();
                    if (base != null && tx.getExchangeRate().compareTo(base) != 0) {
                        discountLines.add(DailyReportFullDto.DiscountLineDto.builder()
                                .currencyCode(tx.getCurrency().getCode())
                                .amount(tx.getCurrencyAmount())
                                .discountRate(tx.getExchangeRate())
                                .receiptNumber(tx.getReceiptNumber())
                                .build());
                    }
                }
            }
        }

        // 3. Címletek — DenominationBalance (HUF, EVENING)
        List<DenominationBalance> denomBalances = denominationBalanceRepository.findByCashDeskId(branchId);
        List<DailyReportFullDto.DenominationLineDto> denomLines = new ArrayList<>();
        BigDecimal denomTotal = BigDecimal.ZERO;
        int euroCoin1 = 0, euroCoin2 = 0;

        for (DenominationBalance db : denomBalances) {
            if (db.getDenomination() == null) continue;
            Denomination denom = db.getDenomination();

            String currCode = denom.getCurrency() != null ? denom.getCurrency().getCode() : "HUF";
            if ("HUF".equals(currCode) && db.getDenominationCategory() == DenominationCategory.EVENING) {
                BigDecimal total = db.getTotalValue() != null ? db.getTotalValue() : BigDecimal.ZERO;
                denomLines.add(DailyReportFullDto.DenominationLineDto.builder()
                        .label(denom.getFaceValue() + " Ft")
                        .faceValue(denom.getFaceValue())
                        .quantity(db.getQuantity())
                        .totalValue(total)
                        .build());
                denomTotal = denomTotal.add(total);
            }

            // Euro érmék
            if ("EUR".equals(currCode) && denom.getDenominationType() == DenominationType.COIN) {
                if (denom.getFaceValue() != null) {
                    if (denom.getFaceValue().intValue() == 1) euroCoin1 = db.getQuantity() != null ? db.getQuantity() : 0;
                    if (denom.getFaceValue().intValue() == 2) euroCoin2 = db.getQuantity() != null ? db.getQuantity() : 0;
                }
            }
        }

        // 4. WU/ÁFA készletek — DailySubledgerSnapshot
        BigDecimal wuUsd = subledgerSnapshotRepository
                .findByBranchIdAndSnapshotDateAndSubledgerTypeAndCurrencyCode(branchId, date, "WU_USD", "USD")
                .map(DailySubledgerSnapshot::getClosingBalance).orElse(BigDecimal.ZERO);
        BigDecimal wuHuf = subledgerSnapshotRepository
                .findByBranchIdAndSnapshotDateAndSubledgerTypeAndCurrencyCode(branchId, date, "WU_HUF", "HUF")
                .map(DailySubledgerSnapshot::getClosingBalance).orElse(BigDecimal.ZERO);
        BigDecimal afa = subledgerSnapshotRepository
                .findByBranchIdAndSnapshotDateAndSubledgerTypeAndCurrencyCode(branchId, date, "WU_VAT", "HUF")
                .map(DailySubledgerSnapshot::getClosingBalance).orElse(BigDecimal.ZERO);

        // 5. E-kereskedelem záró
        BigDecimal ecommerce = subledgerSnapshotRepository
                .findByBranchIdAndSnapshotDateAndSubledgerTypeAndCurrencyCode(branchId, date, "ECOMMERCE", "HUF")
                .map(DailySubledgerSnapshot::getClosingBalance).orElse(BigDecimal.ZERO);

        // 6. Pénztáros nevek — a nap első és második műszakjának dolgozója
        String morningCashier = null;
        String afternoonCashier = null;
        for (Transaction tx : dayTx) {
            if (tx.getWorker() == null) continue;
            boolean morning = tx.getTransactionTime() != null && tx.getTransactionTime().isBefore(noon);
            if (morning && morningCashier == null) {
                morningCashier = tx.getWorker().getName();
            } else if (!morning && afternoonCashier == null) {
                afternoonCashier = tx.getWorker().getName();
            }
        }

        return DailyReportFullDto.builder()
                .reportDate(date.toString())
                .branchId(branchId.toString())
                .branchCode(branch.getCode())
                .branchName(branch.getName())
                .closingBalanceHuf(closingHuf)
                .closingBalanceForeign(closingForeign)
                .closingBalanceTotal(closingHuf.add(closingForeign))
                .currencyLines(currencyLines)
                .morningBuyHuf(morningBuy)
                .morningSellHuf(morningSell)
                .afternoonBuyHuf(afternoonBuy)
                .afternoonSellHuf(afternoonSell)
                .totalBuyHuf(morningBuy.add(afternoonBuy))
                .totalSellHuf(morningSell.add(afternoonSell))
                .transactionCount(dayTx.size())
                .buyCount(buyCount)
                .sellCount(sellCount)
                .reversalCount(reversalCount)
                .hufDenominations(denomLines)
                .denominatedTotalHuf(denomTotal)
                .euroCoin1Count(euroCoin1)
                .euroCoin2Count(euroCoin2)
                .wuUsdBalance(wuUsd)
                .wuHufBalance(wuHuf)
                .afaBalance(afa)
                .discountLines(discountLines.size() > 10 ? discountLines.subList(0, 10) : discountLines)
                .dailyHandlingFee(totalHandlingFee)
                .ecommerceBalanceHuf(ecommerce)
                .morningCashierName(morningCashier)
                .afternoonCashierName(afternoonCashier)
                .requestNotes(List.of()) // TODO: memo implementáció jövőbeli feature
                .sendNotes(List.of())
                .build();
    }

    // ============ HELPER ============

    private DailyReportDto toDto(DailyReport report) {
        return DailyReportDto.builder()
                .id(report.getId())
                .branchId(report.getBranch().getId().toString())
                .branchCode(report.getBranch().getCode())
                .branchName(report.getBranch().getName())
                .reportDate(report.getReportDate().toString())
                .submitted(report.getSubmitted())
                .submittedAt(report.getSubmittedAt() != null ? report.getSubmittedAt().toString() : null)
                .submittedById(report.getSubmittedBy() != null ? report.getSubmittedBy().getId() : null)
                .submittedByName(report.getSubmittedBy() != null ? report.getSubmittedBy().getName() : null)
                .reportData(report.getReportData())
                .totalBuyHuf(report.getTotalBuyHuf())
                .totalSellHuf(report.getTotalSellHuf())
                .totalFeeHuf(report.getTotalFeeHuf())
                .totalProfit(report.getTotalProfit())
                .transactionCount(report.getTransactionCount())
                .createdAt(report.getCreatedAt() != null ? report.getCreatedAt().toString() : null)
                .build();
    }
}
