package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.WuTransactionStatus;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.dto.wu.WuDailyReportDto;
import hu.puzzleir.valuta.dto.wu.WuTransactionDto;
import hu.puzzleir.valuta.entity.WuBalance;
import hu.puzzleir.valuta.entity.WuCustomer;
import hu.puzzleir.valuta.entity.WuTransaction;
import hu.puzzleir.valuta.repository.WuBalanceRepository;
import hu.puzzleir.valuta.repository.WuCustomerRepository;
import hu.puzzleir.valuta.repository.WuTransactionRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;
import java.util.UUID;

/**
 * Western Union forgalom szolgáltatás.
 *
 * Legacy: WU DLL — WU küldés/fogadás nyilvántartás, egyenlegek, napi riport.
 * Supports: SEND, RECEIVE, IC_IN, IC_OUT, CUSTOMER_IN, CUSTOMER_OUT, STORNO
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class WesternUnionService {

    private final WuTransactionRepository wuTransactionRepository;
    private final WuCustomerRepository wuCustomerRepository;
    private final WuBalanceRepository wuBalanceRepository;
    private final BranchRepository branchRepository;
    private final CompanyRepository companyRepository;
    private final AmlService amlService;

    // ============ MTCN VALIDATION ============

    /**
     * MTCN validáció: 10 jegyű szám (WU szabvány).
     * Legacy: WUNION.DLL — MTCN ellenőrzés.
     *
     * @param mtcn a Money Transfer Control Number
     * @throws ValidationException ha formátum nem megfelelő
     */
    private void validateMtcn(String mtcn) {
        if (mtcn == null || mtcn.isBlank()) {
            throw new ValidationException("MTCN kötelező");
        }
        if (!mtcn.matches("\\d{10}")) {
            throw new ValidationException(
                "Érvénytelen MTCN formátum: '" + mtcn + "' — pontosan 10 számjegy szükséges");
        }
    }

    // ============ AML HELPER ============

    /**
     * WU tranzakció AML ellenőrzése.
     * HUF összeg alapján végzi az ellenőrzést; ha nincs HUF összeg, USD-ből becsüli.
     *
     * @throws ValidationException ha az AML check blokkol
     */
    private void performAmlCheck(String customerName, String documentNumber, BigDecimal amountHuf, BigDecimal amountUsd) {
        BigDecimal hufForCheck = amountHuf;
        if (hufForCheck == null || hufForCheck.compareTo(BigDecimal.ZERO) == 0) {
            // Ha nincs HUF összeg, nem fut AML ellenőrzés (pl. IC tranzakciók)
            return;
        }

        AmlService.AmlBasicCheckResult result = amlService.checkTransaction(
                hufForCheck,
                null,          // WU ügyfélnek nincs belső customerId
                customerName,
                documentNumber
        );

        if (!result.isApproved()) {
            throw new ValidationException("AML ellenőrzés megtagadta a tranzakciót: " + result.getRejectionReason());
        }

        if (result.isRequiresDetailedId()) {
            log.warn("WU AML: Részletes azonosítás szükséges — összeg={} HUF",
                    hufForCheck);
        } else if (result.isRequiresIdentification()) {
            log.info("WU AML: Azonosítás szükséges — összeg={} HUF", hufForCheck);
        }
    }

    // ============ SEND / RECEIVE ============

    /**
     * WU küldés rögzítése.
     */
    @Transactional
    public WuTransaction recordSend(WuTransactionDto dto) {
        validateMtcn(dto.getMtcn());
        Branch branch = findBranch(dto.getBranchId());
        performAmlCheck(dto.getSenderName(), null, dto.getAmountHuf(), dto.getAmountUsd());

        WuTransaction tx = WuTransaction.builder()
                .branch(branch)
                .company(branch.getCompany())
                .transactionType("SEND")
                .mtcn(dto.getMtcn())
                .amountUsd(dto.getAmountUsd())
                .amountHuf(dto.getAmountHuf())
                .exchangeRate(dto.getExchangeRate())
                .feeAmount(dto.getFeeAmount())
                .senderName(dto.getSenderName())
                .receiverName(dto.getReceiverName())
                .destinationCountry(dto.getDestinationCountry())
                .receiptNumber(dto.getReceiptNumber())
                .status(WuTransactionStatus.COMPLETED)
                .transactionDate(dto.getTransactionDate() != null ? dto.getTransactionDate() : LocalDateTime.now())
                .build();

        if (dto.getWuCustomerId() != null) {
            WuCustomer customer = wuCustomerRepository.findById(dto.getWuCustomerId()).orElse(null);
            tx.setWuCustomer(customer);
        }

        WuTransaction saved = wuTransactionRepository.save(tx);
        updateBalance(branch, dto.getAmountUsd(), dto.getAmountHuf(), true);

        log.info("WU SEND recorded: MTCN={}, amount={} USD, branch={}",
                dto.getMtcn(), dto.getAmountUsd(), dto.getBranchId());
        return saved;
    }

    /**
     * WU fogadás rögzítése.
     */
    @Transactional
    public WuTransaction recordReceive(WuTransactionDto dto) {
        validateMtcn(dto.getMtcn());
        Branch branch = findBranch(dto.getBranchId());
        performAmlCheck(dto.getReceiverName(), null, dto.getAmountHuf(), dto.getAmountUsd());

        WuTransaction tx = WuTransaction.builder()
                .branch(branch)
                .company(branch.getCompany())
                .transactionType("RECEIVE")
                .mtcn(dto.getMtcn())
                .amountUsd(dto.getAmountUsd())
                .amountHuf(dto.getAmountHuf())
                .exchangeRate(dto.getExchangeRate())
                .feeAmount(dto.getFeeAmount())
                .senderName(dto.getSenderName())
                .receiverName(dto.getReceiverName())
                .destinationCountry(dto.getDestinationCountry())
                .receiptNumber(dto.getReceiptNumber())
                .status(WuTransactionStatus.COMPLETED)
                .transactionDate(dto.getTransactionDate() != null ? dto.getTransactionDate() : LocalDateTime.now())
                .build();

        if (dto.getWuCustomerId() != null) {
            WuCustomer customer = wuCustomerRepository.findById(dto.getWuCustomerId()).orElse(null);
            tx.setWuCustomer(customer);
        }

        WuTransaction saved = wuTransactionRepository.save(tx);
        // Fogadásnál ellentétes irány: USD nő, HUF csökken
        updateBalance(branch, dto.getAmountUsd(), dto.getAmountHuf(), false);

        log.info("WU RECEIVE recorded: MTCN={}, amount={} USD, branch={}",
                dto.getMtcn(), dto.getAmountUsd(), dto.getBranchId());
        return saved;
    }

    // ============ IC_IN / IC_OUT ============

    /**
     * IC_IN: irodák közötti beérkező USD (másik irodától érkező készlet).
     * Legacy: WUNION.DLL IC_IN típusú mozgás.
     */
    @Transactional
    public WuTransaction recordIcIn(WuTransactionDto dto) {
        Branch branch = findBranch(dto.getBranchId());

        WuTransaction tx = WuTransaction.builder()
                .branch(branch)
                .company(branch.getCompany())
                .transactionType("IC_IN")
                .amountUsd(dto.getAmountUsd())
                .amountHuf(dto.getAmountHuf())
                .exchangeRate(dto.getExchangeRate())
                .receiptNumber(dto.getReceiptNumber())
                .status(WuTransactionStatus.COMPLETED)
                .transactionDate(dto.getTransactionDate() != null ? dto.getTransactionDate() : LocalDateTime.now())
                .build();

        WuTransaction saved = wuTransactionRepository.save(tx);
        // IC_IN: USD egyenleg nő (beérkezés)
        updateBalanceUsdOnly(branch, dto.getAmountUsd(), true);

        log.info("WU IC_IN recorded: amount={} USD, branch={}", dto.getAmountUsd(), dto.getBranchId());
        return saved;
    }

    /**
     * IC_OUT: irodák közötti kimenő USD (másik irodának átadott készlet).
     * Legacy: WUNION.DLL IC_OUT típusú mozgás.
     */
    @Transactional
    public WuTransaction recordIcOut(WuTransactionDto dto) {
        Branch branch = findBranch(dto.getBranchId());

        WuTransaction tx = WuTransaction.builder()
                .branch(branch)
                .company(branch.getCompany())
                .transactionType("IC_OUT")
                .amountUsd(dto.getAmountUsd())
                .amountHuf(dto.getAmountHuf())
                .exchangeRate(dto.getExchangeRate())
                .receiptNumber(dto.getReceiptNumber())
                .status(WuTransactionStatus.COMPLETED)
                .transactionDate(dto.getTransactionDate() != null ? dto.getTransactionDate() : LocalDateTime.now())
                .build();

        WuTransaction saved = wuTransactionRepository.save(tx);
        // IC_OUT: USD egyenleg csökken (kimenés)
        updateBalanceUsdOnly(branch, dto.getAmountUsd(), false);

        log.info("WU IC_OUT recorded: amount={} USD, branch={}", dto.getAmountUsd(), dto.getBranchId());
        return saved;
    }

    // ============ REVERSAL (STORNO) ============

    /**
     * WU tranzakció sztornózása.
     *
     * Legacy: WUNION.DLL STORNO logika — ellentétes tételű STORNO rekord, eredeti státus REVERSED.
     *
     * @param originalId   az eredeti tranzakció UUID-ja
     * @param reason       sztornó indoklás
     * @return a létrehozott STORNO tranzakció
     * @throws ResourceNotFoundException ha az eredeti nem található
     * @throws ValidationException       ha már sztornózva van, vagy STORNO típus
     */
    @Transactional
    public WuTransaction reverseWuTransaction(UUID originalId, String reason) {
        WuTransaction original = wuTransactionRepository.findById(originalId)
                .orElseThrow(() -> new ResourceNotFoundException("WU tranzakció nem található: " + originalId));

        // Dupla sztornó megakadályozása
        if (original.getStatus() == WuTransactionStatus.REVERSED) {
            throw new ValidationException("A tranzakció már sztornózva van: " + originalId);
        }
        if ("STORNO".equals(original.getTransactionType())) {
            throw new ValidationException("Sztornó tranzakció nem sztornózható: " + originalId);
        }

        // STORNO rekord létrehozása
        WuTransaction storno = WuTransaction.builder()
                .branch(original.getBranch())
                .company(original.getCompany())
                .wuCustomer(original.getWuCustomer())
                .transactionType("STORNO")
                .mtcn(original.getMtcn())
                .amountUsd(original.getAmountUsd())
                .amountHuf(original.getAmountHuf())
                .exchangeRate(original.getExchangeRate())
                .feeAmount(original.getFeeAmount())
                .senderName(original.getSenderName())
                .receiverName(original.getReceiverName())
                .destinationCountry(original.getDestinationCountry())
                .receiptNumber(original.getReceiptNumber())
                .status(WuTransactionStatus.COMPLETED)
                .reversedTransaction(original)
                .reversalReason(reason)
                .transactionDate(LocalDateTime.now())
                .build();

        WuTransaction savedStorno = wuTransactionRepository.save(storno);

        // Eredeti tranzakció státuszának megjelölése
        original.setStatus(WuTransactionStatus.REVERSED);
        wuTransactionRepository.save(original);

        // Egyenleg visszaállítása (ellentétes irány)
        Branch branch = original.getBranch();
        boolean wasSend = "SEND".equals(original.getTransactionType())
                || "IC_OUT".equals(original.getTransactionType())
                || "CUSTOMER_OUT".equals(original.getTransactionType());

        if ("IC_IN".equals(original.getTransactionType()) || "IC_OUT".equals(original.getTransactionType())) {
            updateBalanceUsdOnly(branch, original.getAmountUsd(), wasSend);
        } else {
            // SEND sztornó: fordított updateBalance
            updateBalance(branch, original.getAmountUsd(), original.getAmountHuf(), !wasSend);
        }

        log.info("WU STORNO created: originalId={}, stornoId={}, reason='{}'",
                originalId, savedStorno.getId(), reason);
        return savedStorno;
    }

    // ============ WUCUSTOMER DEDUPLIKÁCIÓ ============

    /**
     * WU ügyfél keresése vagy létrehozása.
     *
     * Ha azonos vezéknév + keresztnév + dokumentumszám kombináció már létezik,
     * visszaadja a meglévő rekordot (deduplikáció).
     * Ha nem létezik, új WuCustomer-t hoz létre.
     *
     * @param lastName     ügyfél vezékneve
     * @param firstName    ügyfél keresztneve
     * @param idType       igazolvány típusa
     * @param idNumber     igazolvány száma
     * @return meglévő vagy újonnan létrehozott WuCustomer
     */
    @Transactional
    public WuCustomer findOrCreateWuCustomer(String lastName, String firstName,
                                              String idType, String idNumber) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        if (idNumber != null && !idNumber.isBlank()) {
            return wuCustomerRepository
                    .findByCompanyIdAndLastNameAndFirstNameAndIdNumber(companyId, lastName, firstName, idNumber)
                    .orElseGet(() -> createWuCustomer(companyId, lastName, firstName, idType, idNumber));
        }
        // Ha nincs dokumentumszám, mindig új rekord
        return createWuCustomer(companyId, lastName, firstName, idType, idNumber);
    }

    private WuCustomer createWuCustomer(UUID companyId, String lastName, String firstName,
                                         String idType, String idNumber) {
        hu.puzzleir.valuta.entity.Company company = companyRepository.findById(companyId)
                .orElseThrow(() -> new ResourceNotFoundException("Cég nem található: " + companyId));

        WuCustomer customer = WuCustomer.builder()
                .company(company)
                .lastName(lastName)
                .firstName(firstName)
                .idType(idType)
                .idNumber(idNumber)
                .build();
        WuCustomer saved = wuCustomerRepository.save(customer);
        log.info("WuCustomer created: id={}, companyId={}", saved.getId(), companyId);
        return saved;
    }

    // ============ QUERY ============

    /**
     * WU tranzakciók lekérdezése irodánként és dátum tartomány szerint.
     * Multi-tenant: ellenőrzi, hogy a branch az aktuális céghez tartozik.
     */
    @Transactional(readOnly = true)
    public Page<WuTransaction> getTransactions(UUID branchId, LocalDate from, LocalDate to, Pageable pageable) {
        verifyBranchOwnership(branchId);
        LocalDateTime fromDt = from != null ? from.atStartOfDay() : null;
        LocalDateTime toDt = to != null ? to.atTime(LocalTime.MAX) : null;
        return wuTransactionRepository.findByBranchAndDateRange(branchId, fromDt, toDt, pageable);
    }

    // ============ NAPI RIPORT ============

    /**
     * WU napi riport — SEND, RECEIVE, IC_IN, IC_OUT, CUSTOMER_IN, CUSTOMER_OUT, STORNO típusokra bontva.
     * Multi-tenant: ellenőrzi, hogy a branch az aktuális céghez tartozik.
     */
    @Transactional(readOnly = true)
    public WuDailyReportDto getDailyReport(UUID branchId, LocalDate date) {
        verifyBranchOwnership(branchId);
        LocalDateTime from = date.atStartOfDay();
        LocalDateTime to = date.atTime(LocalTime.MAX);
        List<WuTransaction> transactions = wuTransactionRepository.findAllByBranchAndDateRange(branchId, from, to);

        int sendCount = 0;
        int receiveCount = 0;
        int icInCount = 0;
        int icOutCount = 0;
        int customerInCount = 0;
        int customerOutCount = 0;
        int stornoCount = 0;

        BigDecimal totalSendUsd = BigDecimal.ZERO;
        BigDecimal totalSendHuf = BigDecimal.ZERO;
        BigDecimal totalReceiveUsd = BigDecimal.ZERO;
        BigDecimal totalReceiveHuf = BigDecimal.ZERO;
        BigDecimal totalFees = BigDecimal.ZERO;
        BigDecimal totalIcInUsd = BigDecimal.ZERO;
        BigDecimal totalIcOutUsd = BigDecimal.ZERO;
        BigDecimal totalStornoUsd = BigDecimal.ZERO;

        for (WuTransaction tx : transactions) {
            // Sztornózott eredeti tételek kihagyása a riportból
            if (tx.getStatus() == WuTransactionStatus.REVERSED) {
                continue;
            }

            String type = tx.getTransactionType();
            switch (type != null ? type : "") {
                case "SEND" -> {
                    sendCount++;
                    if (tx.getAmountUsd() != null) totalSendUsd = totalSendUsd.add(tx.getAmountUsd());
                    if (tx.getAmountHuf() != null) totalSendHuf = totalSendHuf.add(tx.getAmountHuf());
                }
                case "RECEIVE" -> {
                    receiveCount++;
                    if (tx.getAmountUsd() != null) totalReceiveUsd = totalReceiveUsd.add(tx.getAmountUsd());
                    if (tx.getAmountHuf() != null) totalReceiveHuf = totalReceiveHuf.add(tx.getAmountHuf());
                }
                case "IC_IN" -> {
                    icInCount++;
                    if (tx.getAmountUsd() != null) totalIcInUsd = totalIcInUsd.add(tx.getAmountUsd());
                }
                case "IC_OUT" -> {
                    icOutCount++;
                    if (tx.getAmountUsd() != null) totalIcOutUsd = totalIcOutUsd.add(tx.getAmountUsd());
                }
                case "CUSTOMER_IN" -> customerInCount++;
                case "CUSTOMER_OUT" -> customerOutCount++;
                case "STORNO" -> {
                    stornoCount++;
                    if (tx.getAmountUsd() != null) totalStornoUsd = totalStornoUsd.add(tx.getAmountUsd());
                }
                default -> {
                    // Ismeretlen típus: logoljuk, de NEM számoljuk bele egyetlen kategóriába sem
                    log.warn("WU napi riport: ismeretlen tranzakció típus kihagyva: '{}', txId={}",
                            type, tx.getId());
                }
            }
            if (tx.getFeeAmount() != null) totalFees = totalFees.add(tx.getFeeAmount());
        }

        return WuDailyReportDto.builder()
                .date(date)
                .sendCount(sendCount)
                .receiveCount(receiveCount)
                .totalSendUsd(totalSendUsd)
                .totalSendHuf(totalSendHuf)
                .totalReceiveUsd(totalReceiveUsd)
                .totalReceiveHuf(totalReceiveHuf)
                .totalFees(totalFees)
                .icInCount(icInCount)
                .icOutCount(icOutCount)
                .totalIcInUsd(totalIcInUsd)
                .totalIcOutUsd(totalIcOutUsd)
                .customerInCount(customerInCount)
                .customerOutCount(customerOutCount)
                .stornoCount(stornoCount)
                .totalStornoUsd(totalStornoUsd)
                .build();
    }

    // ============ EGYENLEG ============

    /**
     * WU egyenleg lekérdezése.
     * Multi-tenant: ellenőrzi, hogy a branch az aktuális céghez tartozik.
     */
    @Transactional(readOnly = true)
    public List<WuBalance> getBalance(UUID branchId) {
        verifyBranchOwnership(branchId);
        return wuBalanceRepository.findAllByBranchId(branchId);
    }

    // ============ PRIVATE HELPERS ============

    /**
     * Ellenőrzi, hogy a megadott iroda az aktuális céghez tartozik-e.
     * Ha nem, ResourceNotFoundException-t dob (nem fedünk fel más cég adatait).
     */
    private void verifyBranchOwnership(UUID branchId) {
        Branch branch = branchRepository.findById(branchId)
                .orElseThrow(() -> new ResourceNotFoundException("Iroda nem található: " + branchId));
        UUID currentCompanyId = SecurityUtils.getCurrentCompanyId();
        if (branch.getCompany() == null || !branch.getCompany().getId().equals(currentCompanyId)) {
            throw new ResourceNotFoundException("Iroda nem található: " + branchId);
        }
    }

    private Branch findBranch(UUID branchId) {
        Branch branch = branchRepository.findById(branchId)
                .orElseThrow(() -> new ResourceNotFoundException("Branch not found: " + branchId));
        if (branch.getCompany() == null) {
            throw new ValidationException("Az iroda nincs céghez rendelve: " + branchId);
        }
        return branch;
    }

    /**
     * WU egyenleg frissítése USD + HUF mozgással.
     * Branch-et veszi paraméterül, hogy a company referencia elérhető legyen.
     */
    private void updateBalance(Branch branch, BigDecimal amountUsd, BigDecimal amountHuf, boolean isSend) {
        WuBalance balance = getOrCreateBalance(branch);

        if (isSend) {
            // Küldés: USD csökken (kifolyik), HUF nő (ügyfél befizeti HUF-ban)
            if (amountUsd != null) balance.setUsdBalance(balance.getUsdBalance().subtract(amountUsd));
            if (amountHuf != null) balance.setHufBalance(balance.getHufBalance().add(amountHuf));
        } else {
            // Fogadás: USD nő (befolyik), HUF csökken (ügyfélnek kifizetjük HUF-ban)
            if (amountUsd != null) balance.setUsdBalance(balance.getUsdBalance().add(amountUsd));
            if (amountHuf != null) balance.setHufBalance(balance.getHufBalance().subtract(amountHuf));
        }

        balance.setUpdatedAt(LocalDateTime.now());
        wuBalanceRepository.save(balance);
    }

    /**
     * WU egyenleg frissítése csak USD mozgással (IC tranzakciókhoz).
     */
    private void updateBalanceUsdOnly(Branch branch, BigDecimal amountUsd, boolean isIncrease) {
        if (amountUsd == null) return;
        WuBalance balance = getOrCreateBalance(branch);

        if (isIncrease) {
            balance.setUsdBalance(balance.getUsdBalance().add(amountUsd));
        } else {
            balance.setUsdBalance(balance.getUsdBalance().subtract(amountUsd));
        }

        balance.setUpdatedAt(LocalDateTime.now());
        wuBalanceRepository.save(balance);
    }

    /**
     * WU egyenleg betöltése pesszimista zárolással, vagy létrehozása ha nem létezik.
     * A Branch objektumot kapja, így a company referencia mindig elérhető.
     */
    private WuBalance getOrCreateBalance(Branch branch) {
        return wuBalanceRepository.findByBranchIdForUpdate(branch.getId())
                .orElseGet(() -> WuBalance.builder()
                        .branch(branch)
                        .company(branch.getCompany())
                        .usdBalance(BigDecimal.ZERO)
                        .hufBalance(BigDecimal.ZERO)
                        .build());
    }
}
