package hu.puzzleir.valuta.controller;

import tools.jackson.databind.ObjectMapper;
import hu.puzzleir.valuta.dto.cashbalance.AdjustBalanceDto;
import hu.puzzleir.valuta.dto.cashbalance.CashBalanceDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.CashBalance;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.IdempotencyRecord;
import hu.puzzleir.valuta.mapper.CashBalanceMapper;
import hu.puzzleir.valuta.repository.IdempotencyRecordRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.service.AccessScopeService;
import hu.puzzleir.valuta.service.AuditLogService;
import hu.puzzleir.valuta.service.CashBalanceService;
import hu.puzzleir.valuta.util.IdempotencyGuard;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.MockedStatic;
import org.springframework.http.ResponseEntity;
import org.springframework.mock.web.MockHttpServletRequest;

import java.math.BigDecimal;
import java.util.Optional;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicReference;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class CashBalanceControllerIdempotencyTest {

    private static final UUID COMPANY_ID = UUID.fromString("aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa");
    private static final UUID BRANCH_ID = UUID.fromString("bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb");

    private final CashBalanceService cashBalanceService = mock(CashBalanceService.class);
    private final IdempotencyRecordRepository idempotencyRecordRepository = mock(IdempotencyRecordRepository.class);
    private final CashBalanceController controller = new CashBalanceController(
            cashBalanceService,
            new CashBalanceMapper(),
            mock(AccessScopeService.class),
            new IdempotencyGuard(idempotencyRecordRepository, new ObjectMapper(),
                    mock(AuditLogService.class)));

    @Test
    @DisplayName("POST /cash-balances/adjust azonos Idempotency-Key esetén cache-elt választ ad és csak egyszer könyvel")
    void adjustBalanceWithSameIdempotencyKeyCallsServiceOnce() {
        AtomicReference<IdempotencyRecord> storedRecord = new AtomicReference<>();
        when(idempotencyRecordRepository.findByCompanyIdAndEndpointAndIdempotencyKey(
                COMPANY_ID, "cash-balances/adjust", "cash-adjust-key-1"))
                .thenAnswer(invocation -> Optional.ofNullable(storedRecord.get()));
        when(idempotencyRecordRepository.save(any(IdempotencyRecord.class)))
                .thenAnswer(invocation -> {
                    IdempotencyRecord record = invocation.getArgument(0);
                    storedRecord.set(record);
                    return record;
                });
        when(cashBalanceService.adjustBalance(any(CashBalanceService.AdjustBalanceRequest.class)))
                .thenReturn(balance("1250"));

        try (MockedStatic<SecurityUtils> securityUtils = org.mockito.Mockito.mockStatic(SecurityUtils.class)) {
            securityUtils.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            AdjustBalanceDto dto = adjustDto();
            MockHttpServletRequest firstRequest = requestWithIdempotencyKey("cash-adjust-key-1");
            MockHttpServletRequest secondRequest = requestWithIdempotencyKey("cash-adjust-key-1");

            ResponseEntity<CashBalanceDto> first = controller.adjustBalance(dto, firstRequest);
            ResponseEntity<CashBalanceDto> second = controller.adjustBalance(dto, secondRequest);

            assertThat(first.getBody()).isNotNull();
            assertThat(second.getBody()).isNotNull();
            assertThat(second.getBody().getCurrentBalance()).isEqualByComparingTo("1250");
            assertThat(second.getBody().getCurrencyCode()).isEqualTo("EUR");
            verify(cashBalanceService, times(1)).adjustBalance(any(CashBalanceService.AdjustBalanceRequest.class));
        }
    }

    @Test
    @DisplayName("POST /cash-balances/adjust Idempotency-Key nélkül backward-compatible: nincs cache, mindkét hívás átmegy")
    void adjustBalanceWithoutIdempotencyKeyRemainsBackwardCompatible() {
        when(cashBalanceService.adjustBalance(any(CashBalanceService.AdjustBalanceRequest.class)))
                .thenReturn(balance("1250"));

        controller.adjustBalance(adjustDto(), new MockHttpServletRequest());
        controller.adjustBalance(adjustDto(), new MockHttpServletRequest());

        verify(cashBalanceService, times(2)).adjustBalance(any(CashBalanceService.AdjustBalanceRequest.class));
    }

    private static MockHttpServletRequest requestWithIdempotencyKey(String key) {
        MockHttpServletRequest request = new MockHttpServletRequest();
        request.addHeader("Idempotency-Key", key);
        return request;
    }

    private static AdjustBalanceDto adjustDto() {
        return AdjustBalanceDto.builder()
                .currencyId(4L)
                .amount(new BigDecimal("250"))
                .incoming(true)
                .reason("teszt feltöltés")
                .build();
    }

    private static CashBalance balance(String currentBalance) {
        Currency eur = Currency.builder().id(4L).code("EUR").name("Euro").build();
        Branch branch = Branch.builder().id(BRANCH_ID).name("Teszt iroda").build();
        return CashBalance.builder()
                .id(10L)
                .currency(eur)
                .branch(branch)
                .currentBalance(new BigDecimal(currentBalance))
                .build();
    }
}
