package hu.puzzleir.valuta.service;

import com.puzzleir.backend.entity.Branch;
import com.puzzleir.backend.exception.ResourceNotFoundException;
import com.puzzleir.backend.exception.ValidationException;
import com.puzzleir.backend.repository.BranchRepository;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import hu.puzzleir.valuta.dto.closingwizard.ClosingWizardDto;
import hu.puzzleir.valuta.dto.closingwizard.ClosingWizardStepDto;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.repository.CashBalanceRepository;
import hu.puzzleir.valuta.repository.ClosingWizardRepository;
import hu.puzzleir.valuta.repository.DailySessionRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

/**
 * Zárási varázsló szolgáltatás.
 */
@Service
@RequiredArgsConstructor
@Transactional
@Slf4j
public class ClosingWizardService {

    private final ClosingWizardRepository closingWizardRepository;
    private final WorkerRepository workerRepository;
    private final BranchRepository branchRepository;
    private final CashBalanceRepository cashBalanceRepository;
    private final DailySessionRepository dailySessionRepository;
    private final ObjectMapper objectMapper;

    /**
     * Zárási varázsló indítása
     */
    public ClosingWizardDto startWizard(UUID branchId, UUID cashDeskId, String closingTypeStr, Long workerId) {
        Branch branch = branchRepository.findById(branchId)
                .orElseThrow(() -> new ResourceNotFoundException("Iroda nem található: " + branchId));

        Worker worker = workerRepository.findById(workerId)
                .orElseThrow(() -> new ResourceNotFoundException("Pénztáros nem található: " + workerId));

        // Ellenőrzés: nincs-e már aktív varázsló
        List<ClosingWizard> activeWizards = closingWizardRepository.findByBranchIdAndStatus(branchId, WizardStatus.IN_PROGRESS);
        if (!activeWizards.isEmpty()) {
            throw new ValidationException("Már van aktív zárási varázsló ehhez az irodához!");
        }

        ClosingType closingType = ClosingType.valueOf(closingTypeStr);
        int totalSteps = getStepCount(closingType);

        ClosingWizard wizard = ClosingWizard.builder()
                .branch(branch)
                .cashDeskId(cashDeskId)
                .closingDate(LocalDate.now())
                .closingType(closingType)
                .currentStep(1)
                .totalSteps(totalSteps)
                .wizardStatus(WizardStatus.IN_PROGRESS)
                .startedByWorker(worker)
                .startedAt(LocalDateTime.now())
                .build();

        // Lépések inicializálása
        List<ClosingWizardStep> steps = createStepsForType(closingType, wizard);
        wizard.setSteps(steps);

        ClosingWizard saved = closingWizardRepository.save(wizard);
        log.info("Zárási varázsló indítva: id={}, típus={}, iroda={}", saved.getId(), closingType, branchId);

        return toDto(saved);
    }

    /**
     * Varázsló lekérése
     */
    @Transactional(readOnly = true)
    public ClosingWizardDto getWizard(UUID wizardId) {
        ClosingWizard wizard = closingWizardRepository.findByIdWithSteps(wizardId)
                .orElseThrow(() -> new ResourceNotFoundException("Varázsló nem található: " + wizardId));
        return toDto(wizard);
    }

    /**
     * Adott lépés lekérése
     */
    @Transactional(readOnly = true)
    public ClosingWizardStepDto getStep(UUID wizardId, int stepNumber) {
        ClosingWizard wizard = closingWizardRepository.findByIdWithSteps(wizardId)
                .orElseThrow(() -> new ResourceNotFoundException("Varázsló nem található: " + wizardId));

        return wizard.getSteps().stream()
                .filter(s -> s.getStepNumber().equals(stepNumber))
                .findFirst()
                .map(this::toStepDto)
                .orElseThrow(() -> new ResourceNotFoundException("Lépés nem található: " + stepNumber));
    }

    /**
     * Navigáció adott lépésre
     */
    public ClosingWizardDto navigate(UUID wizardId, int targetStep) {
        ClosingWizard wizard = closingWizardRepository.findByIdWithSteps(wizardId)
                .orElseThrow(() -> new ResourceNotFoundException("Varázsló nem található: " + wizardId));

        if (wizard.getWizardStatus() != WizardStatus.IN_PROGRESS) {
            throw new ValidationException("Ez a varázsló már nem aktív!");
        }

        if (targetStep < 1 || targetStep > wizard.getTotalSteps()) {
            throw new ValidationException("Érvénytelen lépés szám: " + targetStep);
        }

        wizard.setCurrentStep(targetStep);
        ClosingWizard saved = closingWizardRepository.save(wizard);

        return toDto(saved);
    }

    /**
     * Varázsló befejezése
     */
    public ClosingWizardDto complete(UUID wizardId, Long workerId) {
        ClosingWizard wizard = closingWizardRepository.findByIdWithSteps(wizardId)
                .orElseThrow(() -> new ResourceNotFoundException("Varázsló nem található: " + wizardId));

        if (wizard.getWizardStatus() != WizardStatus.IN_PROGRESS) {
            throw new ValidationException("Ez a varázsló már nem aktív!");
        }

        Worker worker = workerRepository.findById(workerId)
                .orElseThrow(() -> new ResourceNotFoundException("Pénztáros nem található: " + workerId));

        // Minden lépés teljesítve jelölése
        wizard.getSteps().forEach(step -> step.setCompleted(true));

        wizard.setWizardStatus(WizardStatus.COMPLETED);
        wizard.setCompletedByWorker(worker);
        wizard.setCompletedAt(LocalDateTime.now());

        ClosingWizard saved = closingWizardRepository.save(wizard);
        log.info("Zárási varázsló befejezve: id={}", wizardId);

        return toDto(saved);
    }

    /**
     * Varázsló megszakítása
     */
    public ClosingWizardDto cancel(UUID wizardId) {
        ClosingWizard wizard = closingWizardRepository.findByIdWithSteps(wizardId)
                .orElseThrow(() -> new ResourceNotFoundException("Varázsló nem található: " + wizardId));

        if (wizard.getWizardStatus() != WizardStatus.IN_PROGRESS) {
            throw new ValidationException("Ez a varázsló már nem aktív!");
        }

        wizard.setWizardStatus(WizardStatus.CANCELLED);
        ClosingWizard saved = closingWizardRepository.save(wizard);
        log.info("Zárási varázsló megszakítva: id={}", wizardId);

        return toDto(saved);
    }

    // ============ STEP-SPECIFIC METHODS ============

    /**
     * Step 1: Nyitott tranzakciók validálása.
     * Visszaadja a befejezetlen tranzakciók listáját.
     */
    @Transactional(readOnly = true)
    public List<String> validateOpenTransactions(UUID branchId) {
        List<String> errors = new ArrayList<>();

        // Ellenőrzés: van-e nyitott session
        if (!dailySessionRepository.hasOpenSession(branchId)) {
            errors.add("Nincs nyitott napi munkamenet!");
            return errors;
        }

        // Aktuális session lekérése
        DailySession currentSession = dailySessionRepository.findLatest(branchId)
                .orElse(null);
        if (currentSession != null && currentSession.getStatus() == DailySessionStatus.PENDING_CLOSE) {
            errors.add("A nap zárás alatt van, várjon a folyamat befejezésére!");
        }

        // TODO(integration): Tranzakció repository ellenőrzés (ha van PENDING státuszú tranzakció)
        // A valós implementációban a TransactionRepository.findByBranchIdAndStatus(PENDING) szükséges

        return errors;
    }

    /**
     * Step 2: Címletolvasó — valutánként címletek rögzítése.
     * Visszaadja a számolt összesítést.
     */
    public Map<String, Object> countDenominations(UUID branchId, Map<String, Map<Integer, Integer>> denomCounts) {
        Map<String, Object> result = new LinkedHashMap<>();
        Map<String, BigDecimal> totals = new LinkedHashMap<>();

        for (Map.Entry<String, Map<Integer, Integer>> entry : denomCounts.entrySet()) {
            String currencyCode = entry.getKey();
            Map<Integer, Integer> denoms = entry.getValue();

            BigDecimal total = BigDecimal.ZERO;
            List<Map<String, Object>> denomDetails = new ArrayList<>();

            for (Map.Entry<Integer, Integer> denom : denoms.entrySet()) {
                int value = denom.getKey();
                int count = denom.getValue();
                BigDecimal subtotal = BigDecimal.valueOf(value).multiply(BigDecimal.valueOf(count));
                total = total.add(subtotal);

                denomDetails.add(Map.of(
                        "value", value,
                        "count", count,
                        "subtotal", subtotal
                ));
            }

            totals.put(currencyCode, total);
            result.put(currencyCode, Map.of("denominations", denomDetails, "total", total));
        }

        result.put("totals", totals);
        return result;
    }

    /**
     * Step 3: Eltérés számítás — nyilvántartás vs fizikai készlet.
     */
    @Transactional(readOnly = true)
    public List<Map<String, Object>> calculateDifferences(UUID branchId, Map<String, BigDecimal> physicalCounts) {
        List<CashBalance> balances = cashBalanceRepository.findByBranchId(branchId);
        List<Map<String, Object>> differences = new ArrayList<>();

        for (CashBalance cb : balances) {
            String code = cb.getCurrency().getCode();
            BigDecimal expected = cb.getCurrentBalance();
            BigDecimal actual = physicalCounts.getOrDefault(code, BigDecimal.ZERO);
            BigDecimal diff = actual.subtract(expected);

            Map<String, Object> item = new LinkedHashMap<>();
            item.put("currencyCode", code);
            item.put("expected", expected);
            item.put("actual", actual);
            item.put("difference", diff);
            item.put("status", diff.compareTo(BigDecimal.ZERO) == 0 ? "OK" : "DISCREPANCY");

            differences.add(item);
        }

        return differences;
    }

    /**
     * Step 4: Zárási riport generálás.
     */
    @Transactional(readOnly = true)
    public Map<String, Object> generateClosingReport(UUID wizardId) {
        ClosingWizard wizard = closingWizardRepository.findByIdWithSteps(wizardId)
                .orElseThrow(() -> new ResourceNotFoundException("Varázsló nem található: " + wizardId));

        UUID branchId = wizard.getBranch().getId();
        DailySession session = dailySessionRepository.findByBranchIdAndSessionDate(branchId, LocalDate.now())
                .orElse(null);

        Map<String, Object> report = new LinkedHashMap<>();
        report.put("wizardId", wizardId.toString());
        report.put("branchName", wizard.getBranch().getName());
        report.put("closingDate", wizard.getClosingDate().toString());
        report.put("closingType", wizard.getClosingType().name());

        if (session != null) {
            report.put("transactionCount", session.getTransactionCount());
            report.put("buyCount", session.getBuyCount());
            report.put("sellCount", session.getSellCount());
            report.put("reversalCount", session.getReversalCount());
            report.put("buyTurnoverHuf", session.getBuyTurnoverHuf());
            report.put("sellTurnoverHuf", session.getSellTurnoverHuf());
            report.put("handlingFeeTotal", session.getHandlingFeeTotal());
            report.put("openingBalanceHuf", session.getOpeningBalanceHuf());
            report.put("closingBalanceHuf", session.getClosingBalanceHuf() != null
                    ? session.getClosingBalanceHuf() : BigDecimal.ZERO);
        }

        // Készlet állapot
        List<CashBalance> balances = cashBalanceRepository.findByBranchId(branchId);
        List<Map<String, Object>> inventorySnapshot = new ArrayList<>();
        for (CashBalance cb : balances) {
            inventorySnapshot.add(Map.of(
                    "currencyCode", cb.getCurrency().getCode(),
                    "openingBalance", cb.getOpeningBalance(),
                    "currentBalance", cb.getCurrentBalance(),
                    "dailyChange", cb.getDailyChange()
            ));
        }
        report.put("inventory", inventorySnapshot);

        return report;
    }

    /**
     * Step 5: Zárás véglegesítése és session lezárása.
     */
    public boolean finalizeClosing(UUID wizardId, Long workerId) {
        ClosingWizard wizard = closingWizardRepository.findByIdWithSteps(wizardId)
                .orElseThrow(() -> new ResourceNotFoundException("Varázsló nem található: " + wizardId));

        if (wizard.getWizardStatus() != WizardStatus.IN_PROGRESS) {
            throw new ValidationException("Ez a varázsló már nem aktív!");
        }

        Worker worker = workerRepository.findById(workerId)
                .orElseThrow(() -> new ResourceNotFoundException("Pénztáros nem található: " + workerId));

        UUID branchId = wizard.getBranch().getId();

        // Session lezárása
        DailySession session = dailySessionRepository.findByBranchIdAndSessionDate(branchId, LocalDate.now())
                .orElse(null);
        if (session != null && session.isOpen()) {
            BigDecimal closingBalance = cashBalanceRepository.sumCurrentBalanceHuf(branchId);
            session.setStatus(DailySessionStatus.CLOSED);
            session.setClosedByWorker(worker);
            session.setClosedAt(LocalDateTime.now());
            session.setClosingBalanceHuf(closingBalance);
            session.setDenominationVerified(true);
            dailySessionRepository.save(session);
        }

        // Wizard lezárása
        wizard.getSteps().forEach(step -> step.setCompleted(true));
        wizard.setWizardStatus(WizardStatus.COMPLETED);
        wizard.setCompletedByWorker(worker);
        wizard.setCompletedAt(LocalDateTime.now());
        closingWizardRepository.save(wizard);

        log.info("Zárás véglegesítve: wizard={}, session={}", wizardId,
                session != null ? session.getId() : "none");

        return true;
    }

    // ============ HELPER METHODS ============

    private int getStepCount(ClosingType type) {
        return switch (type) {
            case DAILY -> 5;
            case POS -> 3;
            case DECADE -> 6;
            case MONTHLY -> 7;
        };
    }

    private List<ClosingWizardStep> createStepsForType(ClosingType type, ClosingWizard wizard) {
        List<String[]> stepDefinitions = switch (type) {
            case DAILY -> List.of(
                new String[]{"Tranzakció összesítés", "Napi tranzakciók ellenőrzése és összesítése"},
                new String[]{"Készpénz egyeztetés", "Kasszában lévő készpénz egyeztetése a nyilvántartással"},
                new String[]{"Címlet számlálás", "Bankjegyek és érmék tételes számlálása"},
                new String[]{"Bizonylatok ellenőrzése", "Napi bizonylatok teljességének ellenőrzése"},
                new String[]{"Lezárás", "Napi zárás véglegesítése és nyomtatás"}
            );
            case POS -> List.of(
                new String[]{"POS tranzakciók", "POS terminál tranzakcióinak összesítése"},
                new String[]{"Egyeztetés", "POS forgalom egyeztetése a nyilvántartással"},
                new String[]{"Lezárás", "POS zárás véglegesítése"}
            );
            case DECADE -> List.of(
                new String[]{"Időszak összesítés", "Dekádos időszak tranzakcióinak összesítése"},
                new String[]{"Forgalom elemzés", "Forgalmi adatok elemzése és összesítése"},
                new String[]{"Készlet egyeztetés", "Valutakészlet egyeztetése"},
                new String[]{"Címlet ellenőrzés", "Címletek egyeztetése a nyilvántartással"},
                new String[]{"Jelentés generálás", "Dekádos jelentés generálása"},
                new String[]{"Lezárás", "Dekádos zárás véglegesítése"}
            );
            case MONTHLY -> List.of(
                new String[]{"Havi összesítés", "Havi tranzakciók teljes összesítése"},
                new String[]{"Forgalom elemzés", "Havi forgalmi adatok elemzése"},
                new String[]{"Készlet egyeztetés", "Teljes valutakészlet egyeztetése"},
                new String[]{"Címlet ellenőrzés", "Összes címlet egyeztetése"},
                new String[]{"NAV jelentés", "NAV felé adatszolgáltatási kötelezettség"},
                new String[]{"Nyomtatások", "Havi jelentések nyomtatása"},
                new String[]{"Lezárás", "Havi zárás véglegesítése"}
            );
        };

        List<ClosingWizardStep> steps = new ArrayList<>();
        for (int i = 0; i < stepDefinitions.size(); i++) {
            String[] def = stepDefinitions.get(i);
            steps.add(ClosingWizardStep.builder()
                    .wizard(wizard)
                    .stepNumber(i + 1)
                    .stepTitle(def[0])
                    .stepDescription(def[1])
                    .completed(false)
                    .canProceed(true)
                    .stepData("{}")
                    .build());
        }
        return steps;
    }

    private ClosingWizardDto toDto(ClosingWizard entity) {
        return ClosingWizardDto.builder()
                .id(entity.getId().toString())
                .branchId(entity.getBranch().getId().toString())
                .branchName(entity.getBranch().getName())
                .cashDeskId(entity.getCashDeskId() != null ? entity.getCashDeskId().toString() : null)
                .closingDate(entity.getClosingDate().toString())
                .closingType(entity.getClosingType().name())
                .currentStep(entity.getCurrentStep())
                .totalSteps(entity.getTotalSteps())
                .wizardStatus(entity.getWizardStatus().name())
                .startedByWorkerId(String.valueOf(entity.getStartedByWorker().getId()))
                .startedByWorkerName(entity.getStartedByWorker().getName())
                .startedAt(entity.getStartedAt())
                .completedByWorkerId(entity.getCompletedByWorker() != null ? String.valueOf(entity.getCompletedByWorker().getId()) : null)
                .completedByWorkerName(entity.getCompletedByWorker() != null ? entity.getCompletedByWorker().getName() : null)
                .completedAt(entity.getCompletedAt())
                .notes(entity.getNotes())
                .steps(entity.getSteps() != null
                    ? entity.getSteps().stream().map(this::toStepDto).collect(Collectors.toList())
                    : null)
                .build();
    }

    private ClosingWizardStepDto toStepDto(ClosingWizardStep step) {
        Map<String, Object> stepDataMap = new HashMap<>();
        if (step.getStepData() != null && !step.getStepData().isBlank()) {
            try {
                stepDataMap = objectMapper.readValue(step.getStepData(), new TypeReference<>() {});
            } catch (JsonProcessingException e) {
                log.warn("Nem sikerült parse-olni a stepData-t: {}", step.getStepData());
            }
        }

        return ClosingWizardStepDto.builder()
                .stepNumber(step.getStepNumber())
                .stepTitle(step.getStepTitle())
                .stepDescription(step.getStepDescription())
                .completed(step.getCompleted())
                .canProceed(step.getCanProceed())
                .stepData(stepDataMap)
                .build();
    }
}
