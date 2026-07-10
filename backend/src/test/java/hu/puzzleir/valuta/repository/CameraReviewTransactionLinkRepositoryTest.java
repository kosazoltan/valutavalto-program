package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.TestApplication;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.CameraRecording;
import hu.puzzleir.valuta.entity.CameraTransactionLink;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Dictionary;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest(
        classes = TestApplication.class,
        properties = {
                "app.encryption.key=test-only-local-encryption-key-32chars",
                "app.encryption.salt=00112233445566778899aabbccddeeff"
        })
@ActiveProfiles("test")
@Transactional
class CameraReviewTransactionLinkRepositoryTest {

    @Autowired private CompanyRepository companyRepository;
    @Autowired private DictionaryRepository dictionaryRepository;
    @Autowired private BranchRepository branchRepository;
    @Autowired private CameraRecordingRepository recordingRepository;
    @Autowired private CameraTransactionLinkRepository linkRepository;

    @Test
    void findByBranchAndTimeRangeRequiresCompanyMatch() {
        LocalDate day = LocalDate.of(2026, 7, 10);
        LocalDateTime start = day.atStartOfDay();
        LocalDateTime end = day.plusDays(1).atStartOfDay();
        Tenant own = seedTenant("FS14A");
        Tenant foreign = seedTenant("FS14B");

        CameraRecording ownRecording = recordingRepository.save(recording(own.branch(), start.plusHours(8)));
        CameraRecording foreignRecording = recordingRepository.save(recording(foreign.branch(), start.plusHours(9)));
        linkRepository.save(link(ownRecording, "FS14-OWN", start.plusHours(8).plusMinutes(5)));
        linkRepository.save(link(foreignRecording, "FS14-FOREIGN", start.plusHours(9).plusMinutes(5)));
        linkRepository.flush();

        List<CameraTransactionLink> ownResult = linkRepository.findByBranchAndTimeRange(
                own.branch().getId(), own.company().getId(), start, end);
        List<CameraTransactionLink> crossTenantResult = linkRepository.findByBranchAndTimeRange(
                foreign.branch().getId(), own.company().getId(), start, end);

        assertThat(ownResult).extracting(CameraTransactionLink::getReceiptNumber).containsExactly("FS14-OWN");
        assertThat(crossTenantResult).isEmpty();
    }

    private Tenant seedTenant(String prefix) {
        LocalDateTime now = LocalDateTime.of(2026, 7, 10, 8, 0);
        String suffix = prefix + shortId();
        Company company = companyRepository.save(Company.builder()
                .code(shortCode("C", suffix))
                .name("FS-14 Company " + suffix)
                .createdAt(now)
                .build());
        Dictionary branchType = dictionaryRepository.save(Dictionary.builder()
                .category("BRANCH_TYPE")
                .code(shortCode("BT", suffix))
                .name("FS-14 branch type")
                .createdAt(now)
                .build());
        Dictionary country = dictionaryRepository.save(Dictionary.builder()
                .category("COUNTRY")
                .code(shortCode("CO", suffix))
                .name("Hungary")
                .createdAt(now)
                .build());
        Dictionary branchStatus = dictionaryRepository.save(Dictionary.builder()
                .category("BRANCH_STATUS")
                .code(shortCode("BS", suffix))
                .name("Active")
                .createdAt(now)
                .build());
        Branch branch = branchRepository.save(Branch.builder()
                .code(shortCode("BR", suffix))
                .company(company)
                .bankCode("FS14BANK")
                .branchType(branchType)
                .name("FS-14 Branch " + suffix)
                .address("Kamera utca 1")
                .city("Budapest")
                .zipCode("1000")
                .country(country)
                .branchStatus(branchStatus)
                .openingDate(LocalDate.of(2026, 1, 1))
                .createdAt(now)
                .build());
        return new Tenant(company, branch);
    }

    private CameraRecording recording(Branch branch, LocalDateTime startTime) {
        return CameraRecording.builder()
                .branchId(branch.getId())
                .cameraId("cam-1")
                .startTime(startTime)
                .endTime(startTime.plusMinutes(30))
                .localFilePath("C:/camera/" + branch.getCode() + ".mp4")
                .expiresAt(startTime.toLocalDate().plusDays(90))
                .build();
    }

    private CameraTransactionLink link(CameraRecording recording, String receiptNumber, LocalDateTime transactionTime) {
        return CameraTransactionLink.builder()
                .recording(recording)
                .transactionId(System.nanoTime())
                .receiptNumber(receiptNumber)
                .transactionTime(transactionTime)
                .frameOffsetSeconds(300)
                .build();
    }

    private String shortId() {
        return Long.toString(System.nanoTime(), 36).toUpperCase();
    }

    private String shortCode(String prefix, String suffix) {
        String normalized = (prefix + suffix).replaceAll("[^A-Z0-9]", "");
        return normalized.substring(0, Math.min(20, normalized.length()));
    }

    private record Tenant(Company company, Branch branch) {}
}
