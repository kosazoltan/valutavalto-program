package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.entity.WorkerRole;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@ExtendWith(MockitoExtension.class)
class PublicBranchControllerTest {

    private static final UUID COMPANY_ID = UUID.fromString("10000000-0000-0000-0000-000000000001");

    private MockMvc mockMvc;

    @Mock private CompanyRepository companyRepository;
    @Mock private BranchRepository branchRepository;
    @Mock private WorkerRepository workerRepository;

    @InjectMocks private PublicBranchController controller;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.standaloneSetup(controller).build();
    }

    @Test
    @DisplayName("Public worker lista companyCode es branchCode alapjan ceghez scope-olt")
    void getPublicWorkersByBranch_scopesBranchToCompanyWhenCompanyCodeProvided() throws Exception {
        Company company = company();
        Branch branch = branch(company, "KORUT", "SZEGED");
        Worker worker = worker(company, branch, "BORSI", "Borsi Tamas");

        when(companyRepository.findByCode("EBC")).thenReturn(Optional.of(company));
        when(branchRepository.findByCompanyIdAndCode(COMPANY_ID, "KORUT")).thenReturn(Optional.of(branch));
        when(workerRepository.findByCompanyIdAndRegionAndActiveTrue(COMPANY_ID, "SZEGED"))
                .thenReturn(List.of(worker));

        mockMvc.perform(get("/api/v1/public/workers")
                        .param("companyCode", "EBC")
                        .param("branchCode", "KORUT"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].code").value("BORSI"))
                .andExpect(jsonPath("$[0].name").value("Borsi Tamas"))
                .andExpect(jsonPath("$[0].region").value("SZEGED"));
    }

    @Test
    @DisplayName("Company-scoped public worker keresés nem esik vissza global branch lookupra")
    void getPublicWorkersByBranch_doesNotFallbackToGlobalBranchWhenCompanyCodeProvided() throws Exception {
        Company company = company();

        when(companyRepository.findByCode("EBC")).thenReturn(Optional.of(company));
        when(branchRepository.findByCompanyIdAndCode(COMPANY_ID, "KORUT")).thenReturn(Optional.empty());

        mockMvc.perform(get("/api/v1/public/workers")
                        .param("companyCode", "EBC")
                        .param("branchCode", "KORUT"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isEmpty());

        verify(branchRepository, never()).findByCode("KORUT");
    }

    private Company company() {
        return Company.builder()
                .id(COMPANY_ID)
                .code("EBC")
                .name("Exchange Best Change")
                .build();
    }

    private Branch branch(Company company, String code, String region) {
        return Branch.builder()
                .id(UUID.randomUUID())
                .company(company)
                .code(code)
                .name(code)
                .city("Szeged")
                .address("Teszt utca 1")
                .region(region)
                .build();
    }

    private Worker worker(Company company, Branch branch, String code, String name) {
        return Worker.builder()
                .id(10L)
                .company(company)
                .branch(branch)
                .code(code)
                .name(name)
                .role(WorkerRole.CASHIER)
                .passwordHash("$2b$10$hash")
                .active(true)
                .region(branch.getRegion())
                .build();
    }
}
