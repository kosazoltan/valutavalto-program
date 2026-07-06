package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Customer;
import hu.puzzleir.valuta.entity.CustomerRiskRating;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.CustomerRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class CustomerRiskRatingServiceTest {

    private static final UUID COMPANY_ID = UUID.randomUUID();
    private static final UUID OTHER_COMPANY_ID = UUID.randomUUID();

    @Mock private CustomerRepository customerRepository;
    @Mock private AuditLogService auditLogService;
    @InjectMocks private CustomerRiskRatingService service;

    @Test
    void setRiskRating_lowToHigh_savesAndAudits() {
        Customer customer = Customer.builder()
                .id(42L)
                .customerCode("C42")
                .company(Company.builder().id(COMPANY_ID).build())
                .riskRating(CustomerRiskRating.LOW)
                .build();
        when(customerRepository.findById(42L)).thenReturn(Optional.of(customer));
        when(customerRepository.save(customer)).thenReturn(customer);

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

            Customer result = service.setRiskRating(42L, CustomerRiskRating.HIGH, "compliance döntés");

            assertThat(result.getRiskRating()).isEqualTo(CustomerRiskRating.HIGH);
            verify(customerRepository).save(customer);
            verify(auditLogService).logForCompany(eq("CUSTOMER_RISK_RATING_SET"), contains("LOW"), any(), eq(COMPANY_ID));
            verify(auditLogService).logForCompany(eq("CUSTOMER_RISK_RATING_SET"), contains("HIGH"), any(), eq(COMPANY_ID));
            verify(auditLogService).logForCompany(eq("CUSTOMER_RISK_RATING_SET"), contains("compliance döntés"), any(), eq(COMPANY_ID));
        }
    }

    @Test
    void setRiskRating_blankReason_throwsWithoutSave() {
        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

            assertThatThrownBy(() -> service.setRiskRating(42L, CustomerRiskRating.HIGH, "  "))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("indoka");
            verify(customerRepository, never()).save(any());
        }
    }

    @Test
    void setRiskRating_crossTenant_throwsResourceNotFound() {
        Customer customer = Customer.builder()
                .id(42L)
                .customerCode("C42")
                .company(Company.builder().id(OTHER_COMPANY_ID).build())
                .riskRating(CustomerRiskRating.LOW)
                .build();
        when(customerRepository.findById(42L)).thenReturn(Optional.of(customer));

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

            assertThatThrownBy(() -> service.setRiskRating(42L, CustomerRiskRating.HIGH, "másik cég"))
                    .isInstanceOf(ResourceNotFoundException.class);
            verify(customerRepository, never()).save(any());
        }
    }

    @Test
    void setRiskRating_unchangedValue_auditsWithoutSave() {
        Customer customer = Customer.builder()
                .id(42L)
                .customerCode("C42")
                .company(Company.builder().id(COMPANY_ID).build())
                .riskRating(CustomerRiskRating.HIGH)
                .build();
        when(customerRepository.findById(42L)).thenReturn(Optional.of(customer));

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

            Customer result = service.setRiskRating(42L, CustomerRiskRating.HIGH, "éves felülvizsgálat");

            assertThat(result.getRiskRating()).isEqualTo(CustomerRiskRating.HIGH);
            verify(customerRepository, never()).save(any());
            verify(auditLogService).logForCompany(eq("CUSTOMER_RISK_RATING_SET"), contains("változatlan"), any(), eq(COMPANY_ID));
            verify(auditLogService).logForCompany(eq("CUSTOMER_RISK_RATING_SET"), contains("éves felülvizsgálat"), any(), eq(COMPANY_ID));
        }
    }
}
