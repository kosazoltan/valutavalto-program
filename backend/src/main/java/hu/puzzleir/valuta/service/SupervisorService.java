package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.dto.supervisor.SystemParamDto;
import hu.puzzleir.valuta.entity.ExchangeRate;
import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.repository.ExchangeRateRepository;
import hu.puzzleir.valuta.repository.SystemParameterRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.env.Environment;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Supervisor mód — felülbírálások, autentikáció, rendszerparaméterek.
 * Minden felülbírálat audit_log-ba kerül!
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class SupervisorService {

    private final SystemParameterRepository systemParameterRepository;
    private final TransactionRepository transactionRepository;
    private final ExchangeRateRepository exchangeRateRepository;
    private final AuditLogService auditLogService;
    private final PasswordEncoder passwordEncoder;
    private final Environment environment;

    @Value("${app.supervisor.password-hash}")
    private String supervisorPasswordHash;

    @PostConstruct
    void validateSupervisorHash() {
        boolean isProduction = java.util.Arrays.asList(environment.getActiveProfiles())
                .contains("production");
        if (isProduction && (supervisorPasswordHash == null
                || supervisorPasswordHash.isBlank()
                || supervisorPasswordHash.startsWith("CHANGE-ME")
                || !supervisorPasswordHash.startsWith("$2"))) {
            throw new IllegalStateException(
                    "FATAL: app.supervisor.password-hash nincs konfigurálva vagy nem BCrypt hash! "
                            + "Állítsd be az APP_SUPERVISOR_PASSWORD_HASH env változót (BCrypt hash).");
        }
        if (!isProduction && (supervisorPasswordHash == null || supervisorPasswordHash.isBlank())) {
            log.warn("app.supervisor.password-hash nincs beállítva — supervisor jelszavas auth letiltva (fail-closed)");
        }
    }

    /**
     * Supervisor jelszó ellenőrzés.
     */
    public boolean authenticate(String rawPassword) {
        if (supervisorPasswordHash == null || supervisorPasswordHash.isBlank()) {
            return false; // fail-closed: nincs konfigurált hash → soha nincs egyezés
        }
        return passwordEncoder.matches(rawPassword, supervisorPasswordHash);
    }

    /**
     * Rendszer paraméterek lekérdezés (readonly).
     */
    @Transactional(readOnly = true)
    public List<SystemParamDto> getSystemParams() {
        return systemParameterRepository.findAllVisibleTo(SecurityUtils.getCurrentCompanyIdOrNull()).stream()
                .map(SystemParamDto::from)
                .collect(Collectors.toList());
    }

    /**
     * Árfolyam kézi felülbírálat.
     * AUDIT: minden felülbírálat naplózva!
     */
    @Transactional(rollbackFor = Exception.class)
    public void overrideRate(UUID branchId, String currency, BigDecimal newBuyRate,
                             BigDecimal newSellRate, String reason) {
        if (!SecurityUtils.isSupervisorOrAbove()) {
            throw new ValidationException("Nincs supervisor jogosultság!");
        }

        UUID companyId = SecurityUtils.getCurrentCompanyId();
        // Find the active rate for this currency and branch, then update it
        List<ExchangeRate> rates = exchangeRateRepository.findActiveByDateAndBranch(
                companyId, java.time.LocalDate.now(), branchId);
        ExchangeRate rate = rates.stream()
                .filter(r -> r.getCurrency().getCode().equals(currency))
                .findFirst()
                .orElseThrow(() -> new ValidationException(
                        "Nincs aktív árfolyam ehhez a valutához: " + currency));

        BigDecimal oldBuyRate = rate.getBaseBuyRate();
        BigDecimal oldSellRate = rate.getBaseSellRate();
        rate.setBaseBuyRate(newBuyRate);
        rate.setBaseSellRate(newSellRate);
        exchangeRateRepository.save(rate);

        String userId = String.valueOf(SecurityUtils.getCurrentWorkerId());
        String workerCode = SecurityUtils.getCurrentWorkerCode();

        auditLogService.log(
                "RATE_OVERRIDE",
                "EXCHANGE_RATE",
                currency,
                userId,
                workerCode,
                branchId.toString(),
                null,
                String.format("currency=%s, oldBuy=%s, newBuy=%s, oldSell=%s, newSell=%s, reason=%s",
                        currency, oldBuyRate, newBuyRate, oldSellRate, newSellRate, reason),
                null,
                null
        );

        log.info("[Supervisor] Árfolyam felülbírálat: {} buy={}→{} sell={}→{} branch={} reason={}",
                currency, oldBuyRate, newBuyRate, oldSellRate, newSellRate, branchId, reason);
    }

    /**
     * Kezelési díj felülbírálat.
     * AUDIT: naplózva!
     */
    @Transactional(rollbackFor = Exception.class)
    public void overrideFee(Long transactionId, BigDecimal newFee, String reason) {
        if (!SecurityUtils.isSupervisorOrAbove()) {
            throw new ValidationException("Nincs supervisor jogosultság!");
        }

        Transaction tx = transactionRepository.findById(transactionId)
                .orElseThrow(() -> new ValidationException("Tranzakció nem található: " + transactionId));

        BigDecimal oldFee = tx.getHandlingFee();
        tx.setHandlingFee(newFee);
        transactionRepository.save(tx);

        String userId = String.valueOf(SecurityUtils.getCurrentWorkerId());
        String workerCode = SecurityUtils.getCurrentWorkerCode();

        auditLogService.log(
                "FEE_OVERRIDE",
                "TRANSACTION",
                String.valueOf(transactionId),
                userId,
                workerCode,
                null,
                null,
                String.format("oldFee=%s, newFee=%s, reason=%s", oldFee, newFee, reason),
                null,
                null
        );

        log.info("[Supervisor] Díj felülbírálat: tx={} oldFee={} newFee={} reason={}",
                transactionId, oldFee, newFee, reason);
    }
}
