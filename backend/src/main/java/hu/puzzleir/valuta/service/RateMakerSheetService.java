package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.RateMakerSheet;
import hu.puzzleir.valuta.repository.RateMakerSheetRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

/**
 * Az árfolyamkészítő munkaív (rate-maker working sheet) kétirányú sync-szolgáltatása.
 *
 * <p>Multi-tenant: minden művelet a bejelentkezett {@link SecurityUtils#getCurrentCompanyId()}
 * cégre szűr; cégenként egy aktív munkaív. A vékony kliens az igazságforrás aktív szerkesztéskor
 * (last-write-wins a kliens javára); megnyitáskor a kliens a {@link #getSheet()} verzióját olvassa
 * be alapként. Minden {@link #upsertSheet} a {@code version}-t növeli.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class RateMakerSheetService {

    private final RateMakerSheetRepository repository;

    /** A bejelentkezett cég aktuális munkaíve (PULL alap megnyitáskor), ha létezik. */
    @Transactional(readOnly = true)
    public Optional<RateMakerSheet> getSheet() {
        return repository.findByCompanyId(SecurityUtils.getCurrentCompanyId());
    }

    /**
     * A munkaív feltöltése/frissítése (PUSH). Idempotens upsert cégenként: ha nincs még munkaív,
     * létrehozza; egyébként felülírja a JSON-t és növeli a verziót (LWW a kliens javára).
     *
     * @param sheetJson   a munkaív teljes JSON-snapshotja
     * @param source      'rate-maker' (vékony kliens) vagy 'central' (központi modul)
     * @param deviceId    a kliens eszköz-azonosítója (audit + más-gép detektálás)
     * @param baseVersion az a verzió, amelyről a kliens indult (csak naplózott ütközés-jelzés)
     */
    @Transactional
    public RateMakerSheet upsertSheet(String sheetJson, String source, String deviceId, Long baseVersion) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        Long workerId = SecurityUtils.getCurrentWorkerId();
        String effectiveSource = (source == null || source.isBlank()) ? "rate-maker" : source;

        RateMakerSheet sheet = repository.findByCompanyId(companyId).orElse(null);
        if (sheet == null) {
            sheet = RateMakerSheet.builder()
                    .companyId(companyId)
                    .sheetJson(sheetJson)
                    .version(1L)
                    .source(effectiveSource)
                    .deviceId(deviceId)
                    .updatedBy(workerId)
                    .updatedAt(LocalDateTime.now())
                    .createdAt(LocalDateTime.now())
                    .build();
            log.info("Rate-maker munkaív LÉTREHOZVA (company={}, source={}, device={})",
                    companyId, effectiveSource, deviceId);
            return repository.save(sheet);
        }

        if (baseVersion != null && baseVersion < sheet.getVersion()) {
            // Nem blokkoló: a kliens régebbi verzióról ír (más gép közben frissített). A kérés szerint
            // a vékony kliens az igazságforrás aktív szerkesztéskor → felülírjuk, de naplózzuk.
            log.warn("Rate-maker munkaív felülírás elavult bázisról (company={}, base={}, szerver={}, source={})",
                    companyId, baseVersion, sheet.getVersion(), effectiveSource);
        }

        sheet.setSheetJson(sheetJson);
        sheet.setSource(effectiveSource);
        sheet.setDeviceId(deviceId);
        sheet.setUpdatedBy(workerId);
        sheet.setVersion(sheet.getVersion() + 1);
        sheet.setUpdatedAt(LocalDateTime.now());
        return repository.save(sheet);
    }
}
