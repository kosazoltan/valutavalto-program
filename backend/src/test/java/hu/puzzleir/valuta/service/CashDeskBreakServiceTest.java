package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.cashdesk.CashDeskBreakDto;
import hu.puzzleir.valuta.entity.CashDeskBreak;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.CashDeskBreakRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.MockedStatic;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Multi-tenant scoping unit-tesztek a {@link CashDeskBreakService}-hez.
 * Audit-NO-GO-iter3 P0 fix verifikációja: a service minden lekérdezést a
 * SecurityContext-ből kiolvasott companyId-ra szűr — cross-tenant data leak nem lehetséges.
 */
@ExtendWith(MockitoExtension.class)
class CashDeskBreakServiceTest {

    private static final UUID COMPANY_A = UUID.fromString("11111111-1111-1111-1111-111111111111");
    private static final UUID COMPANY_B = UUID.fromString("22222222-2222-2222-2222-222222222222");
    private static final UUID CASH_DESK_1 = UUID.fromString("aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa");
    private static final UUID BREAK_ID = UUID.fromString("bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb");

    @Mock
    private CashDeskBreakRepository repository;

    @InjectMocks
    private CashDeskBreakService service;

    private CashDeskBreak companyABreak;

    @BeforeEach
    void setUp() {
        companyABreak = CashDeskBreak.builder()
                .id(BREAK_ID)
                .companyId(COMPANY_A)
                .cashDeskId(CASH_DESK_1)
                .breakStart(LocalDateTime.now().minusMinutes(15))
                .breakType("LUNCH")
                .reason("ebéd")
                .isActive(true)
                .build();
    }

    @Test
    @DisplayName("listBreaks(null) → companyA scope szerint lekérdez (audit P0 fix)")
    void listBreaks_noFilter_scopedByCompany() {
        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_A);
            when(repository.findByCompanyIdOrderByBreakStartDesc(COMPANY_A))
                    .thenReturn(List.of(companyABreak));

            List<CashDeskBreakDto> result = service.listBreaks(null);

            assertThat(result).hasSize(1);
            verify(repository).findByCompanyIdOrderByBreakStartDesc(COMPANY_A);
        }
    }

    @Test
    @DisplayName("listBreaks(cashDeskId) → companyA + cashDeskId scope szerint lekérdez")
    void listBreaks_withCashDeskId_scopedByCompanyAndCashDesk() {
        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_A);
            when(repository.findByCompanyIdAndCashDeskIdOrderByBreakStartDesc(COMPANY_A, CASH_DESK_1))
                    .thenReturn(List.of(companyABreak));

            List<CashDeskBreakDto> result = service.listBreaks(CASH_DESK_1);

            assertThat(result).hasSize(1);
            verify(repository).findByCompanyIdAndCashDeskIdOrderByBreakStartDesc(COMPANY_A, CASH_DESK_1);
        }
    }

    @Test
    @DisplayName("startBreak → új CashDeskBreak.companyId = SecurityUtils companyId-ja (multi-tenant audit P0)")
    void startBreak_setsCompanyIdFromSecurityContext() {
        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_A);
            when(repository.findByCompanyIdAndCashDeskIdAndIsActiveTrue(COMPANY_A, CASH_DESK_1))
                    .thenReturn(Optional.empty());
            when(repository.save(any(CashDeskBreak.class))).thenAnswer(inv -> {
                CashDeskBreak b = inv.getArgument(0);
                b.setId(BREAK_ID);
                return b;
            });

            service.startBreak(CASH_DESK_1, "LUNCH", "ebéd");

            ArgumentCaptor<CashDeskBreak> captor = ArgumentCaptor.forClass(CashDeskBreak.class);
            verify(repository).save(captor.capture());
            assertThat(captor.getValue().getCompanyId()).isEqualTo(COMPANY_A);
            assertThat(captor.getValue().getCashDeskId()).isEqualTo(CASH_DESK_1);
        }
    }

    @Test
    @DisplayName("endBreak más company szünetén → ResourceNotFoundException (tenant boundary, nem ValidationException)")
    void endBreak_otherCompanysBreak_throwsResourceNotFound() {
        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_B);
            when(repository.findById(BREAK_ID)).thenReturn(Optional.of(companyABreak));

            assertThatThrownBy(() -> service.endBreak(BREAK_ID))
                    .isInstanceOf(ResourceNotFoundException.class)
                    .hasMessageContaining(BREAK_ID.toString());

            // FONTOS: a save() NEM hívódott — a más company szünetét nem módosítja
            verify(repository, never()).save(any(CashDeskBreak.class));
        }
    }

    @Test
    @DisplayName("endBreak saját company szünetén → sikeres lezárás")
    void endBreak_ownCompanysActiveBreak_succeeds() {
        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_A);
            when(repository.findById(BREAK_ID)).thenReturn(Optional.of(companyABreak));
            when(repository.save(any(CashDeskBreak.class))).thenAnswer(inv -> inv.getArgument(0));

            CashDeskBreakDto result = service.endBreak(BREAK_ID);

            assertThat(result).isNotNull();
            ArgumentCaptor<CashDeskBreak> captor = ArgumentCaptor.forClass(CashDeskBreak.class);
            verify(repository).save(captor.capture());
            assertThat(captor.getValue().getIsActive()).isFalse();
            assertThat(captor.getValue().getBreakEnd()).isNotNull();
        }
    }

    @Test
    @DisplayName("endBreak NULL companyId-jű legacy szüneten → ResourceNotFoundException (V164 előtti adat tenant-leak nélkül blokkolt)")
    void endBreak_legacyNullCompanyId_throwsResourceNotFound() {
        CashDeskBreak legacyBreak = CashDeskBreak.builder()
                .id(BREAK_ID)
                .companyId(null) // legacy NULL
                .cashDeskId(CASH_DESK_1)
                .breakStart(LocalDateTime.now().minusMinutes(15))
                .breakType("LUNCH")
                .isActive(true)
                .build();

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_A);
            when(repository.findById(BREAK_ID)).thenReturn(Optional.of(legacyBreak));

            assertThatThrownBy(() -> service.endBreak(BREAK_ID))
                    .isInstanceOf(ResourceNotFoundException.class);
            verify(repository, never()).save(any(CashDeskBreak.class));
        }
    }

    @Test
    @DisplayName("startBreak ha már van aktív szünet a saját company-ban → ValidationException")
    void startBreak_activeExists_throwsValidation() {
        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_A);
            when(repository.findByCompanyIdAndCashDeskIdAndIsActiveTrue(COMPANY_A, CASH_DESK_1))
                    .thenReturn(Optional.of(companyABreak));

            assertThatThrownBy(() -> service.startBreak(CASH_DESK_1, "LUNCH", "ebéd"))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("aktív");
            verify(repository, never()).save(any(CashDeskBreak.class));
        }
    }
}
