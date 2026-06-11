package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.MachineConfig;
import hu.puzzleir.valuta.repository.MachineConfigRepository;
import hu.puzzleir.valuta.security.WorkerAuthenticationDetails;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

/**
 * EXCMD b6-beallitasok FR-14 — MachineConfigService unit teszt.
 *
 * <p>Lefedi: upsert, company-izoláció/cross-tenant védelme, jelszó hash-elés,
 * és hogy GET nem adja vissza a jelszó hash-t (a service szinten a rekordban
 * a hash megvan, de a controller soha nem hozza ki — ezt az integrációs tesztek
 * fedik; itt a service-szintű viselkedést teszteljük).</p>
 */
@ExtendWith(MockitoExtension.class)
class MachineConfigServiceTest {

    @Mock private MachineConfigRepository machineConfigRepository;
    @Mock private PasswordEncoder passwordEncoder;
    @InjectMocks private MachineConfigService service;

    private final UUID companyId = UUID.randomUUID();
    private final UUID otherCompanyId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        // Bejelentkezett worker company = companyId
        UsernamePasswordAuthenticationToken auth =
                new UsernamePasswordAuthenticationToken("W42", null, List.of());
        auth.setDetails(new WorkerAuthenticationDetails(42L, companyId, UUID.randomUUID(), "CASHIER"));
        SecurityContextHolder.getContext().setAuthentication(auth);
    }

    @AfterEach
    void clear() {
        SecurityContextHolder.clearContext();
    }

    // --- upsert: új rekord létrehozása ---

    @Test
    @DisplayName("upsert — új rekord: nem létező workstation esetén új MachineConfig mentése")
    void upsert_newRecord_savesNewEntity() {
        when(machineConfigRepository.findByCompanyIdAndWorkstationCode(companyId, "BR039"))
                .thenReturn(Optional.empty());
        when(machineConfigRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        MachineConfig result = service.upsert("BR039", "{\"machineRole\":\"PENZTARI\"}", null);

        ArgumentCaptor<MachineConfig> captor = ArgumentCaptor.forClass(MachineConfig.class);
        verify(machineConfigRepository).save(captor.capture());
        MachineConfig saved = captor.getValue();

        assertThat(saved.getCompanyId()).isEqualTo(companyId);
        assertThat(saved.getWorkstationCode()).isEqualTo("BR039");
        assertThat(saved.getConfig()).isEqualTo("{\"machineRole\":\"PENZTARI\"}");
        assertThat(saved.getUpdatedBy()).isEqualTo("W42");
        assertThat(saved.getUpdatedAt()).isNotNull();
        // Nincs jelszó: hash null
        assertThat(saved.getDailyReportPasswordHash()).isNull();
    }

    @Test
    @DisplayName("upsert — meglévő rekord frissítése: config cserélődik, id megmarad")
    void upsert_existingRecord_updatesInPlace() {
        UUID existingId = UUID.randomUUID();
        MachineConfig existing = MachineConfig.builder()
                .id(existingId)
                .companyId(companyId)
                .workstationCode("BR039")
                .config("{\"machineRole\":\"ERTEKTARI\"}")
                .updatedAt(LocalDateTime.now().minusDays(1))
                .updatedBy("W1")
                .build();
        when(machineConfigRepository.findByCompanyIdAndWorkstationCode(companyId, "BR039"))
                .thenReturn(Optional.of(existing));
        when(machineConfigRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        service.upsert("BR039", "{\"machineRole\":\"PENZTARI\"}", null);

        ArgumentCaptor<MachineConfig> captor = ArgumentCaptor.forClass(MachineConfig.class);
        verify(machineConfigRepository).save(captor.capture());
        MachineConfig saved = captor.getValue();
        // Azonos id (update, nem insert)
        assertThat(saved.getId()).isEqualTo(existingId);
        assertThat(saved.getConfig()).isEqualTo("{\"machineRole\":\"PENZTARI\"}");
        assertThat(saved.getUpdatedBy()).isEqualTo("W42");
    }

    // --- Jelszó hash-elés ---

    @Test
    @DisplayName("upsert — ha dailyReportPassword meg van adva, BCrypt-tel hash-eli és menti")
    void upsert_withPassword_hashesAndStores() {
        when(machineConfigRepository.findByCompanyIdAndWorkstationCode(companyId, "BR039"))
                .thenReturn(Optional.empty());
        when(passwordEncoder.encode("titkos123")).thenReturn("$2a$12$hashedvalue");
        when(machineConfigRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        service.upsert("BR039", "{}", "titkos123");

        ArgumentCaptor<MachineConfig> captor = ArgumentCaptor.forClass(MachineConfig.class);
        verify(machineConfigRepository).save(captor.capture());
        // Hash mentve
        assertThat(captor.getValue().getDailyReportPasswordHash()).isEqualTo("$2a$12$hashedvalue");
        verify(passwordEncoder).encode("titkos123");
    }

    @Test
    @DisplayName("upsert — ha dailyReportPassword null, a meglévő hash nem változik")
    void upsert_nullPassword_keepsExistingHash() {
        MachineConfig existing = MachineConfig.builder()
                .id(UUID.randomUUID())
                .companyId(companyId)
                .workstationCode("BR039")
                .config("{}")
                .dailyReportPasswordHash("$2a$12$existinghash")
                .build();
        when(machineConfigRepository.findByCompanyIdAndWorkstationCode(companyId, "BR039"))
                .thenReturn(Optional.of(existing));
        when(machineConfigRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        service.upsert("BR039", "{\"machineRole\":\"PENZTARI\"}", null);

        ArgumentCaptor<MachineConfig> captor = ArgumentCaptor.forClass(MachineConfig.class);
        verify(machineConfigRepository).save(captor.capture());
        // Hash megmaradt, PasswordEncoder NEM lett meghívva
        assertThat(captor.getValue().getDailyReportPasswordHash()).isEqualTo("$2a$12$existinghash");
        verify(passwordEncoder, never()).encode(anyString());
    }

    @Test
    @DisplayName("upsert — ha dailyReportPassword üres string, a meglévő hash nem változik")
    void upsert_emptyPassword_keepsExistingHash() {
        MachineConfig existing = MachineConfig.builder()
                .id(UUID.randomUUID())
                .companyId(companyId)
                .workstationCode("BR039")
                .config("{}")
                .dailyReportPasswordHash("$2a$12$existinghash")
                .build();
        when(machineConfigRepository.findByCompanyIdAndWorkstationCode(companyId, "BR039"))
                .thenReturn(Optional.of(existing));
        when(machineConfigRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        service.upsert("BR039", "{}", "");

        verify(passwordEncoder, never()).encode(anyString());
    }

    // --- GET: hash soha nem adódik vissza ---

    @Test
    @DisplayName("getConfig — visszaad rekordot (a service szinten a hash megvan, de null-biztonságos)")
    void getConfig_returnsRecord_withHashPresent() {
        MachineConfig mc = MachineConfig.builder()
                .id(UUID.randomUUID())
                .companyId(companyId)
                .workstationCode("BR039")
                .config("{\"machineRole\":\"PENZTARI\"}")
                .dailyReportPasswordHash("$2a$12$existinghash")
                .updatedAt(LocalDateTime.now())
                .updatedBy("W42")
                .build();
        when(machineConfigRepository.findByCompanyIdAndWorkstationCode(companyId, "BR039"))
                .thenReturn(Optional.of(mc));

        MachineConfig result = service.getConfig("BR039");

        assertThat(result).isNotNull();
        // A service visszaadja a teljes rekordot — a controller felelőssége, hogy
        // a hash-t NE tegye a válasz JSON-ba (dailyReportPasswordSet = true jelzőként).
        assertThat(result.getDailyReportPasswordHash()).isNotNull();
        assertThat(result.getConfig()).contains("machineRole");
    }

    @Test
    @DisplayName("getConfig — nem létező rekordnál null visszatérés (nem 404)")
    void getConfig_notFound_returnsNull() {
        when(machineConfigRepository.findByCompanyIdAndWorkstationCode(companyId, "BR039"))
                .thenReturn(Optional.empty());

        MachineConfig result = service.getConfig("BR039");

        assertThat(result).isNull();
    }

    // --- Company-izoláció / cross-tenant védelme ---

    @Test
    @DisplayName("company-izoláció: upsert mindig a bejelentkezett company-hoz ment, nem kap companyId-t klienstől")
    void upsert_alwaysUsesSecurityContextCompanyId() {
        when(machineConfigRepository.findByCompanyIdAndWorkstationCode(eq(companyId), eq("BR039")))
                .thenReturn(Optional.empty());
        when(machineConfigRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        service.upsert("BR039", "{}", null);

        // Csak a companyId-val kerestük (NEM az otherCompanyId-val)
        verify(machineConfigRepository).findByCompanyIdAndWorkstationCode(eq(companyId), eq("BR039"));
        verify(machineConfigRepository, never())
                .findByCompanyIdAndWorkstationCode(eq(otherCompanyId), anyString());
    }

    @Test
    @DisplayName("company-izoláció: getConfig a SecurityContext companyId-jával szűr (cross-tenant védelme)")
    void getConfig_usesSecurityContextCompanyId() {
        when(machineConfigRepository.findByCompanyIdAndWorkstationCode(companyId, "BR099"))
                .thenReturn(Optional.empty());

        service.getConfig("BR099");

        verify(machineConfigRepository).findByCompanyIdAndWorkstationCode(companyId, "BR099");
        // Más cégnél tárolt, azonos nevű workstation NEM elérhető
        verify(machineConfigRepository, never())
                .findByCompanyIdAndWorkstationCode(eq(otherCompanyId), anyString());
    }
}
