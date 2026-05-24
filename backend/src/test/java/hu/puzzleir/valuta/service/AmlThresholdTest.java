package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.sanction.SanctionScreeningResult;
import hu.puzzleir.valuta.entity.ProhibitedPerson;
import hu.puzzleir.valuta.repository.AmlReportRepository;
import hu.puzzleir.valuta.repository.AmlThresholdRepository;
import hu.puzzleir.valuta.repository.CustomerRepository;
import hu.puzzleir.valuta.repository.ShiftedCalendarDayRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

/**
 * AmlService.checkTransaction küszöb-logika tesztje (Pmt. 2017. LIII. tv. 7.§, VV-ELVI 9.1).
 *
 * <p>A repo-t érintő éves/napi göngyölés (3./4./5. szekció) {@code customerId == null}
 * mellett kimarad, így a tiszta küszöb-ágak izoláltan tesztelhetők:
 * 100k egyszerűsített azonosítás, 300k teljes azonosítás, 1.5M részletes azonosítás.
 */
@ExtendWith(MockitoExtension.class)
class AmlThresholdTest {

    @Mock private TransactionRepository transactionRepository;
    @Mock private CustomerRepository customerRepository;
    @Mock private AmlReportRepository amlReportRepository;
    @Mock private AmlThresholdRepository amlThresholdRepository;
    @Mock private AuditLogService auditLogService;
    @Mock private SanctionScreeningService sanctionScreeningService;
    @Mock private BlacklistService blacklistService;
    @Mock private ShiftedCalendarDayRepository shiftedCalendarDayRepository;

    @InjectMocks
    private AmlService amlService;

    /** Tiszta szankció+tiltólista (a névvel hívott esetekhez). */
    private void cleanScreening() {
        when(sanctionScreeningService.screenCustomer(any(), any(), any(), any(), any(), any()))
                .thenReturn(SanctionScreeningResult.builder().matched(false).build());
        when(blacklistService.findActivePersonMatch(any(), any()))
                .thenReturn(Optional.<ProhibitedPerson>empty());
    }

    @Test
    @DisplayName("100k alatt: jóváhagyva, azonosítás NEM kötelező")
    void belowSimplifiedLimit() {
        var r = amlService.checkTransaction(new BigDecimal("99999"), null, null, null);
        assertThat(r.isApproved()).isTrue();
        assertThat(r.isRequiresIdentification()).isFalse();
        assertThat(r.isRequiresDetailedId()).isFalse();
    }

    @Test
    @DisplayName("100k–300k azonosítás NÉLKÜL (név/okmány hiányzik): elutasítva")
    void simplifiedRangeWithoutIdRejected() {
        var r = amlService.checkTransaction(new BigDecimal("150000"), null, null, null);
        assertThat(r.isApproved()).isFalse();
        assertThat(r.isRequiresIdentification()).isTrue();
        assertThat(r.getRejectionReason()).contains("azonositas");
    }

    @Test
    @DisplayName("100k–300k azonosítással: jóváhagyva, egyszerűsített azonosítás, részletes NEM")
    void simplifiedRangeWithId() {
        cleanScreening();
        var r = amlService.checkTransaction(new BigDecimal("150000"), null, "Teszt Elek", "AB123456");
        assertThat(r.isApproved()).isTrue();
        assertThat(r.isRequiresIdentification()).isTrue();
        assertThat(r.isRequiresDetailedId()).isFalse();
    }

    @Test
    @DisplayName("300k felett: teljes azonosítás kötelező (requiresDetailedId)")
    void fullIdentificationLimit() {
        cleanScreening();
        var r = amlService.checkTransaction(new BigDecimal("300000"), null, "Teszt Elek", "AB123456");
        assertThat(r.isApproved()).isTrue();
        assertThat(r.isRequiresIdentification()).isTrue();
        assertThat(r.isRequiresDetailedId()).isTrue();
    }

    @Test
    @DisplayName("1.5M felett: részletes azonosítás + azonosítás kötelező")
    void detailedIdentificationLimit() {
        cleanScreening();
        var r = amlService.checkTransaction(new BigDecimal("1500000"), null, "Teszt Elek", "AB123456");
        assertThat(r.isApproved()).isTrue();
        assertThat(r.isRequiresDetailedId()).isTrue();
        assertThat(r.isRequiresIdentification()).isTrue();
    }

    @Test
    @DisplayName("Negatív összeg: elutasítva (érvénytelen)")
    void negativeAmountRejected() {
        var r = amlService.checkTransaction(new BigDecimal("-1"), null, null, null);
        assertThat(r.isApproved()).isFalse();
        assertThat(r.getRejectionReason()).contains("Ervenytelen");
    }

    @Test
    @DisplayName("null összeg: elutasítva (érvénytelen)")
    void nullAmountRejected() {
        var r = amlService.checkTransaction(null, null, null, null);
        assertThat(r.isApproved()).isFalse();
        assertThat(r.getRejectionReason()).contains("Ervenytelen");
    }
}
