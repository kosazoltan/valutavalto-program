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
import hu.puzzleir.valuta.repository.ClosingWizardRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

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
