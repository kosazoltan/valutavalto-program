package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.mnbsettlement.MnbQueryRateDto;
import hu.puzzleir.valuta.dto.mnbsettlement.MnbSettlementRateDto;
import hu.puzzleir.valuta.dto.mnbsettlement.MnbSettlementRateUpdateRequest;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.MnbSettlementRate;
import hu.puzzleir.valuta.exception.BusinessException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.repository.MnbSettlementRateHistoryRepository;
import hu.puzzleir.valuta.repository.MnbSettlementRateRepository;
import hu.puzzleir.valuta.security.WorkerAuthenticationDetails;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.authentication.TestingAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class MnbSettlementRateServiceTest {

    private static final UUID COMPANY_ID = UUID.fromString("00000000-0000-0000-0000-000000000111");
    private static final UUID BRANCH_ID = UUID.fromString("00000000-0000-0000-0000-000000000222");

    @Mock
    private MnbSettlementRateRepository rateRepository;
    @Mock
    private MnbSettlementRateHistoryRepository historyRepository;
    @Mock
    private CurrencyRepository currencyRepository;
    @Mock
    private AuditLogService auditLogService;
    @Mock
    private MnbRateQueryClient mnbRateQueryClient;

    @InjectMocks
    private MnbSettlementRateService service;

    @AfterEach
    void clearSecurityContext() {
        SecurityContextHolder.clearContext();
    }

    @Test
    @DisplayName("lista: aktív valuták displayOrder szerint, hiányzó sor 0, HUF hiányzó sor 1.0000, read-only")
    void list_returnsActiveCurrenciesWithDefaultsWithoutCreatingRows() {
        installAuth("BELSO_ELLENOR", "ELLENOR01");
        Currency huf = currency("HUF", "Forint", 1);
        Currency eur = currency("EUR", "Euro", 2);
        Instant publishedAt = Instant.parse("2026-07-09T10:15:30Z");
        when(currencyRepository.findByActiveTrueOrderByDisplayOrderAsc()).thenReturn(List.of(huf, eur));
        when(rateRepository.findByCompanyId(COMPANY_ID)).thenReturn(List.of(
                MnbSettlementRate.builder()
                        .companyId(COMPANY_ID)
                        .currencyCode("EUR")
                        .officialRate(new BigDecimal("399.1234"))
                        .availableToOfficesAt(publishedAt)
                        .build()));

        List<MnbSettlementRateDto> rows = service.list();

        assertThat(rows).extracting(MnbSettlementRateDto::currencyCode).containsExactly("HUF", "EUR");
        assertThat(rows.get(0).officialRate()).isEqualByComparingTo("1.0000");
        assertThat(rows.get(1).officialRate()).isEqualByComparingTo("399.1234");
        assertThat(rows.get(1).availableToOfficesAt()).isEqualTo(publishedAt);
        verify(rateRepository, never()).save(any());
        verifyNoInteractions(historyRepository, auditLogService);
    }

    @Test
    @DisplayName("update: BELSO_ELLENOR 403 + ACCESS_DENIED audit REQUIRES_NEW-ban")
    void update_deniesBelsoEllenorAndAuditsAccessDenied() {
        installAuth("BELSO_ELLENOR", "ELLENOR01");

        assertThatThrownBy(() -> service.update(request(item("EUR", "400.0000")), false))
                .isInstanceOf(AccessDeniedException.class)
                .hasMessageContaining("VV-AUTH-001");

        verify(auditLogService).logInNewTransaction(
                eq("ACCESS_DENIED"), eq("MnbSettlementRate"), eq("UPDATE"),
                eq("1"), eq(null), eq(null), eq(null),
                org.mockito.ArgumentMatchers.contains("VV-AUTH-001"));
        verify(rateRepository, never()).save(any());
        verifyNoInteractions(historyRepository);
    }

    @Test
    @DisplayName("publish: UGYVEZETO 403 + ACCESS_DENIED audit REQUIRES_NEW-ban")
    void publish_deniesUgyvezetoAndAuditsAccessDenied() {
        installAuth("UGYVEZETO", "UGYV01");

        assertThatThrownBy(() -> service.update(request(), true))
                .isInstanceOf(AccessDeniedException.class)
                .hasMessageContaining("VV-AUTH-001");

        verify(auditLogService).logInNewTransaction(
                eq("ACCESS_DENIED"), eq("MnbSettlementRate"), eq("PUBLISH"),
                eq("1"), eq(null), eq(null), eq(null),
                org.mockito.ArgumentMatchers.contains("UGYVEZETO"));
        verify(rateRepository, never()).save(any());
        verifyNoInteractions(historyRepository);
    }

    @Test
    @DisplayName("update: HUF payload invalid → nulla rate/history/update-audit írás")
    void update_rejectsHufPayloadBeforeAnyWrite() {
        installAuth("FOERTEKTAR", "FO01");
        when(currencyRepository.findByActiveTrueOrderByDisplayOrderAsc()).thenReturn(List.of(
                currency("HUF", "Forint", 1), currency("EUR", "Euro", 2)));

        assertThatThrownBy(() -> service.update(request(item("HUF", "1.0000")), false))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("HUF");

        verify(rateRepository, never()).save(any());
        verify(historyRepository, never()).save(any());
        verify(auditLogService, never()).logWithDetails(any(), any(), any(), any(), any(), any(), any(), any(), any(), any(), any());
    }

    @Test
    @DisplayName("update: ismeretlen/inaktív valuta invalid → nulla rate/history/update-audit írás")
    void update_rejectsUnknownCurrencyBeforeAnyWrite() {
        installAuth("FOERTEKTAR", "FO01");
        when(currencyRepository.findByActiveTrueOrderByDisplayOrderAsc()).thenReturn(List.of(
                currency("HUF", "Forint", 1), currency("EUR", "Euro", 2)));

        assertThatThrownBy(() -> service.update(request(item("USD", "350.0000")), false))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("USD");

        verify(rateRepository, never()).save(any());
        verify(historyRepository, never()).save(any());
        verify(auditLogService, never()).logWithDetails(any(), any(), any(), any(), any(), any(), any(), any(), any(), any(), any());
    }

    @Test
    @DisplayName("update: FOERTEKTAR módosítás sort ment, UPDATE/RATE auditot ír és teljes snapshotot készít")
    void update_savesRowsAuditsAndCreatesFullSnapshot() {
        installAuth("FOERTEKTAR", "FO01");
        Currency huf = currency("HUF", "Forint", 1);
        Currency eur = currency("EUR", "Euro", 2);
        when(currencyRepository.findByActiveTrueOrderByDisplayOrderAsc()).thenReturn(List.of(huf, eur));
        when(rateRepository.findByCompanyId(COMPANY_ID)).thenReturn(List.of(
                MnbSettlementRate.builder()
                        .companyId(COMPANY_ID)
                        .currencyCode("HUF")
                        .officialRate(new BigDecimal("1.0000"))
                        .build(),
                MnbSettlementRate.builder()
                        .companyId(COMPANY_ID)
                        .currencyCode("EUR")
                        .officialRate(new BigDecimal("399.0000"))
                        .build()));
        when(rateRepository.findByCompanyIdAndCurrencyCode(COMPANY_ID, "EUR")).thenReturn(Optional.of(
                MnbSettlementRate.builder()
                        .companyId(COMPANY_ID)
                        .currencyCode("EUR")
                        .officialRate(new BigDecimal("399.0000"))
                        .build()));
        when(rateRepository.save(any())).thenAnswer(invocation -> invocation.getArgument(0));
        when(historyRepository.save(any())).thenAnswer(invocation -> invocation.getArgument(0));

        service.update(request(item("EUR", "401.2500")), false);

        ArgumentCaptor<MnbSettlementRate> saved = ArgumentCaptor.forClass(MnbSettlementRate.class);
        verify(rateRepository).save(saved.capture());
        assertThat(saved.getValue().getOfficialRate()).isEqualByComparingTo("401.2500");
        assertThat(saved.getValue().getUpdatedBy()).isEqualTo("FO01");
        verify(auditLogService).logWithDetails(
                eq("UPDATE"), eq("MnbSettlementRate"), eq("EUR"), eq("1"), eq(null), eq(null), eq(null),
                org.mockito.ArgumentMatchers.contains("\"KAT\":\"RATE\""),
                org.mockito.ArgumentMatchers.contains("401.2500"),
                eq("Rögzítés"), eq(null));
        verify(historyRepository, org.mockito.Mockito.times(2)).save(any());
    }

    @Test
    @DisplayName("update: kiválasztott canonical foertektar activeRole legacy MANAGER mellett is írhat")
    void update_allowsSelectedCanonicalFoertektarActiveRole() {
        installAuth("MANAGER", "foertektar", "FO01");
        Currency huf = currency("HUF", "Forint", 1);
        Currency eur = currency("EUR", "Euro", 2);
        when(currencyRepository.findByActiveTrueOrderByDisplayOrderAsc()).thenReturn(List.of(huf, eur));
        when(rateRepository.findByCompanyId(COMPANY_ID)).thenReturn(List.of(
                MnbSettlementRate.builder()
                        .companyId(COMPANY_ID)
                        .currencyCode("HUF")
                        .officialRate(new BigDecimal("1.0000"))
                        .build(),
                MnbSettlementRate.builder()
                        .companyId(COMPANY_ID)
                        .currencyCode("EUR")
                        .officialRate(new BigDecimal("399.0000"))
                        .build()));
        when(rateRepository.findByCompanyIdAndCurrencyCode(COMPANY_ID, "EUR")).thenReturn(Optional.of(
                MnbSettlementRate.builder()
                        .companyId(COMPANY_ID)
                        .currencyCode("EUR")
                        .officialRate(new BigDecimal("399.0000"))
                        .build()));
        when(rateRepository.save(any())).thenAnswer(invocation -> invocation.getArgument(0));
        when(historyRepository.save(any())).thenAnswer(invocation -> invocation.getArgument(0));

        service.update(request(item("EUR", "402.0000")), false);

        verify(auditLogService, never()).logInNewTransaction(any(), any(), any(), any(), any(), any(), any(), any());
        verify(rateRepository).save(any(MnbSettlementRate.class));
        verify(historyRepository, org.mockito.Mockito.times(2)).save(any());
    }

    @Test
    @DisplayName("mnb-query: FOERTEKTAR aktív nem-HUF valutákra szűri a mockolt MNB választ, és nem ír táblát")
    void mnbQuery_returnsActiveNonHufRatesWithoutWrites() {
        installAuth("FOERTEKTAR", "FO01");
        when(currencyRepository.findByActiveTrueOrderByDisplayOrderAsc()).thenReturn(List.of(
                currency("HUF", "Forint", 1),
                currency("EUR", "Euro", 2),
                currency("USD", "US dollar", 3)));
        when(mnbRateQueryClient.fetchCurrentRates()).thenReturn(Map.of(
                "EUR", new BigDecimal("401.2500"),
                "USD", new BigDecimal("352.1000"),
                "CHF", new BigDecimal("420.0000")));

        List<MnbQueryRateDto> rows = service.mnbQuery();

        assertThat(rows).extracting(MnbQueryRateDto::currencyCode).containsExactly("EUR", "USD");
        assertThat(rows.get(0).officialRate()).isEqualByComparingTo("401.2500");
        assertThat(rows.get(1).officialRate()).isEqualByComparingTo("352.1000");
        verify(rateRepository, never()).save(any());
        verify(historyRepository, never()).save(any());
        verify(auditLogService, never()).logWithDetails(any(), any(), any(), any(), any(), any(), any(), any(), any(), any(), any());
    }

    @Test
    @DisplayName("mnb-query: ugyanaz a worker 10 mp-en belül 429 BusinessExceptiont kap")
    void mnbQuery_rateLimitsSameWorkerWithinWindow() {
        installAuth("FOERTEKTAR", "FO01");
        when(currencyRepository.findByActiveTrueOrderByDisplayOrderAsc()).thenReturn(List.of(currency("EUR", "Euro", 2)));
        when(mnbRateQueryClient.fetchCurrentRates()).thenReturn(Map.of("EUR", new BigDecimal("401.2500")));

        service.mnbQuery();

        assertThatThrownBy(() -> service.mnbQuery())
                .isInstanceOf(BusinessException.class)
                .extracting("errorCode", "httpStatus")
                .containsExactly("VV-RATE-LIMIT-001", HttpStatus.TOO_MANY_REQUESTS);
        verify(mnbRateQueryClient, times(1)).fetchCurrentRates();
    }

    @Test
    @DisplayName("mnb-query: MNB klienshiba 503 VV-MNB-UNAVAILABLE válaszra fordul, írás nélkül")
    void mnbQuery_clientFailureBecomesServiceUnavailable() {
        installAuth("FOERTEKTAR", "FO01");
        when(mnbRateQueryClient.fetchCurrentRates()).thenThrow(new BusinessException("timeout", "MNB_TIMEOUT"));

        assertThatThrownBy(() -> service.mnbQuery())
                .isInstanceOf(BusinessException.class)
                .extracting("errorCode", "httpStatus")
                .containsExactly("VV-MNB-UNAVAILABLE", HttpStatus.SERVICE_UNAVAILABLE);
        verify(rateRepository, never()).save(any());
        verify(historyRepository, never()).save(any());
        verify(auditLogService, never()).logWithDetails(any(), any(), any(), any(), any(), any(), any(), any(), any(), any(), any());
    }

    @Test
    @DisplayName("mnb-query: BELSO_ELLENOR 403 + ACCESS_DENIED audit REQUIRES_NEW-ban, MNB hívás nélkül")
    void mnbQuery_deniesBelsoEllenorAndAuditsAccessDenied() {
        installAuth("BELSO_ELLENOR", "ELLENOR01");

        assertThatThrownBy(() -> service.mnbQuery())
                .isInstanceOf(AccessDeniedException.class)
                .hasMessageContaining("VV-AUTH-001");

        verify(auditLogService).logInNewTransaction(
                eq("ACCESS_DENIED"), eq("MnbSettlementRate"), eq("MNB_QUERY"),
                eq("1"), eq(null), eq(null), eq(null),
                org.mockito.ArgumentMatchers.contains("BELSO_ELLENOR"));
        verifyNoInteractions(mnbRateQueryClient);
        verify(rateRepository, never()).save(any());
        verify(historyRepository, never()).save(any());
    }

    private static void installAuth(String role, String workerCode) {
        WorkerAuthenticationDetails details = new WorkerAuthenticationDetails(1L, COMPANY_ID, BRANCH_ID, role);
        TestingAuthenticationToken auth = new TestingAuthenticationToken(workerCode, "x", "ROLE_" + role);
        auth.setDetails(details);
        SecurityContextHolder.getContext().setAuthentication(auth);
    }

    private static void installAuth(String legacyRole, String activeRole, String workerCode) {
        WorkerAuthenticationDetails details = new WorkerAuthenticationDetails(
                1L, COMPANY_ID, BRANCH_ID, legacyRole, activeRole);
        TestingAuthenticationToken auth = new TestingAuthenticationToken(
                workerCode, "x", "ROLE_" + legacyRole, "ROLE_" + activeRole.toUpperCase());
        auth.setDetails(details);
        SecurityContextHolder.getContext().setAuthentication(auth);
    }

    private static MnbSettlementRateUpdateRequest request(MnbSettlementRateUpdateRequest.Item... items) {
        MnbSettlementRateUpdateRequest request = new MnbSettlementRateUpdateRequest();
        request.setItems(List.of(items));
        return request;
    }

    private static MnbSettlementRateUpdateRequest.Item item(String currencyCode, String rate) {
        return MnbSettlementRateUpdateRequest.Item.builder()
                .currencyCode(currencyCode)
                .officialRate(new BigDecimal(rate))
                .build();
    }

    private static Currency currency(String code, String name, int displayOrder) {
        return Currency.builder()
                .code(code)
                .name(name)
                .active(true)
                .displayOrder(displayOrder)
                .build();
    }
}
