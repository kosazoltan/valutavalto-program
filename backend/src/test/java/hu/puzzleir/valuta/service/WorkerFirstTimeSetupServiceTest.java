package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.auth.WorkerFirstTimeSetupRequestDto;
import hu.puzzleir.valuta.dto.auth.WorkerFirstTimeSetupResponseDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.entity.WorkerRole;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.security.JwtTokenProvider;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
@DisplayName("WorkerFirstTimeSetupService - lezart bootstrap utani jelszobeallitas")
class WorkerFirstTimeSetupServiceTest {

    @Mock private CompanyRepository companyRepository;
    @Mock private WorkerRepository workerRepository;
    @Mock private PasswordEncoder passwordEncoder;
    @Mock private JwtTokenProvider jwtTokenProvider;
    @Mock private AdminBootstrapService adminBootstrapService;
    @Mock private WorkerRoleService workerRoleService;
    @Mock private BranchRepository branchRepository;

    @InjectMocks private WorkerFirstTimeSetupService service;

    private Company company;
    private Branch branch;

    @BeforeEach
    void setUp() {
        company = new Company();
        company.setId(UUID.randomUUID());
        company.setCode("EBC");
        company.setName("Exclusive Best Change");

        branch = new Branch();
        branch.setId(UUID.randomUUID());
        branch.setCode("TISZA");
        branch.setName("Tisza iroda");
    }

    @Test
    @DisplayName("Lezart bootstrap utan seed hash-sel rendelkezo worker nem veheto at currentPassword nelkul")
    void rejectsSeedWorkerWithoutCurrentPasswordAfterBootstrap() {
        Worker worker = seedWorker("$2b$10$seed");
        when(companyRepository.findByCode("EBC")).thenReturn(Optional.of(company));
        when(workerRepository.findByCompanyIdAndCodeIgnoreCase(company.getId(), "BORSI"))
                .thenReturn(Optional.of(worker));
        when(adminBootstrapService.isBootstrapAlreadyCompleted()).thenReturn(true);

        assertThatThrownBy(() -> service.setupWorkerPassword(request(null)))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("telepites mar lezarult")
                .hasMessageContaining("jelenlegi vagy kezdo");

        verify(passwordEncoder, never()).encode(any());
        verify(workerRepository, never()).save(any(Worker.class));
        verifyNoTokenGenerated();
        verify(workerRoleService, never()).getRoleCodesForWorker(any());
    }

    @Test
    @DisplayName("Lezart bootstrap utan a helyes kezdo jelszo engedi az uj BCrypt hash beallitasat")
    void allowsSeedWorkerWithMatchingCurrentPasswordAfterBootstrap() {
        Worker worker = seedWorker("$2b$10$seed");
        when(companyRepository.findByCode("EBC")).thenReturn(Optional.of(company));
        when(workerRepository.findByCompanyIdAndCodeIgnoreCase(company.getId(), "BORSI"))
                .thenReturn(Optional.of(worker));
        when(adminBootstrapService.isBootstrapAlreadyCompleted()).thenReturn(true);
        when(passwordEncoder.matches("1234", "$2b$10$seed")).thenReturn(true);
        when(passwordEncoder.encode("UjGlobalisJelszo123!")).thenReturn("$2b$10$new");
        when(workerRepository.save(any(Worker.class))).thenAnswer(inv -> inv.getArgument(0));
        when(jwtTokenProvider.generateToken(any(Worker.class))).thenReturn("jwt-token");

        WorkerFirstTimeSetupResponseDto response = service.setupWorkerPassword(request("1234"));

        assertThat(response.isSuccess()).isTrue();
        assertThat(response.getToken()).isEqualTo("jwt-token");
        assertThat(response.getWorkerCode()).isEqualTo("BORSI");

        ArgumentCaptor<Worker> saved = ArgumentCaptor.forClass(Worker.class);
        verify(workerRepository).save(saved.capture());
        assertThat(saved.getValue().getPasswordHash()).isEqualTo("$2b$10$new");
        assertThat(saved.getValue().getPasswordChangedAt()).isNotNull();
    }

    @Test
    @DisplayName("AppMode megadasakor az auto-login token es valasz a megfelelo aktiv role-t kapja")
    void issuesAppModeActiveRoleTokenAfterPasswordSetup() {
        Worker worker = seedWorker("$2b$10$seed");
        WorkerFirstTimeSetupRequestDto dto = request("1234");
        dto.setAppMode("ertektar");
        when(companyRepository.findByCode("EBC")).thenReturn(Optional.of(company));
        when(workerRepository.findByCompanyIdAndCodeIgnoreCase(company.getId(), "BORSI"))
                .thenReturn(Optional.of(worker));
        when(workerRoleService.getRoleCodesForWorker(10L)).thenReturn(List.of("penztar", "ertektar"));
        when(workerRoleService.getPermissionCodesForRole("ertektar")).thenReturn(List.of("VAULT_READ"));
        when(adminBootstrapService.isBootstrapAlreadyCompleted()).thenReturn(true);
        when(passwordEncoder.matches("1234", "$2b$10$seed")).thenReturn(true);
        when(passwordEncoder.encode("UjGlobalisJelszo123!")).thenReturn("$2b$10$new");
        when(workerRepository.save(any(Worker.class))).thenAnswer(inv -> inv.getArgument(0));
        when(jwtTokenProvider.generateToken(any(Worker.class), org.mockito.ArgumentMatchers.eq("ertektar"), org.mockito.ArgumentMatchers.eq(List.of("VAULT_READ"))))
                .thenReturn("jwt-ertektar");

        WorkerFirstTimeSetupResponseDto response = service.setupWorkerPassword(dto);

        assertThat(response.getToken()).isEqualTo("jwt-ertektar");
        assertThat(response.getActiveRole()).isEqualTo("ertektar");
        assertThat(response.getRoles()).containsExactly("penztar", "ertektar");
    }

    @Test
    @DisplayName("Legacy branch nelkuli worker setup auto-login elott cegszintu aktiv fiokot kap")
    void assignsFallbackBranchBeforeJwtForLegacyBranchlessWorker() {
        Worker worker = seedWorker("$2b$10$seed");
        worker.setBranch(null);
        WorkerFirstTimeSetupRequestDto dto = request("1234");
        dto.setAppMode("penztar");
        when(companyRepository.findByCode("EBC")).thenReturn(Optional.of(company));
        when(workerRepository.findByCompanyIdAndCodeIgnoreCase(company.getId(), "BORSI"))
                .thenReturn(Optional.of(worker));
        when(workerRoleService.getRoleCodesForWorker(10L)).thenReturn(List.of());
        when(adminBootstrapService.isBootstrapAlreadyCompleted()).thenReturn(true);
        when(passwordEncoder.matches("1234", "$2b$10$seed")).thenReturn(true);
        when(passwordEncoder.encode("UjGlobalisJelszo123!")).thenReturn("$2b$10$new");
        when(branchRepository.findByCompanyIdAndIsActiveTrue(company.getId())).thenReturn(List.of(branch));
        when(workerRepository.save(any(Worker.class))).thenAnswer(inv -> inv.getArgument(0));
        when(jwtTokenProvider.generateToken(any(Worker.class))).thenReturn("jwt-token");

        WorkerFirstTimeSetupResponseDto response = service.setupWorkerPassword(dto);

        ArgumentCaptor<Worker> tokenWorker = ArgumentCaptor.forClass(Worker.class);
        verify(jwtTokenProvider).generateToken(tokenWorker.capture());
        assertThat(tokenWorker.getValue().getBranch()).isSameAs(branch);
        assertThat(response.getBranchCode()).isEqualTo("TISZA");
        assertThat(response.getToken()).isEqualTo("jwt-token");
    }

    @Test
    @DisplayName("Masik lokalis appMode-hoz tartozo role eseten nem ir uj jelszohash-t")
    void rejectsSetupWhenNoRoleMatchesAppMode() {
        Worker worker = seedWorker("$2b$10$seed");
        WorkerFirstTimeSetupRequestDto dto = request("1234");
        dto.setAppMode("penztar");
        when(companyRepository.findByCode("EBC")).thenReturn(Optional.of(company));
        when(workerRepository.findByCompanyIdAndCodeIgnoreCase(company.getId(), "BORSI"))
                .thenReturn(Optional.of(worker));
        when(workerRoleService.getRoleCodesForWorker(10L)).thenReturn(List.of("ertektar"));
        when(adminBootstrapService.isBootstrapAlreadyCompleted()).thenReturn(true);
        when(passwordEncoder.matches("1234", "$2b$10$seed")).thenReturn(true);

        assertThatThrownBy(() -> service.setupWorkerPassword(dto))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("használható");

        verify(passwordEncoder, never()).encode(any());
        verify(workerRepository, never()).save(any(Worker.class));
        verifyNoTokenGenerated();
    }

    @Test
    @DisplayName("AppMode fallbackban tobb szerver role kozul az elsot valasztja automatikusan")
    void autoSelectsFirstSelectableRoleForSetup() {
        Worker worker = seedWorker("$2b$10$seed");
        WorkerFirstTimeSetupRequestDto dto = request("1234");
        dto.setAppMode("ertektar");
        when(companyRepository.findByCode("EBC")).thenReturn(Optional.of(company));
        when(workerRepository.findByCompanyIdAndCodeIgnoreCase(company.getId(), "BORSI"))
                .thenReturn(Optional.of(worker));
        when(adminBootstrapService.isBootstrapAlreadyCompleted()).thenReturn(true);
        when(passwordEncoder.matches("1234", "$2b$10$seed")).thenReturn(true);
        when(workerRoleService.getRoleCodesForWorker(10L)).thenReturn(List.of("ugyvezeto", "foertektar"));
        when(passwordEncoder.encode("UjGlobalisJelszo123!")).thenReturn("$2b$10$new");
        when(workerRepository.save(any(Worker.class))).thenAnswer(inv -> inv.getArgument(0));
        when(workerRoleService.getPermissionCodesForRole("ugyvezeto")).thenReturn(List.of());
        when(jwtTokenProvider.generateToken(any(Worker.class), any(String.class), any(List.class))).thenReturn("jwt-token");

        WorkerFirstTimeSetupResponseDto response = service.setupWorkerPassword(dto);

        assertThat(response.isSuccess()).isTrue();
        assertThat(response.getActiveRole()).isEqualTo("ugyvezeto");
    }

    @Test
    @DisplayName("Legacy CASHIER role assignment nelkul sem allithat jelszot ertektar appMode-ban")
    void rejectsLegacyWorkerRoleWhenNoAssignmentsMatchAppMode() {
        Worker worker = seedWorker("$2b$10$seed");
        WorkerFirstTimeSetupRequestDto dto = request("1234");
        dto.setAppMode("ertektar");
        when(companyRepository.findByCode("EBC")).thenReturn(Optional.of(company));
        when(workerRepository.findByCompanyIdAndCodeIgnoreCase(company.getId(), "BORSI"))
                .thenReturn(Optional.of(worker));
        when(adminBootstrapService.isBootstrapAlreadyCompleted()).thenReturn(true);
        when(passwordEncoder.matches("1234", "$2b$10$seed")).thenReturn(true);
        when(workerRoleService.getRoleCodesForWorker(10L)).thenReturn(List.of());

        assertThatThrownBy(() -> service.setupWorkerPassword(dto))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("használható");

        verify(passwordEncoder, never()).encode(any());
        verify(workerRepository, never()).save(any(Worker.class));
        verify(jwtTokenProvider, never()).generateToken(any(Worker.class));
    }

    @Test
    @DisplayName("Lezart bootstrap utan hibas kezdo jelszo nem ir uj hash-t")
    void rejectsWrongCurrentPasswordAfterBootstrap() {
        Worker worker = seedWorker("$2b$10$seed");
        when(companyRepository.findByCode("EBC")).thenReturn(Optional.of(company));
        when(workerRepository.findByCompanyIdAndCodeIgnoreCase(company.getId(), "BORSI"))
                .thenReturn(Optional.of(worker));
        when(adminBootstrapService.isBootstrapAlreadyCompleted()).thenReturn(true);
        when(passwordEncoder.matches("rossz", "$2b$10$seed")).thenReturn(false);

        assertThatThrownBy(() -> service.setupWorkerPassword(request("rossz")))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("seed");

        verify(passwordEncoder, never()).encode(any());
        verify(workerRepository, never()).save(any(Worker.class));
    }

    @Test
    @DisplayName("Elso, meg le nem zart telepiteskor seed hash-sel currentPassword nelkul sem veheto at worker")
    void rejectsSeedWorkerWithoutCurrentPasswordBeforeBootstrap() {
        Worker worker = seedWorker("$2b$10$seed");
        when(companyRepository.findByCode("EBC")).thenReturn(Optional.of(company));
        when(workerRepository.findByCompanyIdAndCodeIgnoreCase(company.getId(), "BORSI"))
                .thenReturn(Optional.of(worker));
        when(adminBootstrapService.isBootstrapAlreadyCompleted()).thenReturn(false);

        assertThatThrownBy(() -> service.setupWorkerPassword(request(null)))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("kezdo jelszo tartozik")
                .hasMessageContaining("jelenlegi vagy kezdo");

        verify(passwordEncoder, never()).encode(any());
        verify(workerRepository, never()).save(any(Worker.class));
        verifyNoTokenGenerated();
    }

    @Test
    @DisplayName("V198 fix: Lezart bootstrap utan hash + passwordChangedAt nelkuli worker szabadon allithat jelszot (ujratelepites use-case)")
    void allowsMissingHashAfterBootstrapWhenFullyReset() {
        // V198 migracio: password_hash = NULL, password_changed_at = NULL
        // Ez az ujratelepites use-case — a dolgozo teljesen resetelt allapotban van.
        Worker worker = seedWorker(null);
        when(companyRepository.findByCode("EBC")).thenReturn(Optional.of(company));
        when(workerRepository.findByCompanyIdAndCodeIgnoreCase(company.getId(), "BORSI"))
                .thenReturn(Optional.of(worker));
        when(adminBootstrapService.isBootstrapAlreadyCompleted()).thenReturn(true);
        when(passwordEncoder.encode("UjGlobalisJelszo123!")).thenReturn("$2b$10$new");
        when(workerRepository.save(any(Worker.class))).thenAnswer(inv -> inv.getArgument(0));
        when(jwtTokenProvider.generateToken(any(Worker.class))).thenReturn("jwt-token");

        WorkerFirstTimeSetupResponseDto response = service.setupWorkerPassword(request(null));

        assertThat(response.isSuccess()).isTrue();
        verify(workerRepository).save(any(Worker.class));
    }

    @Test
    @DisplayName("Friss, bootstrap elotti hash nelkuli workerhez tovabbra is beallithato az elso jelszo")
    void allowsMissingHashBeforeBootstrap() {
        Worker worker = seedWorker(null);
        when(companyRepository.findByCode("EBC")).thenReturn(Optional.of(company));
        when(workerRepository.findByCompanyIdAndCodeIgnoreCase(company.getId(), "BORSI"))
                .thenReturn(Optional.of(worker));
        when(adminBootstrapService.isBootstrapAlreadyCompleted()).thenReturn(false);
        when(passwordEncoder.encode("UjGlobalisJelszo123!")).thenReturn("$2b$10$new");
        when(workerRepository.save(any(Worker.class))).thenAnswer(inv -> inv.getArgument(0));
        when(jwtTokenProvider.generateToken(any(Worker.class))).thenReturn("jwt-token");

        WorkerFirstTimeSetupResponseDto response = service.setupWorkerPassword(request(null));

        assertThat(response.isSuccess()).isTrue();
        verify(workerRepository).save(any(Worker.class));
    }

    // ─── Hibauzenet-konzisztencia tesztek ───

    @Test
    @DisplayName("Ismeretlen cegkod pontos hibauzenettel ter vissza")
    void unknownCompanyCodeReturnsExactMessage() {
        when(companyRepository.findByCode("NEMLETEZIK")).thenReturn(Optional.empty());
        when(companyRepository.findByCodeIgnoreCase("NEMLETEZIK")).thenReturn(Optional.empty());

        WorkerFirstTimeSetupRequestDto dto = new WorkerFirstTimeSetupRequestDto(
                "nemletezik", "borsi", "UjGlobalisJelszo123!", null);

        assertThatThrownBy(() -> service.setupWorkerPassword(dto))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("Ismeretlen cegkod: NEMLETEZIK");
    }

    @Test
    @DisplayName("Ismeretlen dolgozoi azonosito pontos hibauzenettel ter vissza")
    void unknownWorkerCodeReturnsExactMessage() {
        when(companyRepository.findByCode("EBC")).thenReturn(Optional.of(company));
        when(workerRepository.findByCompanyIdAndCodeIgnoreCase(company.getId(), "NEMLETEZIK"))
                .thenReturn(Optional.empty());

        WorkerFirstTimeSetupRequestDto dto = new WorkerFirstTimeSetupRequestDto(
                "ebc", "nemletezik", "UjGlobalisJelszo123!", null);

        assertThatThrownBy(() -> service.setupWorkerPassword(dto))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("Ismeretlen dolgozoi azonosito: NEMLETEZIK")
                .hasMessageContaining("ceg: EBC");
    }

    @Test
    @DisplayName("Inaktiv worker pontos hibauzenettel ter vissza")
    void inactiveWorkerReturnsExactMessage() {
        Worker worker = seedWorker("$2b$10$seed");
        worker.setActive(false);
        when(companyRepository.findByCode("EBC")).thenReturn(Optional.of(company));
        when(workerRepository.findByCompanyIdAndCodeIgnoreCase(company.getId(), "BORSI"))
                .thenReturn(Optional.of(worker));

        assertThatThrownBy(() -> service.setupWorkerPassword(request(null)))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("inaktiv");
    }

    @Test
    @DisplayName("Aktiv jelszoval rendelkezo worker hibas jelenlegi jelszora pontos uzenetet ad")
    void activePasswordMismatchReturnsExactMessage() {
        Worker worker = seedWorker("$2b$10$active");
        worker.setPasswordChangedAt(java.time.LocalDateTime.now());
        when(companyRepository.findByCode("EBC")).thenReturn(Optional.of(company));
        when(workerRepository.findByCompanyIdAndCodeIgnoreCase(company.getId(), "BORSI"))
                .thenReturn(Optional.of(worker));
        when(passwordEncoder.matches("rossz", "$2b$10$active")).thenReturn(false);

        assertThatThrownBy(() -> service.setupWorkerPassword(request("rossz")))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("jelenlegi jelszo nem egyezik");
    }

    @Test
    @DisplayName("Aktiv jelszoval rendelkezo worker jelenlegi jelszo nelkul pontos uzenetet ad")
    void activePasswordRequiredReturnsExactMessage() {
        Worker worker = seedWorker("$2b$10$active");
        worker.setPasswordChangedAt(java.time.LocalDateTime.now());
        when(companyRepository.findByCode("EBC")).thenReturn(Optional.of(company));
        when(workerRepository.findByCompanyIdAndCodeIgnoreCase(company.getId(), "BORSI"))
                .thenReturn(Optional.of(worker));

        assertThatThrownBy(() -> service.setupWorkerPassword(request(null)))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("mar beallitott jelszot")
                .hasMessageContaining("jelenlegi jelszo is kotelezo");
    }

    @Test
    @DisplayName("Ertektar-only role penztar appMode-ban pontos uzenetet ad")
    void ertektarRoleInPenztarModeReturnsExactMessage() {
        Worker worker = seedWorker("$2b$10$seed");
        WorkerFirstTimeSetupRequestDto dto = request("1234");
        dto.setAppMode("penztar");
        when(companyRepository.findByCode("EBC")).thenReturn(Optional.of(company));
        when(workerRepository.findByCompanyIdAndCodeIgnoreCase(company.getId(), "BORSI"))
                .thenReturn(Optional.of(worker));
        when(adminBootstrapService.isBootstrapAlreadyCompleted()).thenReturn(true);
        when(passwordEncoder.matches("1234", "$2b$10$seed")).thenReturn(true);
        when(workerRoleService.getRoleCodesForWorker(10L)).thenReturn(List.of("ertektar"));

        assertThatThrownBy(() -> service.setupWorkerPassword(dto))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("Nincs ebben a programban használható szerepköre");
    }

    @Test
    @DisplayName("Penztar role penztar appMode-ban sikeresen vegigmegy")
    void penztarRoleInPenztarModeSucceeds() {
        Worker worker = seedWorker("$2b$10$seed");
        WorkerFirstTimeSetupRequestDto dto = request("1234");
        dto.setAppMode("penztar");
        when(companyRepository.findByCode("EBC")).thenReturn(Optional.of(company));
        when(workerRepository.findByCompanyIdAndCodeIgnoreCase(company.getId(), "BORSI"))
                .thenReturn(Optional.of(worker));
        when(adminBootstrapService.isBootstrapAlreadyCompleted()).thenReturn(true);
        when(passwordEncoder.matches("1234", "$2b$10$seed")).thenReturn(true);
        when(workerRoleService.getRoleCodesForWorker(10L)).thenReturn(List.of("penztar", "foertektar"));
        when(workerRoleService.getPermissionCodesForRole("penztar")).thenReturn(List.of("TRANSACTION_BUY"));
        when(passwordEncoder.encode("UjGlobalisJelszo123!")).thenReturn("$2b$10$new");
        when(workerRepository.save(any(Worker.class))).thenAnswer(inv -> inv.getArgument(0));
        when(jwtTokenProvider.generateToken(any(Worker.class), any(String.class), any(List.class))).thenReturn("jwt");

        WorkerFirstTimeSetupResponseDto response = service.setupWorkerPassword(dto);

        assertThat(response.isSuccess()).isTrue();
        assertThat(response.getActiveRole()).isEqualTo("penztar");
    }

    @Test
    @DisplayName("Szerver role (ugyvezeto) penztar appMode-ban sikeresen vegigmegy")
    void serverRoleInPenztarModeSucceeds() {
        Worker worker = seedWorker("$2b$10$seed");
        WorkerFirstTimeSetupRequestDto dto = request("1234");
        dto.setAppMode("penztar");
        when(companyRepository.findByCode("EBC")).thenReturn(Optional.of(company));
        when(workerRepository.findByCompanyIdAndCodeIgnoreCase(company.getId(), "BORSI"))
                .thenReturn(Optional.of(worker));
        when(adminBootstrapService.isBootstrapAlreadyCompleted()).thenReturn(true);
        when(passwordEncoder.matches("1234", "$2b$10$seed")).thenReturn(true);
        when(workerRoleService.getRoleCodesForWorker(10L)).thenReturn(List.of("ugyvezeto"));
        when(workerRoleService.getPermissionCodesForRole("ugyvezeto")).thenReturn(List.of());
        when(passwordEncoder.encode("UjGlobalisJelszo123!")).thenReturn("$2b$10$new");
        when(workerRepository.save(any(Worker.class))).thenAnswer(inv -> inv.getArgument(0));
        when(jwtTokenProvider.generateToken(any(Worker.class), any(String.class), any(List.class))).thenReturn("jwt");

        WorkerFirstTimeSetupResponseDto response = service.setupWorkerPassword(dto);

        assertThat(response.isSuccess()).isTrue();
        assertThat(response.getActiveRole()).isEqualTo("ugyvezeto");
    }

    @Test
    @DisplayName("AppMode nelkul tobb role eseten pontos hibauzenet")
    void multipleRolesWithoutAppModeReturnsExactMessage() {
        Worker worker = seedWorker("$2b$10$seed");
        WorkerFirstTimeSetupRequestDto dto = new WorkerFirstTimeSetupRequestDto(
                "ebc", "borsi", "UjGlobalisJelszo123!", "1234");
        when(companyRepository.findByCode("EBC")).thenReturn(Optional.of(company));
        when(workerRepository.findByCompanyIdAndCodeIgnoreCase(company.getId(), "BORSI"))
                .thenReturn(Optional.of(worker));
        when(adminBootstrapService.isBootstrapAlreadyCompleted()).thenReturn(true);
        when(passwordEncoder.matches("1234", "$2b$10$seed")).thenReturn(true);
        when(workerRoleService.getRoleCodesForWorker(10L)).thenReturn(List.of("penztar", "ertektar"));

        assertThatThrownBy(() -> service.setupWorkerPassword(dto))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("programtipus megadasa kotelezo");
    }

    private WorkerFirstTimeSetupRequestDto request(String currentPassword) {
        return new WorkerFirstTimeSetupRequestDto(
                "ebc",
                "borsi",
                "UjGlobalisJelszo123!",
                currentPassword
        );
    }

    private Worker seedWorker(String passwordHash) {
        Worker worker = new Worker();
        worker.setId(10L);
        worker.setCompany(company);
        worker.setBranch(branch);
        worker.setCode("BORSI");
        worker.setName("Borsi Kollegano");
        worker.setRole(WorkerRole.CASHIER);
        worker.setActive(true);
        worker.setPasswordHash(passwordHash);
        worker.setPasswordChangedAt(null);
        return worker;
    }

    private void verifyNoTokenGenerated() {
        verify(jwtTokenProvider, never()).generateToken(any(Worker.class));
        verify(jwtTokenProvider, never()).generateToken(any(Worker.class), any(String.class), any());
    }
}
