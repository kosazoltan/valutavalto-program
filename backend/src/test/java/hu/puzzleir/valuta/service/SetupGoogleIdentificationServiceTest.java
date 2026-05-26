package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.setup.SetupGoogleIdentifyRequestDto;
import hu.puzzleir.valuta.dto.setup.SetupGoogleIdentifyResponseDto;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.entity.WorkerRole;
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

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * SetupGoogleIdentificationService — Google-azonosítás a SetupWizard-hoz.
 *
 * <p><b>2026-05-26 fix (Bali/Szeged értéktár Google-login regresszió + Codex P1):</b> a korábbi
 * PP-13 "bootstrap-completed" BLANKET-guard MINDEN setup-identify hívást elutasított a cég
 * bootstrap-ja után → megtörte minden ÚJ kliens-telepítés Google-belépését (értéktáros/vezető
 * CSAK Google-lel léphet be). Az új viselkedés: bootstrap után a setup-identify <b>READ-ONLY</b> —
 * az azonosítás engedett (a wizard működik), de semmilyen állapot-mutáció (subject-kötés,
 * google-enable) nem történik a publikus endpointon; azt az autentikált GoogleLoginService végzi.</p>
 */
@ExtendWith(MockitoExtension.class)
@DisplayName("SetupGoogleIdentificationService — whitelist + bootstrap-read-only Google azonosítás")
class SetupGoogleIdentificationServiceTest {

    @Mock private GoogleIdTokenService googleIdTokenService;
    @Mock private CompanyRepository companyRepository;
    @Mock private BranchRepository branchRepository;
    @Mock private WorkerRepository workerRepository;
    @Mock private WorkerRoleService workerRoleService;
    @Mock private AdminBootstrapService adminBootstrapService;

    @InjectMocks private SetupGoogleIdentificationService service;

    private SetupGoogleIdentifyRequestDto anyRequest() {
        return SetupGoogleIdentifyRequestDto.builder()
                .idToken("google-id-token-xyz")
                .companyCode("EBC")
                .appMode("penztar")
                .build();
    }

    private GoogleIdTokenService.VerifiedGoogleIdentity identity(String email, String sub) {
        return new GoogleIdTokenService.VerifiedGoogleIdentity(
                sub, email, true, null, "aud", "https://accounts.google.com", "Teszt Név", null);
    }

    @Test
    @DisplayName("Bootstrap után IS lefut a token-verify (nincs blanket pre-block) — érvénytelen token → AuthenticationException")
    void identify_invalidToken_runsVerify_andThrows() throws Exception {
        doThrow(new GoogleIdTokenService.GoogleTokenInvalidException("TEST", "test token invalid"))
                .when(googleIdTokenService).verify(anyString());

        assertThatThrownBy(() -> service.identify(anyRequest()))
                .isInstanceOf(AuthenticationException.class)
                .hasMessageContaining("Google bejelentkezes");

        // Bizonyíték: a token-verify ténylegesen lefutott (a korábbi blanket-guard ezt megelőzte volna).
        verify(googleIdTokenService).verify("google-id-token-xyz");
    }

    @Test
    @DisplayName("Whitelist a kapu: érvényes token, de nincs engedélyezett worker/branch → AuthenticationException")
    void identify_validToken_notWhitelisted_throwsNotAllowed() throws Exception {
        UUID companyId = UUID.randomUUID();
        when(googleIdTokenService.verify(anyString())).thenReturn(identity("kivulrol@gmail.com", "sub-x"));
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

    @Test
    @DisplayName("Bootstrap UTÁN: whitelistelt dolgozó AZONOSÍTÁSA sikeres, de a subject-kötés NEM fut (read-only)")
    void identify_postBootstrap_whitelistedWorker_identifiesReadOnly() throws Exception {
        UUID companyId = UUID.randomUUID();
        Worker bali = Worker.builder()
                .id(42L).code("BALI").name("Bali Henrietta")
                .role(WorkerRole.CASHIER).active(true)
                .googleSubject(null) // még nincs kötve — bootstrap után MÉGSEM kötjük (read-only)
                .build();

        when(adminBootstrapService.isBootstrapAlreadyCompleted()).thenReturn(true);
        when(googleIdTokenService.verify(anyString())).thenReturn(identity("szeged.ebc@gmail.com", "sub-bali"));
        when(companyRepository.findByCode("EBC"))
                .thenReturn(Optional.of(Company.builder().id(companyId).code("EBC").build()));
        when(workerRepository.findGoogleLoginCandidatesByCompanyIdAndEmail(any(), any()))
                .thenReturn(List.of(bali));
        when(workerRoleService.getRoleCodesForWorker(anyLong())).thenReturn(List.of("ertektar"));

        // A kliens kötést kérne (bindGoogleSubject=true), de bootstrap után READ-ONLY → nem köt.
        SetupGoogleIdentifyResponseDto response = service.identify(
                SetupGoogleIdentifyRequestDto.builder()
                        .idToken("google-id-token-xyz")
                        .companyCode("EBC")
                        .appMode("penztar")
                        .bindGoogleSubject(true)
                        .build());

        assertThat(response.getWorker()).isNotNull();
        assertThat(response.getWorker().getCode()).isEqualTo("BALI");
        // KULCS: a publikus endpoint NEM mutált — a subject-kötés (workerRepository.save) NEM futott.
        verify(workerRepository, never()).save(any());
    }
}
