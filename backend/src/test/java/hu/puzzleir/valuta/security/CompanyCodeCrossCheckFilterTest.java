package hu.puzzleir.valuta.security;

import tools.jackson.databind.ObjectMapper;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.repository.CompanyRepository;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.mock.web.MockFilterChain;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class CompanyCodeCrossCheckFilterTest {

    private static final UUID COMPANY_ID = UUID.fromString("11111111-1111-1111-1111-111111111111");
    private static final UUID BRANCH_ID = UUID.fromString("22222222-2222-2222-2222-222222222222");

    @Mock
    private CompanyRepository companyRepository;

    private CompanyCodeCrossCheckFilter filter;

    @BeforeEach
    void setUp() {
        filter = new CompanyCodeCrossCheckFilter(companyRepository, new ObjectMapper());
    }

    @AfterEach
    void tearDown() {
        SecurityContextHolder.clearContext();
    }

    @Test
    @DisplayName("POST-1: missing X-Company-Code header passes through unchanged")
    void missingHeader_passesThrough() throws Exception {
        MockHttpServletRequest request = protectedPost();
        MockHttpServletResponse response = new MockHttpServletResponse();
        MockFilterChain chain = new MockFilterChain();

        filter.doFilter(request, response, chain);

        assertNotNull(chain.getRequest());
        assertEquals(200, response.getStatus());
        verify(companyRepository, never()).findById(COMPANY_ID);
    }

    @Test
    @DisplayName("POST-1: blank X-Company-Code header passes through unchanged")
    void blankHeader_passesThrough() throws Exception {
        MockHttpServletRequest request = protectedPost();
        request.addHeader(CompanyCodeCrossCheckFilter.COMPANY_CODE_HEADER, "   ");
        MockHttpServletResponse response = new MockHttpServletResponse();
        MockFilterChain chain = new MockFilterChain();

        filter.doFilter(request, response, chain);

        assertNotNull(chain.getRequest());
        verify(companyRepository, never()).findById(COMPANY_ID);
    }

    @Test
    @DisplayName("POST-2: matching company code passes through")
    void matchingHeader_passesThrough() throws Exception {
        authenticateWorker();
        when(companyRepository.findById(COMPANY_ID)).thenReturn(Optional.of(company("BEST")));
        MockHttpServletRequest request = protectedPost();
        request.addHeader(CompanyCodeCrossCheckFilter.COMPANY_CODE_HEADER, "BEST");
        MockHttpServletResponse response = new MockHttpServletResponse();
        MockFilterChain chain = new MockFilterChain();

        filter.doFilter(request, response, chain);

        assertNotNull(chain.getRequest());
        assertEquals(200, response.getStatus());
    }

    @Test
    @DisplayName("POST-2: matching company code is trimmed and case-insensitive")
    void matchingHeader_caseInsensitiveAndTrimmed_passesThrough() throws Exception {
        authenticateWorker();
        when(companyRepository.findById(COMPANY_ID)).thenReturn(Optional.of(company("BEST")));
        MockHttpServletRequest request = protectedPost();
        request.addHeader(CompanyCodeCrossCheckFilter.COMPANY_CODE_HEADER, " best ");
        MockHttpServletResponse response = new MockHttpServletResponse();
        MockFilterChain chain = new MockFilterChain();

        filter.doFilter(request, response, chain);

        assertNotNull(chain.getRequest());
        assertEquals(200, response.getStatus());
    }

    @Test
    @DisplayName("POST-3: mismatched company code returns 409 and does not invoke chain")
    void mismatchedHeader_returns409_andChainNotInvoked() throws Exception {
        authenticateWorker();
        when(companyRepository.findById(COMPANY_ID)).thenReturn(Optional.of(company("BEST")));
        MockHttpServletRequest request = protectedPost();
        request.addHeader(CompanyCodeCrossCheckFilter.COMPANY_CODE_HEADER, "PANNON");
        MockHttpServletResponse response = new MockHttpServletResponse();
        MockFilterChain chain = new MockFilterChain();

        filter.doFilter(request, response, chain);

        assertEquals(409, response.getStatus());
        assertTrue(response.getContentAsString().contains("CONFLICT"));
        assertTrue(response.getContentAsString().contains("Cégeltérés"));
        assertNull(chain.getRequest());
    }

    @Test
    @DisplayName("POST-4: header present without authentication context passes through")
    void noAuthentication_headerPresent_passesThrough() throws Exception {
        MockHttpServletRequest request = protectedPost();
        request.addHeader(CompanyCodeCrossCheckFilter.COMPANY_CODE_HEADER, "BEST");
        MockHttpServletResponse response = new MockHttpServletResponse();
        MockFilterChain chain = new MockFilterChain();

        filter.doFilter(request, response, chain);

        assertNotNull(chain.getRequest());
        verify(companyRepository, never()).findById(COMPANY_ID);
    }

    @Test
    @DisplayName("POST-5: unknown token company returns 409")
    void unknownTokenCompany_headerPresent_returns409() throws Exception {
        authenticateWorker();
        when(companyRepository.findById(COMPANY_ID)).thenReturn(Optional.empty());
        MockHttpServletRequest request = protectedPost();
        request.addHeader(CompanyCodeCrossCheckFilter.COMPANY_CODE_HEADER, "BEST");
        MockHttpServletResponse response = new MockHttpServletResponse();
        MockFilterChain chain = new MockFilterChain();

        filter.doFilter(request, response, chain);

        assertEquals(409, response.getStatus());
        assertTrue(response.getContentAsString().contains("CONFLICT"));
        assertTrue(response.getContentAsString().contains("Cégeltérés"));
        assertNull(chain.getRequest());
    }

    @Test
    @DisplayName("INV-2: GET requests are not filtered")
    void getRequest_notFiltered() throws Exception {
        MockHttpServletRequest request = new MockHttpServletRequest("GET", "/api/v1/transactions/buy");

        assertTrue(filter.shouldNotFilter(request));
    }

    @Test
    @DisplayName("INV-2: excluded prefixes are not filtered")
    void excludedPrefix_notFiltered() throws Exception {
        MockHttpServletRequest request = new MockHttpServletRequest("POST", "/api/v1/auth/login");

        assertTrue(filter.shouldNotFilter(request));
    }

    @Test
    @DisplayName("INV-2: protected API write requests are filtered")
    void protectedWrite_isFiltered() throws Exception {
        MockHttpServletRequest request = protectedPost();

        assertFalse(filter.shouldNotFilter(request));
    }

    private MockHttpServletRequest protectedPost() {
        return new MockHttpServletRequest("POST", "/api/v1/transactions/buy");
    }

    private void authenticateWorker() {
        UsernamePasswordAuthenticationToken authentication =
                new UsernamePasswordAuthenticationToken("worker-1", null, java.util.List.of());
        authentication.setDetails(new WorkerAuthenticationDetails(42L, COMPANY_ID, BRANCH_ID, "CASHIER"));
        SecurityContextHolder.getContext().setAuthentication(authentication);
    }

    private Company company(String code) {
        Company company = new Company();
        company.setId(COMPANY_ID);
        company.setCode(code);
        company.setName("Test Company");
        return company;
    }
}
