package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Customer;
import hu.puzzleir.valuta.entity.ReviewStatus;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.CustomerRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class CustomerReviewServiceTest {

    private static final UUID COMPANY_ID = UUID.randomUUID();
    private static final UUID OTHER_COMPANY_ID = UUID.randomUUID();

    @Mock private CustomerRepository customerRepository;
    @Mock private AuditLogService auditLogService;
    @InjectMocks private CustomerReviewService service;

    @Test
    void review_pendingCustomer_setsReviewedAndAudits() {
        Customer customer = Customer.builder()
                .id(42L)
                .customerCode("C42")
                .company(Company.builder().id(COMPANY_ID).build())
                .reviewStatus(ReviewStatus.PENDING_REVIEW)
                .build();
        when(customerRepository.findById(42L)).thenReturn(Optional.of(customer));
        when(customerRepository.save(customer)).thenReturn(customer);

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            sec.when(SecurityUtils::getCurrentWorkerCode).thenReturn("W007");

            Customer result = service.review(42L);

            assertThat(result.getReviewStatus()).isEqualTo(ReviewStatus.REVIEWED);
            assertThat(result.getReviewedBy()).isEqualTo("W007");
            assertThat(result.getReviewedAt()).isNotNull();
            verify(customerRepository).save(customer);
            verify(auditLogService).logForCompany(eq("CUSTOMER_REVIEWED"), contains("átnézve"), eq("C42"), eq(COMPANY_ID));
        }
    }

    @Test
    void review_alreadyReviewed_idempotentWithoutSaveOrAudit() {
        Customer customer = Customer.builder()
                .id(42L)
                .customerCode("C42")
                .company(Company.builder().id(COMPANY_ID).build())
                .reviewStatus(ReviewStatus.REVIEWED)
                .build();
        when(customerRepository.findById(42L)).thenReturn(Optional.of(customer));

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

            Customer result = service.review(42L);

            assertThat(result).isSameAs(customer);
            verify(customerRepository, never()).save(any());
            verify(auditLogService, never()).logForCompany(any(), any(), any(), any());
        }
    }

    @Test
    void review_crossTenant_throwsResourceNotFound() {
        Customer customer = Customer.builder()
                .id(42L)
                .customerCode("C42")
                .company(Company.builder().id(OTHER_COMPANY_ID).build())
                .reviewStatus(ReviewStatus.PENDING_REVIEW)
                .build();
        when(customerRepository.findById(42L)).thenReturn(Optional.of(customer));

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

            assertThatThrownBy(() -> service.review(42L))
                    .isInstanceOf(ResourceNotFoundException.class);
            verify(customerRepository, never()).save(any());
        }
    }

    @Test
    void getPendingReview_usesCompanyScopedRepositoryQuery() {
        Customer customer = Customer.builder()
                .id(42L)
                .company(Company.builder().id(COMPANY_ID).build())
                .reviewStatus(ReviewStatus.PENDING_REVIEW)
                .build();
        when(customerRepository.findByCompanyIdAndReviewStatusOrderByUpdatedAtDesc(
                COMPANY_ID, ReviewStatus.PENDING_REVIEW)).thenReturn(List.of(customer));

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

            List<Customer> result = service.getPendingReview();

            assertThat(result).containsExactly(customer);
            verify(customerRepository).findByCompanyIdAndReviewStatusOrderByUpdatedAtDesc(
                    COMPANY_ID, ReviewStatus.PENDING_REVIEW);
        }
    }
}
