package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.ExchangeRate;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.repository.ExchangeRateRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import java.math.BigDecimal;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.contains;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

/**
 * FKH-067 (spec doc: FKH-063) — exchange-rate TTL made non-blocking for transactions
 * created on the client AFTER the TTL_NONBLOCKING_CUTOFF system parameter.
 *
 * Doc-to-code numbering note: the doc id "FKH-063" is already taken in code by
 * V391__fkh063_decade_line_rate_source.sql, the doc series runs 4 behind the code series.
 *
 * FR-2 (cutoff branching), FR-3 (safe default), FR-4 (audit event), FR-5 (stuck items stay blocked)
 * plus the TBD-2 server-side plausibility check for a future-dated client timestamp.
 */
@ExtendWith(MockitoExtension.class)
class ExchangeRateStaleRateFkh067Test {

    @Mock private ExchangeRateRepository exchangeRateRepository;
    @Mock private CurrencyRepository currencyRepository;
    @Mock private CompanyRepository companyRepository;
    @Mock private BranchRepository branchRepository;
    @Mock private SystemParameterService systemParameterService;
    @Mock private AuditLogService auditLogService;
    @InjectMocks private ExchangeRateService service;

    private static final UUID COMPANY_ID = UUID.randomUUID();
    private static final UUID BRANCH_ID = UUID.randomUUID();
    private static final long EUR_ID = 4L;

    /** Cutoff 10 days ago — everything is expressed relative to it, so the fixture never ages out. */
    private static final Instant CUTOFF = Instant.now().minus(Duration.ofDays(10));
    private static final Instant AFTER_CUTOFF = CUTOFF.plus(Duration.ofDays(1));
    private static final Instant BEFORE_CUTOFF = CUTOFF.minus(Duration.ofDays(1));

    private ExchangeRate staleRate() {
        // ~100 days old, exactly the live incident (EUR rate not refreshed, 720h limit exceeded).
        LocalDateTime validAt = LocalDateTime.now().minusDays(100);
        return ExchangeRate.builder()
                .id(1L)
                .currency(Currency.builder().id(EUR_ID).code("EUR").build())
                .baseBuyRate(new BigDecimal("395.50"))
                .baseSellRate(new BigDecimal("405.50"))
                .validDate(validAt.toLocalDate())
                .validTime(validAt.toLocalTime())
                .build();
    }

    private ExchangeRate freshRate() {
        return ExchangeRate.builder()
                .id(2L)
                .currency(Currency.builder().id(EUR_ID).code("EUR").build())
                .baseBuyRate(new BigDecimal("395.50"))
                .baseSellRate(new BigDecimal("405.50"))
                .validDate(LocalDate.now())
                .validTime(LocalTime.now().minusHours(1))
                .build();
    }

    private void arrange(ExchangeRate rate) {
        ReflectionTestUtils.setField(service, "maxAgeHours", 720);
        when(exchangeRateRepository.findLatestRate(COMPANY_ID, EUR_ID, BRANCH_ID))
                .thenReturn(Optional.of(rate));
    }

    private void cutoffParameter(String value) {
        when(systemParameterService.findEffectiveValue(ExchangeRateService.TTL_NONBLOCKING_CUTOFF_KEY))
                .thenReturn(Optional.ofNullable(value));
    }

    private MockedStatic<SecurityUtils> securityContext() {
        MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class);
        su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
        su.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);
        return su;
    }

    @Test
    @DisplayName("FR-2: stale rate + post-cutoff client timestamp -> does NOT block")
    void staleRateAfterCutoffIsNotBlocking() {
        arrange(staleRate());
        cutoffParameter(DateTimeFormatter.ISO_INSTANT.format(CUTOFF));

        try (MockedStatic<SecurityUtils> su = securityContext()) {
            assertThatCode(() -> service.getCurrentRate(EUR_ID, AFTER_CUTOFF)).doesNotThrowAnyException();
        }
    }

    @Test
    @DisplayName("FR-4: the non-blocking branch writes a STALE_RATE_TRANSACTION_COMMITTED audit with the rate age")
    void nonBlockingBranchWritesAuditEvent() {
        arrange(staleRate());
        cutoffParameter(DateTimeFormatter.ISO_INSTANT.format(CUTOFF));

        try (MockedStatic<SecurityUtils> su = securityContext()) {
            service.getCurrentRate(EUR_ID, AFTER_CUTOFF);
        }

        verify(auditLogService, times(1)).log(
                eq(ExchangeRateService.AUDIT_STALE_RATE_TRANSACTION_COMMITTED),
                contains("EUR"),
                anyString());
    }

    @Test
    @DisplayName("FR-2/FR-5: pre-cutoff client timestamp -> still blocks, no audit")
    void staleRateBeforeCutoffStillBlocks() {
        arrange(staleRate());
        cutoffParameter(DateTimeFormatter.ISO_INSTANT.format(CUTOFF));

        try (MockedStatic<SecurityUtils> su = securityContext()) {
            assertThatThrownBy(() -> service.getCurrentRate(EUR_ID, BEFORE_CUTOFF))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("Az árfolyam lejárt!");
        }
        verifyNoInteractions(auditLogService);
    }

    @Test
    @DisplayName("FR-2: missing client timestamp (older client version) -> fail-closed, blocks")
    void missingClientTimestampIsFailClosed() {
        arrange(staleRate());
        // No cutoff stub: a missing timestamp blocks BEFORE the parameter is read (short circuit),
        // asserted by verify(never()) - the cutoff value cannot influence the outcome.

        try (MockedStatic<SecurityUtils> su = securityContext()) {
            assertThatThrownBy(() -> service.getCurrentRate(EUR_ID, null))
                    .isInstanceOf(ValidationException.class);
        }
        verifyNoInteractions(auditLogService);
        verify(systemParameterService, never()).findEffectiveValue(anyString());
    }

    @Test
    @DisplayName("FR-3: unset TTL_NONBLOCKING_CUTOFF -> every transaction blocks (safe default)")
    void missingCutoffParameterBlocksEverything() {
        arrange(staleRate());
        cutoffParameter(null);

        try (MockedStatic<SecurityUtils> su = securityContext()) {
            assertThatThrownBy(() -> service.getCurrentRate(EUR_ID, AFTER_CUTOFF))
                    .isInstanceOf(ValidationException.class);
        }
        verifyNoInteractions(auditLogService);
    }

    @Test
    @DisplayName("FR-3: unparsable cutoff value -> fail-closed, blocks")
    void unparsableCutoffParameterBlocks() {
        arrange(staleRate());
        cutoffParameter("nem-datum");

        try (MockedStatic<SecurityUtils> su = securityContext()) {
            assertThatThrownBy(() -> service.getCurrentRate(EUR_ID, AFTER_CUTOFF))
                    .isInstanceOf(ValidationException.class);
        }
        verifyNoInteractions(auditLogService);
    }

    @Test
    @DisplayName("TBD-2: future client timestamp (manipulated client) -> no exemption, blocks")
    void futureClientTimestampIsRejected() {
        arrange(staleRate());
        // No cutoff stub: the plausibility check decides BEFORE the parameter is read (short
        // circuit), so a manipulated future timestamp is never exempt for any cutoff value.

        Instant implausibleFuture = Instant.now().plus(Duration.ofDays(1));
        try (MockedStatic<SecurityUtils> su = securityContext()) {
            assertThatThrownBy(() -> service.getCurrentRate(EUR_ID, implausibleFuture))
                    .isInstanceOf(ValidationException.class);
        }
        verifyNoInteractions(auditLogService);
        verify(systemParameterService, never()).findEffectiveValue(anyString());
    }

    @Test
    @DisplayName("NFR-5: fresh rate -> unchanged path, no cutoff lookup and no audit")
    void freshRateIsUntouched() {
        arrange(freshRate());

        try (MockedStatic<SecurityUtils> su = securityContext()) {
            assertThatCode(() -> service.getCurrentRate(EUR_ID, AFTER_CUTOFF)).doesNotThrowAnyException();
        }
        verifyNoInteractions(auditLogService);
        verify(systemParameterService, never()).findEffectiveValue(anyString());
    }

    @Test
    @DisplayName("FR-5 regression: the stuck V020000002/003 (pre-cutoff recording) is still not booked")
    void stuckLiveItemsStayBlocked() {
        arrange(staleRate());
        // Live cutoff shape: an operator sets it to the rollout instant; the stuck items were
        // recorded on 2026-09-11, i.e. before it.
        Instant rollout = LocalDateTime.of(2026, 9, 12, 6, 0).atZone(ZoneId.systemDefault()).toInstant();
        Instant stuckItemCreatedAt = LocalDateTime.of(2026, 9, 11, 14, 30).atZone(ZoneId.systemDefault()).toInstant();
        cutoffParameter(DateTimeFormatter.ISO_INSTANT.format(rollout));

        try (MockedStatic<SecurityUtils> su = securityContext()) {
            assertThatThrownBy(() -> service.getCurrentRate(EUR_ID, stuckItemCreatedAt))
                    .isInstanceOf(ValidationException.class);
        }
        verifyNoInteractions(auditLogService);
    }
}
