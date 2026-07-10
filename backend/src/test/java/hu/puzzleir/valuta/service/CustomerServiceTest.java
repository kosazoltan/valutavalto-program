package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Customer;
import hu.puzzleir.valuta.entity.DataChangeSource;
import hu.puzzleir.valuta.entity.ReviewStatus;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.repository.CustomerRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class CustomerServiceTest {

    @Mock private CustomerRepository customerRepository;
    @Mock private CompanyRepository companyRepository;
    @Mock private CustomerVersionService customerVersionService;
    @InjectMocks private CustomerService service;

    private static final UUID COMPANY_ID = UUID.randomUUID();

    @Test
    @DisplayName("createCustomer — sikeres letrehozas")
    void testCreateCustomer_success() {
        Company company = Company.builder().id(COMPANY_ID).build();
        CustomerService.CreateCustomerRequest request = new CustomerService.CreateCustomerRequest();
        request.setName("Teszt Ugyfel");
        request.setDocumentNumber("123456AB");
        request.setNationality("HU");

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(companyRepository.findById(COMPANY_ID)).thenReturn(Optional.of(company));
            when(customerRepository.findByDocumentNumberAndCompanyId("123456AB", COMPANY_ID))
                    .thenReturn(Optional.empty());
            when(customerVersionService.currentChangeSource()).thenReturn(DataChangeSource.CASHIER);
            when(customerRepository.save(any())).thenAnswer(inv -> {
                Customer c = inv.getArgument(0);
                c.setId(1L);
                return c;
            });

            Customer result = service.createCustomer(request);

            assertThat(result.getName()).isEqualTo("Teszt Ugyfel");
            assertThat(result.getActive()).isTrue();
            verify(customerRepository).save(any());
            verify(customerVersionService).recordVersion(result, DataChangeSource.CASHIER);
        }
    }

    @Test
    @DisplayName("createCustomer — inaktív ügyfél kódját nem osztja ki újra")
    void createCustomer_inactiveCustomerCodeCollision_usesNextCode() {
        Company company = Company.builder().id(COMPANY_ID).build();
        CustomerService.CreateCustomerRequest request = new CustomerService.CreateCustomerRequest();
        request.setName("Uj Ugyfel");
        request.setDocumentNumber("NEW-001");

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(companyRepository.findById(COMPANY_ID)).thenReturn(Optional.of(company));
            when(customerRepository.findByDocumentNumberAndCompanyId("NEW-001", COMPANY_ID))
                    .thenReturn(Optional.empty());
            when(customerRepository.findMaxCustomerCodeSuffix()).thenReturn(1);
            when(customerVersionService.currentChangeSource()).thenReturn(DataChangeSource.CASHIER);
            when(customerRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

            Customer result = service.createCustomer(request);

            assertThat(result.getCustomerCode()).isEqualTo("C000002");
        }
    }

    @Test
    @DisplayName("createCustomer — jogi személy TEÁOR kód perzisztálódik (G27)")
    void testCreateCustomer_teaorCode() {
        Company company = Company.builder().id(COMPANY_ID).build();
        CustomerService.CreateCustomerRequest request = new CustomerService.CreateCustomerRequest();
        request.setName("Teszt Kft.");
        request.setDocumentNumber("CEG-001");
        request.setIsCompany(true);
        request.setCompanyName("Teszt Kft.");
        request.setTaxNumber("12345678-2-42");
        request.setTeaorCode("6612"); // értékpapír-ügynöki tevékenység

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(companyRepository.findById(COMPANY_ID)).thenReturn(Optional.of(company));
            when(customerRepository.findByDocumentNumberAndCompanyId("CEG-001", COMPANY_ID))
                    .thenReturn(Optional.empty());
            when(customerVersionService.currentChangeSource()).thenReturn(DataChangeSource.CASHIER);
            when(customerRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

            Customer result = service.createCustomer(request);

            assertThat(result.getTeaorCode()).isEqualTo("6612");
            assertThat(result.getCompanyName()).isEqualTo("Teszt Kft.");
        }
    }

    @Test
    @DisplayName("createCustomer — PEP státusz perzisztálódik")
    void testCreateCustomer_isPep() {
        Company company = Company.builder().id(COMPANY_ID).build();
        CustomerService.CreateCustomerRequest request = new CustomerService.CreateCustomerRequest();
        request.setName("PEP Ugyfel");
        request.setDocumentNumber("PEP-001");
        request.setIsPep(true);

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(companyRepository.findById(COMPANY_ID)).thenReturn(Optional.of(company));
            when(customerRepository.findByDocumentNumberAndCompanyId("PEP-001", COMPANY_ID))
                    .thenReturn(Optional.empty());
            when(customerVersionService.currentChangeSource()).thenReturn(DataChangeSource.CASHIER);
            when(customerRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

            Customer result = service.createCustomer(request);

            assertThat(result.getIsPep()).isTrue();
        }
    }

    @Test
    @DisplayName("createCustomer — duplikalt dokumentum szam: IDEMPOTENS upsert visszaadja a letezot (HIBA #9 2026-05-15)")
    void testCreateCustomer_duplicateDocumentIdempotent() {
        Company company = Company.builder().id(COMPANY_ID).build();
        CustomerService.CreateCustomerRequest request = new CustomerService.CreateCustomerRequest();
        request.setName("Masik Ugyfel");
        request.setDocumentNumber("DUPLICATE");

        Customer existing = Customer.builder().id(99L).customerCode("EXISTING").documentNumber("DUPLICATE").build();

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(companyRepository.findById(COMPANY_ID)).thenReturn(Optional.of(company));
            when(customerRepository.findByDocumentNumberAndCompanyId("DUPLICATE", COMPANY_ID))
                    .thenReturn(Optional.of(existing));

            Customer result = service.createCustomer(request);

            assertThat(result)
                    .as("duplikalt doc# eseten a letezo customer-t kell visszaadni, NEM exception")
                    .isNotNull()
                    .extracting(Customer::getId).isEqualTo(99L);
        }
    }

    @Test
    void createCustomer_cashierSource_pendingReview_andVersionRecorded() {
        Company company = Company.builder().id(COMPANY_ID).build();
        CustomerService.CreateCustomerRequest request = new CustomerService.CreateCustomerRequest();
        request.setName("Pénztári Ugyfel");
        request.setDocumentNumber("PEND-001");

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(companyRepository.findById(COMPANY_ID)).thenReturn(Optional.of(company));
            when(customerRepository.findByDocumentNumberAndCompanyId("PEND-001", COMPANY_ID))
                    .thenReturn(Optional.empty());
            when(customerVersionService.currentChangeSource()).thenReturn(DataChangeSource.CASHIER);
            when(customerRepository.save(any())).thenAnswer(inv -> {
                Customer c = inv.getArgument(0);
                c.setId(10L);
                return c;
            });

            Customer result = service.createCustomer(request);

            assertThat(result.getReviewStatus()).isEqualTo(ReviewStatus.PENDING_REVIEW);
            assertThat(result.getReviewedBy()).isNull();
            assertThat(result.getReviewedAt()).isNull();
            verify(customerVersionService).recordVersion(result, DataChangeSource.CASHIER);
        }
    }

    @Test
    void createCustomer_complianceSource_autoReviewed() {
        Company company = Company.builder().id(COMPANY_ID).build();
        CustomerService.CreateCustomerRequest request = new CustomerService.CreateCustomerRequest();
        request.setName("Compliance Ugyfel");
        request.setDocumentNumber("REV-001");

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            su.when(SecurityUtils::getCurrentWorkerCode).thenReturn("W1");
            when(companyRepository.findById(COMPANY_ID)).thenReturn(Optional.of(company));
            when(customerRepository.findByDocumentNumberAndCompanyId("REV-001", COMPANY_ID))
                    .thenReturn(Optional.empty());
            when(customerVersionService.currentChangeSource()).thenReturn(DataChangeSource.COMPLIANCE);
            when(customerRepository.save(any())).thenAnswer(inv -> {
                Customer c = inv.getArgument(0);
                c.setId(11L);
                return c;
            });

            Customer result = service.createCustomer(request);

            assertThat(result.getReviewStatus()).isEqualTo(ReviewStatus.REVIEWED);
            assertThat(result.getReviewedBy()).isEqualTo("W1");
            assertThat(result.getReviewedAt()).isNotNull();
            verify(customerVersionService).recordVersion(result, DataChangeSource.COMPLIANCE);
        }
    }

    @Test
    void updateCustomer_dataChanged_flipsToPendingAndRecordsVersion() {
        Customer customer = Customer.builder()
                .id(42L)
                .name("Régi Név")
                .customerCode("C42")
                .reviewStatus(ReviewStatus.REVIEWED)
                .reviewedBy("WOLD")
                .company(Company.builder().id(COMPANY_ID).build())
                .build();
        CustomerService.UpdateCustomerRequest request = new CustomerService.UpdateCustomerRequest();
        request.setName("Új Név");

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(customerRepository.findById(42L)).thenReturn(Optional.of(customer));
            when(customerVersionService.currentChangeSource()).thenReturn(DataChangeSource.CASHIER);
            when(customerVersionService.hasDataChanged(customer)).thenReturn(true);
            when(customerRepository.save(customer)).thenReturn(customer);

            Customer result = service.updateCustomer(42L, request);

            assertThat(result.getReviewStatus()).isEqualTo(ReviewStatus.PENDING_REVIEW);
            assertThat(result.getReviewedBy()).isNull();
            assertThat(result.getReviewedAt()).isNull();
            verify(customerVersionService).recordVersion(result, DataChangeSource.CASHIER);
        }
    }

    @Test
    void updateCustomer_noDataChange_keepsStatusAndNoVersion() {
        Customer customer = Customer.builder()
                .id(42L)
                .name("Régi Név")
                .customerCode("C42")
                .reviewStatus(ReviewStatus.REVIEWED)
                .reviewedBy("WOLD")
                .company(Company.builder().id(COMPANY_ID).build())
                .build();
        CustomerService.UpdateCustomerRequest request = new CustomerService.UpdateCustomerRequest();
        request.setName("Régi Név");

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(customerRepository.findById(42L)).thenReturn(Optional.of(customer));
            when(customerVersionService.currentChangeSource()).thenReturn(DataChangeSource.CASHIER);
            when(customerVersionService.hasDataChanged(customer)).thenReturn(false);
            when(customerRepository.save(customer)).thenReturn(customer);

            Customer result = service.updateCustomer(42L, request);

            assertThat(result.getReviewStatus()).isEqualTo(ReviewStatus.REVIEWED);
            assertThat(result.getReviewedBy()).isEqualTo("WOLD");
            verify(customerVersionService, never()).recordVersion(any(), any());
        }
    }

    @Test
    @DisplayName("findById — letezo ugyfel, sajat ceg")
    void testFindById_found() {
        Customer customer = Customer.builder()
                .id(1L)
                .name("Teszt")
                .company(Company.builder().id(COMPANY_ID).build())
                .build();

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(customerRepository.findById(1L)).thenReturn(Optional.of(customer));

            Customer result = service.findById(1L);
            assertThat(result.getName()).isEqualTo("Teszt");
        }
    }

    @Test
    @DisplayName("findById — nem letezo ugyfel")
    void testFindById_notFound() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(customerRepository.findById(999L)).thenReturn(Optional.empty());

            assertThatThrownBy(() -> service.findById(999L))
                    .isInstanceOf(ResourceNotFoundException.class);
        }
    }

    @Test
    @DisplayName("findById — mas ceg ugyfele → IDOR vedelem")
    void testFindById_otherCompany_blocked() {
        UUID otherCompanyId = UUID.randomUUID();
        Customer customer = Customer.builder()
                .id(1L)
                .name("Mas Ceg Ugyfele")
                .company(Company.builder().id(otherCompanyId).build())
                .build();

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(customerRepository.findById(1L)).thenReturn(Optional.of(customer));

            assertThatThrownBy(() -> service.findById(1L))
                    .isInstanceOf(ResourceNotFoundException.class);
        }
    }

    @Test
    @DisplayName("deactivateCustomer — sikeres deaktivalas")
    void testDeactivateCustomer() {
        Customer customer = Customer.builder()
                .id(1L)
                .name("Teszt")
                .active(true)
                .company(Company.builder().id(COMPANY_ID).build())
                .build();

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(customerRepository.findById(1L))
                    .thenReturn(Optional.of(customer));
            when(customerRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

            service.deactivateCustomer(1L);

            assertThat(customer.getActive()).isFalse();
            verify(customerRepository).save(customer);
        }
    }

    @Test
    @DisplayName("searchByName — talalatok")
    void testSearchByName() {
        Customer c1 = Customer.builder().id(1L).name("Kovacs Janos").build();
        Customer c2 = Customer.builder().id(2L).name("Kovacs Peter").build();

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(customerRepository.searchByName(COMPANY_ID, "Kovacs"))
                    .thenReturn(List.of(c1, c2));

            List<Customer> result = service.searchByName("Kovacs");
            assertThat(result).hasSize(2);
        }
    }

    @Test
    @DisplayName("searchByNameOrDocument — név vagy okmányszám keresés company scope-pal")
    void testSearchByNameOrDocument() {
        Customer c1 = Customer.builder().id(1L).name("Kovacs Janos").documentNumber("123456AB").build();

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(customerRepository.searchByNameOrDocument(COMPANY_ID, "123456AB"))
                    .thenReturn(List.of(c1));

            List<Customer> result = service.searchByNameOrDocument("123456AB");

            assertThat(result).containsExactly(c1);
            verify(customerRepository).searchByNameOrDocument(COMPANY_ID, "123456AB");
        }
    }
}
