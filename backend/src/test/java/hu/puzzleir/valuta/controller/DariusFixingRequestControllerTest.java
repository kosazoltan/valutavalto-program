package hu.puzzleir.valuta.controller;

import tools.jackson.databind.json.JsonMapper;
import hu.puzzleir.valuta.dto.darius.DariusBankBranchCreateDto;
import hu.puzzleir.valuta.dto.darius.DariusBankBranchDto;
import hu.puzzleir.valuta.dto.darius.DariusFixingRequestCreateDto;
import hu.puzzleir.valuta.dto.darius.DariusFixingRequestDto;
import hu.puzzleir.valuta.dto.darius.DariusFixingRequestLineDto;
import hu.puzzleir.valuta.exception.GlobalExceptionHandler;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.service.darius.DariusFixingRequestService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.converter.json.JacksonJsonHttpMessageConverter;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class DariusFixingRequestControllerTest {

    private static final UUID BANK_BRANCH_ID = UUID.fromString("20000000-0000-0000-0000-000000000002");
    private static final UUID REQUEST_ID = UUID.fromString("30000000-0000-0000-0000-000000000003");
    private static final LocalDate REQUEST_DATE = LocalDate.of(2026, 7, 14);

    private final DariusFixingRequestService service = mock(DariusFixingRequestService.class);
    private MockMvc mockMvc;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.standaloneSetup(new DariusFixingRequestController(service))
                .setControllerAdvice(new GlobalExceptionHandler())
                .setMessageConverters(new JacksonJsonHttpMessageConverter(new JsonMapper()))
                .build();
    }

    @Test
    void bankBranchEndpointsCoverListCreateAndDeactivate() throws Exception {
        DariusBankBranchDto branch = new DariusBankBranchDto(
                BANK_BRANCH_ID, "RB01", "Raiffeisen Budapest", true);
        when(service.listBankBranches(true)).thenReturn(List.of(branch));
        when(service.createBankBranch(any(DariusBankBranchCreateDto.class))).thenReturn(branch);
        when(service.deactivateBankBranch(BANK_BRANCH_ID))
                .thenReturn(new DariusBankBranchDto(BANK_BRANCH_ID, "RB01", "Raiffeisen Budapest", false));

        mockMvc.perform(get("/api/v1/darius/bank-branches").param("includeInactive", "true"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].bankBranchCode").value("RB01"));
        mockMvc.perform(post("/api/v1/darius/bank-branches")
                        .contentType("application/json")
                        .content("{\"bankBranchCode\":\"RB01\",\"name\":\"Raiffeisen Budapest\"}"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").value(BANK_BRANCH_ID.toString()));
        mockMvc.perform(post("/api/v1/darius/bank-branches/{id}/deactivate", BANK_BRANCH_ID))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.active").value(false));

        verify(service).listBankBranches(true);
        verify(service).deactivateBankBranch(BANK_BRANCH_ID);
    }

    @Test
    void fixingRequestEndpointsCoverFullLifecycle() throws Exception {
        DariusFixingRequestDto dto = requestDto("DRAFT");
        when(service.listRequests(REQUEST_DATE)).thenReturn(List.of(dto));
        when(service.create(any(DariusFixingRequestCreateDto.class))).thenReturn(dto);
        when(service.updateLines(any(UUID.class), any(DariusFixingRequestCreateDto.class))).thenReturn(dto);
        when(service.approve(REQUEST_ID)).thenReturn(requestDto("APPROVED"));
        when(service.cancel(REQUEST_ID)).thenReturn(requestDto("CANCELLED"));
        String requestBody = """
                {
                  "bankBranchId":"%s",
                  "requestDate":"2026-07-14",
                  "note":"Heti igény",
                  "lines":[{"currencyCode":"EUR","deliveredAmount":100,"collectedAmount":0}]
                }
                """.formatted(BANK_BRANCH_ID);

        mockMvc.perform(get("/api/darius/fixing-requests").param("date", "2026-07-14"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].status").value("DRAFT"));
        mockMvc.perform(post("/api/v1/darius/fixing-requests")
                        .contentType("application/json")
                        .content(requestBody))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.lines[0].currencyCode").value("EUR"));
        mockMvc.perform(put("/api/v1/darius/fixing-requests/{id}", REQUEST_ID)
                        .contentType("application/json")
                        .content(requestBody))
                .andExpect(status().isOk());
        mockMvc.perform(post("/api/v1/darius/fixing-requests/{id}/approve", REQUEST_ID))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("APPROVED"));
        mockMvc.perform(post("/api/v1/darius/fixing-requests/{id}/cancel", REQUEST_ID))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("CANCELLED"));

        verify(service).listRequests(REQUEST_DATE);
        verify(service).approve(REQUEST_ID);
        verify(service).cancel(REQUEST_ID);
    }

    @Test
    void validationExceptionMapsTo400AndMalformedDateNeverCallsService() throws Exception {
        when(service.listRequests(REQUEST_DATE)).thenThrow(new ValidationException("aggregált hiba"));

        mockMvc.perform(get("/api/v1/darius/fixing-requests").param("date", "2026-07-14"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("aggregált hiba"));
        mockMvc.perform(get("/api/v1/darius/fixing-requests").param("date", "2026/07/14"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void everyEndpointIsMainTreasuryCompatibleAndApproveExcludesSystemAdmin() throws Exception {
        assertAuthority("bankBranches", new Class<?>[] {boolean.class}, "MAIN_TREASURY");
        assertAuthority("createBankBranch", new Class<?>[] {DariusBankBranchCreateDto.class}, "MAIN_TREASURY");
        assertAuthority("deactivateBankBranch", new Class<?>[] {UUID.class}, "MAIN_TREASURY");
        assertAuthority("list", new Class<?>[] {LocalDate.class}, "MAIN_TREASURY");
        assertAuthority("create", new Class<?>[] {DariusFixingRequestCreateDto.class}, "MAIN_TREASURY");
        assertAuthority("updateLines", new Class<?>[] {UUID.class, DariusFixingRequestCreateDto.class}, "MAIN_TREASURY");
        assertAuthority("approve", new Class<?>[] {UUID.class}, "MAIN_TREASURY");
        assertAuthority("cancel", new Class<?>[] {UUID.class}, "MAIN_TREASURY");

        PreAuthorize approve = DariusFixingRequestController.class
                .getMethod("approve", UUID.class)
                .getAnnotation(PreAuthorize.class);
        assertThat(approve.value()).contains("DARIUS_REPORT_RUN", "MAIN_TREASURY");
        assertThat(approve.value()).doesNotContain("SYSTEM_ADMIN");
    }

    private void assertAuthority(String method, Class<?>[] parameterTypes, String authority) throws Exception {
        PreAuthorize annotation = DariusFixingRequestController.class
                .getMethod(method, parameterTypes)
                .getAnnotation(PreAuthorize.class);
        assertThat(annotation).isNotNull();
        assertThat(annotation.value()).contains(authority);
    }

    private DariusFixingRequestDto requestDto(String status) {
        return new DariusFixingRequestDto(
                REQUEST_ID,
                BANK_BRANCH_ID,
                "RB01",
                "Raiffeisen Budapest",
                REQUEST_DATE,
                status,
                "Heti igény",
                "FOERT01",
                LocalDateTime.of(2026, 7, 11, 10, 0),
                "FOERT02",
                LocalDateTime.of(2026, 7, 11, 11, 0),
                null,
                List.of(new DariusFixingRequestLineDto("EUR", new BigDecimal("100"), BigDecimal.ZERO)));
    }
}
