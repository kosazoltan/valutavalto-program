package hu.puzzleir.valuta.controller;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.mock.env.MockEnvironment;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class PublicGoogleConfigStatusControllerTest {

    private MockMvc mockMvc;
    private PublicGoogleConfigStatusController controller;
    private MockEnvironment environment;

    @BeforeEach
    void setUp() {
        environment = new MockEnvironment();
        environment.setActiveProfiles("test");
        controller = new PublicGoogleConfigStatusController(environment);
        mockMvc = MockMvcBuilders.standaloneSetup(controller).build();
    }

    @Test
    @DisplayName("Ures konfiguracio -> webConfigured=false, desktopConfigured=false")
    void emptyConfig_returnsFalseForBothFlags() throws Exception {
        ReflectionTestUtils.setField(controller, "googleClientId", "");
        ReflectionTestUtils.setField(controller, "googleDesktopClientId", "");

        mockMvc.perform(get("/api/v1/public/auth/google-config-status"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.webConfigured").value(false))
                .andExpect(jsonPath("$.desktopConfigured").value(false))
                .andExpect(jsonPath("$.webPrefix").value(""))
                .andExpect(jsonPath("$.desktopPrefix").value(""))
                .andExpect(jsonPath("$.activeProfile").value("test"));
    }

    @Test
    @DisplayName("Csak web konfiguralva -> webConfigured=true, desktopConfigured=false")
    void onlyWebConfigured_marksDesktopAsMissing() throws Exception {
        ReflectionTestUtils.setField(controller, "googleClientId",
                "819982945323-5tve3fr5a9cstso6o3db6p838lo2v6sn.apps.googleusercontent.com");
        ReflectionTestUtils.setField(controller, "googleDesktopClientId", "");

        mockMvc.perform(get("/api/v1/public/auth/google-config-status"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.webConfigured").value(true))
                .andExpect(jsonPath("$.desktopConfigured").value(false))
                .andExpect(jsonPath("$.webPrefix").value("81998294***"))
                .andExpect(jsonPath("$.desktopPrefix").value(""));
    }

    @Test
    @DisplayName("Mindketto konfiguralva -> prefix redact-elt, NEM tartalmazza a teljes erteket")
    void bothConfigured_returnsRedactedPrefixes() throws Exception {
        String webId = "819982945323-5tve3fr5a9cstso6o3db6p838lo2v6sn.apps.googleusercontent.com";
        String desktopId = "28369624592-3cf88hndlq4eru6ht15f3ikt5e8gs8te.apps.googleusercontent.com";
        ReflectionTestUtils.setField(controller, "googleClientId", webId);
        ReflectionTestUtils.setField(controller, "googleDesktopClientId", desktopId);

        mockMvc.perform(get("/api/v1/public/auth/google-config-status"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.webConfigured").value(true))
                .andExpect(jsonPath("$.desktopConfigured").value(true))
                .andExpect(jsonPath("$.webPrefix").value("81998294***"))
                .andExpect(jsonPath("$.desktopPrefix").value("28369624***"));
    }

    @Test
    @DisplayName("Rovid (8 karakter alatti) ertek -> teljes redaction ***")
    void shortValue_fullyMasked() throws Exception {
        ReflectionTestUtils.setField(controller, "googleClientId", "short");
        ReflectionTestUtils.setField(controller, "googleDesktopClientId", "");

        mockMvc.perform(get("/api/v1/public/auth/google-config-status"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.webPrefix").value("***"));
    }
}
