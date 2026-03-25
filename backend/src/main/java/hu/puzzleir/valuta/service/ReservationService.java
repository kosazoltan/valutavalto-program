package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.dto.reservation.ReservedStockDto;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.repository.CashBalanceRepository;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.repository.CustomerRepository;
import hu.puzzleir.valuta.repository.NotificationRepository;
import hu.puzzleir.valuta.repository.ReservationRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * Foglaló (Reservation) szolgáltatás.
 *
 * Legacy mapping: FOGLALO.DLL — FoglaloBevetelezes, VisszaFizetoProcedura, FoglaloKivezetes
 *
 * Üzleti logika:
 * 1. Bevételezés: ügyfél befizet HUF-ban → valuta lefoglalás + készlet elkülönítés
 * 2. Teljesítés (_visszatipus=1): ügyfél megkapja a valutát, refund = deposit
 * 3. Ügyfél stornó (_visszatipus=2): letét NEM jár vissza, refund = 0
 * 4. EBC stornó (_visszatipus=3): dupla visszafizetés, refund = 2 × deposit
 * 5. Készlet kezelés: FOGLALOKESZLET — valutanemenként elkülönített készlet
 * 6. Bizonylat: bevételi + kiadási bizonylat generálás
 */
@Service
@RequiredArgsConstructor
@Transactional(rollbackFor = Exception.class)
@Slf4j
public class ReservationService {

    private final ReservationRepository reservationRepository;
    private final CustomerRepository customerRepository;
    private final WorkerRepository workerRepository;
    private final CashBalanceRepository cashBalanceRepository;
    private final CurrencyRepository currencyRepository;
    private final CompanyRepository companyRepository;
    private final BranchRepository branchRepository;
    private final AuditLogService auditLogService;
    private final NotificationRepository notificationRepository;

    /** 5-re kerekítés (legacy Kerekito) */
    private static final BigDecimal FIVE = new BigDecimal("5");

    // ============ FOGLALÓ BEVÉTELEZÉS ============

    /**
     * Új foglaló létrehozás (FoglaloBevetelezes).
     *
     * Üzleti logika:
     * 1. Ügyfél ellenőrzés
     * 2. Valuta ellenőrzés + készlet ellenőrzés
     * 3. Letét számítás: deposit = amount × rate, 5-re kerekítve
     * 4. Készlet elkülönítés (CashBalance csökkentés a lefoglalt valuta összegével)
     * 5. HUF készlet növelés (letét beérkezése)
     * 6. AuditLog bejegyzés
     *
     * @param customerId   ügyfél ID
     * @param currencyCode valuta kód (EUR, USD, stb.)
     * @param amount       lefoglalandó valuta mennyiség
     * @param exchangeRate alkalmazott árfolyam
     * @param expiresAt    lejárati időpont
     * @param notes        megjegyzés (opcionális)
     * @return létrehozott Reservation
     */
    public Reservation createReservation(Long customerId, String currencyCode, BigDecimal amount,
                                          BigDecimal exchangeRate, LocalDateTime expiresAt, String notes) {
        // Security context
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        UUID branchId = SecurityUtils.getCurrentBranchId();
        Long workerId = SecurityUtils.getCurrentWorkerId();

        // Validáció
        if (expiresAt.isBefore(LocalDateTime.now())) {
            throw new ValidationException("Lejárati idő nem lehet a múltban!");
        }

        // Entitások betöltése
        Company company = companyRepository.findById(companyId)
                .orElseThrow(() -> new ResourceNotFoundException("Cég nem található"));
        Branch branch = branchRepository.findById(branchId)
                .orElseThrow(() -> new ResourceNotFoundException("Iroda nem található"));
        Worker worker = workerRepository.findById(workerId)
                .orElseThrow(() -> new ResourceNotFoundException("Pénztáros nem található"));
        Customer customer = customerRepository.findById(customerId)
                .orElseThrow(() -> new ResourceNotFoundException("Ügyfél nem található: " + customerId));

        // Valuta ellenőrzés
        Currency currency = currencyRepository.findByCode(currencyCode)
                .orElseThrow(() -> new ResourceNotFoundException("Valuta nem található: " + currencyCode));
        if (!Boolean.TRUE.equals(currency.getActive())) {
            throw new ValidationException("Inaktív valuta: " + currencyCode);
        }

        // Letét számítás: deposit = amount × rate, 5-re kerekítve
        BigDecimal rawDeposit = amount.multiply(exchangeRate).setScale(2, RoundingMode.HALF_UP);
        BigDecimal depositAmount = roundToFive(rawDeposit);

        // CRITICAL FIX #2: PESSIMISTIC_WRITE lock — párhuzamos készletmódosítás megakadályozása
        CashBalance currencyBalance = cashBalanceRepository
                .findByBranchIdAndCurrencyIdForUpdate(branchId, currency.getId())
                .orElseThrow(() -> new ResourceNotFoundException(
                    "Kassza egyenleg nem található: " + currencyCode));
        if (currencyBalance.getCurrentBalance().compareTo(amount) < 0) {
            throw new ValidationException(String.format(
                "Nincs elegendő %s készlet! Jelenlegi: %s, szükséges: %s",
                currencyCode, currencyBalance.getCurrentBalance().toPlainString(),
                amount.toPlainString()));
        }

        // Készlet elkülönítés — valuta csökkentés (lefoglalás)
        currencyBalance.subtractBalance(amount);
        cashBalanceRepository.save(currencyBalance);

        // HUF készlet növelés — letét beérkezése
        addHufBalance(branchId, depositAmount);

        // Foglaló létrehozás
        Reservation reservation = Reservation.builder()
                .company(company)
                .customer(customer)
                .branch(branch)
                .worker(worker)
                .currencyCode(currencyCode)
                .reservedAmount(amount)
                .exchangeRate(exchangeRate)
                .depositAmount(depositAmount)
                .status(ReservationStatus.ACTIVE)
                .expiresAt(expiresAt)
                .refundAmount(BigDecimal.ZERO)
                .supervisorApproval(false)
                .notes(notes)
                .build();

        reservation = reservationRepository.save(reservation);

        // AuditLog
        auditLogService.log(
                "RESERVATION_CREATED",
                "Reservation",
                reservation.getId().toString(),
                workerId.toString(),
                worker.getName(),
                branchId.toString(),
                branch.getName(),
                String.format("Foglaló létrehozva: %s %s @ %s, letét: %s HUF, ügyfél: %s, lejárat: %s",
                        amount.toPlainString(), currencyCode, exchangeRate.toPlainString(),
                        depositAmount.toPlainString(), customer.getName(), expiresAt),
                null, null
        );

        log.info("Foglaló létrehozva: id={}, ügyfél={}, {} {} @ {}, letét={} HUF",
                reservation.getId(), customer.getName(), amount, currencyCode,
                exchangeRate, depositAmount);

        return reservation;
    }

    // ============ FOGLALÓ TELJESÍTÉS ============

    /**
     * Foglaló teljesítés (VisszaFizetoProcedura, _visszatipus=1: "ÜGYLET RENDBEN").
     *
     * Ügyfél megkapja a lefoglalt valutát.
     * refundAmount = depositAmount (a letét beszámít a vételárba).
     *
     * @param reservationId foglaló ID
     * @return frissített Reservation
     */
    public Reservation fulfillReservation(Long reservationId) {
        Long workerId = SecurityUtils.getCurrentWorkerId();
        UUID branchId = SecurityUtils.getCurrentBranchId();

        // CRITICAL FIX #1: PESSIMISTIC_WRITE lock — párhuzamos teljesítés/stornó megakadályozása
        Reservation reservation = reservationRepository.findByIdForUpdate(reservationId)
                .orElseThrow(() -> new ResourceNotFoundException("Foglaló nem található: " + reservationId));
        validateActive(reservation);
        validateBranch(reservation, branchId);

        // Bug #1 fix: maradékfizetés számítás és HUF egyenleg növelés
        // A valuta már a createReservation()-ban kivonásra került — csak a pénzmozgást kell rendezni.
        BigDecimal fullPrice = roundToFive(
                reservation.getReservedAmount().multiply(reservation.getExchangeRate()));
        BigDecimal remainingPayment = fullPrice.subtract(reservation.getDepositAmount());
        if (remainingPayment.compareTo(BigDecimal.ZERO) > 0) {
            addHufBalance(branchId, remainingPayment);
        }

        reservation.setStatus(ReservationStatus.FULFILLED);
        reservation.setFulfilledAt(LocalDateTime.now());
        reservation.setRefundAmount(reservation.getDepositAmount());

        reservation = reservationRepository.save(reservation);

        // AuditLog
        Worker worker = workerRepository.findById(workerId)
                .orElseThrow(() -> new ResourceNotFoundException("Pénztáros nem található"));
        auditLogService.log(
                "RESERVATION_FULFILLED",
                "Reservation",
                reservation.getId().toString(),
                workerId.toString(),
                worker.getName(),
                branchId.toString(),
                reservation.getBranch().getName(),
                String.format("Foglaló teljesítve: %s %s, refund: %s HUF",
                        reservation.getReservedAmount().toPlainString(),
                        reservation.getCurrencyCode(),
                        reservation.getRefundAmount().toPlainString()),
                null, null
        );

        log.info("Foglaló teljesítve: id={}, refund={} HUF",
                reservation.getId(), reservation.getRefundAmount());

        return reservation;
    }

    // ============ ÜGYFÉL STORNÓ ============

    /**
     * Ügyfél stornó (VisszaFizetoProcedura, _visszatipus=2: "ÜGYFÉL MIATT SEMMIS").
     *
     * Ügyfél hibájából semmisül meg a foglaló.
     * refundAmount = 0 (letét NEM jár vissza).
     * A lefoglalt valuta visszakerül a készletbe.
     *
     * @param reservationId foglaló ID
     * @param reason        stornó oka (opcionális)
     * @return frissített Reservation
     */
    public Reservation cancelByCustomer(Long reservationId, String reason) {
        Long workerId = SecurityUtils.getCurrentWorkerId();
        UUID branchId = SecurityUtils.getCurrentBranchId();

        // CRITICAL FIX #1: PESSIMISTIC_WRITE lock — párhuzamos teljesítés/stornó megakadályozása
        Reservation reservation = reservationRepository.findByIdForUpdate(reservationId)
                .orElseThrow(() -> new ResourceNotFoundException("Foglaló nem található: " + reservationId));
        validateActive(reservation);
        validateBranch(reservation, branchId);

        // Státusz váltás
        reservation.setStatus(ReservationStatus.CANCELLED_BY_CUSTOMER);
        reservation.setCancelledAt(LocalDateTime.now());
        reservation.setRefundAmount(BigDecimal.ZERO);
        reservation.setCancellationReason(reason);

        // Valuta visszavezetés a készletbe (FoglaloKivezetes inverze)
        restoreCurrencyStock(reservation);

        reservation = reservationRepository.save(reservation);

        // AuditLog
        Worker worker = workerRepository.findById(workerId)
                .orElseThrow(() -> new ResourceNotFoundException("Pénztáros nem található"));
        auditLogService.log(
                "RESERVATION_CANCELLED_BY_CUSTOMER",
                "Reservation",
                reservation.getId().toString(),
                workerId.toString(),
                worker.getName(),
                branchId.toString(),
                reservation.getBranch().getName(),
                String.format("Ügyfél stornó: %s %s, refund: 0 HUF, ok: %s",
                        reservation.getReservedAmount().toPlainString(),
                        reservation.getCurrencyCode(),
                        reason != null ? reason : "nincs megadva"),
                null, null
        );

        log.info("Ügyfél stornó: id={}, valuta visszavezetve: {} {}",
                reservation.getId(), reservation.getReservedAmount(), reservation.getCurrencyCode());

        return reservation;
    }

    // ============ EBC STORNÓ ============

    /**
     * EBC stornó (VisszaFizetoProcedura, _visszatipus=3: "EBC MIATT SEMMIS").
     *
     * EBC hibájából semmisül meg a foglaló.
     * refundAmount = 2 × depositAmount (dupla visszafizetés).
     * A lefoglalt valuta visszakerül a készletbe.
     * Supervisor jóváhagyás KÖTELEZŐ.
     *
     * @param reservationId     foglaló ID
     * @param reason            stornó oka (KÖTELEZŐ)
     * @param supervisorWorkerId supervisor worker ID
     * @return frissített Reservation
     */
    public Reservation cancelByCompany(Long reservationId, String reason, Long supervisorWorkerId) {
        Long workerId = SecurityUtils.getCurrentWorkerId();
        UUID branchId = SecurityUtils.getCurrentBranchId();

        // Validáció
        if (reason == null || reason.isBlank()) {
            throw new ValidationException("EBC stornónál az indoklás kötelező!");
        }
        if (supervisorWorkerId == null) {
            throw new ValidationException("EBC stornóhoz supervisor jóváhagyás szükséges!");
        }

        // Supervisor ellenőrzés
        Worker supervisor = workerRepository.findById(supervisorWorkerId)
                .orElseThrow(() -> new ResourceNotFoundException("Supervisor nem található: " + supervisorWorkerId));
        if (supervisor.getRole() != WorkerRole.SUPERVISOR
                && supervisor.getRole() != WorkerRole.MANAGER
                && supervisor.getRole() != WorkerRole.ADMIN) {
            throw new ValidationException("A megadott dolgozónak nincs supervisor jogosultsága!");
        }

        // CRITICAL FIX #3: Supervisor branch ellenőrzés — csak a SAJÁT irodájában hagyhat jóvá
        if (!supervisor.getBranch().getId().equals(branchId)) {
            throw new ValidationException(
                    "A supervisor csak a saját irodájában hagyhat jóvá EBC stornót! " +
                    "Supervisor iroda: " + supervisor.getBranch().getName() +
                    ", aktuális iroda: " + branchId);
        }

        // CRITICAL FIX #1: PESSIMISTIC_WRITE lock — párhuzamos teljesítés/stornó megakadályozása
        Reservation reservation = reservationRepository.findByIdForUpdate(reservationId)
                .orElseThrow(() -> new ResourceNotFoundException("Foglaló nem található: " + reservationId));
        validateActive(reservation);
        validateBranch(reservation, branchId);

        // Dupla visszafizetés
        BigDecimal refund = reservation.getDepositAmount()
                .multiply(new BigDecimal("2"))
                .setScale(2, RoundingMode.HALF_UP);

        // HUF készlet csökkentés (dupla visszafizetés kiadása)
        subtractHufBalance(branchId, refund);

        // Státusz váltás
        reservation.setStatus(ReservationStatus.CANCELLED_BY_COMPANY);
        reservation.setCancelledAt(LocalDateTime.now());
        reservation.setRefundAmount(refund);
        reservation.setCancellationReason(reason);
        reservation.setSupervisorApproval(true);
        reservation.setSupervisorWorker(supervisor);

        // Valuta visszavezetés a készletbe
        restoreCurrencyStock(reservation);

        reservation = reservationRepository.save(reservation);

        // AuditLog
        Worker worker = workerRepository.findById(workerId)
                .orElseThrow(() -> new ResourceNotFoundException("Pénztáros nem található"));
        auditLogService.log(
                "RESERVATION_CANCELLED_BY_COMPANY",
                "Reservation",
                reservation.getId().toString(),
                workerId.toString(),
                worker.getName(),
                branchId.toString(),
                reservation.getBranch().getName(),
                String.format("EBC stornó: %s %s, refund: %s HUF (2×), ok: %s, supervisor: %s",
                        reservation.getReservedAmount().toPlainString(),
                        reservation.getCurrencyCode(),
                        refund.toPlainString(),
                        reason,
                        supervisor.getName()),
                null, null
        );

        log.info("EBC stornó: id={}, refund={} HUF (2×), supervisor={}",
                reservation.getId(), refund, supervisor.getName());

        return reservation;
    }

    // ============ LEKÉRDEZÉSEK ============

    /**
     * Foglaló részletek lekérdezése
     */
    @Transactional(readOnly = true)
    public Reservation getReservation(Long reservationId) {
        return getReservationById(reservationId);
    }

    /**
     * Aktív foglalók listája egy irodához.
     */
    @Transactional(readOnly = true)
    public List<Reservation> getActiveReservations(UUID branchId) {
        return reservationRepository.findActiveByBranch(branchId);
    }

    /**
     * Lejárt, de nem lezárt foglalók.
     */
    @Transactional(readOnly = true)
    public List<Reservation> getExpiredReservations() {
        return reservationRepository.findByStatusAndExpiresAtBefore(
                ReservationStatus.ACTIVE, LocalDateTime.now());
    }

    /**
     * Foglalt készlet valutanemenként (FOGLALOKESZLET megfelelője).
     *
     * @param branchId iroda ID
     * @return foglalt készlet lista valutanemenként
     */
    @Transactional(readOnly = true)
    public List<ReservedStockDto> getReservedStock(UUID branchId) {
        List<Object[]> rawData = reservationRepository.getReservedStockByBranch(branchId);
        List<ReservedStockDto> result = new ArrayList<>();

        for (Object[] row : rawData) {
            String code = (String) row[0];
            BigDecimal totalAmount = (BigDecimal) row[1];

            // Bug #2 fix: currency-specifikus aktív count (nem az összes valuta összesített száma)
            long count = reservationRepository.countActiveByCurrencyAndBranch(branchId, code);

            result.add(ReservedStockDto.builder()
                    .currencyCode(code)
                    .reservedAmount(totalAmount)
                    .activeCount(count)
                    .build());
        }

        return result;
    }

    // ============ GAP 3: AUTO-EXPIRY ============

    /**
     * Lejárt foglalók automatikus lezárása.
     *
     * Legacy üzleti szabály: ha a foglaló 2 napja lejárt és senki nem kezelte,
     * automatikusan EXPIRED státuszra vált. A letét összeg a kezelési költség
     * pénztárba (HUF kassza) kerül — az ügyfélnek NEM jár visszafizetés.
     * A lefoglalt valuta visszakerül a készletbe.
     *
     * @return lejárt foglalók száma
     */
    public int autoExpireReservations() {
        List<Reservation> expired = reservationRepository.findByStatusAndExpiresAtBefore(
                ReservationStatus.ACTIVE, LocalDateTime.now());

        int count = 0;
        for (Reservation reservation : expired) {
            try {
                // Bug #3 fix: idempotency — újra-lekérdezés PESSIMISTIC_WRITE lock-kal,
                // majd státusz ellenőrzés. Ha közben már nem ACTIVE, kihagyjuk.
                Reservation locked = reservationRepository
                        .findByIdForUpdate(reservation.getId()).orElse(null);
                if (locked == null || locked.getStatus() != ReservationStatus.ACTIVE) {
                    log.debug("Foglaló már nem aktív, kihagyva: id={}, státusz={}",
                            reservation.getId(),
                            locked != null ? locked.getStatus() : "NOT_FOUND");
                    continue;
                }
                reservation = locked;

                reservation.setStatus(ReservationStatus.EXPIRED);
                reservation.setCancelledAt(LocalDateTime.now());
                reservation.setRefundAmount(BigDecimal.ZERO);
                reservation.setCancellationReason("Automatikus lejárat — 2 napos határidő letelt");

                // Valuta visszavezetés a készletbe
                restoreCurrencyStock(reservation);

                // Letét összeg a kezelési költség pénztárban MARAD (HUF készlet nem változik,
                // mert a letét már a bevételezéskor hozzáadódott a HUF kasszához).
                // A deposit a cég bevétele lesz — nincs visszafizetés.

                reservationRepository.save(reservation);

                auditLogService.log(
                        "RESERVATION_AUTO_EXPIRED",
                        "Reservation",
                        reservation.getId().toString(),
                        "SYSTEM",
                        "Automatikus lejárat",
                        reservation.getBranch().getId().toString(),
                        reservation.getBranch().getName(),
                        String.format("Foglaló automatikusan lejárt: %s %s, letét: %s HUF → kezelési költség",
                                reservation.getReservedAmount().toPlainString(),
                                reservation.getCurrencyCode(),
                                reservation.getDepositAmount().toPlainString()),
                        null, null
                );

                log.info("Foglaló automatikusan lejárt: id={}, {} {}, letét={} HUF → kezelési költség",
                        reservation.getId(), reservation.getReservedAmount(),
                        reservation.getCurrencyCode(), reservation.getDepositAmount());
                count++;
            } catch (Exception e) {
                log.error("Hiba a foglaló auto-expiry során: id={}, hiba: {}",
                        reservation.getId(), e.getMessage(), e);
            }
        }

        if (count > 0) {
            log.info("Összesen {} foglaló automatikusan lejárt", count);
        }
        return count;
    }

    // ============ GAP 4: PRE-EXPIRY WARNING ============

    /**
     * Előfigyelmeztetés 1 nappal a lejárat előtt (Bug #4 — új feature).
     *
     * 30 percenként fut. Minden olyan aktív foglalóhoz, amelyik a következő 24 órán belül lejár,
     * egyszer létrehoz egy Notification-t. Idempotens: ha már létezik, kihagyja.
     */
    @Scheduled(fixedDelay = 30 * 60 * 1000)
    @Transactional(rollbackFor = Exception.class)
    public void sendPreExpiryWarnings() {
        LocalDateTime now = LocalDateTime.now();
        LocalDateTime in24h = now.plusHours(24);

        List<Reservation> expiringSoon = reservationRepository.findActiveExpiringBetween(now, in24h);

        int created = 0;
        for (Reservation reservation : expiringSoon) {
            String entityType = "Reservation";
            String entityId = reservation.getId().toString();
            String notificationType = "PRE_EXPIRY_WARNING";

            // Idempotency: ha már van ilyen értesítés, kihagyjuk
            if (notificationRepository.existsByEntityTypeAndEntityIdAndNotificationType(
                    entityType, entityId, notificationType)) {
                continue;
            }

            Notification notification = Notification.builder()
                    .title("Foglaló hamarosan lejár")
                    .message(String.format(
                            "A(z) %s %s foglaló (ID: %d, ügyfél: %s) %s-kor jár le — kevesebb mint 24 óra van hátra.",
                            reservation.getReservedAmount().toPlainString(),
                            reservation.getCurrencyCode(),
                            reservation.getId(),
                            reservation.getCustomer().getName(),
                            reservation.getExpiresAt()))
                    .type("WARNING")
                    .entityType(entityType)
                    .entityId(entityId)
                    .notificationType(notificationType)
                    .build();

            notificationRepository.save(notification);
            created++;

            log.info("Pre-expiry warning értesítés létrehozva: foglaló id={}, lejárat={}",
                    reservation.getId(), reservation.getExpiresAt());
        }

        if (created > 0) {
            log.info("Összesen {} pre-expiry warning értesítés létrehozva", created);
        }
    }

    // ============ PRIVATE HELPER METHODS ============

    /**
     * Foglaló lekérdezése ID alapján, ResourceNotFoundException ha nem található.
     */
    private Reservation getReservationById(Long reservationId) {
        return reservationRepository.findById(reservationId)
                .orElseThrow(() -> new ResourceNotFoundException("Foglaló nem található: " + reservationId));
    }

    /**
     * Ellenőrzi, hogy a foglaló aktív-e.
     */
    private void validateActive(Reservation reservation) {
        if (!reservation.isActive()) {
            throw new ValidationException(String.format(
                "Foglaló nem aktív! Jelenlegi státusz: %s", reservation.getStatus()));
        }
    }

    /**
     * Ellenőrzi, hogy a foglaló a megfelelő irodához tartozik-e.
     */
    private void validateBranch(Reservation reservation, UUID branchId) {
        if (!reservation.getBranch().getId().equals(branchId)) {
            throw new ValidationException("Ez a foglaló másik irodához tartozik!");
        }
    }

    /**
     * Valuta visszavezetés a készletbe (stornó esetén).
     * A lefoglalt valuta mennyiséget hozzáadja a CashBalance-hoz.
     */
    private void restoreCurrencyStock(Reservation reservation) {
        Currency currency = currencyRepository.findByCode(reservation.getCurrencyCode())
                .orElseThrow(() -> new ResourceNotFoundException(
                    "Valuta nem található: " + reservation.getCurrencyCode()));

        // CRITICAL FIX #2: PESSIMISTIC_WRITE lock — párhuzamos készletmódosítás megakadályozása
        CashBalance currencyBalance = cashBalanceRepository
                .findByBranchIdAndCurrencyIdForUpdate(reservation.getBranch().getId(), currency.getId())
                .orElseThrow(() -> new ResourceNotFoundException(
                    "Kassza egyenleg nem található: " + reservation.getCurrencyCode()));

        currencyBalance.addBalance(reservation.getReservedAmount());
        cashBalanceRepository.save(currencyBalance);

        log.debug("Valuta visszavezetve: {} {} → iroda: {}",
                reservation.getReservedAmount(), reservation.getCurrencyCode(),
                reservation.getBranch().getName());
    }

    /**
     * HUF készlet növelés (letét beérkezésekor).
     */
    private void addHufBalance(UUID branchId, BigDecimal amount) {
        Currency huf = currencyRepository.findByCode("HUF")
                .orElseThrow(() -> new ResourceNotFoundException("HUF valuta nem található!"));

        // CRITICAL FIX #2: PESSIMISTIC_WRITE lock — párhuzamos készletmódosítás megakadályozása
        CashBalance hufBalance = cashBalanceRepository
                .findByBranchIdAndCurrencyIdForUpdate(branchId, huf.getId())
                .orElseThrow(() -> new ResourceNotFoundException("HUF kassza egyenleg nem található!"));

        hufBalance.addBalance(amount);
        cashBalanceRepository.save(hufBalance);
    }

    /**
     * HUF készlet csökkentés (dupla visszafizetéskor).
     */
    private void subtractHufBalance(UUID branchId, BigDecimal amount) {
        Currency huf = currencyRepository.findByCode("HUF")
                .orElseThrow(() -> new ResourceNotFoundException("HUF valuta nem található!"));

        // CRITICAL FIX #2: PESSIMISTIC_WRITE lock — párhuzamos készletmódosítás megakadályozása
        CashBalance hufBalance = cashBalanceRepository
                .findByBranchIdAndCurrencyIdForUpdate(branchId, huf.getId())
                .orElseThrow(() -> new ResourceNotFoundException("HUF kassza egyenleg nem található!"));

        if (hufBalance.getCurrentBalance().compareTo(amount) < 0) {
            throw new ValidationException(String.format(
                "Nincs elegendő HUF a visszafizetéshez! Jelenlegi: %s, szükséges: %s",
                hufBalance.getCurrentBalance().toPlainString(), amount.toPlainString()));
        }

        hufBalance.subtractBalance(amount);
        cashBalanceRepository.save(hufBalance);
    }

    /**
     * 5-re kerekítés (legacy Kerekito függvény).
     *
     * Pl: 1232 → 1230, 1233 → 1235, 1237 → 1235, 1238 → 1240
     */
    private BigDecimal roundToFive(BigDecimal value) {
        // Egészre kerekítés HALF_UP, majd 5-re kerekítés
        BigDecimal rounded = value.setScale(0, RoundingMode.HALF_UP);
        BigDecimal remainder = rounded.remainder(FIVE);
        if (remainder.compareTo(BigDecimal.ZERO) == 0) {
            return rounded;
        }
        // Ha a maradék >= 3, felfelé kerekítünk 5-re; egyébként lefelé
        if (remainder.compareTo(new BigDecimal("3")) >= 0) {
            return rounded.add(FIVE.subtract(remainder));
        } else {
            return rounded.subtract(remainder);
        }
    }
}
