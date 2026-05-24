package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.auth.BootstrapAdminRequestDto;
import hu.puzzleir.valuta.dto.auth.BootstrapAdminResponseDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.SystemParameter;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.entity.WorkerRole;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.repository.SystemParameterRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
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
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * {@link AdminBootstrapService} egységtesztek.
 *
 * Tesztesetek:
 *   1. Happy path: létezik worker, frissítjük, flag-et beállítjuk
 *   2. Worker nem létezik: új workert hozunk létre az első aktív branch-hez kötve
 *   3. Bootstrap flag már true: ValidationException, nincs publikus jelszó reset
 *   4. Cégkód nem található: ValidationException
 *   5. Nincs branch a cégnél: ValidationException (újlétrehozás esetén)
 *   6. isBootstrapAlreadyCompleted: false ha nincs flag, true ha van és active
 */
@ExtendWith(MockitoExtension.class)
@DisplayName("AdminBootstrapService — first-run wizard admin létrehozás")
class AdminBootstrapServiceTest {

    @Mock private CompanyRepository companyRepository;
    @Mock private BranchRepository branchRepository;
    @Mock private WorkerRepository workerRepository;
    @Mock private SystemParameterRepository systemParameterRepository;
    @Mock private PasswordEncoder passwordEncoder;

    @InjectMocks private AdminBootstrapService service;

    private Company ebcCompany;
    private Branch tiszaBranch;

    @BeforeEach
    void setUp() {
        ebcCompany = new Company();
        ebcCompany.setId(UUID.randomUUID());
        ebcCompany.setCode("EBC");
        ebcCompany.setName("Exclusive Best Change Zrt.");

        tiszaBranch = new Branch();
        tiszaBranch.setId(UUID.randomUUID());
        tiszaBranch.setCompany(ebcCompany);
        tiszaBranch.setCode("TISZA");
        tiszaBranch.setName("Tisza Sarok");
        tiszaBranch.setIsActive(true);
    }

    private BootstrapAdminRequestDto validRequest() {
        return new BootstrapAdminRequestDto(
                "ebc",
                "admin",
                "Admin Master",
                "admin@example.com",
                "SuperErosJelszo123!"
        );
    }

    @Test
    @DisplayName("Happy path: létező worker frissítése ADMIN role-ra + jelszó csere + flag")
    void happyPath_existingWorker() {
        when(systemParameterRepository.findByParameterKey(AdminBootstrapService.BOOTSTRAP_FLAG_KEY))
                .thenReturn(Optional.empty());
        when(companyRepository.findByCode("EBC")).thenReturn(Optional.of(ebcCompany));

        Worker existing = new Worker();
        existing.setId(42L);
        existing.setCompany(ebcCompany);
        existing.setBranch(tiszaBranch);
        existing.setCode("ADMIN");
        existing.setName("Régi név");
        existing.setRole(WorkerRole.CASHIER);
        existing.setActive(false);

        when(workerRepository.findByCompanyIdAndCodeIgnoreCase(ebcCompany.getId(), "ADMIN"))
                .thenReturn(Optional.of(existing));
        when(passwordEncoder.encode("SuperErosJelszo123!")).thenReturn("$2b$10$hashed");
        when(workerRepository.save(any(Worker.class))).thenAnswer(inv -> inv.getArgument(0));

        BootstrapAdminResponseDto response = service.bootstrapAdmin(validRequest());

        assertThat(response.isSuccess()).isTrue();
        assertThat(response.getCompanyCode()).isEqualTo("EBC");
        assertThat(response.getWorkerCode()).isEqualTo("ADMIN");

        ArgumentCaptor<Worker> captor = ArgumentCaptor.forClass(Worker.class);
        verify(workerRepository).save(captor.capture());
        Worker saved = captor.getValue();
        assertThat(saved.getRole()).isEqualTo(WorkerRole.ADMIN);
        assertThat(saved.getActive()).isTrue();
        assertThat(saved.getPasswordHash()).isEqualTo("$2b$10$hashed");
        assertThat(saved.getName()).isEqualTo("Admin Master");
        assertThat(saved.getEmail()).isEqualTo("admin@example.com");
        assertThat(saved.getPasswordChangedAt()).isNotNull();

        // Flag beállítás ellenőrzés
        ArgumentCaptor<SystemParameter> flagCaptor = ArgumentCaptor.forClass(SystemParameter.class);
        verify(systemParameterRepository).save(flagCaptor.capture());
        assertThat(flagCaptor.getValue().getParameterValue()).isEqualTo("true");
        assertThat(flagCaptor.getValue().getIsActive()).isTrue();
    }

    @Test
    @DisplayName("Worker nem létezik: újat hoz létre az első aktív branch-hez")
    void happyPath_newWorker() {
        when(systemParameterRepository.findByParameterKey(AdminBootstrapService.BOOTSTRAP_FLAG_KEY))
                .thenReturn(Optional.empty());
        when(companyRepository.findByCode("EBC")).thenReturn(Optional.of(ebcCompany));
        when(workerRepository.findByCompanyIdAndCodeIgnoreCase(ebcCompany.getId(), "ADMIN"))
                .thenReturn(Optional.empty());
        when(branchRepository.findByCompanyIdAndIsActiveTrue(ebcCompany.getId()))
                .thenReturn(List.of(tiszaBranch));
        when(passwordEncoder.encode(anyString())).thenReturn("$2b$10$hashed");
        when(workerRepository.save(any(Worker.class))).thenAnswer(inv -> {
            Worker w = inv.getArgument(0);
            w.setId(100L);
            return w;
        });

        BootstrapAdminResponseDto response = service.bootstrapAdmin(validRequest());

        assertThat(response.isSuccess()).isTrue();
        assertThat(response.getWorkerId()).isEqualTo(100L);

        ArgumentCaptor<Worker> captor = ArgumentCaptor.forClass(Worker.class);
        verify(workerRepository).save(captor.capture());
        Worker saved = captor.getValue();
        assertThat(saved.getCode()).isEqualTo("ADMIN");
        assertThat(saved.getBranch()).isEqualTo(tiszaBranch);
        assertThat(saved.getRole()).isEqualTo(WorkerRole.ADMIN);
    }

    @Test
    @DisplayName("PP-14: bootstrap flag már true → ValidationException, cég NEM kerül lekérdezésre (enumeration guard)")
    void rejectsRepeatedBootstrapPasswordUpdate() {
        SystemParameter completedFlag = SystemParameter.builder()
                .parameterKey(AdminBootstrapService.BOOTSTRAP_FLAG_KEY)
                .parameterValue("true")
                .isActive(true)
                .build();
        when(systemParameterRepository.findByParameterKey(AdminBootstrapService.BOOTSTRAP_FLAG_KEY))
                .thenReturn(Optional.of(completedFlag));

        assertThatThrownBy(() -> service.bootstrapAdmin(validRequest()))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("bootstrap már lezajlott")
                .hasMessageContaining("hitelesített");

        // PP-14: cégkód feloldás NEM fut le — enumeration-prevention
        verify(companyRepository, never()).findByCode(anyString());
        verify(companyRepository, never()).findByCodeIgnoreCase(anyString());
        verify(workerRepository, never()).findByCompanyIdAndCodeIgnoreCase(any(), anyString());
        verify(passwordEncoder, never()).encode(anyString());
        verify(workerRepository, never()).save(any(Worker.class));
    }

    @Test
    @DisplayName("Ismeretlen cégkód -> ValidationException")
    void rejectsUnknownCompany() {
        when(systemParameterRepository.findByParameterKey(AdminBootstrapService.BOOTSTRAP_FLAG_KEY))
                .thenReturn(Optional.empty());
        when(companyRepository.findByCode("EBC")).thenReturn(Optional.empty());
        when(companyRepository.findByCodeIgnoreCase("EBC")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.bootstrapAdmin(validRequest()))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("Ismeretlen cégkód");
    }

    @Test
    @DisplayName("Nincs branch a cégnél -> ValidationException")
    void rejectsCompanyWithoutBranches() {
        when(systemParameterRepository.findByParameterKey(AdminBootstrapService.BOOTSTRAP_FLAG_KEY))
                .thenReturn(Optional.empty());
        when(companyRepository.findByCode("EBC")).thenReturn(Optional.of(ebcCompany));
        when(workerRepository.findByCompanyIdAndCodeIgnoreCase(ebcCompany.getId(), "ADMIN"))
                .thenReturn(Optional.empty());
        when(branchRepository.findByCompanyIdAndIsActiveTrue(ebcCompany.getId())).thenReturn(List.of());
        when(branchRepository.findByCompanyId(ebcCompany.getId())).thenReturn(List.of());

        assertThatThrownBy(() -> service.bootstrapAdmin(validRequest()))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("nincs egyetlen branch sem");
    }

    @Test
    @DisplayName("isBootstrapAlreadyCompleted — false ha nincs flag vagy inaktív")
    void bootstrapStatus_checks() {
        when(systemParameterRepository.findByParameterKey(AdminBootstrapService.BOOTSTRAP_FLAG_KEY))
                .thenReturn(Optional.empty());
        assertThat(service.isBootstrapAlreadyCompleted()).isFalse();

        SystemParameter inactive = SystemParameter.builder()
                .parameterKey(AdminBootstrapService.BOOTSTRAP_FLAG_KEY)
                .parameterValue("true")
                .isActive(false)
                .build();
        when(systemParameterRepository.findByParameterKey(AdminBootstrapService.BOOTSTRAP_FLAG_KEY))
                .thenReturn(Optional.of(inactive));
        assertThat(service.isBootstrapAlreadyCompleted()).isFalse();

        SystemParameter active = SystemParameter.builder()
                .parameterKey(AdminBootstrapService.BOOTSTRAP_FLAG_KEY)
                .parameterValue("true")
                .isActive(true)
                .build();
        when(systemParameterRepository.findByParameterKey(AdminBootstrapService.BOOTSTRAP_FLAG_KEY))
                .thenReturn(Optional.of(active));
        assertThat(service.isBootstrapAlreadyCompleted()).isTrue();

        SystemParameter falseValue = SystemParameter.builder()
                .parameterKey(AdminBootstrapService.BOOTSTRAP_FLAG_KEY)
                .parameterValue("false")
                .isActive(true)
                .build();
        when(systemParameterRepository.findByParameterKey(AdminBootstrapService.BOOTSTRAP_FLAG_KEY))
                .thenReturn(Optional.of(falseValue));
        assertThat(service.isBootstrapAlreadyCompleted()).isFalse();
    }

    @Test
    @DisplayName("Email opcionális — ha null, a meglévő email marad")
    void optionalEmail_preservesExisting() {
        when(systemParameterRepository.findByParameterKey(AdminBootstrapService.BOOTSTRAP_FLAG_KEY))
                .thenReturn(Optional.empty());
        when(companyRepository.findByCode("EBC")).thenReturn(Optional.of(ebcCompany));

        Worker existing = new Worker();
        existing.setCompany(ebcCompany);
        existing.setBranch(tiszaBranch);
        existing.setCode("ADMIN");
        existing.setName("Admin");
        existing.setEmail("old@example.com");
        existing.setRole(WorkerRole.CASHIER);

        when(workerRepository.findByCompanyIdAndCodeIgnoreCase(ebcCompany.getId(), "ADMIN"))
                .thenReturn(Optional.of(existing));
        when(passwordEncoder.encode(anyString())).thenReturn("$2b$10$hashed");
        when(workerRepository.save(any(Worker.class))).thenAnswer(inv -> inv.getArgument(0));

        BootstrapAdminRequestDto dto = validRequest();
        dto.setEmail(null);

        service.bootstrapAdmin(dto);

        ArgumentCaptor<Worker> captor = ArgumentCaptor.forClass(Worker.class);
        verify(workerRepository, times(1)).save(captor.capture());
        assertThat(captor.getValue().getEmail()).isEqualTo("old@example.com");
    }
}
