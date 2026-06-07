package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.vatrefund.CreateVatRefundRequest;
import hu.puzzleir.valuta.dto.vatrefund.VatRefundTransactionDto;
import hu.puzzleir.valuta.entity.VatRefundTransaction;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.CircularRepository;
import hu.puzzleir.valuta.repository.VatRefundTransactionRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.math.BigDecimal;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.contains;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.ArgumentMatchers.nullable;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Sztornó-audit: az ÁFA-visszatérítés sztornó/serial javításai (cégszintű DB-alapú sorszám,
 * cross-tenant 404, dupla-sztornó pessimistic lock, audit).
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class VatRefundServiceTest {

    @Mock private VatRefundTransactionRepository repo;
    @Mock private SystemParameterService systemParameterService;
    @Mock private CircularRepository circularRepository;
    @Mock private AuditLogService auditLogService;
    @InjectMocks private VatRefundService service;

    private static final UUID COMPANY = UUID.randomUUID();
    private static final UUID BRANCH = UUID.randomUUID();

    private VatRefundTransaction original(UUID companyId, boolean reversed) {
        return VatRefundTransaction.builder()
                .id(7L).companyId(companyId).branchId(BRANCH)
                .voucherType(VatRefundTransaction.VoucherType.AK)
                .serialNumber("AK-20260607-00001")
                .grossAmount(new BigDecimal("1270")).vatAmount(new BigDecimal("270"))
                .vatPercentage(new BigDecimal("27")).customerName("Teszt Ügyfél")
                .isReversed(reversed)
                .build();
    }

    @Test
    @DisplayName("create: cégszintű DB-alapú sorszám (TÍPUS-YYYYMMDD-NNNNN), MAX+1, + audit")
    void create_serialIsCompanyScopedDbBacked() {
        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY);
            sec.when(SecurityUtils::getCurrentWorkerCode).thenReturn("W1");
            sec.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH);
            when(repo.findMaxVatSerialForCompany(eq(COMPANY), anyString(), anyInt())).thenReturn(0L);
            when(repo.save(any())).thenAnswer(inv -> inv.getArgument(0));

            CreateVatRefundRequest req = CreateVatRefundRequest.builder()
                    .voucherType("AK").grossAmount(new BigDecimal("1270"))
                    .vatAmount(new BigDecimal("270")).vatPercentage(new BigDecimal("27"))
                    .customerName("Teszt Ügyfél").build();

            VatRefundTransactionDto dto = service.createVatRefund(req);

            assertThat(dto.getSerialNumber()).matches("AK-\\d{8}-00001");
            // A cégszintű MAX+1-et használja (NEM a régi static AtomicLong-ot).
            verify(repo).findMaxVatSerialForCompany(eq(COMPANY), anyString(), anyInt());
            verify(auditLogService).log(eq("VAT_REFUND_CREATED"), anyString(), nullable(Long.class));
        }
    }

    @Test
    @DisplayName("reverse: idegen cég tranzakciója → ResourceNotFoundException (404, nem 403-leak)")
    void reverse_crossTenant_404() {
        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(UUID.randomUUID());
            sec.when(SecurityUtils::getCurrentWorkerCode).thenReturn("W1");
            when(repo.findByIdForUpdate(7L)).thenReturn(Optional.of(original(COMPANY, false)));

            assertThatThrownBy(() -> service.reverseVatRefund(7L))
                    .isInstanceOf(ResourceNotFoundException.class);
            verify(repo, never()).save(any());
        }
    }

    @Test
    @DisplayName("reverse: már sztornózott → ValidationException")
    void reverse_alreadyReversed_throws() {
        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY);
            sec.when(SecurityUtils::getCurrentWorkerCode).thenReturn("W1");
            when(repo.findByIdForUpdate(7L)).thenReturn(Optional.of(original(COMPANY, true)));

            assertThatThrownBy(() -> service.reverseVatRefund(7L))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("már sztornózva");
            verify(repo, never()).save(any());
        }
    }

    @Test
    @DisplayName("reverse: pessimistic lock (findByIdForUpdate) + SZTORNO- sorszám + eredeti reversed + audit")
    void reverse_success_locksAuditsAndReverses() {
        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY);
            sec.when(SecurityUtils::getCurrentWorkerCode).thenReturn("W1");
            sec.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH);
            VatRefundTransaction orig = original(COMPANY, false);
            when(repo.findByIdForUpdate(7L)).thenReturn(Optional.of(orig));
            when(repo.save(any())).thenAnswer(inv -> inv.getArgument(0));

            VatRefundTransactionDto storno = service.reverseVatRefund(7L);

            assertThat(orig.getIsReversed()).isTrue();
            assertThat(storno.getSerialNumber()).isEqualTo("SZTORNO-AK-20260607-00001");
            assertThat(storno.getGrossAmount()).isEqualByComparingTo("-1270");
            // dupla-sztornó race elleni lock + audit
            verify(repo).findByIdForUpdate(7L);
            verify(auditLogService).log(eq("VAT_REFUND_STORNO"), contains("SZTORNO-"), nullable(Long.class));
        }
    }
}
