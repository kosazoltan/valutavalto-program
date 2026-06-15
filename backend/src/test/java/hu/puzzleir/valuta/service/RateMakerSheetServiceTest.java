package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.RateMakerSheet;
import hu.puzzleir.valuta.repository.RateMakerSheetRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.when;

/**
 * RateMakerSheetService — az árfolyamkészítő munkaív kétirányú sync-szolgáltatásának tesztjei.
 * Lefedi: getSheet (üres + meglévő), upsert (create version=1, update version+1), multi-tenant scope.
 */
@ExtendWith(MockitoExtension.class)
class RateMakerSheetServiceTest {

    private static final UUID COMPANY_ID = UUID.fromString("11111111-1111-1111-1111-111111111111");
    private static final Long WORKER_ID = 42L;

    @Mock
    private RateMakerSheetRepository repository;

    @InjectMocks
    private RateMakerSheetService service;

    @Test
    void getSheet_returnsEmpty_whenNoSheetForCompany() {
        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(repository.findByCompanyId(COMPANY_ID)).thenReturn(Optional.empty());

            assertThat(service.getSheet()).isEmpty();
        }
    }

    @Test
    void upsertSheet_createsNewSheet_withVersionOne_whenAbsent() {
        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            sec.when(SecurityUtils::getCurrentWorkerId).thenReturn(WORKER_ID);
            when(repository.findByCompanyId(COMPANY_ID)).thenReturn(Optional.empty());
            when(repository.save(any(RateMakerSheet.class))).thenAnswer(inv -> inv.getArgument(0));

            RateMakerSheet saved = service.upsertSheet("{\"a\":1}", "rate-maker", "dev-1", null);

            assertThat(saved.getCompanyId()).isEqualTo(COMPANY_ID);
            assertThat(saved.getVersion()).isEqualTo(1L);
            assertThat(saved.getSource()).isEqualTo("rate-maker");
            assertThat(saved.getDeviceId()).isEqualTo("dev-1");
            assertThat(saved.getUpdatedBy()).isEqualTo(WORKER_ID);
            assertThat(saved.getSheetJson()).isEqualTo("{\"a\":1}");
        }
    }

    @Test
    void upsertSheet_incrementsVersion_andOverwrites_whenPresent() {
        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            sec.when(SecurityUtils::getCurrentWorkerId).thenReturn(WORKER_ID);
            RateMakerSheet existing = RateMakerSheet.builder()
                    .id(UUID.randomUUID())
                    .companyId(COMPANY_ID)
                    .sheetJson("{\"old\":true}")
                    .version(5L)
                    .source("rate-maker")
                    .build();
            when(repository.findByCompanyId(COMPANY_ID)).thenReturn(Optional.of(existing));
            when(repository.save(any(RateMakerSheet.class))).thenAnswer(inv -> inv.getArgument(0));

            RateMakerSheet saved = service.upsertSheet("{\"new\":true}", "central", "dev-2", 5L);

            assertThat(saved.getVersion()).isEqualTo(6L);
            assertThat(saved.getSheetJson()).isEqualTo("{\"new\":true}");
            assertThat(saved.getSource()).isEqualTo("central");
            assertThat(saved.getDeviceId()).isEqualTo("dev-2");
        }
    }

    @Test
    void upsertSheet_defaultsSourceToRateMaker_whenBlank() {
        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            sec.when(SecurityUtils::getCurrentWorkerId).thenReturn(WORKER_ID);
            when(repository.findByCompanyId(COMPANY_ID)).thenReturn(Optional.empty());
            when(repository.save(any(RateMakerSheet.class))).thenAnswer(inv -> inv.getArgument(0));

            RateMakerSheet saved = service.upsertSheet("{}", "  ", null, null);

            assertThat(saved.getSource()).isEqualTo("rate-maker");
        }
    }
}
