package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.closingwizard.ClosingWizardDto;
import hu.puzzleir.valuta.service.ClosingWizardService;
import org.junit.jupiter.api.Test;

import java.time.LocalDate;
import java.util.Map;
import java.util.UUID;

import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class ClosingWizardControllerTest {

    @Test
    void countDenominationsPropagatesWizardBusinessDate() {
        ClosingWizardService service = mock(ClosingWizardService.class);
        ClosingWizardController controller = new ClosingWizardController(service);
        UUID wizardId = UUID.randomUUID();
        UUID branchId = UUID.randomUUID();
        LocalDate businessDate = LocalDate.of(2026, 7, 22);
        Map<String, Map<Integer, Integer>> counts = Map.of("HUF", Map.of(1000, 2));
        ClosingWizardDto wizard = ClosingWizardDto.builder()
                .branchId(branchId.toString())
                .closingDate(businessDate.toString())
                .build();
        when(service.getWizard(wizardId)).thenReturn(wizard);
        when(service.countDenominations(branchId, businessDate, counts)).thenReturn(Map.of());

        controller.countDenominations(wizardId, counts);

        verify(service).countDenominations(branchId, businessDate, counts);
    }
}