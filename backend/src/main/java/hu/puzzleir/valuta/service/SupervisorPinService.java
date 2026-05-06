package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.SupervisorPinAttempt;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.SupervisorPinAttemptRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.regex.Pattern;

/**
 * P2-2 Supervisor PIN — gyors-engedély 4-6 számjegy a jelszó helyett.
 *
 * <p>Use case: sztornó / supervisor-jóváhagyás műveletekhez 5-10 mp alatt
 * végrehajtható megerősítés (jelszó-bevitel + lookup helyett 4-6 számjegy
 * auto-submit).</p>
 *
 * <p>Biztonság:
 * <ul>
 *   <li>BCrypt hash (10 round, ugyanaz mint a password_hash)</li>
 *   <li>PIN nem helyettesíti a jelszót — opcionális gyors-engedély</li>
 *   <li>Rate limit: 3 hibás próbálkozás 5 perc alatt → 5 perc lockout</li>
 *   <li>Audit log minden PIN-verify-re (success + fail)</li>
 *   <li>Minimum 4, maximum 6 számjegy</li>
 * </ul>
 * </p>
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class SupervisorPinService {

    private static final Pattern PIN_PATTERN = Pattern.compile("^\\d{4,6}$");
    private static final int MAX_FAILED_ATTEMPTS = 3;
    private static final int LOCKOUT_WINDOW_MINUTES = 5;

    private final WorkerRepository workerRepository;
    private final SupervisorPinAttemptRepository attemptRepository;
    private final PasswordEncoder passwordEncoder;

    /**
     * PIN beállítás vagy módosítás. A jelenlegi jelszó megerősítése kötelező.
     */
    @Transactional
    public void setPin(Long workerId, String currentPassword, String newPin) {
        Worker worker = workerRepository.findById(workerId)
                .orElseThrow(() -> new ResourceNotFoundException("Worker nem található: " + workerId));

        if (!PIN_PATTERN.matcher(newPin).matches()) {
            throw new ValidationException("A PIN-nek 4-6 számjegynek kell lennie");
        }

        if (worker.getPasswordHash() == null
                || !passwordEncoder.matches(currentPassword, worker.getPasswordHash())) {
            throw new ValidationException("Hibás jelszó — PIN beállítás megtagadva");
        }

        worker.setSupervisorPin(passwordEncoder.encode(newPin));
        worker.setSupervisorPinChangedAt(LocalDateTime.now());
        workerRepository.save(worker);
        log.info("[supervisor-pin] SET worker={} (workerCode={})", workerId, worker.getCode());
    }

    /**
     * PIN ellenőrzés. Lockout-ot is vizsgálja.
     *
     * @return true ha sikeres, false egyébként (a hívó hozzáadja a lockoutot)
     */
    @Transactional
    public boolean verifyPin(Long workerId, String pin, String clientIp, String userAgent) {
        Worker worker = workerRepository.findById(workerId)
                .orElseThrow(() -> new ResourceNotFoundException("Worker nem található: " + workerId));

        if (worker.getSupervisorPin() == null) {
            throw new ValidationException("Ehhez a workerhez nincs supervisor PIN beállítva");
        }

        // Lockout check
        LocalDateTime lockoutWindowStart = LocalDateTime.now().minusMinutes(LOCKOUT_WINDOW_MINUTES);
        long recentFailures = attemptRepository
                .countByWorkerIdAndSuccessFalseAndAttemptAtAfter(workerId, lockoutWindowStart);
        if (recentFailures >= MAX_FAILED_ATTEMPTS) {
            log.warn("[supervisor-pin] LOCKOUT worker={} ({} hibás próbálkozás {} percen belül)",
                    workerId, recentFailures, LOCKOUT_WINDOW_MINUTES);
            // Lockout audit (sikertelen, lockout miatt)
            recordAttempt(worker, false, clientIp, userAgent);
            throw new ValidationException("Túl sok hibás próbálkozás — várjon "
                    + LOCKOUT_WINDOW_MINUTES + " percet");
        }

        boolean ok = passwordEncoder.matches(pin, worker.getSupervisorPin());
        recordAttempt(worker, ok, clientIp, userAgent);

        if (ok) {
            worker.setSupervisorPinLastUsedAt(LocalDateTime.now());
            workerRepository.save(worker);
            log.info("[supervisor-pin] VERIFY OK worker={} (workerCode={})", workerId, worker.getCode());
        } else {
            log.warn("[supervisor-pin] VERIFY FAIL worker={} (workerCode={})", workerId, worker.getCode());
        }
        return ok;
    }

    /**
     * Saját PIN törlés (csak a worker maga).
     */
    @Transactional
    public void clearOwnPin(String currentPassword) {
        Long workerId = SecurityUtils.getCurrentWorkerId();
        if (workerId == null) throw new ValidationException("Nincs bejelentkezett munkavállaló");
        Worker worker = workerRepository.findById(workerId)
                .orElseThrow(() -> new ResourceNotFoundException("Worker nem található"));

        if (worker.getPasswordHash() == null
                || !passwordEncoder.matches(currentPassword, worker.getPasswordHash())) {
            throw new ValidationException("Hibás jelszó — PIN törlés megtagadva");
        }

        worker.setSupervisorPin(null);
        worker.setSupervisorPinChangedAt(LocalDateTime.now());
        workerRepository.save(worker);
        log.info("[supervisor-pin] CLEARED worker={}", workerId);
    }

    private void recordAttempt(Worker worker, boolean success, String clientIp, String userAgent) {
        SupervisorPinAttempt attempt = SupervisorPinAttempt.builder()
                .worker(worker)
                .success(success)
                .clientIp(clientIp)
                .userAgent(safeTruncate(userAgent, 300))
                .attemptAt(LocalDateTime.now())
                .build();
        attemptRepository.save(attempt);
    }

    private static String safeTruncate(String s, int max) {
        if (s == null) return null;
        return s.length() <= max ? s : s.substring(0, max);
    }
}
