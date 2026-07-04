package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.ExchangeRateDistribution;
import hu.puzzleir.valuta.entity.ExchangeRateDistribution.DistributionStatus;
import hu.puzzleir.valuta.entity.ExchangeRateMaster;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.repository.ExchangeRateDistributionRepository;
import hu.puzzleir.valuta.repository.ExchangeRateMasterRepository;
import hu.puzzleir.valuta.repository.ExchangeRateRepository;
import hu.puzzleir.valuta.repository.RateWorkgroupRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.messaging.simp.SimpMessagingTemplate;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class ExchangeRateMasterServicePrintTest {

    private static final UUID COMPANY_ID = UUID.fromString("aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa");
    private static final UUID OTHER_COMPANY_ID = UUID.fromString("bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb");
    private static final UUID BRANCH_ID = UUID.fromString("cccccccc-cccc-cccc-cccc-cccccccccccc");
    private static final UUID OTHER_BRANCH_ID = UUID.fromString("dddddddd-dddd-dddd-dddd-dddddddddddd");
    private static final UUID MASTER_ID = UUID.fromString("eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee");
    private static final UUID DISTRIBUTION_ID = UUID.fromString("ffffffff-ffff-ffff-ffff-ffffffffffff");
    private static final Long WORKER_ID = 42L;

    @Mock private ExchangeRateMasterRepository masterRepository;
    @Mock private ExchangeRateDistributionRepository distributionRepository;
    @Mock private ExchangeRateRepository exchangeRateRepository;
    @Mock private CurrencyRepository currencyRepository;
    @Mock private CompanyRepository companyRepository;
    @Mock private BranchRepository branchRepository;
    @Mock private RateWorkgroupRepository workgroupRepository;
    @Mock private SimpMessagingTemplate messagingTemplate;
    @Mock private AuditLogService auditLogService;
    @Mock private RatePrintProofService ratePrintProofService;

    @InjectMocks private ExchangeRateMasterService service;

    @Test
    @DisplayName("acknowledgeDistribution token nélkül fail-closed: ValidationException és nincs mentés")
    void acknowledgeDistributionRejectsMissingProofTokenWithoutMutation() {
        ExchangeRateDistribution dist = distribution(DistributionStatus.DISTRIBUTED, BRANCH_ID);
        ExchangeRateMaster master = master(COMPANY_ID);
        when(distributionRepository.findById(DISTRIBUTION_ID)).thenReturn(Optional.of(dist));
        when(masterRepository.findById(MASTER_ID)).thenReturn(Optional.of(master));

        try (MockedStatic<SecurityUtils> su = security("CASHIER", BRANCH_ID)) {
            assertThatThrownBy(() -> service.acknowledgeDistribution(DISTRIBUTION_ID, null))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("Proof-of-Print");
        }

        verify(distributionRepository, never()).save(any());
        verify(auditLogService, never()).log(eq("RATE_PRINT_CONFIRM"), anyString(), anyString());
    }

    @Test
    @DisplayName("acknowledgeDistribution hibás tokennel fail-closed: ValidationException és nincs mentés")
    void acknowledgeDistributionRejectsInvalidProofTokenWithoutMutation() {
        ExchangeRateDistribution dist = distribution(DistributionStatus.DISTRIBUTED, BRANCH_ID);
        ExchangeRateMaster master = master(COMPANY_ID);
        when(distributionRepository.findById(DISTRIBUTION_ID)).thenReturn(Optional.of(dist));
        when(masterRepository.findById(MASTER_ID)).thenReturn(Optional.of(master));
        when(ratePrintProofService.verifyToken("rossz-token", DISTRIBUTION_ID, BRANCH_ID, MASTER_ID, COMPANY_ID)).thenReturn(false);

        try (MockedStatic<SecurityUtils> su = security("CASHIER", BRANCH_ID)) {
            assertThatThrownBy(() -> service.acknowledgeDistribution(DISTRIBUTION_ID, "rossz-token"))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("Proof-of-Print");
        }

        verify(distributionRepository, never()).save(any());
        verify(auditLogService, never()).log(eq("RATE_PRINT_CONFIRM"), anyString(), anyString());
    }

    @Test
    @DisplayName("acknowledgeDistribution érvényes tokennel ACKNOWLEDGED-re állít, nyomtatási auditmezőkkel")
    void acknowledgeDistributionAcceptsValidProofToken() {
        ExchangeRateDistribution dist = distribution(DistributionStatus.DISTRIBUTED, BRANCH_ID);
        ExchangeRateMaster master = master(COMPANY_ID);
        when(distributionRepository.findById(DISTRIBUTION_ID)).thenReturn(Optional.of(dist));
        when(masterRepository.findById(MASTER_ID)).thenReturn(Optional.of(master));
        when(ratePrintProofService.verifyToken("valid-token", DISTRIBUTION_ID, BRANCH_ID, MASTER_ID, COMPANY_ID)).thenReturn(true);

        try (MockedStatic<SecurityUtils> su = security("CASHIER", BRANCH_ID)) {
            service.acknowledgeDistribution(DISTRIBUTION_ID, "valid-token");
        }

        assertThat(dist.getStatus()).isEqualTo(DistributionStatus.ACKNOWLEDGED);
        assertThat(dist.getAcknowledgedAt()).isNotNull();
        assertThat(dist.getPrintedAt()).isNotNull();
        assertThat(dist.getPrintedBy()).isEqualTo(WORKER_ID);
        verify(distributionRepository).save(dist);
        verify(auditLogService).log(eq("RATE_PRINT_CONFIRM"), anyString(), eq(DISTRIBUTION_ID.toString()));
    }

    @Test
    @DisplayName("acknowledgeDistribution már ACKNOWLEDGED + érvényes token esetén idempotens no-op")
    void acknowledgeDistributionIsIdempotentForAlreadyAcknowledgedValidToken() {
        LocalDateTime originalPrintedAt = LocalDateTime.parse("2026-07-04T10:15:30");
        LocalDateTime originalAcknowledgedAt = LocalDateTime.parse("2026-07-04T10:15:31");
        ExchangeRateDistribution dist = distribution(DistributionStatus.ACKNOWLEDGED, BRANCH_ID);
        dist.setPrintedAt(originalPrintedAt);
        dist.setAcknowledgedAt(originalAcknowledgedAt);
        dist.setPrintedBy(7L);
        ExchangeRateMaster master = master(COMPANY_ID);
        when(distributionRepository.findById(DISTRIBUTION_ID)).thenReturn(Optional.of(dist));
        when(masterRepository.findById(MASTER_ID)).thenReturn(Optional.of(master));
        when(ratePrintProofService.verifyToken("valid-token", DISTRIBUTION_ID, BRANCH_ID, MASTER_ID, COMPANY_ID)).thenReturn(true);

        try (MockedStatic<SecurityUtils> su = security("CASHIER", BRANCH_ID)) {
            service.acknowledgeDistribution(DISTRIBUTION_ID, "valid-token");
        }

        assertThat(dist.getPrintedAt()).isEqualTo(originalPrintedAt);
        assertThat(dist.getAcknowledgedAt()).isEqualTo(originalAcknowledgedAt);
        assertThat(dist.getPrintedBy()).isEqualTo(7L);
        verify(distributionRepository, never()).save(any());
        verify(auditLogService, never()).log(eq("RATE_PRINT_CONFIRM"), anyString(), anyString());
    }

    @Test
    @DisplayName("acknowledgeDistribution FAILED státuszú elosztást nem igazol vissza")
    void acknowledgeDistributionRejectsFailedDistribution() {
        ExchangeRateDistribution dist = distribution(DistributionStatus.FAILED, BRANCH_ID);
        ExchangeRateMaster master = master(COMPANY_ID);
        when(distributionRepository.findById(DISTRIBUTION_ID)).thenReturn(Optional.of(dist));
        when(masterRepository.findById(MASTER_ID)).thenReturn(Optional.of(master));
        when(ratePrintProofService.verifyToken("valid-token", DISTRIBUTION_ID, BRANCH_ID, MASTER_ID, COMPANY_ID)).thenReturn(true);

        try (MockedStatic<SecurityUtils> su = security("CASHIER", BRANCH_ID)) {
            assertThatThrownBy(() -> service.acknowledgeDistribution(DISTRIBUTION_ID, "valid-token"))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("FAILED");
        }

        verify(distributionRepository, never()).save(any());
    }

    @Test
    @DisplayName("acknowledgeDistribution cross-tenant elosztás létezését sem szivárogtatja")
    void acknowledgeDistributionRejectsCrossTenantAsNotFound() {
        ExchangeRateDistribution dist = distribution(DistributionStatus.DISTRIBUTED, BRANCH_ID);
        ExchangeRateMaster master = master(OTHER_COMPANY_ID);
        when(distributionRepository.findById(DISTRIBUTION_ID)).thenReturn(Optional.of(dist));
        when(masterRepository.findById(MASTER_ID)).thenReturn(Optional.of(master));

        try (MockedStatic<SecurityUtils> su = security("CASHIER", BRANCH_ID)) {
            assertThatThrownBy(() -> service.acknowledgeDistribution(DISTRIBUTION_ID, "valid-token"))
                    .isInstanceOf(ResourceNotFoundException.class);
        }

        verify(ratePrintProofService, never()).verifyToken(anyString(), any(), any(), any(), any());
        verify(distributionRepository, never()).save(any());
    }

    @Test
    @DisplayName("acknowledgeDistribution nem-admin hívónál branch-kötött")
    void acknowledgeDistributionRejectsNonAdminOtherBranch() {
        ExchangeRateDistribution dist = distribution(DistributionStatus.DISTRIBUTED, BRANCH_ID);
        ExchangeRateMaster master = master(COMPANY_ID);
        when(distributionRepository.findById(DISTRIBUTION_ID)).thenReturn(Optional.of(dist));
        when(masterRepository.findById(MASTER_ID)).thenReturn(Optional.of(master));

        try (MockedStatic<SecurityUtils> su = security("CASHIER", OTHER_BRANCH_ID)) {
            assertThatThrownBy(() -> service.acknowledgeDistribution(DISTRIBUTION_ID, "valid-token"))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("branch");
        }

        verify(ratePrintProofService, never()).verifyToken(anyString(), any(), any(), any(), any());
        verify(distributionRepository, never()).save(any());
    }

    @Test
    @DisplayName("acknowledgeDistribution főértéktár/admin szerepben branch-felmentést ad")
    void acknowledgeDistributionAllowsPrivilegedRoleOtherBranch() {
        ExchangeRateDistribution dist = distribution(DistributionStatus.DISTRIBUTED, BRANCH_ID);
        ExchangeRateMaster master = master(COMPANY_ID);
        when(distributionRepository.findById(DISTRIBUTION_ID)).thenReturn(Optional.of(dist));
        when(masterRepository.findById(MASTER_ID)).thenReturn(Optional.of(master));
        when(ratePrintProofService.verifyToken("valid-token", DISTRIBUTION_ID, BRANCH_ID, MASTER_ID, COMPANY_ID)).thenReturn(true);

        try (MockedStatic<SecurityUtils> su = security("FOERTEKTAR", OTHER_BRANCH_ID)) {
            service.acknowledgeDistribution(DISTRIBUTION_ID, "valid-token");
        }

        verify(distributionRepository).save(dist);
    }

    @Test
    @DisplayName("getPendingPrintObligations csak DISTRIBUTED tételeket ad vissza tokennel")
    void getPendingPrintObligationsReturnsDistributedItemsWithToken() {
        ExchangeRateDistribution dist = distribution(DistributionStatus.DISTRIBUTED, BRANCH_ID);
        ExchangeRateMaster master = master(COMPANY_ID);
        Currency eur = Currency.builder().id(4L).code("EUR").build();
        when(distributionRepository.findByBranchIdAndStatus(BRANCH_ID, DistributionStatus.DISTRIBUTED)).thenReturn(List.of(dist));
        when(masterRepository.findById(MASTER_ID)).thenReturn(Optional.of(master));
        when(currencyRepository.findById(4L)).thenReturn(Optional.of(eur));
        when(ratePrintProofService.issueToken(DISTRIBUTION_ID, BRANCH_ID, MASTER_ID, COMPANY_ID)).thenReturn("print-token");

        try (MockedStatic<SecurityUtils> su = security("CASHIER", BRANCH_ID)) {
            List<ExchangeRateMasterService.PendingPrintObligation> result = service.getPendingPrintObligations();

            assertThat(result).hasSize(1);
            ExchangeRateMasterService.PendingPrintObligation obligation = result.get(0);
            assertThat(obligation.getDistributionId()).isEqualTo(DISTRIBUTION_ID);
            assertThat(obligation.getMasterRateId()).isEqualTo(MASTER_ID);
            assertThat(obligation.getCurrencyCode()).isEqualTo("EUR");
            assertThat(obligation.getVersionNumber()).isEqualTo(3);
            assertThat(obligation.getBaseBuyRate()).isEqualByComparingTo("390.10");
            assertThat(obligation.getBaseSellRate()).isEqualByComparingTo("401.20");
            assertThat(obligation.getPrintProofToken()).isEqualTo("print-token");
        }
    }

    private static MockedStatic<SecurityUtils> security(String role, UUID branchId) {
        MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class);
        su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
        su.when(SecurityUtils::getCurrentWorkerId).thenReturn(WORKER_ID);
        su.when(SecurityUtils::getCurrentBranchIdOrNull).thenReturn(branchId);
        su.when(SecurityUtils::getCurrentRole).thenReturn(role);
        return su;
    }

    private static ExchangeRateDistribution distribution(DistributionStatus status, UUID branchId) {
        return ExchangeRateDistribution.builder()
                .id(DISTRIBUTION_ID)
                .masterRateId(MASTER_ID)
                .branchId(branchId)
                .status(status)
                .build();
    }

    private static ExchangeRateMaster master(UUID companyId) {
        return ExchangeRateMaster.builder()
                .id(MASTER_ID)
                .companyId(companyId)
                .currencyId(4L)
                .baseBuyRate(new BigDecimal("390.10"))
                .baseSellRate(new BigDecimal("401.20"))
                .officialRate(new BigDecimal("395.50"))
                .limit1Amount(new BigDecimal("1000"))
                .limit1BuyRate(new BigDecimal("389.00"))
                .limit1SellRate(new BigDecimal("402.00"))
                .versionNumber(3)
                .validFrom(LocalDateTime.parse("2026-07-04T09:00:00"))
                .createdBy(WORKER_ID)
                .build();
    }
}
