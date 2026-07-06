package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Customer;
import hu.puzzleir.valuta.entity.CustomerRiskRating;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.CustomerRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

/**
 * FS-2: ügyfél MNB kockázati besorolásának kézi állítása (compliance-művelet).
 * Tenant-guard + INSERT-only audit az AmlEddService.markManualEdd mintájára.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class CustomerRiskRatingService {

    static final String AUDIT_ACTION = "CUSTOMER_RISK_RATING_SET";

    private final CustomerRepository customerRepository;
    private final AuditLogService auditLogService;

    @Transactional(rollbackFor = Exception.class)
    public Customer setRiskRating(Long customerId, CustomerRiskRating newRating, String reason) {
        if (newRating == null) {
            throw new ValidationException("A kockázati besorolás kötelező");
        }
        if (reason == null || reason.isBlank()) {
            throw new ValidationException("A besorolás indoka kötelező");
        }
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        Customer customer = customerRepository.findById(customerId)
                .filter(c -> c.getCompany() != null && c.getCompany().getId().equals(companyId))
                .orElseThrow(() -> new ResourceNotFoundException("Ügyfél nem található: " + customerId));

        CustomerRiskRating old = customer.getRiskRating() != null
                ? customer.getRiskRating() : CustomerRiskRating.LOW;
        String trimmedReason = reason.trim();
        if (old == newRating) {
            // A besorolási DÖNTÉS ténye változatlan értéknél is audit-köteles (Pmt.30/EDD-precedens).
            auditLogService.logForCompany(AUDIT_ACTION,
                    "Kockázati besorolás megerősítve (változatlan): " + old + " — " + trimmedReason,
                    customer.getCustomerCode() + ":" + newRating, companyId);
            return customer;
        }
        customer.setRiskRating(newRating);
        customerRepository.save(customer);
        auditLogService.logForCompany(AUDIT_ACTION,
                "Kockázati besorolás módosítva: " + old + " → " + newRating + " — " + trimmedReason,
                customer.getCustomerCode() + ":" + newRating, companyId);
        // PII-mentes app-log (AmlApprovalService log-mintája: id-k, nem nevek).
        log.info("[RISK-RATING] Ügyfél #{} besorolás: {} → {}", customer.getId(), old, newRating);
        return customer;
    }
}
