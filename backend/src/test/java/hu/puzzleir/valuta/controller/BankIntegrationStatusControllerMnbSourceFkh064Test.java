package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.bankapi.BankApiConfigDto;
import hu.puzzleir.valuta.entity.BankApiMode;
import hu.puzzleir.valuta.entity.BankApiRunStatus;
import hu.puzzleir.valuta.entity.DariusReportStatus;
import hu.puzzleir.valuta.repository.DariusDailyReportRepository;
import hu.puzzleir.valuta.repository.MnbExchangeRateCacheRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.service.BankApiConfigService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * FKH-064 (board #38) — the {@code mnb} block of the bank-integration status must describe the MNB
 * source only.
 *
 * <p>{@code mnb_exchange_rate_cache} is shared between rate sources (unique key
 * {@code currency_code, rate_date, source}). Production 2026-09-11: 17 MNB rows all frozen at
 * 2026-03-16 versus 705 RAIFFEISEN rows up to 2026-09-11. The unfiltered {@code findAll()} /
 * {@code count()} reads therefore reported {@code rateCount=722},
 * {@code lastFetchDate=2026-09-11} and {@code lastFetchSuccess=true} — the freshness signal was
 * inverted by rows of another source.</p>
 *
 * <p>RED before the fix: {@code mnbStatusCountsOnlyMnbSourceRows} and
 * {@code staleMnbCacheIsNotFreshEvenWithNewerForeignSourceRows} fail, because the controller reads
 * the whole table. {@code freshMnbRowIsStillReportedFresh} pins that the fix does not over-correct
 * into always-false.</p>
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class BankIntegrationStatusControllerMnbSourceFkh064Test {

    private static final String MNB_SOURCE = "MNB";

    @Mock
    private MnbExchangeRateCacheRepository mnbCacheRepository;

    @Mock
    private DariusDailyReportRepository dariusReportRepository;

    @Mock
    private BankApiConfigService bankApiConfigService;

    @InjectMocks
    private BankIntegrationStatusController controller;

    private final UUID companyId = UUID.randomUUID();

    private void stubNonMnbCollaborators() {
        when(dariusReportRepository.findByCompanyIdAndStatusAndReportDateBetween(
                any(), any(DariusReportStatus.class), any(), any()))
                .thenReturn(List.of());
        when(dariusReportRepository.findByCompanyIdAndStatusOrderByReportDateDesc(
                any(), any(DariusReportStatus.class)))
                .thenReturn(List.of());
        when(bankApiConfigService.getDto(BankApiConfigService.PROVIDER_RAIFFEISEN))
                .thenReturn(BankApiConfigDto.builder()
                        .providerName(BankApiConfigService.PROVIDER_RAIFFEISEN)
                        .mode(BankApiMode.DISABLED)
                        .enabled(false)
                        .lastRunStatus(BankApiRunStatus.NEVER_RUN)
                        .build());
    }

    private BankIntegrationStatusController.BankIntegrationStatusResponse callStatus() {
        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
            return controller.getStatus();
        }
    }

    @Test
    @DisplayName("FKH-064: rateCount and lastFetchDate come from source='MNB' rows only")
    void mnbStatusCountsOnlyMnbSourceRows() {
        stubNonMnbCollaborators();
        when(mnbCacheRepository.countBySource(MNB_SOURCE)).thenReturn(17L);
        when(mnbCacheRepository.findMaxRateDateBySource(MNB_SOURCE))
                .thenReturn(Optional.of(LocalDate.of(2026, 3, 16)));

        var response = callStatus();

        assertThat(response.getMnb().getRateCount()).isEqualTo(17);
        assertThat(response.getMnb().getLastFetchDate()).isEqualTo(LocalDate.of(2026, 3, 16));
        // The shared table must never be read unfiltered on the MNB path.
        verify(mnbCacheRepository, never()).findAll();
        verify(mnbCacheRepository, never()).count();
    }

    @Test
    @DisplayName("FKH-064: a stale MNB cache is not fresh even when another source has newer rows")
    void staleMnbCacheIsNotFreshEvenWithNewerForeignSourceRows() {
        stubNonMnbCollaborators();
        // MNB frozen 10 days ago; RAIFFEISEN rows exist for today but must not be considered.
        when(mnbCacheRepository.countBySource(MNB_SOURCE)).thenReturn(17L);
        when(mnbCacheRepository.findMaxRateDateBySource(MNB_SOURCE))
                .thenReturn(Optional.of(LocalDate.now().minusDays(10)));

        var response = callStatus();

        assertThat(response.getMnb().getLastFetchSuccess()).isFalse();
    }

    @Test
    @DisplayName("FKH-064: a fresh MNB row is still reported fresh (no over-correction)")
    void freshMnbRowIsStillReportedFresh() {
        stubNonMnbCollaborators();
        when(mnbCacheRepository.countBySource(MNB_SOURCE)).thenReturn(20L);
        when(mnbCacheRepository.findMaxRateDateBySource(MNB_SOURCE))
                .thenReturn(Optional.of(LocalDate.now()));

        var response = callStatus();

        assertThat(response.getMnb().getLastFetchSuccess()).isTrue();
        assertThat(response.getMnb().getRateCount()).isEqualTo(20);
    }

    @Test
    @DisplayName("FKH-064: an empty MNB cache is not fresh and reports zero rows")
    void emptyMnbCacheIsNotFresh() {
        stubNonMnbCollaborators();
        when(mnbCacheRepository.countBySource(eq(MNB_SOURCE))).thenReturn(0L);
        when(mnbCacheRepository.findMaxRateDateBySource(eq(MNB_SOURCE))).thenReturn(Optional.empty());

        var response = callStatus();

        assertThat(response.getMnb().getRateCount()).isZero();
        assertThat(response.getMnb().getLastFetchDate()).isNull();
        assertThat(response.getMnb().getLastFetchSuccess()).isFalse();
    }
}
