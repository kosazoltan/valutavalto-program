package hu.puzzleir.valuta.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import hu.puzzleir.valuta.errorlog.ErrorLogController;
import hu.puzzleir.valuta.util.ClientIpResolver;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import static org.springframework.http.MediaType.APPLICATION_JSON;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@ExtendWith(MockitoExtension.class)
class ErrorLogControllerTest {

    private MockMvc mockMvc;

    @Mock
    private JavaMailSender mailSender;

    @Mock
    private ObjectMapper objectMapper;

    @Mock
    private ClientIpResolver clientIpResolver;

    @InjectMocks
    private ErrorLogController controller;

    @BeforeEach
    void setUp() {
        // Audit P1.4: a `resolveClientIp` mock visszaad a request remoteAddr-jet
        org.mockito.Mockito.lenient().when(clientIpResolver.resolveClientIp(org.mockito.Mockito.any()))
                .thenAnswer(inv -> {
                    jakarta.servlet.http.HttpServletRequest req = inv.getArgument(0);
                    return req == null ? "0.0.0.0" : req.getRemoteAddr();
                });
        mockMvc = MockMvcBuilders.standaloneSetup(controller).build();
    }

    @Test
    @DisplayName("POST /error-log alá kerül a HMAC-alapú hibalog endpoint")
    void signedErrorLogEndpointUsesDedicatedRoute() throws Exception {
        mockMvc.perform(post("/api/v1/error-log")
                        .contentType(APPLICATION_JSON)
                        .content("{\"errorType\":\"frontend_error\",\"message\":\"boom\"}"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.error").value("Missing signature"));
    }
}
