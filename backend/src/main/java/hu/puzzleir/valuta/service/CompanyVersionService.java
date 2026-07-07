package hu.puzzleir.valuta.service;

import tools.jackson.databind.ObjectMapper;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.CompanyVersion;
import hu.puzzleir.valuta.entity.DataChangeSource;
import hu.puzzleir.valuta.repository.CompanyVersionRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/** FS-3 (D1): tenant-cég törzsadat verziózás teljes JSON-snapshottal. */
@Service
@RequiredArgsConstructor
@Slf4j
public class CompanyVersionService {

    private final CompanyVersionRepository companyVersionRepository;
    private final ObjectMapper objectMapper;

    @Transactional(readOnly = true)
    public boolean hasDataChanged(Company company) {
        Optional<CompanyVersion> latest =
                companyVersionRepository.findTopByCompanyIdOrderByVersionNoDesc(company.getId());
        if (latest.isEmpty()) {
            return true;
        }
        String current = objectMapper.writeValueAsString(CompanySnapshot.of(company));
        CompanySnapshot previous = objectMapper.readValue(latest.get().getSnapshot(), CompanySnapshot.class);
        return !objectMapper.writeValueAsString(previous).equals(current);
    }

    @Transactional(rollbackFor = Exception.class)
    public CompanyVersion recordVersion(Company company, DataChangeSource source) {
        long nextNo = companyVersionRepository
                .findTopByCompanyIdOrderByVersionNoDesc(company.getId())
                .map(v -> v.getVersionNo() + 1)
                .orElse(1L);
        CompanyVersion version = CompanyVersion.builder()
                .companyId(company.getId())
                .versionNo(nextNo)
                .snapshot(objectMapper.writeValueAsString(CompanySnapshot.of(company)))
                .changeSource(source)
                .changedBy(SecurityUtils.getCurrentWorkerCode())
                .changedAt(LocalDateTime.now())
                .build();
        CompanyVersion saved = companyVersionRepository.save(version);
        log.info("[COMPANY-VERSION] Cég #{} v{} rögzítve ({})", company.getId(), nextNo, source);
        return saved;
    }

    @Transactional(readOnly = true)
    public List<CompanyVersion> listVersions(UUID companyId) {
        return companyVersionRepository.findByCompanyIdOrderByVersionNoDesc(companyId);
    }

    @Transactional(readOnly = true)
    public Optional<CompanyVersion> getVersion(UUID companyId, Long versionNo) {
        return companyVersionRepository.findByCompanyIdAndVersionNo(companyId, versionNo);
    }

    /** A cég-törzs kanonikus snapshot-vetülete (terv C3). */
    record CompanySnapshot(String code, String name, String taxNumber,
                           String registrationNumber, String address,
                           String phone, String email, Boolean isActive) {
        static CompanySnapshot of(Company c) {
            return new CompanySnapshot(c.getCode(), c.getName(), c.getTaxNumber(),
                    c.getRegistrationNumber(), c.getAddress(), c.getPhone(),
                    c.getEmail(), c.getIsActive());
        }
    }
}
