package hu.puzzleir.valuta.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import hu.puzzleir.valuta.dto.sanction.SanctionScreeningResult;
import hu.puzzleir.valuta.repository.SanctionEntryRepository;
import hu.puzzleir.valuta.repository.SanctionScreeningLogRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.Spy;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.time.LocalDate;
import java.util.Collections;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

/**
 * #4 — Szankciós lista offline cache fallback (staleness) teszt.
 *
 * A szűrés ELAVULT/ÜRES helyi listán is lefut (NEM áll le), de a {@code staleData} flag
 * jelzi a degradált módot, hogy a hívó/UI figyelmeztethessen.
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class SanctionOfflineFallbackTest {

    @Mock private SanctionEntryRepository sanctionEntryRepository;
    @Mock private SanctionScreeningLogRepository screeningLogRepository;
    @Mock private ObjectMapper objectMapper;
    @Spy private FatfCountryRiskService fatfCountryRiskService = new FatfCountryRiskService();
    @InjectMocks private SanctionScreeningService service;

    private SanctionScreeningResult screenClean(LocalDate lastUpdate, long activeCount) {
        // Nincs találat (üres aktív lista a név-szűréshez), így CLEAR — a staleness a lényeg.
        when(sanctionEntryRepository.findByActiveTrue()).thenReturn(Collections.emptyList());
        when(sanctionEntryRepository.findLastUpdateDate())
                .thenReturn(Optional.ofNullable(lastUpdate));
        when(sanctionEntryRepository.countByActiveTrue()).thenReturn(activeCount);
        when(screeningLogRepository.save(any())).thenReturn(null);
        return service.screenCustomer("Teszt Elek", null, null, "W1", "Teszt Dolgozó", "BR001");
    }

    @Test
    @DisplayName("friss lista (ma frissült, van bejegyzés) → staleData=false")
    void freshList_notStale() {
        SanctionScreeningResult r = screenClean(LocalDate.now(), 100);
        assertThat(r.isMatched()).isFalse();
        assertThat(r.isStaleData()).isFalse();
        assertThat(r.getListAgeDays()).isZero();
    }

    @Test
    @DisplayName("elavult lista (>7 napos) → staleData=true, listAgeDays kitöltve")
    void oldList_stale() {
        SanctionScreeningResult r = screenClean(LocalDate.now().minusDays(10), 100);
        assertThat(r.isStaleData()).isTrue();
        assertThat(r.getListAgeDays()).isEqualTo(10);
    }

    @Test
    @DisplayName("üres lista (0 aktív bejegyzés) → staleData=true (cold start / nincs import)")
    void emptyList_stale() {
        SanctionScreeningResult r = screenClean(LocalDate.now(), 0);
        assertThat(r.isStaleData()).isTrue();
    }

    @Test
    @DisplayName("sosem importált (nincs lastUpdate, de van bejegyzés) → staleData=true")
    void neverImported_stale() {
        SanctionScreeningResult r = screenClean(null, 5);
        assertThat(r.isStaleData()).isTrue();
        assertThat(r.getListAgeDays()).isNull();
    }

    @Test
    @DisplayName("pontosan 7 napos lista → MÉG nem elavult (≤ határ)")
    void exactlyAtLimit_notStale() {
        SanctionScreeningResult r = screenClean(LocalDate.now().minusDays(7), 100);
        assertThat(r.isStaleData()).isFalse();
        assertThat(r.getListAgeDays()).isEqualTo(7);
    }
}
