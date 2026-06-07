package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.vatrefund.CreateVatRefundRequest;
import hu.puzzleir.valuta.dto.vatrefund.VatRefundTransactionDto;
import hu.puzzleir.valuta.entity.VatRefundTransaction;
import hu.puzzleir.valuta.entity.VatRefundTransaction.VoucherType;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.VatRefundTransactionRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.UUID;

/**
 * ÁFA visszatérítés üzleti logika.
 *
 * Kezelt esetek:
 *   AK — EU ügyfél ÁFA visszatérítés HUF-ban
 *   AB — Cég részére ÁFA kifizetés
 *   AV — Innova Invest ellátmány (pénzmozgás oda-vissza)
 *
 * Legacy: WAFATABLAK adatbevitel logika
 */
@Service
@RequiredArgsConstructor
@Transactional(rollbackFor = Exception.class)
@Slf4j
public class VatRefundService {

    private final VatRefundTransactionRepository vatRefundTransactionRepository;
    // A4 (b9-korlevelek FR-02): kötelező körlevél-nyugtázás gate az ÁFA-visszatérítés úton is
    // (önálló tranzakció-belépési pont). Flag-gated (default OFF); a circularRepository CSAK
    // enforce=true ágon dereferálódik (guard → tesztek nem törnek).
    private final SystemParameterService systemParameterService;
    private final hu.puzzleir.valuta.repository.CircularRepository circularRepository;
    private final AuditLogService auditLogService;

    /**
     * ÁFA visszatérítés tranzakció létrehozása.
     *
     * @param request létrehozási kérelem
     * @return létrehozott tranzakció DTO
     */
    public VatRefundTransactionDto createVatRefund(CreateVatRefundRequest request) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        String workerCode = SecurityUtils.getCurrentWorkerCode();

        // A4: kötelező körlevél-nyugtázás gate (flag-gated, default OFF).
        boolean circularEnforce = systemParameterService != null && circularRepository != null
                && "true".equalsIgnoreCase(systemParameterService.getValue(
                        TransactionService.CIRCULAR_ACK_BLOCKING_PARAM,
                        TransactionService.CIRCULAR_ACK_BLOCKING_DEFAULT));
        if (circularEnforce) {
            String circularBlock = TransactionService.circularAckBlockReason(
                    circularRepository.findUnacknowledgedMandatoryForWorker(
                            companyId, SecurityUtils.getCurrentWorkerId(),
                            SecurityUtils.getCurrentBranchIdOrNull(),
                            hu.puzzleir.valuta.util.LegacyCompanyIdentityCodec.toLegacyInt(companyId)),
                    true);
            if (circularBlock != null) {
                throw new ValidationException(circularBlock);
            }
        }

        VoucherType voucherType = parseVoucherType(request.getVoucherType());

        validateRequest(request, voucherType);

        String serialNumber = generateSerialNumber(voucherType, companyId);

        UUID branchId = SecurityUtils.getCurrentBranchId();

        VatRefundTransaction entity = VatRefundTransaction.builder()
            .companyId(companyId)
            .branchId(branchId)
            .voucherType(voucherType)
            .serialNumber(serialNumber)
            .transactionDate(request.getTransactionDate() != null
                ? request.getTransactionDate() : LocalDate.now())
            .transactionTime(request.getTransactionTime() != null
                ? request.getTransactionTime() : LocalTime.now())
            .mainUnit(request.getMainUnit())
            .supplyAmount(request.getSupplyAmount())
            .grossAmount(request.getGrossAmount())
            .vatAmount(request.getVatAmount())
            .vatPercentage(request.getVatPercentage())
            .customerName(request.getCustomerName())
            .customerAddress(request.getCustomerAddress())
            .customerIdentifier(request.getCustomerIdentifier())
            .bankAccountNumber(request.getBankAccountNumber())
            .companyName(request.getCompanyName())
            .siteAddress(request.getSiteAddress())
            .deedNumber(request.getDeedNumber())
            .isReversed(false)
            .createdByWorker(workerCode)
            .build();

        VatRefundTransaction saved = vatRefundTransactionRepository.save(entity);
        log.info("ÁFA visszatérítés létrehozva: id={}, tipus={}, sorszam={}, osszeg={}",
            saved.getId(), saved.getVoucherType(), saved.getSerialNumber(), saved.getGrossAmount());
        auditLogService.log("VAT_REFUND_CREATED",
            String.format("ÁFA visszatérítés: %s (%s), bruttó %s", saved.getSerialNumber(),
                saved.getVoucherType(), saved.getGrossAmount()),
            saved.getId());

        return toDto(saved);
    }

    /**
     * ÁFA visszatérítés sztornózása.
     *
     * @param id sztornózandó tranzakció ID
     * @return sztornó tranzakció DTO
     */
    public VatRefundTransactionDto reverseVatRefund(Long id) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        String workerCode = SecurityUtils.getCurrentWorkerCode();

        // Pessimistic lock: a dupla-sztornó race ellen (isReversed olvasás+írás atomi a sorzáron belül).
        VatRefundTransaction original = vatRefundTransactionRepository.findByIdForUpdate(id)
            .orElseThrow(() -> new ResourceNotFoundException("ÁFA visszatérítés nem található: " + id));

        // Cross-tenant: idegen cég tranzakciója → 404 (a létezést sem áruljuk el, mint a transfer/WU sztornó).
        if (!original.getCompanyId().equals(companyId)) {
            throw new ResourceNotFoundException("ÁFA visszatérítés nem található: " + id);
        }
        if (Boolean.TRUE.equals(original.getIsReversed())) {
            throw new ValidationException("A tranzakció már sztornózva van: " + id);
        }

        String stornoSerial = "SZTORNO-" + original.getSerialNumber();

        UUID branchId = SecurityUtils.getCurrentBranchId();

        VatRefundTransaction storno = VatRefundTransaction.builder()
            .companyId(companyId)
            .branchId(branchId)
            .voucherType(original.getVoucherType())
            .serialNumber(stornoSerial)
            .transactionDate(LocalDate.now())
            .transactionTime(LocalTime.now())
            .mainUnit(original.getMainUnit())
            .supplyAmount(original.getSupplyAmount() != null
                ? original.getSupplyAmount().negate() : null)
            .grossAmount(original.getGrossAmount().negate())
            .vatAmount(original.getVatAmount().negate())
            .vatPercentage(original.getVatPercentage())
            .customerName(original.getCustomerName())
            .customerAddress(original.getCustomerAddress())
            .customerIdentifier(original.getCustomerIdentifier())
            .bankAccountNumber(original.getBankAccountNumber())
            .companyName(original.getCompanyName())
            .siteAddress(original.getSiteAddress())
            .deedNumber(original.getDeedNumber())
            .isReversed(true)
            .originalTransactionId(id)
            .createdByWorker(workerCode)
            .build();

        original.setIsReversed(true);
        vatRefundTransactionRepository.save(original);
        VatRefundTransaction savedStorno = vatRefundTransactionRepository.save(storno);

        log.info("ÁFA visszatérítés sztornózva: eredeti id={}, sztorno id={}", id, savedStorno.getId());
        auditLogService.log("VAT_REFUND_STORNO",
            String.format("ÁFA visszatérítés sztornózva: %s → %s (eredeti id=%d)",
                original.getSerialNumber(), stornoSerial, id),
            savedStorno.getId());
        return toDto(savedStorno);
    }

    /**
     * Tranzakció lekérése ID alapján.
     */
    @Transactional(readOnly = true)
    public VatRefundTransactionDto getById(Long id) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        VatRefundTransaction entity = vatRefundTransactionRepository.findById(id)
            .orElseThrow(() -> new ResourceNotFoundException("ÁFA visszatérítés nem található: " + id));
        // Cross-tenant: idegen cég → 404 (a létezést sem áruljuk el).
        if (!entity.getCompanyId().equals(companyId)) {
            throw new ResourceNotFoundException("ÁFA visszatérítés nem található: " + id);
        }
        return toDto(entity);
    }

    /**
     * Napi tranzakciók listája.
     */
    @Transactional(readOnly = true)
    public List<VatRefundTransactionDto> getDailyTransactions(LocalDate date) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        LocalDate effectiveDate = date != null ? date : LocalDate.now();
        return vatRefundTransactionRepository
            .findActiveByCompanyAndDate(companyId, effectiveDate)
            .stream().map(this::toDto).toList();
    }

    /**
     * Összes tranzakció lekérése (dátum szűrővel).
     */
    @Transactional(readOnly = true)
    public List<VatRefundTransactionDto> getTransactions(LocalDate from, LocalDate to) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        if (from != null && to != null) {
            return vatRefundTransactionRepository
                .findByCompanyIdAndTransactionDateBetweenOrderByTransactionDateDescCreatedAtDesc(
                    companyId, from, to)
                .stream().map(this::toDto).toList();
        }
        return vatRefundTransactionRepository
            .findByCompanyIdOrderByTransactionDateDescCreatedAtDesc(companyId)
            .stream().map(this::toDto).toList();
    }

    // ============ HELPERS ============

    private VoucherType parseVoucherType(String type) {
        try {
            return VoucherType.valueOf(type.toUpperCase());
        } catch (IllegalArgumentException e) {
            throw new ValidationException("Érvénytelen bizonylat típus: " + type + " (elfogadott: AK, AB, AV)");
        }
    }

    private void validateRequest(CreateVatRefundRequest request, VoucherType voucherType) {
        if (request.getGrossAmount() == null || request.getGrossAmount().compareTo(BigDecimal.ZERO) <= 0) {
            throw new ValidationException("A bruttó összeg kötelező és pozitív kell legyen");
        }
        if (request.getVatAmount() == null || request.getVatAmount().compareTo(BigDecimal.ZERO) < 0) {
            throw new ValidationException("Az ÁFA összeg kötelező");
        }
        if (voucherType == VoucherType.AK && (request.getCustomerName() == null || request.getCustomerName().isBlank())) {
            throw new ValidationException("AK típusú bizonylaton az ügyfél neve kötelező");
        }
        if (voucherType == VoucherType.AB && (request.getCompanyName() == null || request.getCompanyName().isBlank())) {
            throw new ValidationException("AB típusú bizonylaton a cég neve kötelező");
        }
    }

    /**
     * Cégszintű, DB-alapú, újraindítás-biztos sorszám: {@code TÍPUS-YYYYMMDD-NNNNN}, a cégen belüli
     * aznapi MAX+1-gyel (a régi static AtomicLong helyett, ami újraindításkor/cégek között ütközött).
     * Egyediség-backstop: a (company_id, serial_number) UNIQUE index (V300).
     */
    private String generateSerialNumber(VoucherType type, UUID companyId) {
        LocalDate today = LocalDate.now();
        String datePart = String.format("%d%02d%02d", today.getYear(), today.getMonthValue(), today.getDayOfMonth());
        String prefix = type.name() + "-" + datePart + "-"; // pl. "AK-20260607-"
        long max = vatRefundTransactionRepository.findMaxVatSerialForCompany(
                companyId, prefix + "%", prefix.length() + 1);
        return prefix + String.format("%05d", max + 1);
    }

    private VatRefundTransactionDto toDto(VatRefundTransaction e) {
        return VatRefundTransactionDto.builder()
            .id(e.getId())
            .companyId(e.getCompanyId())
            .voucherType(e.getVoucherType().name())
            .serialNumber(e.getSerialNumber())
            .transactionDate(e.getTransactionDate())
            .transactionTime(e.getTransactionTime())
            .mainUnit(e.getMainUnit())
            .supplyAmount(e.getSupplyAmount())
            .grossAmount(e.getGrossAmount())
            .vatAmount(e.getVatAmount())
            .vatPercentage(e.getVatPercentage())
            .customerName(e.getCustomerName())
            .customerAddress(e.getCustomerAddress())
            .customerIdentifier(e.getCustomerIdentifier())
            .bankAccountNumber(e.getBankAccountNumber())
            .companyName(e.getCompanyName())
            .siteAddress(e.getSiteAddress())
            .deedNumber(e.getDeedNumber())
            .isReversed(e.getIsReversed())
            .originalTransactionId(e.getOriginalTransactionId())
            .createdByWorker(e.getCreatedByWorker())
            .createdAt(e.getCreatedAt())
            .build();
    }
}
