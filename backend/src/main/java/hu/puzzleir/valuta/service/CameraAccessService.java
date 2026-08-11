package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.CameraAccessLog;
import hu.puzzleir.valuta.entity.CameraConfig;
import hu.puzzleir.valuta.entity.CameraRecording;
import hu.puzzleir.valuta.entity.CameraTransactionLink;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CameraAccessLogRepository;
import hu.puzzleir.valuta.repository.CameraConfigRepository;
import hu.puzzleir.valuta.repository.CameraRecordingRepository;
import hu.puzzleir.valuta.repository.CameraTransactionLinkRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Kamera-hozzáférés use-case réteg: tenant-guard, felvétel-lekérdezés és audit-napló.
 *
 * <p><b>Miért létezik.</b> A {@code CameraController} és a {@code CameraAdminController}
 * korábban közvetlenül injektált öt repository-t (9, illetve 4 rétegsértés), és a
 * tenant-ellenőrzést ({@code enforceBranchAccess}) <b>bitre azonos</b> privát metódusként
 * mindkettő külön tartalmazta. Ez két konkrét kockázat:
 *
 * <ol>
 *   <li><b>Tranzakcióhatár hiánya.</b> Az OSIV ki van kapcsolva, ezért a controller-szintű
 *       repository-olvasásnak nincs tranzakciója. A guard viszont <b>lazy asszociációt
 *       olvas</b> ({@code branch.getCompany().getId()}), és a
 *       {@code CameraTransactionLink#getRecording()} is lazy — ezek a hívások a
 *       prezentációs rétegben {@code LazyInitializationException}-re futhatnak, ami a
 *       {@code canAccessLink} néma {@code catch (RuntimeException)} ágán
 *       <b>hozzáférés-megtagadássá csendesedik</b>: a hívó nem hibát lát, hanem hiányzó
 *       felvételt. Egy kamerás bizonyíték így vizsgálat közben tűnhetne el.</li>
 *   <li><b>Duplikált biztonsági szabály.</b> Két másolatban élő tenant-guard két helyen
 *       driftelhet szét; egy elfelejtett példány cross-tenant szivárgás.</li>
 * </ol>
 *
 * <p>Mostantól minden guard és a hozzá tartozó olvasás <b>egyetlen</b>
 * {@code readOnly} tranzakción belül fut, egyetlen forrásból.
 *
 * <p><b>Multi-tenant invariáns (#1).</b> A kamera-felvétel a tenancyt a {@code branchId}-n
 * keresztül hordozza; minden belépési pont a {@code companyId}-ra validál.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class CameraAccessService {

    private final BranchRepository branchRepository;
    private final CameraConfigRepository cameraConfigRepository;
    private final CameraRecordingRepository recordingRepository;
    private final CameraTransactionLinkRepository linkRepository;
    private final CameraAccessLogRepository accessLogRepository;

    // ==========================================================================
    // Tenant-guard — EGYETLEN forrás mindkét controllernek
    // ==========================================================================

    /**
     * Ellenőrzi, hogy a fiók az aktuális céghez tartozik-e.
     *
     * <p>A {@code branch.getCompany()} <b>lazy</b> asszociáció, ezért ez a metódus
     * tranzakción belül fut. Cross-tenant kérésre {@link ResourceNotFoundException} —
     * szándékosan „nem található", nem „nincs jogosultság": a hibaüzenet nem árulhatja
     * el idegen tenant erőforrásának létezését.
     */
    @Transactional(readOnly = true)
    public void assertBranchInCurrentCompany(UUID branchId) {
        UUID currentCompanyId = SecurityUtils.getCurrentCompanyId();
        Branch branch = branchRepository.findById(branchId)
                .orElseThrow(() -> new ResourceNotFoundException("Iroda nem található: " + branchId));
        if (branch.getCompany() == null || !currentCompanyId.equals(branch.getCompany().getId())) {
            throw new ResourceNotFoundException("Iroda nem található: " + branchId);
        }
    }

    /** Az aktuális céghez tartozó, engedélyezett kamera-azonosítók. */
    @Transactional(readOnly = true)
    public Set<String> getAllowedCameraIds() {
        UUID currentCompanyId = SecurityUtils.getCurrentCompanyId();
        return branchRepository.findByCompanyId(currentCompanyId).stream()
                .map(Branch::getId)
                .flatMap(branchId -> cameraConfigRepository.findByBranchIdAndEnabled(branchId, true).stream())
                .map(CameraConfig::getCameraId)
                .collect(Collectors.toSet());
    }

    /** Kamera-szintű hozzáférés-ellenőrzés (live stream). */
    @Transactional(readOnly = true)
    public void assertCameraAccessible(String cameraId) {
        if (!getAllowedCameraIds().contains(cameraId)) {
            throw new ResourceNotFoundException("Kamera nem található: " + cameraId);
        }
    }

    // ==========================================================================
    // Felvétel-lekérdezés
    // ==========================================================================

    /** Felvételek fiók + időintervallum szerint, tenant-ellenőrzés után. */
    @Transactional(readOnly = true)
    public List<CameraRecording> findRecordings(UUID branchId, LocalDateTime start, LocalDateTime end) {
        assertBranchInCurrentCompany(branchId);
        return recordingRepository.findByBranchIdAndStartTimeBetween(branchId, start, end);
    }

    /**
     * Egyetlen felvétel lekérése tenant-ellenőrzéssel, VIEW audit-bejegyzéssel.
     *
     * @return a felvétel, vagy {@code null}, ha nem létezik (a hívó 404-et ad)
     */
    @Transactional
    public CameraRecording findRecordingForViewing(UUID recordingId) {
        CameraRecording recording = recordingRepository.findById(recordingId).orElse(null);
        if (recording == null) {
            return null;
        }
        assertBranchInCurrentCompany(recording.getBranchId());
        logAccess(recording, "VIEW");
        return recording;
    }

    /** Felvétel lekérése tenant-ellenőrzéssel, audit-bejegyzés NÉLKÜL (admin metaadat-út). */
    @Transactional(readOnly = true)
    public CameraRecording getRecordingChecked(UUID recordingId) {
        CameraRecording recording = recordingRepository.findById(recordingId)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Kamera felvétel nem található: " + recordingId));
        assertBranchInCurrentCompany(recording.getBranchId());
        return recording;
    }

    /** Egy felvételhez tartozó tranzakció-kapcsolatok száma (DTO-hoz). */
    @Transactional(readOnly = true)
    public int countLinkedTransactions(UUID recordingId) {
        return linkRepository.findByRecordingId(recordingId).size();
    }

    /**
     * A hívó számára elérhető kapcsolatok kiszűrése.
     *
     * <p><b>Ez a metódus a fenti 1. kockázat javítása.</b> A {@code link.getRecording()}
     * lazy asszociáció, ezért a szűrésnek tranzakción belül kell futnia. A guard-kivétel
     * elnyelése megmarad (idegen tenant kapcsolata egyszerűen nem jelenik meg), de a
     * váratlan hiba mostantól <b>naplózódik</b>, nem tűnik el nyomtalanul.
     */
    @Transactional(readOnly = true)
    public List<CameraTransactionLink> filterAccessibleLinks(List<CameraTransactionLink> links) {
        return links.stream().filter(this::canAccessLink).collect(Collectors.toList());
    }

    private boolean canAccessLink(CameraTransactionLink link) {
        UUID branchId = link.getRecording() != null ? link.getRecording().getBranchId() : null;
        if (branchId == null) {
            return false;
        }
        try {
            assertBranchInCurrentCompany(branchId);
            return true;
        } catch (ResourceNotFoundException ex) {
            // Idegen tenant vagy torolt fiok: a kapcsolat egyszeruen nem lathato.
            return false;
        }
    }

    // ==========================================================================
    // Kamera-konfiguráció (admin)
    // ==========================================================================

    /** Az aktuális cég összes kamera-konfigurációja. */
    @Transactional(readOnly = true)
    public List<CameraConfig> getAccessibleConfigs() {
        return branchRepository.findByCompanyId(SecurityUtils.getCurrentCompanyId()).stream()
                .map(Branch::getId)
                .flatMap(branchId -> cameraConfigRepository.findByBranchId(branchId).stream())
                .collect(Collectors.toList());
    }

    /** Egy fiók kamera-konfigurációi, tenant-ellenőrzés után. */
    @Transactional(readOnly = true)
    public List<CameraConfig> getConfigsForBranch(UUID branchId) {
        assertBranchInCurrentCompany(branchId);
        return cameraConfigRepository.findByBranchId(branchId);
    }

    /** Kamera-konfiguráció mentése tenant-ellenőrzés után. */
    @Transactional
    public CameraConfig saveConfig(CameraConfig config) {
        assertBranchInCurrentCompany(config.getBranchId());
        return cameraConfigRepository.save(config);
    }

    /** Kamera-konfiguráció törlése tenant-ellenőrzés után. */
    @Transactional
    public void deleteConfig(UUID configId) {
        CameraConfig config = cameraConfigRepository.findById(configId)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Kamera konfiguráció nem található: " + configId));
        assertBranchInCurrentCompany(config.getBranchId());
        cameraConfigRepository.deleteById(configId);
    }

    /** Egy felvétel hozzáférési naplója, tenant-ellenőrzés után. */
    @Transactional(readOnly = true)
    public List<CameraAccessLog> getAccessLogs(UUID recordingId) {
        getRecordingChecked(recordingId);
        return accessLogRepository.findByRecordingIdOrderByCreatedAtDesc(recordingId);
    }

    // ==========================================================================
    // Audit
    // ==========================================================================

    /**
     * Hozzáférési audit-bejegyzés.
     *
     * <p>Az audit-írás hibája nem bukatja el a fő műveletet (a felvétel megtekintése
     * fontosabb, mint a napló), de <b>naplózzuk</b> — a korábbi néma
     * {@code catch (Exception ignored)} elrejtette volna egy tartós audit-kiesést.
     */
    private void logAccess(CameraRecording recording, String action) {
        try {
            accessLogRepository.save(CameraAccessLog.builder()
                    .recording(recording)
                    .workerId(SecurityUtils.getCurrentWorkerId())
                    .action(action)
                    .build());
        } catch (RuntimeException ex) {
            log.warn("[CameraAccess] audit-bejegyzes sikertelen (recordingId={}, action={}): {}",
                    recording.getId(), action, ex.toString());
        }
    }
}
