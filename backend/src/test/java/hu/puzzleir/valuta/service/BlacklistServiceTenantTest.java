package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.ProhibitedCompany;
import hu.puzzleir.valuta.entity.ProhibitedPerson;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.ProhibitedCompanyRepository;
import hu.puzzleir.valuta.repository.ProhibitedPersonRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.Mockito.*;

/**
 * BlacklistService multi-tenant (IDOR) regressziós tesztek.
 *
 * Architect-mode audit (2026-05-27): a createPerson/createCompany nem állította a companyId-t
 * (null/idegen tenant), az update/delete pedig findById/deleteById-val, company-ellenőrzés nélkül
 * futott → cross-tenant szerkesztés/törlés + a saját-cég-szűrő AML-screening csendes megkerülése.
 */
@ExtendWith(MockitoExtension.class)
class BlacklistServiceTenantTest {

    @Mock private ProhibitedPersonRepository personRepo;
    @Mock private ProhibitedCompanyRepository companyRepo;
    @InjectMocks private BlacklistService service;

    private static final UUID MY_COMPANY = UUID.randomUUID();
    private static final UUID OTHER_COMPANY = UUID.randomUUID();

    @Test
    @DisplayName("createPerson — a companyId KÖTELEZŐEN a hívó cégére áll (kliens-érték felülírva)")
    void createPerson_forcesCurrentCompanyId() {
        ProhibitedPerson incoming = ProhibitedPerson.builder()
                .fullName("Teszt Elek")
                .companyId(OTHER_COMPANY) // kliens által küldött idegen tenant — felül kell írni
                .build();
        when(personRepo.save(any(ProhibitedPerson.class))).thenAnswer(inv -> inv.getArgument(0));

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(MY_COMPANY);
            service.createPerson(incoming);
        }

        ArgumentCaptor<ProhibitedPerson> captor = ArgumentCaptor.forClass(ProhibitedPerson.class);
        verify(personRepo).save(captor.capture());
        assertThat(captor.getValue().getCompanyId()).isEqualTo(MY_COMPANY);
        assertThat(captor.getValue().getIsActive()).isTrue();
    }

    @Test
    @DisplayName("updatePerson — idegen tenant rekordja NEM módosítható (404, nincs save)")
    void updatePerson_crossTenant_throwsAndDoesNotSave() {
        UUID id = UUID.randomUUID();
        ProhibitedPerson foreign = ProhibitedPerson.builder()
                .id(id).fullName("Idegen").companyId(OTHER_COMPANY).build();
        when(personRepo.findById(id)).thenReturn(Optional.of(foreign));

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(MY_COMPANY);
            assertThatThrownBy(() -> service.updatePerson(id,
                    ProhibitedPerson.builder().fullName("Hacked").build()))
                    .isInstanceOf(ResourceNotFoundException.class);
        }
        verify(personRepo, never()).save(any());
    }

    @Test
    @DisplayName("updatePerson — saját cég rekordja módosítható")
    void updatePerson_sameTenant_ok() {
        UUID id = UUID.randomUUID();
        ProhibitedPerson own = ProhibitedPerson.builder()
                .id(id).fullName("Sajat").companyId(MY_COMPANY).isActive(true).build();
        when(personRepo.findById(id)).thenReturn(Optional.of(own));
        when(personRepo.save(any(ProhibitedPerson.class))).thenAnswer(inv -> inv.getArgument(0));

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(MY_COMPANY);
            ProhibitedPerson result = service.updatePerson(id,
                    ProhibitedPerson.builder().fullName("Frissitett").isActive(true).build());
            assertThat(result.getFullName()).isEqualTo("Frissitett");
        }
        verify(personRepo).save(any());
    }

    @Test
    @DisplayName("deletePerson — idegen tenant rekordja NEM törölhető (404, nincs delete)")
    void deletePerson_crossTenant_throwsAndDoesNotDelete() {
        UUID id = UUID.randomUUID();
        ProhibitedPerson foreign = ProhibitedPerson.builder()
                .id(id).fullName("Idegen").companyId(OTHER_COMPANY).build();
        when(personRepo.findById(id)).thenReturn(Optional.of(foreign));

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(MY_COMPANY);
            assertThatThrownBy(() -> service.deletePerson(id))
                    .isInstanceOf(ResourceNotFoundException.class);
        }
        verify(personRepo, never()).delete(any());
        verify(personRepo, never()).deleteById(any());
    }

    @Test
    @DisplayName("createCompany — a companyId KÖTELEZŐEN a hívó cégére áll")
    void createCompany_forcesCurrentCompanyId() {
        ProhibitedCompany incoming = ProhibitedCompany.builder()
                .companyName("Tiltott Kft.").companyId(OTHER_COMPANY).build();
        when(companyRepo.save(any(ProhibitedCompany.class))).thenAnswer(inv -> inv.getArgument(0));

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(MY_COMPANY);
            service.createCompany(incoming);
        }

        ArgumentCaptor<ProhibitedCompany> captor = ArgumentCaptor.forClass(ProhibitedCompany.class);
        verify(companyRepo).save(captor.capture());
        assertThat(captor.getValue().getCompanyId()).isEqualTo(MY_COMPANY);
    }

    @Test
    @DisplayName("deleteCompany — idegen tenant rekordja NEM törölhető (404)")
    void deleteCompany_crossTenant_throws() {
        UUID id = UUID.randomUUID();
        ProhibitedCompany foreign = ProhibitedCompany.builder()
                .id(id).companyName("Idegen Kft.").companyId(OTHER_COMPANY).build();
        when(companyRepo.findById(id)).thenReturn(Optional.of(foreign));

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(MY_COMPANY);
            assertThatThrownBy(() -> service.deleteCompany(id))
                    .isInstanceOf(ResourceNotFoundException.class);
        }
        verify(companyRepo, never()).delete(any());
        verify(companyRepo, never()).deleteById(any());
    }
}
