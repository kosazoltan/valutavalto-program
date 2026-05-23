package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.DocumentShortage;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.repository.DocumentShortageRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

/**
 * N7 (legacy OKMANYHIANY / OKMCTRL) — okmányhiány-regiszter tesztek.
 */
@ExtendWith(MockitoExtension.class)
class DocumentShortageServiceTest {

    @Mock private DocumentShortageRepository repository;
    @Mock private CompanyRepository companyRepository;
    @InjectMocks private DocumentShortageService service;

    private static final UUID COMPANY_ID = UUID.randomUUID();

    @Test
    @DisplayName("record — sikeres rögzítés a hívó cégéhez (trimmel)")
    void testRecord() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            su.when(SecurityUtils::getCurrentWorkerId).thenReturn(7L);
            when(companyRepository.findById(COMPANY_ID)).thenReturn(Optional.of(Company.builder().id(COMPANY_ID).build()));
            when(repository.save(any())).thenAnswer(inv -> inv.getArgument(0));

            DocumentShortage r = service.record("  Lakcímkártya  ", "Teszt Ügyfél", "C1", "BR009", "V250000001", "  ");

            assertThat(r.getMissingDocument()).isEqualTo("Lakcímkártya");
            assertThat(r.getCustomerName()).isEqualTo("Teszt Ügyfél");
            assertThat(r.getNote()).isNull(); // üres → null
            assertThat(r.getRecordedBy()).isEqualTo("7");
            assertThat(r.getCompany().getId()).isEqualTo(COMPANY_ID);
        }
    }

    @Test
    @DisplayName("record — hiányzó okmány megnevezés ValidationException")
    void testRecordBlank() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            assertThatThrownBy(() -> service.record("  ", "X", null, null, null, null))
                    .isInstanceOf(ValidationException.class);
        }
    }

    @Test
    @DisplayName("resolve — más cég tétele: IDOR-védelem (ResourceNotFound)")
    void testResolveOtherCompanyBlocked() {
        UUID id = UUID.randomUUID();
        DocumentShortage e = DocumentShortage.builder()
                .id(id).company(Company.builder().id(UUID.randomUUID()).build()).build();
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(repository.findById(id)).thenReturn(Optional.of(e));

            assertThatThrownBy(() -> service.resolve(id)).isInstanceOf(ResourceNotFoundException.class);
            verify(repository, never()).save(any());
        }
    }

    @Test
    @DisplayName("resolve — saját cég tétele: resolvedAt beállítódik")
    void testResolveOwn() {
        UUID id = UUID.randomUUID();
        DocumentShortage e = DocumentShortage.builder()
                .id(id).company(Company.builder().id(COMPANY_ID).build()).resolvedAt(null).build();
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(repository.findById(id)).thenReturn(Optional.of(e));
            when(repository.save(any())).thenAnswer(inv -> inv.getArgument(0));

            service.resolve(id);

            assertThat(e.getResolvedAt()).isNotNull();
            verify(repository).save(e);
        }
    }

    @Test
    @DisplayName("resolve — már lezárt tétel idempotens (nincs újabb save)")
    void testResolveIdempotent() {
        UUID id = UUID.randomUUID();
        DocumentShortage e = DocumentShortage.builder()
                .id(id).company(Company.builder().id(COMPANY_ID).build())
                .resolvedAt(LocalDateTime.now().minusDays(1)).build();
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(repository.findById(id)).thenReturn(Optional.of(e));

            service.resolve(id);

            verify(repository, never()).save(any());
        }
    }

    @Test
    @DisplayName("list — openOnly a nyitott lekérdezést hívja")
    void testListOpenOnly() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(repository.findByCompanyIdAndResolvedAtIsNullOrderByRecordedAtDesc(COMPANY_ID))
                    .thenReturn(java.util.List.of());

            service.list(true);

            verify(repository).findByCompanyIdAndResolvedAtIsNullOrderByRecordedAtDesc(COMPANY_ID);
            verify(repository, never()).findByCompanyIdOrderByRecordedAtDesc(any());
        }
    }
}
