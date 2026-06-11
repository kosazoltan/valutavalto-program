package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.MachineConfig;
import hu.puzzleir.valuta.repository.MachineConfigRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * EXCMD b6-beallitasok FR-14 — gépenként izolált konfigurációs rekord kezelése.
 *
 * <h3>Multi-tenant invariáns</h3>
 * <p>A {@code companyId} MINDIG a {@link SecurityUtils#getCurrentCompanyId()} értéke — soha nem
 * fogadjuk el a klienstől. Minden metódus implicit company-szűréssel dolgozik.</p>
 *
 * <h3>Jelszó kezelés</h3>
 * <p>A napi-jelentés jelszava (FR-06) BCrypt-hash-elve tárolódik ({@code PasswordEncoder}).
 * A PUT payload-ban opcionálisan érkező {@code dailyReportPassword} plain-text értéket a service
 * hash-eli és csak a hash-t menti. A GET soha nem adja vissza a hash-t — csak
 * {@code dailyReportPasswordSet: true/false} jelzőt.</p>
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class MachineConfigService {

    private final MachineConfigRepository machineConfigRepository;
    private final PasswordEncoder passwordEncoder;

    /**
     * Konfigurációs rekord lekérése (company-szűrt).
     *
     * @param workstationCode a gép kódja (branch_code, pl. BR039)
     * @return a megtalált rekord, vagy null ha még nincs mentett konfiguráció
     */
    @Transactional(readOnly = true)
    public MachineConfig getConfig(String workstationCode) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return machineConfigRepository
                .findByCompanyIdAndWorkstationCode(companyId, workstationCode)
                .orElse(null);
    }

    /**
     * Konfiguráció upsert: ha létezik, frissíti; ha nem, létrehozza.
     *
     * <p>Ha a {@code plainPassword} nem null és nem üres, BCrypt-tel hash-eli és menti.
     * Üres string esetén a jelszó-hash nem változik (a meglévő megmarad).
     * A {@code companyId} MINDIG a SecurityContext-ből jön — a kliens által
     * megadott company értéket FIGYELMEN KÍVÜL HAGYJUK.</p>
     *
     * @param workstationCode a gép kódja
     * @param configJson      a frissített config JSON string (a teljes settings payload)
     * @param plainPassword   a napi-jelentés új jelszava plain-text-ben, vagy null/üres = nem változik
     * @return a mentett rekord
     */
    @Transactional
    public MachineConfig upsert(String workstationCode, String configJson, String plainPassword) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        String workerCode = SecurityUtils.getCurrentWorkerCode();

        MachineConfig mc = machineConfigRepository
                .findByCompanyIdAndWorkstationCode(companyId, workstationCode)
                .orElseGet(() -> {
                    log.info("[MachineConfig] Új konfiguráció létrehozva: company={} workstation={}", companyId, workstationCode);
                    return MachineConfig.builder()
                            .companyId(companyId)
                            .workstationCode(workstationCode)
                            .build();
                });

        mc.setConfig(configJson != null ? configJson : "{}");
        mc.setUpdatedAt(LocalDateTime.now());
        mc.setUpdatedBy(workerCode);

        // Jelszó csak akkor módosul, ha a kliens valóban küldött új értéket.
        // Üres/null → hash megmarad változatlanul (nem töröljük a meglévő jelszót).
        if (plainPassword != null && !plainPassword.isBlank()) {
            mc.setDailyReportPasswordHash(passwordEncoder.encode(plainPassword));
            log.info("[MachineConfig] Napi-jelentés jelszó frissítve (hash-elve): company={} workstation={}", companyId, workstationCode);
        }

        return machineConfigRepository.save(mc);
    }
}
