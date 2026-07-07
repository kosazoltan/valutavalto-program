package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Customer;
import hu.puzzleir.valuta.entity.ReviewStatus;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.CustomerRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

/**
 * FS-3 (D2): compliance "Átnézve" jóváhagyás. Tenant-guard + audit a
 * CustomerRiskRatingService (FS-2) mintájára.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class CustomerReviewService {

    static final String AUDIT_ACTION = "CUSTOMER_REVIEWED";

    private final CustomerRepository customerRepository;
    private final AuditLogService auditLogService;

    @Transactional(rollbackFor = Exception.class)
    public Customer review(Long customerId) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        Customer customer = customerRepository.findById(customerId)
                .filter(c -> c.getCompany() != null && c.getCompany().getId().equals(companyId))
                .orElseThrow(() -> new ResourceNotFoundException("Ügyfél nem található: " + customerId));

        if (customer.getReviewStatus() == ReviewStatus.REVIEWED) {
            return customer; // idempotens — a megerősítés nem külön döntés (terv-contract)
        }
        customer.setReviewStatus(ReviewStatus.REVIEWED);
        customer.setReviewedBy(SecurityUtils.getCurrentWorkerCode());
        customer.setReviewedAt(LocalDateTime.now());
        customerRepository.save(customer);
        auditLogService.logForCompany(AUDIT_ACTION,
                "Ügyféladat-módosítás átnézve (compliance jóváhagyás)",
                customer.getCustomerCode(), companyId);
        log.info("[REVIEW] Ügyfél #{} átnézve", customer.getId());
        return customer;
    }

    @Transactional(readOnly = true)
    public List<Customer> getPendingReview() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return customerRepository
                .findByCompanyIdAndReviewStatusOrderByUpdatedAtDesc(companyId, ReviewStatus.PENDING_REVIEW);
    }
}
