package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.config.IntegrationTransportProperties;
import hu.puzzleir.valuta.dto.eveningclosing.*;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.exception.BusinessException;
import hu.puzzleir.valuta.repository.*;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestTemplate;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
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
    private final IntegrationTransportProperties integrationTransportProperties;
    private final FileTransportService fileTransportService;
    // FKH-036 FR-1: az előnézeti összefoglaló forrásai (branchName, készített csomagok).
    private final BranchRepository branchRepository;
    private final ShipmentRequestRepository shipmentRequestRepository;

    @Value("${evening.closing.artifact-success-enabled:false}")
    private boolean artifactSuccessEnabled;

    /**
     * HQ HTTP kliens. Szándékosan nem a projekt timeout-os RestTemplate-je
     * (FK-091 Scope OUT). Mező, hogy a 2xx ág unit-tesztelhető legyen.
     */
    private RestTemplate headquartersRestTemplate = new RestTemplate();

    /** Maximum küldési próbálkozás */
    private static final int MAX_SEND_ATTEMPTS = 3;

    // ============ NAPI ADATCSOMAG KÉSZÍTÉS ============

    /**
     * Napi adatcsomag előkészítése (Delphi CsomagoloGombClick ekvivalens).
     *
     * @param branchId Iroda azonosító (Long, backward compat)
     * @param date     Dátum
     * @return Összeállított napi adatcsomag
     */
    public DailyDataPackage prepareDailyPackage(Long branchId, LocalDate date) {
        log.info("Napi adatcsomag készítése: branchId={}, datum={}", branchId, date);

        // Bug 5 fix: Long-ból UUID-t állítunk elő — jelezzük, hogy ez legacy path
        UUID branchUuid = uuidFromLong(branchId);
        return prepareDailyPackageInternal(branchUuid, branchId, date);
    }

    /**
     * Overload UUID branchId-vel — Bug 5 fix: közvetlenül UUID-del dolgozik, nem konvertál Long-gá és vissza.
     */
    public DailyDataPackage prepareDailyPackage(UUID branchId, LocalDate date) {
        log.info("Napi adatcsomag készítése: branchId={}, datum={}", branchId, date);
        return prepareDailyPackageInternal(branchId, branchId.getLeastSignificantBits(), date);
    }

    /**
     * Belső implementáció: mindkét overload ebbe fut bele.
     */
    private DailyDataPackage prepareDailyPackageInternal(UUID branchUuid, Long branchIdLong, LocalDate date) {
        List<TransactionSummary> transactions = getTransactions(branchUuid, date);
        List<DenominationEntry> denominations = getDenominations(branchUuid, date);
        List<RateSnapshot> rates = getRates(branchUuid, date);
        List<CustomerData> customers = getCustomers(branchUuid, date);
        List<ReservationData> reservations = getReservations(branchUuid, date);
        HandlingFeeSummary handlingFees = getHandlingFees(branchUuid, date);

        DailyDataPackage pkg = DailyDataPackage.builder()
                .branchId(branchIdLong)
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

        // FKH-036 FR-1: előnézeti összefoglaló — a checksum UTÁN (terv pitfall 2: a
        // calculateChecksum csak a 9 eredeti bemenetet hasheli; ha egy jövőbeli edit
        // az enrich-mezőket is hashelné, ez a sorrend akkor sem változtatná meg a
        // már kiszámított értéket, és a WU-1 checksum-teszt ezt őrzi).
        enrichSummary(pkg, branchUuid, date, transactions, reservations);

        log.info("Napi adatcsomag kész: branchId={}, datum={}, tranzakciók={}, checksum={}",
                branchIdLong, date, transactions.size(), pkg.getChecksum());

        return pkg;
    }

    // ============ CSOMAG KÜLDÉSE KÖZPONTNAK ============

    /**
     * Adatcsomag küldése a központi szervernek.
     *
     * Legacy: FTP PUT a központi szerverre (port 21100).
     * Modern: REST API POST — retry logikával (max 3 próba, exponential backoff).
     *
     * Bug 6 fix: valódi HTTP POST implementálva RestTemplate-tel.
     *
     * @param pkg Az előkészített adatcsomag
     * @return Küldés eredménye
     */
    @Transactional(rollbackFor = Exception.class)
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
        // FR-5: újrafelhasznált sor (branch_id+sync_date) korábbi bridged siker után
        // is_bridged=true maradna, ha az ARTIFACT_PENDING/FAILED ág nem állítja vissza.
        syncLog.setIsBridged(false);

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
                    Path artifact = writeEveningPackageArtifact(pkg);
                    log.info("Esti zárás bridge artifact létrehozva (HQ URL nincs konfigurálva): " +
                                    "branchId={}, datum={}, tranzakciók={}, checksum={}, artifact={}",
                            pkg.getBranchId(),
                            pkg.getDate(),
                            pkg.getTransactions() != null ? pkg.getTransactions().size() : 0,
                            pkg.getChecksum(),
                            artifact);

                    if (!artifactSuccessEnabled) {
                        syncLog.setStatus("ARTIFACT_PENDING");
                        syncLog.setIsBridged(false);
                        syncLog.setPackageChecksum(pkg.getChecksum());
                        syncLog.setCompletedAt(LocalDateTime.now());
                        syncLog.setErrorMessage("HQ_URL_MISSING_ARTIFACT=" + artifact);
                        eveningSyncLogRepository.save(syncLog);
                        return DataSyncResult.failure(
                                "HQ URL nincs konfigurálva; adatcsomag artifactba mentve: " + artifact,
                                attempt);
                    }

                    syncLog.setStatus("EVENING_SYNC_DONE");
                    syncLog.setIsBridged(true);
                    syncLog.setPackageChecksum(pkg.getChecksum());
                    syncLog.setCompletedAt(LocalDateTime.now());
                    syncLog.setErrorMessage("BRIDGED_TO_MANAGED_ARTIFACT");
                    eveningSyncLogRepository.save(syncLog);

                    return DataSyncResult.success(pkg.getChecksum());
                }

                // Bug 6 fix: valódi REST API hívás
                String targetUrl = headquartersUrl.stripTrailing() + "/" +
                        "api/v1/branches/" + pkg.getBranchId() + "/daily-report";

                HttpHeaders headers = new HttpHeaders();
                headers.setContentType(MediaType.APPLICATION_JSON);
                headers.set("X-Checksum", pkg.getChecksum());
                headers.set("X-Branch-Id", String.valueOf(pkg.getBranchId()));
                headers.set("X-Report-Date", pkg.getDate().toString());

                HttpEntity<DailyDataPackage> request = new HttpEntity<>(pkg, headers);

                log.info("REST küldés: POST {} (checksum={})", targetUrl, pkg.getChecksum());
                ResponseEntity<String> response = headquartersRestTemplate.exchange(
                        targetUrl, HttpMethod.POST, request, String.class);

                if (response.getStatusCode().is2xxSuccessful()) {
                    syncLog.setStatus("EVENING_SYNC_DONE");
                    syncLog.setIsBridged(false);
                    syncLog.setPackageChecksum(pkg.getChecksum());
                    syncLog.setCompletedAt(LocalDateTime.now());
                    eveningSyncLogRepository.save(syncLog);

                    log.info("Adatcsomag sikeresen elküldve: branchId={}, datum={}, HTTP {}",
                            pkg.getBranchId(), pkg.getDate(), response.getStatusCode());
                    return DataSyncResult.success(pkg.getChecksum());
                } else {
                    throw new BusinessException("Sikertelen HTTP válasz: " + response.getStatusCode(), "HTTP_CALL_FAILED");
                }

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
        syncLog.setIsBridged(false);
        eveningSyncLogRepository.save(syncLog);

        // FKH-045 FR-5: the user-facing message must NOT contain the raw
        // filesystem path or stacktrace detail — those belong in the log and in
        // sync_log.error_message only. The UI shows an understandable message
        // that directs the user to operations.
        return DataSyncResult.failure(
                "Esti zárás adatcsomag küldés sikertelen " + MAX_SEND_ATTEMPTS +
                        " próba után (szerver-oldali tárolási hiba). Forduljon az üzemeltetéshez.",
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
     *
     * Bug 1 fix: DenominationBalanceRepository-ból olvassa az aznapi (módosított) egyenlegeket,
     * nem a Denomination master táblából.
     */
    private List<DenominationEntry> getDenominations(UUID branchId, LocalDate date) {
        log.debug("Címletezés adatok gyűjtése: branchId={}, datum={}", branchId, date);

        List<DenominationBalance> balances = denominationBalanceRepository.findByBranchIdAndDate(branchId, date);

        return balances.stream()
                .map(db -> {
                    Denomination d = db.getDenomination();
                    return DenominationEntry.builder()
                            .currencyCode(d != null && d.getCurrency() != null ? d.getCurrency().getCode() : null)
                            .denominationType(d != null && d.getDenominationType() != null ? d.getDenominationType().name() : null)
                            .denominationValue(d != null ? d.getFaceValue() : null)
                            .quantity(db.getQuantity())
                            .totalAmount(db.getTotalValue())
                            .build();
                })
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
     *
     * Bug 2 fix:
     * - .distinct() helyett LinkedHashMap-alapú deduplikáció customerId vagy documentNumber szerint
     * - customerType nem hardkódolt "NATURAL" — ha nincs adat, "NATURAL" a default
     */
    private List<CustomerData> getCustomers(UUID branchId, LocalDate date) {
        List<Transaction> transactions = transactionRepository.findByBranchAndDate(branchId, date);

        // Deduplikáció: kulcs = customerId ha van, egyébként documentNumber, egyébként customerName
        Map<String, CustomerData> seen = new LinkedHashMap<>();

        for (Transaction tx : transactions) {
            if (tx.getCustomerName() == null || tx.getCustomerName().isBlank()) continue;

            String key;
            if (tx.getCustomerId() != null && !tx.getCustomerId().isBlank()) {
                key = "id:" + tx.getCustomerId();
            } else if (tx.getCustomerDocumentNumber() != null && !tx.getCustomerDocumentNumber().isBlank()) {
                key = "doc:" + tx.getCustomerDocumentNumber();
            } else {
                key = "name:" + tx.getCustomerName().trim().toLowerCase();
            }

            seen.putIfAbsent(key, CustomerData.builder()
                    .customerId(tx.getCustomerId())
                    .customerName(tx.getCustomerName())
                    .customerAddress(tx.getCustomerAddress())
                    .documentNumber(tx.getCustomerDocumentNumber())
                    .nationality(tx.getCustomerNationality())
                    // customerType: ha nincs specifikus megkülönböztetés, default "NATURAL"
                    // Jogi személy azonosítása: nincs dedicált mező a Transaction-ben,
                    // így természetes személy az alapértelmezett (adóhatósági logika szerint)
                    .customerType("NATURAL")
                    .build());
        }

        return new ArrayList<>(seen.values());
    }

    /**
     * Foglaló adatok gyűjtése.
     *
     * Bug 3 fix: csak az adott napon létrehozott ACTIVE foglalókat adja vissza,
     * nem az összes aktív foglalót.
     */
    private List<ReservationData> getReservations(UUID branchId, LocalDate date) {
        LocalDateTime dayStart = date.atStartOfDay();
        LocalDateTime dayEnd = date.atTime(LocalTime.MAX);

        List<Reservation> reservations = reservationRepository.findActiveByBranchAndDate(
                branchId, dayStart, dayEnd);

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

    // ============ FKH-036 FR-1: ELŐNÉZETI ÖSSZEFOGLALÓ ============

    /**
     * FKH-036 FR-1: a UI-előnézet összefoglaló mezőinek feltöltése a már felépített,
     * DÁTUM-SZKÓPOLT bemenetekből.
     *
     * <p>B1 (dátum-invariáns): minden mező EGY napra válaszol. A PENDING-tranzakció
     * figyelmeztetés a már felépített, dátum-szkópolt {@code transactions} listából
     * származik — NEM a {@code transactionRepository.existsByBranchIdAndStatus(...)}
     * branch-szintű (dátum nélküli) metódusból, ami egy korábbi napi beragadt sortól
     * véglegesen bekapcsolná a figyelmeztetést.</p>
     *
     * <p>Minden lista-mező soha nem null. Ha a tenant-kontextus hiányzik
     * (companyId == null), a csomaglista fail-closed üres.</p>
     */
    private void enrichSummary(DailyDataPackage pkg, UUID branchUuid, LocalDate date,
                               List<TransactionSummary> transactions,
                               List<ReservationData> reservations) {
        UUID companyId = SecurityUtils.getCurrentCompanyIdOrNull();

        // branchName — tenant-szkópolt, ha van cég-kontextus.
        pkg.setBranchName(companyId != null
                ? branchRepository.findByIdAndCompanyId(branchUuid, companyId)
                        .map(Branch::getName).orElse(null)
                : branchRepository.findById(branchUuid).map(Branch::getName).orElse(null));

        // Forgalmi összesítők — a dátum-szkópolt tranzakciólistából.
        pkg.setTransactionCount(transactions != null ? transactions.size() : 0);
        BigDecimal totalBuyHuf = BigDecimal.ZERO;
        BigDecimal totalSellHuf = BigDecimal.ZERO;
        long pendingTransactionCount = 0L;
        if (transactions != null) {
            for (TransactionSummary tx : transactions) {
                if ("BUY".equals(tx.getTransactionType()) && tx.getHufAmount() != null) {
                    totalBuyHuf = totalBuyHuf.add(tx.getHufAmount());
                } else if ("SELL".equals(tx.getTransactionType()) && tx.getHufAmount() != null) {
                    totalSellHuf = totalSellHuf.add(tx.getHufAmount());
                }
                if ("PENDING".equals(tx.getStatus())) {
                    pendingTransactionCount++;
                }
            }
        }
        pkg.setTotalBuyHuf(totalBuyHuf);
        pkg.setTotalSellHuf(totalSellHuf);

        // Szinkron-státusz — EveningSyncLog (legfeljebb egy sor branch+dátumonként).
        Optional<EveningSyncLog> syncLog = eveningSyncLogRepository
                .findByBranchIdAndSyncDate(branchUuid, date);
        pkg.setStatus(syncLog.filter(l -> "EVENING_SYNC_DONE".equals(l.getStatus())).isPresent()
                ? "SENT"
                : syncLog.isPresent() ? "PREVIEW" : "NOT_STARTED");
        int pendingSyncs = syncLog.filter(l -> !"EVENING_SYNC_DONE".equals(l.getStatus()))
                .isPresent() ? 1 : 0;
        pkg.setPendingSyncs(pendingSyncs);

        // Aznapi ACTIVE foglalók (dátum-szkópolt, nem teljes backlog — terv 7. döntés).
        int openReservations = reservations == null ? 0 : reservations.size();
        pkg.setOpenReservations(openReservations);

        // Záró egyenlegek — ugyanaz a forrás, amit a ClosingWizardService.loadPhysicalCounts
        // használ (egyetlen igazság-forrás, terv 8. döntés).
        List<BalanceView> balances = new ArrayList<>();
        for (Object[] row : denominationBalanceRepository.sumActualStockByCurrency(
                branchUuid, date, DenominationCategory.EVENING)) {
            if (row.length >= 2 && row[0] instanceof String code && row[1] instanceof BigDecimal total) {
                balances.add(BalanceView.builder().currency(code).amount(total).build());
            }
        }
        pkg.setBalances(balances);

        // Készített csomagok — KIZÁRÓLAG FF (kimenő), fail-closed: companyId nélkül üres.
        List<PackageView> packages = new ArrayList<>();
        if (companyId != null) {
            for (Object[] row : shipmentRequestRepository.findOutgoingPackageRowsForDate(
                    companyId, branchUuid, date, ShipmentHandlingFeeRepository.KPI_COUNTED_STATUSES)) {
                packages.add(PackageView.builder()
                        .packageId(row[0] != null ? row[0].toString() : null)
                        .currency(row[1] != null ? row[1].toString() : null)
                        .amount(row[2] instanceof BigDecimal amount ? amount : null)
                        .sealNumber(row[3] != null ? row[3].toString() : null)
                        .destination(row[4] != null ? row[4].toString() : null)
                        .build());
            }
        }
        pkg.setPackages(packages);

        // Figyelmeztetések — fix sorrend, soha nem null (terv 21. döntés).
        List<String> warnings = new ArrayList<>();
        if (pendingTransactionCount > 0) {
            warnings.add(pendingTransactionCount
                    + " aznapi, folyamatban lévő (PENDING) tranzakció van — a zárás előtt le kell zárni.");
        }
        if (openReservations > 0) {
            warnings.add(openReservations + " aznapi nyitott foglaló van.");
        }
        if (pendingSyncs > 0) {
            warnings.add("Van függőben lévő esti szinkron erre a napra.");
        }
        pkg.setWarnings(warnings);
    }

    // ============ UTILITY ============

    /**
     * SHA-256 checksum számítása a csomagból.
     *
     * Bug 4 fix: mind a 9 adatkategória belekerül a hashbe, nem csak 4 mező.
     * Tartalmazza: branchId, date, tranzakció count, total HUF összeg,
     * cimlet count, árfolyam count, ügyfél count, foglaló count, total díj.
     */
    private String calculateChecksum(DailyDataPackage pkg) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");

            int txCount = pkg.getTransactions() != null ? pkg.getTransactions().size() : 0;
            int denomCount = pkg.getDenominations() != null ? pkg.getDenominations().size() : 0;
            int rateCount = pkg.getRates() != null ? pkg.getRates().size() : 0;
            int customerCount = pkg.getCustomers() != null ? pkg.getCustomers().size() : 0;
            int reservationCount = pkg.getReservations() != null ? pkg.getReservations().size() : 0;

            BigDecimal totalHuf = pkg.getTransactions() != null
                    ? pkg.getTransactions().stream()
                        .filter(tx -> tx.getHufAmount() != null)
                        .map(TransactionSummary::getHufAmount)
                        .reduce(BigDecimal.ZERO, BigDecimal::add)
                    : BigDecimal.ZERO;

            BigDecimal totalFees = pkg.getHandlingFees() != null
                    ? pkg.getHandlingFees().getTotalHandlingFee()
                    : BigDecimal.ZERO;
            if (totalFees == null) totalFees = BigDecimal.ZERO;

            String data = String.format("%d|%s|%d|%s|%d|%d|%d|%d|%s",
                    pkg.getBranchId(),
                    pkg.getDate(),
                    txCount,
                    totalHuf.toPlainString(),
                    denomCount,
                    rateCount,
                    customerCount,
                    reservationCount,
                    totalFees.toPlainString());

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
     * Long → UUID konverzió helper (backward compat, legacy Long ID-khez).
     *
     * @deprecated Bug 5: Ez a konverzió veszteséges — az UUID felső 64 bitje elvész.
     *             UUID-alapú metódusok használatával kerülhető el.
     *             A Long-alapú overload csak legacy kompatibilitáshoz marad.
     */
    @Deprecated(since = "2.0", forRemoval = false)
    UUID uuidFromLong(Long id) {
        if (id == null) return null;
        return new UUID(0L, id);
    }

    private Path writeEveningPackageArtifact(DailyDataPackage pkg) throws Exception {
        String safeSyncDir = fileTransportService.sanitizePathSegment(
                integrationTransportProperties.getSync().getDir(), "sync.dir");
        String branchSegment = fileTransportService.sanitizePathSegment(
                String.valueOf(pkg.getBranchId()), "branchId");
        String dateSegment = fileTransportService.sanitizePathSegment(
                pkg.getDate().toString(), "reportDate");
        String relativeDir = Paths.get(safeSyncDir, "evening-closing", branchSegment, dateSegment).toString();

        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("action", "DAILY_REPORT");
        payload.put("checksum", pkg.getChecksum());
        payload.put("branchId", pkg.getBranchId());
        payload.put("date", pkg.getDate());
        payload.put("transactionCount", pkg.getTransactions() != null ? pkg.getTransactions().size() : 0);
        payload.put("package", pkg);
        payload.put("createdAt", LocalDateTime.now().toString());

        return fileTransportService.writeJson(relativeDir, "evening_daily_report", payload);
    }
}
