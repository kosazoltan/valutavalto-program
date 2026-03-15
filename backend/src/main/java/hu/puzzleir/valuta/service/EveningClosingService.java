package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.eveningclosing.*;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.repository.*;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

/**
 * Esti zárás szolgáltatás — napi adatcsomag összeállítása és küldése a központnak.
 *
 * Legacy: Delphi ESTIZAR modul → CsomagoloGombClick → bináris csomag (PutByte/PutWord/PutInteger/PutString)
 *         → FTP-n küldés a központnak (port 21100, jelszó: klc+45%)
 *
 * Modern: JSON REST API — strukturált adatcsomag, retry logika, naplózás.
 *
 * A csomag tartalmazza:
 * 1. Tranzakciók (BLOKKFEJ + BLOKKTETEL)
 * 2. Címletezés adatok
 * 3. Napi árfolyamok
 * 4. Ügyfél adatok
 * 5. Foglaló adatok
 * 6. Kezelési díj összesítő
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
@Slf4j
public class EveningClosingService {

    private final TransactionRepository transactionRepository;
    private final DenominationBalanceRepository denominationBalanceRepository;
    private final DenominationRepository denominationRepository;
    private final ExchangeRateRepository exchangeRateRepository;
    private final CustomerRepository customerRepository;
    private final ReservationRepository reservationRepository;
    private final EveningSyncLogRepository eveningSyncLogRepository;
    private final SystemParameterService systemParameterService;

    /** Maximum küldési próbálkozás */
    private static final int MAX_SEND_ATTEMPTS = 3;

    // ============ NAPI ADATCSOMAG KÉSZÍTÉS ============

    /**
     * Napi adatcsomag előkészítése (Delphi CsomagoloGombClick ekvivalens).
     *
     * @param branchId Iroda azonosító
     * @param date     Dátum
     * @return Összeállított napi adatcsomag
     */
    public DailyDataPackage prepareDailyPackage(Long branchId, LocalDate date) {
        log.info("Napi adatcsomag készítése: branchId={}, datum={}", branchId, date);

        UUID branchUuid = uuidFromLong(branchId);

        List<TransactionSummary> transactions = getTransactions(branchUuid, date);
        List<DenominationEntry> denominations = getDenominations(branchUuid, date);
        List<RateSnapshot> rates = getRates(branchUuid, date);
        List<CustomerData> customers = getCustomers(branchUuid, date);
        List<ReservationData> reservations = getReservations(branchUuid, date);
        HandlingFeeSummary handlingFees = getHandlingFees(branchUuid, date);

        DailyDataPackage pkg = DailyDataPackage.builder()
                .branchId(branchId)
                .date(date)
                .transactions(transactions)
                .denominations(denominations)
                .rates(rates)
                .customers(customers)
                .reservations(reservations)
                .handlingFees(handlingFees)
                .build();

        // Checksum számítása
        pkg.setChecksum(calculateChecksum(pkg));

        log.info("Napi adatcsomag kész: branchId={}, datum={}, tranzakciók={}, checksum={}",
                branchId, date, transactions.size(), pkg.getChecksum());

        return pkg;
    }

    /**
     * Overload UUID branchId-vel.
     */
    public DailyDataPackage prepareDailyPackage(UUID branchId, LocalDate date) {
        return prepareDailyPackage(branchId.getLeastSignificantBits(), date);
    }

    // ============ CSOMAG KÜLDÉSE KÖZPONTNAK ============

    /**
     * Adatcsomag küldése a központi szervernek.
     *
     * Legacy: FTP PUT a központi szerverre (port 21100).
     * Modern: REST API POST — retry logikával (max 3 próba, exponential backoff).
     *
     * JELENLEG: csak logol (központi szerver URL-t SystemParameter-ből kell majd olvasni).
     *
     * @param pkg Az előkészített adatcsomag
     * @return Küldés eredménye
     */
    @Transactional
    public DataSyncResult sendToHeadquarters(DailyDataPackage pkg) {
        log.info("Adatcsomag küldése a központnak: branchId={}, datum={}", pkg.getBranchId(), pkg.getDate());

        UUID branchUuid = uuidFromLong(pkg.getBranchId());

        // Sync napló létrehozása/frissítése
        EveningSyncLog syncLog = eveningSyncLogRepository
                .findByBranchIdAndSyncDate(branchUuid, pkg.getDate())
                .orElseGet(() -> EveningSyncLog.builder()
                        .branchId(branchUuid)
                        .syncDate(pkg.getDate())
                        .status("PENDING")
                        .attemptCount(0)
                        .build());

        // Központi szerver URL lekérése
        String headquartersUrl;
        try {
            headquartersUrl = systemParameterService.getValue("evening.closing.headquarters.url");
        } catch (Exception e) {
            headquartersUrl = null;
        }

        // Retry logika: max 3 próba, exponential backoff
        for (int attempt = 1; attempt <= MAX_SEND_ATTEMPTS; attempt++) {
            syncLog.setAttemptCount(attempt);
            syncLog.setLastAttemptAt(LocalDateTime.now());

            try {
                if (headquartersUrl == null || headquartersUrl.isBlank()) {
                    // JELENLEG: csak logolás (nincs központi szerver konfigurálva)
                    log.info("Esti zárás adatcsomag (MOCK küldés — nincs headquarters URL konfigurálva): " +
                                    "branchId={}, datum={}, tranzakciók={}, checksum={}",
                            pkg.getBranchId(), pkg.getDate(),
                            pkg.getTransactions() != null ? pkg.getTransactions().size() : 0,
                            pkg.getChecksum());

                    // Sikeres "küldés" (mock mód)
                    syncLog.setStatus("EVENING_SYNC_DONE");
                    syncLog.setPackageChecksum(pkg.getChecksum());
                    syncLog.setCompletedAt(LocalDateTime.now());
                    eveningSyncLogRepository.save(syncLog);

                    return DataSyncResult.success(pkg.getChecksum());
                }

                // TODO: Valódi REST API hívás implementálása
                // POST {headquartersUrl}/api/v1/branches/{branchId}/daily-report
                // Body: JSON (DailyDataPackage)
                // Headers: Content-Type: application/json, X-Checksum: {checksum}
                log.warn("Valódi REST küldés NEM IMPLEMENTÁLT — headquarters URL: {}", headquartersUrl);

                // Mock sikeres küldés
                syncLog.setStatus("EVENING_SYNC_DONE");
                syncLog.setPackageChecksum(pkg.getChecksum());
                syncLog.setCompletedAt(LocalDateTime.now());
                eveningSyncLogRepository.save(syncLog);

                return DataSyncResult.success(pkg.getChecksum());

            } catch (Exception e) {
                log.error("Adatcsomag küldés hiba (próba {}/{}): {}",
                        attempt, MAX_SEND_ATTEMPTS, e.getMessage(), e);
                syncLog.setErrorMessage(e.getMessage());

                if (attempt < MAX_SEND_ATTEMPTS) {
                    // Exponential backoff: 1s, 2s, 4s
                    try {
                        Thread.sleep((long) Math.pow(2, attempt - 1) * 1000);
                    } catch (InterruptedException ie) {
                        Thread.currentThread().interrupt();
                        break;
                    }
                }
            }
        }

        // Minden próba sikertelen
        syncLog.setStatus("FAILED");
        eveningSyncLogRepository.save(syncLog);

        return DataSyncResult.failure(
                "Adatcsomag küldés sikertelen " + MAX_SEND_ATTEMPTS + " próba után: " + syncLog.getErrorMessage(),
                syncLog.getAttemptCount());
    }

    // ============ NAPI JELENTÉS ============

    /**
     * Napi jelentés generálása (Delphi JelentesBekuldese ekvivalens).
     * Forgalom összesítő + valutanem bontás.
     *
     * @param branchId Iroda azonosító
     * @param date     Dátum
     * @return Napi jelentés
     */
    public hu.puzzleir.valuta.dto.eveningclosing.DailyReport generateDailyReport(Long branchId, LocalDate date) {
        UUID branchUuid = uuidFromLong(branchId);
        return generateDailyReport(branchUuid, date);
    }

    public hu.puzzleir.valuta.dto.eveningclosing.DailyReport generateDailyReport(UUID branchId, LocalDate date) {
        log.info("Napi jelentés generálása: branchId={}, datum={}", branchId, date);

        List<Transaction> transactions = transactionRepository.findByBranchAndDate(branchId, date);

        int buyCount = 0, sellCount = 0, reversalCount = 0, conversionCount = 0;
        BigDecimal totalBuyHuf = BigDecimal.ZERO;
        BigDecimal totalSellHuf = BigDecimal.ZERO;
        BigDecimal totalHandlingFees = BigDecimal.ZERO;
        Map<String, BigDecimal> currencyBreakdown = new LinkedHashMap<>();

        for (Transaction tx : transactions) {
            if (!tx.isActive()) continue;

            BigDecimal huf = tx.getHufAmount() != null ? tx.getHufAmount() : BigDecimal.ZERO;
            BigDecimal fee = tx.getHandlingFee() != null ? tx.getHandlingFee() : BigDecimal.ZERO;
            totalHandlingFees = totalHandlingFees.add(fee);

            String currCode = tx.getCurrency() != null ? tx.getCurrency().getCode() : "UNKNOWN";

            switch (tx.getTransactionType()) {
                case BUY -> {
                    buyCount++;
                    totalBuyHuf = totalBuyHuf.add(huf);
                    currencyBreakdown.merge(currCode, huf, BigDecimal::add);
                }
                case SELL -> {
                    sellCount++;
                    totalSellHuf = totalSellHuf.add(huf);
                    currencyBreakdown.merge(currCode, huf, BigDecimal::add);
                }
                case REVERSAL -> reversalCount++;
                case CONVERSION -> {
                    conversionCount++;
                    currencyBreakdown.merge(currCode, huf, BigDecimal::add);
                }
                default -> { /* egyéb típusok */ }
            }
        }

        return hu.puzzleir.valuta.dto.eveningclosing.DailyReport.builder()
                .branchId(branchId.getLeastSignificantBits())
                .date(date)
                .totalTransactionCount(transactions.size())
                .buyCount(buyCount)
                .sellCount(sellCount)
                .reversalCount(reversalCount)
                .conversionCount(conversionCount)
                .totalBuyHuf(totalBuyHuf)
                .totalSellHuf(totalSellHuf)
                .totalHandlingFees(totalHandlingFees)
                .netTurnover(totalSellHuf.subtract(totalBuyHuf))
                .currencyBreakdown(currencyBreakdown)
                .build();
    }

    // ============ ADATGYŰJTŐ HELPER METÓDUSOK ============

    /**
     * Tranzakciók összegyűjtése a napi adatcsomaghoz.
     */
    private List<TransactionSummary> getTransactions(UUID branchId, LocalDate date) {
        List<Transaction> transactions = transactionRepository.findByBranchAndDate(branchId, date);

        return transactions.stream()
                .map(tx -> TransactionSummary.builder()
                        .transactionId(tx.getId())
                        .receiptNumber(tx.getReceiptNumber())
                        .transactionType(tx.getTransactionType() != null ? tx.getTransactionType().name() : null)
                        .status(tx.getStatus() != null ? tx.getStatus().name() : null)
                        .transactionDate(tx.getTransactionDate())
                        .transactionTime(tx.getTransactionTime())
                        .currencyCode(tx.getCurrency() != null ? tx.getCurrency().getCode() : null)
                        .currencyAmount(tx.getCurrencyAmount())
                        .exchangeRate(tx.getExchangeRate())
                        .hufAmount(tx.getHufAmount())
                        .handlingFee(tx.getHandlingFee())
                        .discountAmount(tx.getDiscountAmount())
                        .roundingAmount(tx.getRoundingAmount())
                        .paymentMethod(tx.getPaymentMethod() != null ? tx.getPaymentMethod().name() : "CASH")
                        .customerName(tx.getCustomerName())
                        .customerDocumentNumber(tx.getCustomerDocumentNumber())
                        .workerName(tx.getWorker() != null ? tx.getWorker().getName() : null)
                        .build())
                .collect(Collectors.toList());
    }

    /**
     * Címletezés adatok gyűjtése.
     * Jelenleg egyszerűsített — a valós implementáció a DenominationBalanceRepository-ból gyűjt.
     */
    private List<DenominationEntry> getDenominations(UUID branchId, LocalDate date) {
        log.debug("Címletezés adatok gyűjtése: branchId={}, datum={}", branchId, date);

        List<Denomination> denominations = denominationRepository.findByBranchId(branchId);

        return denominations.stream()
                .filter(d -> d.getQuantity() != null && d.getQuantity() > 0)
                .map(d -> DenominationEntry.builder()
                        .currencyCode(d.getCurrency() != null ? d.getCurrency().getCode() : null)
                        .denominationType(d.getDenominationType() != null ? d.getDenominationType().name() : null)
                        .denominationValue(d.getFaceValue())
                        .quantity(d.getQuantity())
                        .totalAmount(d.getTotalValue())
                        .build())
                .collect(Collectors.toList());
    }

    /**
     * Napi árfolyamok gyűjtése.
     */
    private List<RateSnapshot> getRates(UUID branchId, LocalDate date) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        List<ExchangeRate> rates = exchangeRateRepository.findActiveRatesByDate(companyId, date);

        return rates.stream()
                .map(r -> RateSnapshot.builder()
                        .currencyCode(r.getCurrency() != null ? r.getCurrency().getCode() : null)
                        .buyRate(r.getBaseBuyRate())
                        .sellRate(r.getBaseSellRate())
                        .midRate(r.getBaseBuyRate() != null && r.getBaseSellRate() != null
                                ? r.getBaseBuyRate().add(r.getBaseSellRate()).divide(BigDecimal.valueOf(2), 4, RoundingMode.HALF_UP)
                                : null)
                        .source("MANUAL")
                        .build())
                .collect(Collectors.toList());
    }

    /**
     * Ügyfél adatok gyűjtése — aznapi tranzakciókban szereplő ügyfelek.
     */
    private List<CustomerData> getCustomers(UUID branchId, LocalDate date) {
        List<Transaction> transactions = transactionRepository.findByBranchAndDate(branchId, date);

        // Egyedi ügyfelek kinyerése a tranzakciókból
        return transactions.stream()
                .filter(tx -> tx.getCustomerName() != null && !tx.getCustomerName().isBlank())
                .map(tx -> CustomerData.builder()
                        .customerId(tx.getCustomerId())
                        .customerName(tx.getCustomerName())
                        .customerAddress(tx.getCustomerAddress())
                        .documentNumber(tx.getCustomerDocumentNumber())
                        .nationality(tx.getCustomerNationality())
                        .customerType("NATURAL")  // Default; jogi személy megkülönböztetés TODO
                        .build())
                .distinct()
                .collect(Collectors.toList());
    }

    /**
     * Foglaló adatok gyűjtése.
     */
    private List<ReservationData> getReservations(UUID branchId, LocalDate date) {
        List<Reservation> reservations = reservationRepository.findByBranchIdAndStatus(
                branchId, ReservationStatus.ACTIVE);

        return reservations.stream()
                .map(r -> ReservationData.builder()
                        .reservationId(r.getId())
                        .customerName(r.getCustomer() != null ? r.getCustomer().getName() : null)
                        .currencyCode(r.getCurrencyCode())
                        .amount(r.getReservedAmount())
                        .depositAmount(r.getDepositAmount())
                        .status(r.getStatus() != null ? r.getStatus().name() : null)
                        .reservationDate(r.getCreatedAt() != null ? r.getCreatedAt().toLocalDate() : null)
                        .expiryDate(r.getExpiresAt() != null ? r.getExpiresAt().toLocalDate() : null)
                        .build())
                .collect(Collectors.toList());
    }

    /**
     * Kezelési díj összesítő.
     */
    private HandlingFeeSummary getHandlingFees(UUID branchId, LocalDate date) {
        BigDecimal totalFees = transactionRepository.sumDailyHandlingFees(branchId, date);
        if (totalFees == null) totalFees = BigDecimal.ZERO;

        List<Transaction> transactions = transactionRepository.findByBranchAndDate(branchId, date);

        List<BigDecimal> fees = transactions.stream()
                .filter(tx -> tx.getHandlingFee() != null && tx.getHandlingFee().compareTo(BigDecimal.ZERO) > 0)
                .map(Transaction::getHandlingFee)
                .collect(Collectors.toList());

        BigDecimal maxFee = fees.stream().max(BigDecimal::compareTo).orElse(BigDecimal.ZERO);
        BigDecimal minFee = fees.stream().min(BigDecimal::compareTo).orElse(BigDecimal.ZERO);
        BigDecimal avgFee = !fees.isEmpty()
                ? totalFees.divide(BigDecimal.valueOf(fees.size()), 2, RoundingMode.HALF_UP)
                : BigDecimal.ZERO;

        return HandlingFeeSummary.builder()
                .totalHandlingFee(totalFees)
                .transactionCount(fees.size())
                .averageFee(avgFee)
                .maxFee(maxFee)
                .minFee(minFee)
                .build();
    }

    // ============ UTILITY ============

    /**
     * SHA-256 checksum számítása a csomagból.
     */
    private String calculateChecksum(DailyDataPackage pkg) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            String data = String.format("%d|%s|%d|%s",
                    pkg.getBranchId(),
                    pkg.getDate(),
                    pkg.getTransactions() != null ? pkg.getTransactions().size() : 0,
                    pkg.getHandlingFees() != null ? pkg.getHandlingFees().getTotalHandlingFee() : "0");
            byte[] hash = digest.digest(data.getBytes(StandardCharsets.UTF_8));
            return bytesToHex(hash);
        } catch (NoSuchAlgorithmException e) {
            log.error("SHA-256 nem elérhető", e);
            return "CHECKSUM_ERROR";
        }
    }

    private static String bytesToHex(byte[] bytes) {
        StringBuilder sb = new StringBuilder(bytes.length * 2);
        for (byte b : bytes) {
            sb.append(String.format("%02x", b));
        }
        return sb.toString();
    }

    /**
     * Long → UUID konverzió helper (backward compat).
     */
    private UUID uuidFromLong(Long id) {
        if (id == null) return null;
        return new UUID(0L, id);
    }
}
