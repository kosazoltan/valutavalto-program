package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.CreateRestrictionDto;
import hu.puzzleir.valuta.dto.CustomerRestrictionDto;
import hu.puzzleir.valuta.dto.CustomerScreeningLogDto;
import hu.puzzleir.valuta.entity.CustomerRestriction;
import hu.puzzleir.valuta.entity.CustomerScreeningLog;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.CustomerRestrictionRepository;
import hu.puzzleir.valuta.repository.CustomerScreeningLogRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional(rollbackFor = Exception.class)
public class CustomerControlService {

    private final CustomerRestrictionRepository restrictionRepository;
    private final CustomerScreeningLogRepository screeningLogRepository;
    // b9 FR-03 gyanú-bejelentés (SAR) függőségei
    private final hu.puzzleir.valuta.repository.CustomerRepository customerRepository;
    private final hu.puzzleir.valuta.repository.WorkerRepository workerRepository;
    private final NotificationService notificationService;
    private final AuditLogService auditLogService;
    private final TransactionRepository transactionRepository;

    // 15M HUF/év limit
    private static final BigDecimal ANNUAL_LIMIT_HUF = new BigDecimal("15000000");

    /**
     * Ügyfél korlátozásainak lekérdezése (aktívak)
     */
    @Transactional(readOnly = true)
    public List<CustomerRestrictionDto> getActiveRestrictions(Long customerId) {
        return restrictionRepository.findByCustomerIdAndActiveTrue(customerId)
                .stream()
                .map(this::toRestrictionDto)
                .collect(Collectors.toList());
    }

    /**
     * Ügyfél összes korlátozása (aktív + inaktív)
     */
    @Transactional(readOnly = true)
    public List<CustomerRestrictionDto> getAllRestrictions(Long customerId) {
        return restrictionRepository.findByCustomerId(customerId)
                .stream()
                .map(this::toRestrictionDto)
                .collect(Collectors.toList());
    }

    /**
     * Új korlátozás hozzáadása
     */
    public CustomerRestrictionDto addRestriction(Long customerId, Long workerId,
                                                  CreateRestrictionDto dto) {
        log.info("Új korlátozás - ügyfél: {}, típus: {}", customerId, dto.getRestrictionType());

        CustomerRestriction restriction = CustomerRestriction.builder()
                .customerId(customerId)
                .restrictionType(dto.getRestrictionType())
                .reason(dto.getReason())
                .addedBy(workerId)
                .addedAt(LocalDateTime.now())
                .expiresAt(dto.getExpiresAt())
                .active(true)
                .build();

        CustomerRestriction saved = restrictionRepository.save(restriction);
        log.info("Korlátozás rögzítve: {}", saved.getId());
        return toRestrictionDto(saved);
    }

    /**
     * Korlátozás eltávolítása (soft: active = false)
     */
    public void removeRestriction(UUID restrictionId) {
        CustomerRestriction restriction = restrictionRepository.findById(restrictionId)
                .orElseThrow(() -> new ResourceNotFoundException("Korlátozás nem található: " + restrictionId));

        restriction.setActive(false);
        restrictionRepository.save(restriction);
        log.info("Korlátozás deaktiválva: {}", restrictionId);
    }

    /**
     * Éves tranzakció összeg lekérdezése (HUF).
     *
     * Legacy: BIGCTRL.DLL — éves kumulatív összeg.
     * A TransactionRepository.sumCustomerAnnualTotal() JPQL lekérdezést használja,
     * amely COMPLETED státuszú tranzakciókat összegzi a megadott évre.
     */
    @Transactional(readOnly = true)
    public BigDecimal getAnnualTransactionTotal(Long customerId, int year) {
        log.debug("Éves összeg lekérdezés - ügyfél: {}, év: {}", customerId, year);

        UUID companyId = SecurityUtils.getCurrentCompanyId();
        LocalDate startDate = LocalDate.of(year, 1, 1);
        LocalDate endDate = LocalDate.of(year, 12, 31);

        BigDecimal total = transactionRepository.sumCustomerAnnualTotal(
                companyId,
                String.valueOf(customerId),
                startDate,
                endDate
        );

        log.debug("Éves összeg: ügyfél={}, év={}, összeg={} HUF", customerId, year, total);
        return total != null ? total : BigDecimal.ZERO;
    }

    /**
     * Éves limit ellenőrzés (>15M HUF → figyelmeztetés)
     */
    @Transactional(readOnly = true)
    public boolean checkAnnualLimit(Long customerId) {
        int currentYear = LocalDateTime.now().getYear();
        BigDecimal total = getAnnualTransactionTotal(customerId, currentYear);
        boolean exceeded = total.compareTo(ANNUAL_LIMIT_HUF) > 0;
        if (exceeded) {
            log.warn("Éves limit túllépve! Ügyfél: {}, összeg: {} HUF", customerId, total);
        }
        return exceeded;
    }

    /**
     * EXCMD b9-korlevelek FR-03: pénztárosi gyanú-bejelentés (SAR) rögzítése.
     *
     * <p>A gyanús jelek a {@code customer_screening_log}-ba kerülnek (SUSPICION/FLAGGED,
     * Pmt. szerinti megőrzés), a cég felsővezetői URGENT értesítést kapnak. A pénztáros a
     * folyamatot felfüggeszti (a tranzakciót NEM rögzíti) és telefonon egyeztet a területi
     * vezetővel — a felfüggesztés emberi lépés, a rendszer-oldali nyomot ez a rekord adja.</p>
     *
     * <p>Tenant-guard: ha {@code customerId} érkezik, csak a saját cég ügyfele jelenthető
     * (cross-tenant 404). Ismeretlen/törzsön kívüli ügyfélnél a customerId null, a név kötelező.</p>
     */
    @Transactional(rollbackFor = Exception.class)
    public CustomerScreeningLogDto reportSuspicion(hu.puzzleir.valuta.dto.SuspicionReportRequest request) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        Long workerId = SecurityUtils.getCurrentWorkerId();

        // Review (Sourcery+Copilot): defenzív null/blank-guard — a @NotBlank csak a controller
        // @Valid útján fut; service-szintű hívásnál is kötelező az indok.
        String signs = request.getSuspicionSigns() != null ? request.getSuspicionSigns().trim() : "";
        if (signs.isEmpty()) {
            throw new hu.puzzleir.valuta.exception.ValidationException(
                    "A gyanús jelek leírása kötelező");
        }

        String customerName;
        if (request.getCustomerId() != null) {
            hu.puzzleir.valuta.entity.Customer customer = customerRepository
                    .findById(request.getCustomerId())
                    .filter(c -> c.getCompany() != null && c.getCompany().getId().equals(companyId))
                    .orElseThrow(() -> new ResourceNotFoundException(
                            "Ügyfél nem található: " + request.getCustomerId()));
            // Review (Copilot, audit-integritás): törzsbeli ügyfélnél MINDIG a törzs-név kerül a
            // naplóba — a kliens által küldött név nem írhatja felül.
            customerName = customer.getName();
        } else {
            customerName = request.getCustomerName() != null ? request.getCustomerName().trim() : "";
            if (customerName.isEmpty()) {
                throw new hu.puzzleir.valuta.exception.ValidationException(
                        "Ismeretlen ügyfélnél az ügyfél neve kötelező a gyanú-bejelentéshez");
            }
        }

        String details = "GYANÚ-BEJELENTÉS (b9 FR-03) — ügyfél: " + customerName
                + (request.getHufAmount() != null
                        ? "; érintett összeg: " + request.getHufAmount().toPlainString() + " Ft" : "")
                + "; gyanús jelek: " + signs;

        CustomerScreeningLog saved = screeningLogRepository.save(CustomerScreeningLog.builder()
                .customerId(request.getCustomerId())
                .screeningType("SUSPICION")
                .result("FLAGGED")
                .details(details)
                .screenedAt(LocalDateTime.now())
                .screenedBy(workerId)
                .build());

        // Felsővezetői értesítés (in-app + email) — a telefonos egyeztetés kötelező emberi lépését
        // a bejelentés ténye + a pénztáros elérhetősége támogatja.
        for (hu.puzzleir.valuta.entity.Worker supervisor : workerRepository.findSupervisorsAndAbove(companyId)) {
            notificationService.sendToWorker(supervisor.getId(),
                    "Gyanú-bejelentés a pénztárból — azonnali egyeztetés szükséges",
                    details + " (bejelentő pénztáros workerId: " + workerId + ")",
                    "URGENT");
        }

        // Pmt.: 8 éves megőrzésű audit-nyom
        auditLogService.log("CUSTOMER_SUSPICION_REPORT", details, String.valueOf(saved.getId()));
        log.warn("Gyanú-bejelentés rögzítve: screeningLogId={}, worker={}", saved.getId(), workerId);
        return toScreeningDto(saved);
    }

    /**
     * Szűrési napló lekérdezése
     */
    @Transactional(readOnly = true)
    public List<CustomerScreeningLogDto> getScreeningHistory(Long customerId) {
        return screeningLogRepository.findByCustomerIdOrderByScreenedAtDesc(customerId)
                .stream()
                .map(this::toScreeningDto)
                .collect(Collectors.toList());
    }

    // --- Helpers ---

    private CustomerRestrictionDto toRestrictionDto(CustomerRestriction entity) {
        return CustomerRestrictionDto.builder()
                .id(entity.getId())
                .customerId(entity.getCustomerId())
                .restrictionType(entity.getRestrictionType())
                .reason(entity.getReason())
                .addedBy(entity.getAddedBy())
                .addedAt(entity.getAddedAt())
                .expiresAt(entity.getExpiresAt())
                .active(entity.getActive())
                .build();
    }

    private CustomerScreeningLogDto toScreeningDto(CustomerScreeningLog entity) {
        return CustomerScreeningLogDto.builder()
                .id(entity.getId())
                .customerId(entity.getCustomerId())
                .screeningType(entity.getScreeningType())
                .result(entity.getResult())
                .details(entity.getDetails())
                .screenedAt(entity.getScreenedAt())
                .screenedBy(entity.getScreenedBy())
                .build();
    }
}
