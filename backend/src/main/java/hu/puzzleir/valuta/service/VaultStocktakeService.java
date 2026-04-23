package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.*;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class VaultStocktakeService {

    private final VaultStocktakeSessionRepository sessionRepo;
    private final VaultStocktakeItemRepository itemRepo;
    private final CompanyRepository companyRepo;
    private final BranchRepository branchRepo;
    private final VaultTerritoryRepository vaultTerritoryRepository;
    private final BanknoteInventoryService banknoteInventoryService;
    private final AuditLogService auditLogService;

    public VaultStocktakeSession createSession(UUID branchId, Integer territoryId, String sessionName, String note) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        String startedBy = SecurityUtils.getCurrentWorkerCode();

        Company company = companyRepo.findById(companyId)
                .orElseThrow(() -> new ResourceNotFoundException("Ceg nem talalhato"));

        Branch branch = null;
        if (branchId != null) {
            branch = branchRepo.findById(branchId)
                    .orElseThrow(() -> new ResourceNotFoundException("Branch nem talalhato: " + branchId));
            if (!branch.getCompany().getId().equals(companyId)) {
                throw new ValidationException("Cross-tenant tiltott");
            }
        }

        // Sourcery PR #128 fix (P1 bug_risk): territoryId resolve + tenant check
        VaultTerritory territory = null;
        if (territoryId != null) {
            territory = vaultTerritoryRepository.findById(territoryId)
                    .orElseThrow(() -> new ResourceNotFoundException("Ertektari terulet nem talalhato: " + territoryId));
            if (territory.getCompany() == null || !territory.getCompany().getId().equals(companyId)) {
                throw new ValidationException("Cross-tenant tiltott: ertektari terulet mas ceghez tartozik");
            }
        }

        VaultStocktakeSession session = VaultStocktakeSession.builder()
                .company(company)
                .branch(branch)
                .territory(territory)
                .sessionName(sessionName)
                .note(note)
                .status(VaultStocktakeSession.Status.OPEN)
                .startedAt(LocalDateTime.now())
                .startedBy(startedBy)
                .build();

        if (branchId != null) {
            List<BanknoteInventory> inventories = banknoteInventoryService.getByBranch(branchId);
            for (BanknoteInventory inv : inventories) {
                VaultStocktakeItem item = VaultStocktakeItem.builder()
                        .session(session)
                        .currencyId(inv.getCurrencyId())
                        .currencyCode(inv.getCurrencyCode())
                        .faceValue(inv.getFaceValue())
                        .expectedQuantity(inv.getQuantity())
                        .actualQuantity(null)
                        .build();
                session.getItems().add(item);
            }
        }

        VaultStocktakeSession saved = sessionRepo.save(session);
        auditLogService.log("VAULT_STOCKTAKE_CREATED",
                "Leltar letrehozva: " + sessionName + ", branch=" + branchId + ", items=" + session.getItems().size(),
                saved.getId().toString());

        log.info("Vault stocktake letrehozva: id={}, branch={}, items={}",
                saved.getId(), branchId, session.getItems().size());
        return saved;
    }

    public VaultStocktakeItem setItemActual(UUID itemId, Integer actualQuantity, String note) {
        VaultStocktakeItem item = itemRepo.findById(itemId)
                .orElseThrow(() -> new ResourceNotFoundException("Leltar tetel nem talalhato: " + itemId));

        VaultStocktakeSession session = item.getSession();
        if (session.getStatus() != VaultStocktakeSession.Status.OPEN
                && session.getStatus() != VaultStocktakeSession.Status.IN_PROGRESS) {
            throw new ValidationException("Felvetel csak OPEN vagy IN_PROGRESS statuszu sessionre. Aktualis: " + session.getStatus());
        }

        UUID companyId = SecurityUtils.getCurrentCompanyId();
        if (!session.getCompany().getId().equals(companyId)) {
            throw new ValidationException("Cross-tenant tiltott");
        }

        if (actualQuantity == null || actualQuantity < 0) {
            throw new ValidationException("actualQuantity negativ vagy null");
        }

        item.setActualQuantity(actualQuantity);
        item.setCountedAt(LocalDateTime.now());
        item.setCountedBy(SecurityUtils.getCurrentWorkerCode());
        if (note != null) item.setNote(note);

        if (session.getStatus() == VaultStocktakeSession.Status.OPEN) {
            session.setStatus(VaultStocktakeSession.Status.IN_PROGRESS);
            sessionRepo.save(session);
        }

        VaultStocktakeItem saved = itemRepo.save(item);
        log.info("Stocktake item felveve: id={}, expected={}, actual={}",
                saved.getId(), saved.getExpectedQuantity(), actualQuantity);
        return saved;
    }

    public VaultStocktakeSession moveToReview(UUID sessionId) {
        VaultStocktakeSession session = sessionRepo.findByIdWithItems(sessionId)
                .orElseThrow(() -> new ResourceNotFoundException("Session nem talalhato: " + sessionId));
        checkTenantAccess(session);

        if (session.getStatus() != VaultStocktakeSession.Status.IN_PROGRESS
                && session.getStatus() != VaultStocktakeSession.Status.OPEN) {
            throw new ValidationException("REVIEW-ba csak IN_PROGRESS vagy OPEN sessionbol. Aktualis: " + session.getStatus());
        }

        for (VaultStocktakeItem item : session.getItems()) {
            if (item.getActualQuantity() == null) {
                throw new ValidationException(
                        "Hianyzo tetel: " + item.getCurrencyCode()
                                + " cimlet=" + item.getFaceValue() + " - actualQuantity hianyzik");
            }
        }

        session.setStatus(VaultStocktakeSession.Status.REVIEW);
        session.setReviewedBy(SecurityUtils.getCurrentWorkerCode());
        VaultStocktakeSession saved = sessionRepo.save(session);

        auditLogService.log("VAULT_STOCKTAKE_REVIEW",
                "Leltar REVIEW fazisba: " + saved.getSessionName(),
                saved.getId().toString());
        return saved;
    }

    public VaultStocktakeSession closeSession(UUID sessionId) {
        String role = SecurityUtils.getCurrentRole();
        boolean allowed = role != null && (role.equals("FOERTEKTAR") || role.equals("UGYVEZETO") || role.equals("ADMIN") || role.equals("MANAGER"));
        if (!allowed) {
            throw new ValidationException("Leltar lezarasahoz FOERTEKTAR/UGYVEZETO/ADMIN/MANAGER jog kell");
        }

        VaultStocktakeSession session = sessionRepo.findByIdWithItems(sessionId)
                .orElseThrow(() -> new ResourceNotFoundException("Session nem talalhato: " + sessionId));
        checkTenantAccess(session);

        if (session.getStatus() != VaultStocktakeSession.Status.REVIEW) {
            throw new ValidationException("Lezaras csak REVIEW fazisbol. Aktualis: " + session.getStatus());
        }

        BigDecimal totalDiscrepancy = session.getItems().stream()
                .map(i -> i.getDiscrepancyValue() != null ? i.getDiscrepancyValue() : BigDecimal.ZERO)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        session.setDiscrepancyTotalHuf(totalDiscrepancy);
        session.setStatus(VaultStocktakeSession.Status.CLOSED);
        session.setCompletedAt(LocalDateTime.now());
        session.setApprovedBy(SecurityUtils.getCurrentWorkerCode());

        VaultStocktakeSession saved = sessionRepo.save(session);

        auditLogService.log("VAULT_STOCKTAKE_CLOSED",
                String.format("Leltar lezarva: %s, ossz.elteres=%s",
                        saved.getSessionName(), totalDiscrepancy),
                saved.getId().toString());

        log.info("Vault stocktake lezarva: id={}, discrepancy={}", saved.getId(), totalDiscrepancy);
        return saved;
    }

    public VaultStocktakeSession cancelSession(UUID sessionId, String reason) {
        VaultStocktakeSession session = sessionRepo.findById(sessionId)
                .orElseThrow(() -> new ResourceNotFoundException("Session nem talalhato: " + sessionId));
        checkTenantAccess(session);

        if (session.getStatus() == VaultStocktakeSession.Status.CLOSED) {
            throw new ValidationException("Lezart sessiont nem lehet megszakitani");
        }

        session.setStatus(VaultStocktakeSession.Status.CANCELLED);
        session.setCompletedAt(LocalDateTime.now());
        if (reason != null) {
            String prefix = session.getNote() != null ? session.getNote() + "\n" : "";
            session.setNote(prefix + "CANCELLED: " + reason);
        }

        VaultStocktakeSession saved = sessionRepo.save(session);
        auditLogService.log("VAULT_STOCKTAKE_CANCELLED",
                "Leltar megszakitva: " + saved.getSessionName() + ", indok: " + reason,
                saved.getId().toString());
        return saved;
    }

    @Transactional(readOnly = true)
    public List<VaultStocktakeSession> listSessions() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return sessionRepo.findByCompanyIdOrderByStartedAtDesc(companyId);
    }

    @Transactional(readOnly = true)
    public VaultStocktakeSession getSession(UUID sessionId) {
        VaultStocktakeSession session = sessionRepo.findByIdWithItems(sessionId)
                .orElseThrow(() -> new ResourceNotFoundException("Session nem talalhato: " + sessionId));
        checkTenantAccess(session);
        return session;
    }

    @Transactional(readOnly = true)
    public StocktakeSummary getSummary(UUID sessionId) {
        VaultStocktakeSession session = getSession(sessionId);

        int totalItems = session.getItems().size();
        int countedItems = (int) session.getItems().stream().filter(i -> i.getActualQuantity() != null).count();
        int discrepancyItems = (int) session.getItems().stream()
                .filter(i -> i.getDiscrepancy() != null && i.getDiscrepancy() != 0).count();

        BigDecimal totalDiscrepancy = session.getItems().stream()
                .map(i -> i.getDiscrepancyValue() != null ? i.getDiscrepancyValue() : BigDecimal.ZERO)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        List<VaultStocktakeItem> discrepancies = new ArrayList<>(session.getItems().stream()
                .filter(i -> i.getDiscrepancy() != null && i.getDiscrepancy() != 0)
                .toList());

        return StocktakeSummary.builder()
                .sessionId(sessionId)
                .sessionName(session.getSessionName())
                .status(session.getStatus().name())
                .totalItems(totalItems)
                .countedItems(countedItems)
                .discrepancyItems(discrepancyItems)
                .totalDiscrepancyHuf(totalDiscrepancy)
                .discrepancies(discrepancies)
                .build();
    }

    private void checkTenantAccess(VaultStocktakeSession session) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        if (!session.getCompany().getId().equals(companyId)) {
            throw new ValidationException("Cross-tenant tiltott");
        }
    }

    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class StocktakeSummary {
        private UUID sessionId;
        private String sessionName;
        private String status;
        private int totalItems;
        private int countedItems;
        private int discrepancyItems;
        private BigDecimal totalDiscrepancyHuf;
        private List<VaultStocktakeItem> discrepancies;
    }
}