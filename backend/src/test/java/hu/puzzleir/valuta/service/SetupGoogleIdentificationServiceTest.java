package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.setup.SetupGoogleIdentifyRequestDto;
import hu.puzzleir.valuta.entity.SystemParameter;
import hu.puzzleir.valuta.exception.AuthenticationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.repository.SystemParameterRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * PP-13 biztonsági teszt — SetupGoogleIdentificationService bootstrap-completed guard.
 *
 * <p>PP-13: Az identify() metódus a bootstrap lezárulta után nyilvánosan érhető el —
 * egy támadó saját Google Subject-jét kötheti bármely worker email-jéhez,
 * ha a bootstrap-completed flaget nem ellenőrizzük. Fix: auth.bootstrap-completed=true
 * esetén azonnal AuthenticationException, token verify nem fut le.</p>
 */
@ExtendWith(MockitoExtension.class)
@DisplayName("SetupGoogleIdentificationService — PP-13 bootstrap-completed guard")
class SetupGoogleIdentificationServiceTest {

    @Mock private GoogleIdTokenService googleIdTokenService;
    @Mock private CompanyRepository companyRepository;
    @Mock private BranchRepository branchRepository;
    @Mock private WorkerRepository workerRepository;
    @Mock private WorkerRoleService workerRoleService;
    @Mock private SystemParameterRepository systemParameterRepository;

    @InjectMocks private SetupGoogleIdentificationService service;

    private SetupGoogleIdentifyRequestDto anyRequest() {
        return SetupGoogleIdentifyRequestDto.builder()
                .idToken("google-id-token-xyz")
                .companyCode("EBC")
                .appMode("penztar")
                .build();
    }

    @Test
    @DisplayName("PP-13: bootstrap már lezárult → AuthenticationException, token verify NEM hívódik")
    void identify_bootstrapCompleted_rejectsBeforeTokenVerify() throws Exception {
        SystemParameter completedFlag = SystemParameter.builder()
                .parameterKey(AdminBootstrapService.BOOTSTRAP_FLAG_KEY)
                .parameterValue("true")
                .isActive(true)
                .build();
        when(systemParameterRepository.findByParameterKey(AdminBootstrapService.BOOTSTRAP_FLAG_KEY))
                .thenReturn(Optional.of(completedFlag));

        assertThatThrownBy(() -> service.identify(anyRequest()))
                .isInstanceOf(AuthenticationException.class)
                .hasMessageContaining("setup mar lezarult");

        verify(googleIdTokenService, never()).verify(anyString());
        verify(companyRepository, never()).findByCode(anyString());
        verify(companyRepository, never()).findByCodeIgnoreCase(anyString());
    }

    @Test
    @DisplayName("PP-13: bootstrap inaktív flag → token verify lefut (setup folytatható)")
    void identify_bootstrapFlagInactive_tokenVerifyProceeds() throws Exception {
        SystemParameter inactiveFlag = SystemParameter.builder()
                .parameterKey(AdminBootstrapService.BOOTSTRAP_FLAG_KEY)
                .parameterValue("true")
                .isActive(false)
                .build();
        when(systemParameterRepository.findByParameterKey(AdminBootstrapService.BOOTSTRAP_FLAG_KEY))
                .thenReturn(Optional.of(inactiveFlag));
        doThrow(new GoogleIdTokenService.GoogleTokenInvalidException("TEST", "test token invalid"))
                .when(googleIdTokenService).verify(anyString());

        assertThatThrownBy(() -> service.identify(anyRequest()))
                .isInstanceOf(AuthenticationException.class)
                .hasMessageContaining("Google bejelentkezes");

        verify(googleIdTokenService).verify("google-id-token-xyz");
    }

    @Test
    @DisplayName("PP-13: bootstrap flag nincs → token verify lefut (setup folytatható)")
    void identify_bootstrapFlagAbsent_tokenVerifyProceeds() throws Exception {
        when(systemParameterRepository.findByParameterKey(AdminBootstrapService.BOOTSTRAP_FLAG_KEY))
                .thenReturn(Optional.empty());
        doThrow(new GoogleIdTokenService.GoogleTokenInvalidException("TEST", "test token invalid"))
                .when(googleIdTokenService).verify(anyString());

        assertThatThrownBy(() -> service.identify(anyRequest()))
                .isInstanceOf(AuthenticationException.class)
                .hasMessageContaining("Google bejelentkezes");

        verify(googleIdTokenService).verify("google-id-token-xyz");
    }
}
