package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.pos.PosTerminalRequest;
import hu.puzzleir.valuta.dto.pos.PosTransactionResult;
import hu.puzzleir.valuta.exception.GlobalExceptionHandler;
import hu.puzzleir.valuta.service.PosTerminalService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.converter.json.MappingJackson2HttpMessageConverter;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.test.context.ContextConfiguration;
import org.springframework.test.context.junit.jupiter.SpringExtension;
import org.springframework.test.context.web.WebAppConfiguration;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.context.WebApplicationContext;
import org.springframework.web.servlet.config.annotation.EnableWebMvc;

import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.reset;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@ExtendWith(SpringExtension.class)
@WebAppConfiguration
@ContextConfiguration(classes = PosTerminalStubControllerSecurityWebMvcTest.TestConfig.class)
class PosTerminalStubControllerSecurityWebMvcTest {

    @Autowired
    private WebApplicationContext context;

    @Autowired
    private PosTerminalService posTerminalService;

    @Autowired
    private PosTerminalStubController posTerminalStubController;

    private MockMvc mockMvc;

    @BeforeEach
    void setup() {
        mockMvc = MockMvcBuilders.webAppContextSetup(context)
                .apply(springSecurity())
                .build();
    }

    @Configuration
    @EnableWebMvc
    @EnableWebSecurity
    @EnableMethodSecurity
    static class TestConfig {
        @Bean
        PosTerminalService posTerminalService() {
            return mock(PosTerminalService.class);
        }

        @Bean
        PosTerminalStubController posTerminalStubController(PosTerminalService posTerminalService) {
            return new PosTerminalStubController(posTerminalService);
        }

        @Bean
        GlobalExceptionHandler globalExceptionHandler() {
            return new GlobalExceptionHandler();
        }

        @Bean
        MappingJackson2HttpMessageConverter mappingJackson2HttpMessageConverter() {
            return new MappingJackson2HttpMessageConverter();
        }

        @Bean
        SecurityFilterChain testSecurityFilterChain(HttpSecurity http) throws Exception {
            http
                    .csrf(csrf -> csrf.disable())
                    .authorizeHttpRequests(auth -> auth
                            .requestMatchers("/api/v1/pos-terminal-stub/**").hasAnyRole("SUPERVISOR", "MANAGER", "ADMIN")
                            .anyRequest().authenticated())
                    .httpBasic(Customizer.withDefaults());
            return http.build();
        }
    }

    @Test
    @DisplayName("AuthZ: SUPERVISOR role engedélyezett (method security) a /void műveletre")
    @WithMockUser(roles = "SUPERVISOR")
    void void_allowedRole_methodSecurity_callsService() {
        reset(posTerminalService);
        when(posTerminalService.initiateReversal(eq("TX-01"), eq("TERM-01")))
                .thenReturn(PosTransactionResult.approved("AUTH-VOID", "REF-VOID"));

        posTerminalStubController.voidTransaction("TX-01", new PosTerminalRequest("TERM-01"));

        verify(posTerminalService).initiateReversal(eq("TX-01"), eq("TERM-01"));
    }

    @Test
    @DisplayName("AuthZ: CASHIER role tiltott (method security) a /void műveletre")
    @WithMockUser(roles = "CASHIER")
    void void_forbiddenRole_methodSecurity_throwsAccessDenied() {
        reset(posTerminalService);

        assertThrows(AccessDeniedException.class,
                () -> posTerminalStubController.voidTransaction("TX-01", new PosTerminalRequest("TERM-01")));

        verify(posTerminalService, never()).initiateReversal(anyString(), anyString());
    }

    @Test
    @DisplayName("POST /void invalid terminalId esetén 400")
    @WithMockUser(roles = "MANAGER")
    void void_invalidTerminalId_returns400() throws Exception {
        mockMvc.perform(post("/api/v1/pos-terminal-stub/void/TX-01").param("terminalId", "BAD$ID"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("VALIDATION_FAILED"))
                .andExpect(jsonPath("$.fieldErrors.terminalId").exists());

        verify(posTerminalService, never()).initiateReversal(anyString(), anyString());
    }

    @Test
    @DisplayName("POST /void missing terminalId esetén 400")
    @WithMockUser(roles = "MANAGER")
    void void_missingTerminalId_returns400() throws Exception {
        mockMvc.perform(post("/api/v1/pos-terminal-stub/void/TX-01"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("VALIDATION_FAILED"))
                .andExpect(jsonPath("$.fieldErrors.terminalId").exists());

        verify(posTerminalService, never()).initiateReversal(anyString(), anyString());
    }

    @Test
    @DisplayName("POST /settlement invalid terminalId esetén 400")
    @WithMockUser(roles = "ADMIN")
    void settlement_invalidTerminalId_returns400() throws Exception {
        mockMvc.perform(post("/api/v1/pos-terminal-stub/settlement").param("terminalId", "BAD$ID"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("VALIDATION_FAILED"))
                .andExpect(jsonPath("$.fieldErrors.terminalId").exists());

        verify(posTerminalService, never()).dailyClose(anyString());
    }

    @Test
    @DisplayName("POST /settlement missing terminalId esetén 400")
    @WithMockUser(roles = "ADMIN")
    void settlement_missingTerminalId_returns400() throws Exception {
        mockMvc.perform(post("/api/v1/pos-terminal-stub/settlement"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("VALIDATION_FAILED"))
                .andExpect(jsonPath("$.fieldErrors.terminalId").exists());

        verify(posTerminalService, never()).dailyClose(anyString());
    }

    @Test
    @DisplayName("GET /status invalid terminalId esetén 400")
    @WithMockUser(roles = "SUPERVISOR")
    void status_invalidTerminalId_returns400() throws Exception {
        mockMvc.perform(get("/api/v1/pos-terminal-stub/status").param("terminalId", "BAD$ID"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("VALIDATION_FAILED"))
                .andExpect(jsonPath("$.fieldErrors.terminalId").exists());

        verify(posTerminalService, never()).getStatus(anyString());
    }

    @Test
    @DisplayName("GET /status missing terminalId esetén 400")
    @WithMockUser(roles = "SUPERVISOR")
    void status_missingTerminalId_returns400() throws Exception {
        mockMvc.perform(get("/api/v1/pos-terminal-stub/status"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("VALIDATION_FAILED"))
                .andExpect(jsonPath("$.fieldErrors.terminalId").exists());

        verify(posTerminalService, never()).getStatus(anyString());
    }
}
