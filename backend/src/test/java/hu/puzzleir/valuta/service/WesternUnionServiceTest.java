package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.wu.WuTransactionDto;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.*;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class WesternUnionServiceTest {

    @Mock WuTransactionRepository wuTransactionRepository;
    @Mock WuCustomerRepository wuCustomerRepository;
    @Mock WuBalanceRepository wuBalanceRepository;
    @Mock BranchRepository branchRepository;
    @Mock CompanyRepository companyRepository;
    @Mock AmlService amlService;

    @InjectMocks WesternUnionService service;

    private UUID branchId;
    private UUID companyId;
    private Branch branch;
    private Company company;
    private MockedStatic<SecurityUtils> securityUtilsMock;

    @BeforeEach
    void setUp() {
        branchId = UUID.randomUUID();
        companyId = UUID.randomUUID();

        company = new Company();
        company.setId(companyId);
        company.setName("Teszt Ceg");

        branch = new Branch();
        branch.setId(branchId);
        branch.setCompany(company);

        securityUtilsMock = mockStatic(SecurityUtils.class);
        securityUtilsMock.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
    }

    @AfterEach
    void tearDown() {
        securityUtilsMock.close();
    }

    // ============ MTCN VALIDATION ============

    @Test
    void recordSend_validMtcn_succeeds() {
        when(branchRepository.findById(branchId)).thenReturn(Optional.of(branch));
        when(amlService.checkTransaction(any(), any(), any(), any()))
                .thenReturn(AmlService.AmlBasicCheckResult.builder().approved(true).build());
        when(wuBalanceRepository.findByBranchIdForUpdate(branchId))
                .thenReturn(Optional.of(WuBalance.builder()
                        .branch(branch)
                        .company(company)
                        .usdBalance(BigDecimal.ZERO)
                        .hufBalance(BigDecimal.ZERO)
                        .build()));
        WuTransaction saved = WuTransaction.builder()
                .id(UUID.randomUUID())
                .transactionType("SEND")
                .status(WuTransactionStatus.COMPLETED)
                .build();
        when(wuTransactionRepository.save(any())).thenReturn(saved);

        WuTransactionDto dto = WuTransactionDto.builder()
                .branchId(branchId)
                .mtcn("1234567890")
                .amountUsd(new BigDecimal("100"))
                .amountHuf(new BigDecimal("36000"))
                .build();

        WuTransaction result = service.recordSend(dto);
        assertThat(result).isNotNull();
        verify(wuTransactionRepository).save(any());
    }

    @Test
    void validateMtcn_null_throws() {
        WuTransactionDto dto = WuTransactionDto.builder()
                .branchId(branchId)
                .mtcn(null)
                .build();

        assertThatThrownBy(() -> service.recordSend(dto))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("MTCN");
    }

    @Test
    void validateMtcn_tooShort_throws() {
        WuTransactionDto dto = WuTransactionDto.builder()
                .branchId(branchId)
                .mtcn("123456789")   // 9 digit — invalid
                .build();

        assertThatThrownBy(() -> service.recordSend(dto))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("10 sz\u00e1mjegy");
    }

    @Test
    void validateMtcn_tooLong_throws() {
        WuTransactionDto dto = WuTransactionDto.builder()
                .branchId(branchId)
                .mtcn("12345678901")  // 11 digit — invalid
                .build();

        assertThatThrownBy(() -> service.recordSend(dto))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("10 sz\u00e1mjegy");
    }

    @Test
    void validateMtcn_containsLetters_throws() {
        WuTransactionDto dto = WuTransactionDto.builder()
                .branchId(branchId)
                .mtcn("123456789A")  // non-numeric
                .build();

        assertThatThrownBy(() -> service.recordSend(dto))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("10 sz\u00e1mjegy");
    }

    @Test
    void validateMtcn_exactlyTenDigits_passes() {
        when(branchRepository.findById(branchId)).thenReturn(Optional.of(branch));
        when(amlService.checkTransaction(any(), any(), any(), any()))
                .thenReturn(AmlService.AmlBasicCheckResult.builder().approved(true).build());
        when(wuBalanceRepository.findByBranchIdForUpdate(branchId))
                .thenReturn(Optional.of(WuBalance.builder()
                        .branch(branch).company(company)
                        .usdBalance(BigDecimal.ZERO).hufBalance(BigDecimal.ZERO).build()));
        when(wuTransactionRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        WuTransactionDto dto = WuTransactionDto.builder()
                .branchId(branchId)
                .mtcn("0000000000")  // exactly 10 digits
                .amountUsd(BigDecimal.TEN)
                .amountHuf(new BigDecimal("3600"))
                .build();

        assertThatCode(() -> service.recordSend(dto)).doesNotThrowAnyException();
    }

    // ============ reverseWuTransaction ============

    @Test
    void reverseWuTransaction_createsStornoAndSetsReversed() {
        UUID originalId = UUID.randomUUID();
        WuTransaction original = WuTransaction.builder()
                .id(originalId)
                .branch(branch)
                .company(company)
                .transactionType("SEND")
                .mtcn("1234567890")
                .amountUsd(new BigDecimal("100"))
                .amountHuf(new BigDecimal("36000"))
                .status(WuTransactionStatus.COMPLETED)
                .transactionDate(LocalDateTime.now().minusHours(1))
                .build();

        when(wuTransactionRepository.findById(originalId)).thenReturn(Optional.of(original));
        when(wuBalanceRepository.findByBranchIdForUpdate(branchId))
                .thenReturn(Optional.of(WuBalance.builder()
                        .branch(branch).company(company)
                        .usdBalance(BigDecimal.ZERO).hufBalance(BigDecimal.ZERO).build()));
        when(wuTransactionRepository.save(any())).thenAnswer(inv -> {
            WuTransaction t = inv.getArgument(0);
            if (t.getId() == null) t = WuTransaction.builder()
                    .id(UUID.randomUUID())
                    .transactionType(t.getTransactionType())
                    .status(t.getStatus())
                    .reversedTransaction(t.getReversedTransaction())
                    .reversalReason(t.getReversalReason())
                    .branch(t.getBranch())
                    .company(t.getCompany())
                    .amountUsd(t.getAmountUsd())
                    .amountHuf(t.getAmountHuf())
                    .build();
            return t;
        });

        WuTransaction storno = service.reverseWuTransaction(originalId, "\u00dcgyf\u00e9l lemondta");

        assertThat(storno.getTransactionType()).isEqualTo("STORNO");
        assertThat(storno.getStatus()).isEqualTo(WuTransactionStatus.COMPLETED);
        assertThat(storno.getReversalReason()).isEqualTo("\u00dcgyf\u00e9l lemondta");
        assertThat(original.getStatus()).isEqualTo(WuTransactionStatus.REVERSED);

        // save called twice: storno + original update
        verify(wuTransactionRepository, times(2)).save(any());
    }

    @Test
    void reverseWuTransaction_alreadyReversed_throws() {
        UUID originalId = UUID.randomUUID();
        WuTransaction original = WuTransaction.builder()
                .id(originalId)
                .branch(branch)
                .company(company)
                .transactionType("SEND")
                .status(WuTransactionStatus.REVERSED)
                .build();

        when(wuTransactionRepository.findById(originalId)).thenReturn(Optional.of(original));

        assertThatThrownBy(() -> service.reverseWuTransaction(originalId, "reason"))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("m\u00e1r sztorn\u00f3zva van");
    }

    @Test
    void reverseWuTransaction_stornoCannotBeReversed_throws() {
        UUID stornoId = UUID.randomUUID();
        WuTransaction storno = WuTransaction.builder()
                .id(stornoId)
                .branch(branch)
                .company(company)
                .transactionType("STORNO")
                .status(WuTransactionStatus.COMPLETED)
                .build();

        when(wuTransactionRepository.findById(stornoId)).thenReturn(Optional.of(storno));

        assertThatThrownBy(() -> service.reverseWuTransaction(stornoId, "reason"))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("Sztorn\u00f3 tranzakci\u00f3 nem sztorn\u00f3zhat\u00f3");
    }

    @Test
    void reverseWuTransaction_notFound_throws() {
        UUID missing = UUID.randomUUID();
        when(wuTransactionRepository.findById(missing)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.reverseWuTransaction(missing, "reason"))
                .isInstanceOf(ResourceNotFoundException.class);
    }

    // ============ findOrCreateWuCustomer DEDUPLICATION ============

    @Test
    void findOrCreateWuCustomer_existingReturned_noDuplicate() {
        WuCustomer existing = WuCustomer.builder()
                .id(UUID.randomUUID())
                .company(company)
                .lastName("Kov\u00e1cs")
                .firstName("J\u00e1nos")
                .idNumber("AB123456")
                .build();

        when(wuCustomerRepository.findByCompanyIdAndLastNameAndFirstNameAndIdNumber(
                companyId, "Kov\u00e1cs", "J\u00e1nos", "AB123456"))
                .thenReturn(Optional.of(existing));

        WuCustomer result = service.findOrCreateWuCustomer("Kov\u00e1cs", "J\u00e1nos", "PASSPORT", "AB123456");

        assertThat(result.getId()).isEqualTo(existing.getId());
        verify(wuCustomerRepository, never()).save(any());
    }

    @Test
    void findOrCreateWuCustomer_newCustomerCreated() {
        when(wuCustomerRepository.findByCompanyIdAndLastNameAndFirstNameAndIdNumber(
                companyId, "Nagy", "P\u00e9ter", "XY999"))
                .thenReturn(Optional.empty());
        when(companyRepository.findById(companyId)).thenReturn(Optional.of(company));
        when(wuCustomerRepository.save(any())).thenAnswer(inv -> {
            WuCustomer c = inv.getArgument(0);
            c = WuCustomer.builder()
                    .id(UUID.randomUUID())
                    .company(c.getCompany())
                    .lastName(c.getLastName())
                    .firstName(c.getFirstName())
                    .idNumber(c.getIdNumber())
                    .build();
            return c;
        });

        WuCustomer result = service.findOrCreateWuCustomer("Nagy", "P\u00e9ter", "ID_CARD", "XY999");

        assertThat(result.getId()).isNotNull();
        assertThat(result.getLastName()).isEqualTo("Nagy");
        verify(wuCustomerRepository).save(any());
    }

    @Test
    void findOrCreateWuCustomer_noDocumentNumber_alwaysCreatesNew() {
        when(companyRepository.findById(companyId)).thenReturn(Optional.of(company));
        when(wuCustomerRepository.save(any())).thenAnswer(inv -> {
            WuCustomer c = inv.getArgument(0);
            c = WuCustomer.builder()
                    .id(UUID.randomUUID())
                    .company(c.getCompany())
                    .lastName(c.getLastName())
                    .firstName(c.getFirstName())
                    .build();
            return c;
        });

        WuCustomer result = service.findOrCreateWuCustomer("Kiss", "\u00c9va", "ID_CARD", null);

        assertThat(result).isNotNull();
        verify(wuCustomerRepository, never()).findByCompanyIdAndLastNameAndFirstNameAndIdNumber(
                any(), any(), any(), any());
        verify(wuCustomerRepository).save(any());
    }

    // ============ AML BLOCK ============

    @Test
    void recordSend_amlBlocked_throws() {
        WuTransactionDto dto = WuTransactionDto.builder()
                .branchId(branchId)
                .mtcn("1234567890")
                .senderName("Blokkolt Szem\u00e9ly")
                .amountHuf(new BigDecimal("1000000"))
                .build();

        when(branchRepository.findById(branchId)).thenReturn(Optional.of(branch));
        when(amlService.checkTransaction(any(), any(), any(), any()))
                .thenReturn(AmlService.AmlBasicCheckResult.builder()
                        .approved(false)
                        .rejectionReason("Szankci\u00f3s lista tal\u00e1lat")
                        .build());

        assertThatThrownBy(() -> service.recordSend(dto))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("AML ellen\u0151rz\u00e9s megtagadta");
    }
}
