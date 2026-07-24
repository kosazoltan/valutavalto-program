package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.ClosingControlDto;
import hu.puzzleir.valuta.dto.ClosingMarkType;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.ClosingControl;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.ClosingControlRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional(rollbackFor = Exception.class)
public class ClosingControlService {

    private final ClosingControlRepository closingControlRepository;
    private final BranchRepository branchRepository;
    private final NotificationService notificationService;
    private final AuditLogService auditLogService;

    /**
     * Összes iroda zárási állapota egy adott napon
     */
    @Transactional(readOnly = true)
    public List<ClosingControlDto> checkAllBranches(LocalDate date) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        log.info("Zárás kontroll — összes aktív iroda lekérése: company={}, date={}", companyId, date);

        Map<UUID, ClosingControl> controlsByBranch = closingControlRepository
                .findByCompanyIdAndControlDate(companyId, date)
                .stream()
                .collect(Collectors.toMap(ClosingControl::getBranchId, control -> control, (left, right) -> left));

        // FK-014 (2026-06-01): a Zárás beérkezés CSAK napi zárást végző valódi irodákat mutat
        // (65 pénztár + 8 értéktár) — a VAULT_COUNTERPARTY banki/speciális partnerek kizárva.
        // Backend-szűrés, így a meglévő (telepítő-frissítés nélküli) kliensek is azonnal tisztulnak.
        return branchRepository.findByCompanyIdAndIsActiveTrueExcludingCounterparties(companyId)
                .stream()
                .sorted(Comparator.comparing(Branch::getCode, Comparator.nullsLast(String::compareToIgnoreCase)))
                .map(branch -> toDto(controlsByBranch.get(branch.getId()), branch, date))
                .collect(Collectors.toList());
    }

    /**
     * Egy adott iroda zárási állapota
     */
    @Transactional(readOnly = true)
    public ClosingControlDto getBranchStatus(UUID branchId, LocalDate date) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        Branch branch = requireBranchInCurrentCompany(branchId, companyId);
        ClosingControl control = closingControlRepository
                .findByCompanyIdAndBranchIdAndControlDate(companyId, branchId, date)
                .orElse(null);
        return toDto(control, branch, date);
    }

    /**
     * Figyelmeztető üzenet küldése egy irodának
     */
    public void sendAlert(UUID branchId, String message) {
        log.warn("ZÁRÁS FIGYELMEZTETÉS — branch: {}, üzenet: {}", branchId, message);

        UUID companyId = SecurityUtils.getCurrentCompanyId();
        requireBranchInCurrentCompany(branchId, companyId);
        LocalDate today = LocalDate.now();
        ClosingControl control = closingControlRepository.findByCompanyIdAndBranchIdAndControlDate(companyId, branchId, today)
                .orElseGet(() -> {
                    ClosingControl newControl = ClosingControl.builder()
                            .branchId(branchId)
                            .companyId(companyId)
                            .controlDate(today)
                            .dailyClosingDone(false)
                            .eveningClosingDone(false)
                            .navClosingDone(false)
                            .alertLevel("WARNING")
                            .notes(message)
                            .build();
                    return closingControlRepository.save(newControl);
                });

        control.setAlertLevel("WARNING");
        control.setNotes(message);
        closingControlRepository.save(control);

        // Értesítés küldése az iroda összes dolgozójának (P0-8 fix)
        try {
            notificationService.sendToBranch(branchId,
                    "Zárási figyelmeztetés",
                    message);
        } catch (Exception e) {
            log.warn("Értesítés küldése sikertelen: branch={}, error={}", branchId, e.getMessage());
        }
        log.info("Figyelmeztetés rögzítve és értesítés küldve: branch={}", branchId);
    }

    /**
     * Backend jelzés arról, hogy egy iroda adott napi zárása beérkezett.
     */
    public ClosingControlDto markClosingDone(UUID companyId, UUID branchId, LocalDate date, ClosingMarkType type) {
        Branch branch = requireBranchInCompany(branchId, companyId, true);
        ClosingControl control = closingControlRepository.findByCompanyIdAndBranchIdAndControlDate(companyId, branchId, date)
                .orElseGet(() -> closingControlRepository.save(ClosingControl.builder()
                        .branchId(branchId)
                        .companyId(companyId)
                        .controlDate(date)
                        .dailyClosingDone(false)
                        .eveningClosingDone(false)
                        .navClosingDone(false)
                        .alertLevel("WARNING")
                        .build()));

        if (type == ClosingMarkType.DAILY) {
            control.setDailyClosingDone(true);
        } else if (type == ClosingMarkType.EVENING) {
            control.setEveningClosingDone(true);
        } else {
            throw new ValidationException("Ismeretlen zárás típus: " + type);
        }
        control.setAlertLevel(resolveAlertLevel(control, branch, date));
        ClosingControl saved = closingControlRepository.save(control);

        String action = type == ClosingMarkType.DAILY ? "CLOSING_RECEIVED_DAILY" : "CLOSING_RECEIVED_EVENING";
        Long workerId = currentWorkerIdOrNull();
        auditLogService.log(action,
                "ClosingControl",
                saved.getId() != null ? saved.getId().toString() : null,
                workerId != null ? workerId.toString() : null,
                null,
                branchId.toString(),
                branch.getName(),
                "{\"date\":\"" + date + "\",\"type\":\"" + type + "\"}",
                null,
                null);
        return toDto(saved, branch, date);
    }

    // --- Helper ---

    private ClosingControlDto toDto(ClosingControl entity, Branch branch, LocalDate date) {
        boolean missingRecord = entity == null;
        boolean dailyDone = entity != null && Boolean.TRUE.equals(entity.getDailyClosingDone());
        boolean eveningDone = entity != null && Boolean.TRUE.equals(entity.getEveningClosingDone());
        boolean navDone = entity != null && Boolean.TRUE.equals(entity.getNavClosingDone());
        boolean requiredDone = isRequiredClosingDone(branch, dailyDone, eveningDone);
        int completed = requiredDone ? 1 : 0;
        int required = 1;

        return ClosingControlDto.builder()
                .id(entity != null ? entity.getId() : null)
                .branchId(branch.getId())
                .branchCode(branch.getCode())
                .branchName(branch.getName())
                .branchCity(branch.getCity())
                .controlDate(entity != null ? entity.getControlDate() : date)
                .dailyClosingDone(dailyDone)
                .eveningClosingDone(eveningDone)
                .navClosingDone(navDone)
                .lastTransactionAt(entity != null ? entity.getLastTransactionAt() : null)
                .alertLevel(resolveAlertLevel(entity, branch, date))
                .notes(entity != null ? entity.getNotes() : null)
                .completedCount(completed)
                .requiredCount(required)
                .missingRecord(missingRecord)
                .build();
    }

    private Branch requireBranchInCurrentCompany(UUID branchId, UUID companyId) {
        return requireBranchInCompany(branchId, companyId, false);
    }

    private Branch requireBranchInCompany(UUID branchId, UUID companyId, boolean auditTenantViolation) {
        Branch branch = branchRepository.findById(branchId)
                .orElseThrow(() -> new ResourceNotFoundException("Iroda nem található: " + branchId));
        if (branch.getCompany() == null || !companyId.equals(branch.getCompany().getId())) {
            if (auditTenantViolation) {
                Long workerId = currentWorkerIdOrNull();
                auditLogService.log("VV-TENANT-001",
                        "ClosingControl",
                        branchId.toString(),
                        workerId != null ? workerId.toString() : null,
                        null,
                        null,
                        null,
                        "Idegen tenant zárásjelzés kísérlet",
                        null,
                        null);
            }
            throw new ResourceNotFoundException("Iroda nem található: " + branchId);
        }
        if (!Boolean.TRUE.equals(branch.getIsActive())) {
            throw new ValidationException("Inaktív irodának nem küldhető zárási figyelmeztetés: " + branchId);
        }
        return branch;
    }

    private Long currentWorkerIdOrNull() {
        try {
            return SecurityUtils.getCurrentWorkerId();
        } catch (Exception e) {
            return null;
        }
    }

    private String resolveAlertLevel(ClosingControl entity, Branch branch, LocalDate date) {
        boolean dailyDone = entity != null && Boolean.TRUE.equals(entity.getDailyClosingDone());
        boolean eveningDone = entity != null && Boolean.TRUE.equals(entity.getEveningClosingDone());
        if (isRequiredClosingDone(branch, dailyDone, eveningDone)) {
            return "NONE";
        }
        if (entity != null && entity.getAlertLevel() != null && !"NONE".equalsIgnoreCase(entity.getAlertLevel())) {
            return entity.getAlertLevel();
        }
        if (date.isBefore(LocalDate.now())) {
            return "CRITICAL";
        }
        return "WARNING";
    }

    private boolean isRequiredClosingDone(Branch branch, boolean dailyDone, boolean eveningDone) {
        // FK-062: minden branch-típusnál (vault és nem-vault) kizárólag a napi zárás
        // (DAILY) jelzője számít "Rendben"-nek. A korábbi vault-ág az EVENING jelzőt
        // várta, amit a zárási varázsló sosem ír — ezért minden értéktári zárás tévesen
        // "Zárás nem érkezett be"-ként jelent meg. Az eveningDone paraméter szándékosan
        // megmarad a szignatúrában (hívási helyek változatlanok), de már nem befolyásol.
        return dailyDone;
    }
}
