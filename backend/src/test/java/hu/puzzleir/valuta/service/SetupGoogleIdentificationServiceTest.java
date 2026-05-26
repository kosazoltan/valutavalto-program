package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.setup.SetupGoogleIdentifyRequestDto;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.exception.AuthenticationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * SetupGoogleIdentificationService — Google-azonosítás a SetupWizard-hoz.
 *
 * <p><b>2026-05-26 fix (Bali/Szeged értéktár Google-login regresszió):</b> a korábbi PP-13
 * "bootstrap-completed" blanket-guard MINDEN setup-identify hívást elutasított a cég bootstrap-ja
 * után, ami megtörte minden ÚJ kliens-telepítés Google-belépését. A tényleges védelem a
 * WHITELIST-en van (google_login_enabled + pontos email-egyezés, admin-vezérelt) + a
 * bindSubjectForUniqueWorker no-overwrite/no-collision logikáján — NEM a bootstrap-állapoton.
 * Ezek a tesztek a whitelist-alapú működést rögzítik.</p>
 */
@ExtendWith(MockitoExtension.class)
@DisplayName("SetupGoogleIdentificationService — whitelist-alapú Google azonosítás")
class SetupGoogleIdentificationServiceTest {

    @Mock private GoogleIdTokenService googleIdTokenService;
    @Mock private CompanyRepository companyRepository;
    @Mock private BranchRepository branchRepository;
    @Mock private WorkerRepository workerRepository;
    @Mock private WorkerRoleService workerRoleService;

    @InjectMocks private SetupGoogleIdentificationService service;

    private SetupGoogleIdentifyRequestDto anyRequest() {
        return SetupGoogleIdentifyRequestDto.builder()
                .idToken("google-id-token-xyz")
                .companyCode("EBC")
                .appMode("penztar")
                .build();
    }

    @Test
    @DisplayName("Bootstrap után IS lefut a token-verify (nincs blanket pre-block) — érvénytelen token → AuthenticationException")
    void identify_invalidToken_runsVerify_andThrows() throws Exception {
        // NINCS adminBootstrapService mock — a guard megszűnt; a verify mindig lefut.
        doThrow(new GoogleIdTokenService.GoogleTokenInvalidException("TEST", "test token invalid"))
                .when(googleIdTokenService).verify(anyString());

        assertThatThrownBy(() -> service.identify(anyRequest()))
                .isInstanceOf(AuthenticationException.class)
                .hasMessageContaining("Google bejelentkezes");

        // Bizonyíték: a token-verify ténylegesen lefutott (a korábbi guard ezt megelőzte volna).
        verify(googleIdTokenService).verify("google-id-token-xyz");
    }

    @Test
    @DisplayName("Whitelist a kapu: érvényes token, de nincs engedélyezett worker/branch → AuthenticationException")
    void identify_validToken_notWhitelisted_throwsNotAllowed() throws Exception {
        UUID companyId = UUID.randomUUID();
        when(googleIdTokenService.verify(anyString())).thenReturn(
                new GoogleIdTokenService.VerifiedGoogleIdentity(
                        "google-sub-123", "kivulrol@gmail.com", true, null,
                        "aud", "https://accounts.google.com", "Kívülálló", null));
        when(companyRepository.findByCode("EBC"))
                .thenReturn(Optional.of(Company.builder().id(companyId).code("EBC").build()));
        when(workerRepository.findGoogleLoginCandidatesByCompanyIdAndEmail(any(), any()))
                .thenReturn(List.of());
        when(branchRepository.findActiveByCompanyIdAndEmailIgnoreCase(any(), any()))
                .thenReturn(List.of());

        assertThatThrownBy(() -> service.identify(anyRequest()))
                .isInstanceOf(AuthenticationException.class)
                .hasMessageContaining("nincs engedelyezve");
    }
}
