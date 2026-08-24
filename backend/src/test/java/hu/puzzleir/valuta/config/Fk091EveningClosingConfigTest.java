package hu.puzzleir.valuta.config;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.core.env.StandardEnvironment;
import org.springframework.core.io.support.ResourcePropertySource;
import org.springframework.mock.env.MockPropertySource;

import java.nio.file.Files;
import java.nio.file.Path;

import static org.assertj.core.api.Assertions.assertThat;

class Fk091EveningClosingConfigTest {

    @Test
    @DisplayName("FK-091: EVENING_CLOSING_ARTIFACT_SUCCESS_ENABLED env felülírja az application.properties false defaultot")
    void artifactSuccessEnabledResolvesFromEnvVar() throws Exception {
        StandardEnvironment env = new StandardEnvironment();
        env.getPropertySources().addFirst(
                new MockPropertySource("fake-env")
                        .withProperty("EVENING_CLOSING_ARTIFACT_SUCCESS_ENABLED", "true"));
        env.getPropertySources().addLast(
                new ResourcePropertySource("classpath:application.properties"));

        assertThat(env.getProperty("evening.closing.artifact-success-enabled", Boolean.class))
                .isTrue();
    }

    @Test
    @DisplayName("FK-091: application-local.properties classpath default true")
    void applicationLocalPropertiesDocumentsFk091Default() throws Exception {
        java.util.Properties props = new java.util.Properties();
        try (java.io.InputStream is = getClass().getResourceAsStream("/application-local.properties")) {
            assertThat(is).isNotNull();
            props.load(is);
        }
        assertThat(props.getProperty("evening.closing.artifact-success-enabled"))
                .contains("true");
    }

    @Test
    @DisplayName("FK-091: env nélkül az application.properties false default marad (profil nélkül)")
    void artifactSuccessEnabledDefaultsToFalseWithoutProfile() throws Exception {
        StandardEnvironment env = new StandardEnvironment();
        env.getPropertySources().addLast(
                new ResourcePropertySource("classpath:application.properties"));

        assertThat(env.getProperty("evening.closing.artifact-success-enabled", Boolean.class))
                .isFalse();
    }

    @Test
    @DisplayName("FK-091: application-production.properties default true (production profil)")
    void productionPropertiesDocumentFk091Default() throws Exception {
        java.util.Properties props = new java.util.Properties();
        try (java.io.InputStream is = getClass().getResourceAsStream("/application-production.properties")) {
            assertThat(is).isNotNull();
            props.load(is);
        }
        assertThat(props.getProperty("evening.closing.artifact-success-enabled")).contains("true");
    }

    @Test
    @DisplayName("FK-091: prod→production profile group az application.properties-ben")
    void applicationPropertiesDeclaresProdProfileGroup() throws Exception {
        java.util.Properties props = new java.util.Properties();
        try (java.io.InputStream is = getClass().getResourceAsStream("/application.properties")) {
            assertThat(is).isNotNull();
            props.load(is);
        }
        assertThat(props.getProperty("spring.profiles.group.prod")).isEqualTo("production");
    }

    @Test
    @DisplayName("FK-091: deploy sablonok tartalmazzák az EVENING_CLOSING_ARTIFACT_SUCCESS_ENABLED=true sort")
    void deployTemplatesDocumentFk091Env() throws Exception {
        Path repoRoot = Path.of(System.getProperty("user.dir")).getParent();
        String envExample = Files.readString(repoRoot.resolve("deploy/.env.example"));
        String bootstrap = Files.readString(repoRoot.resolve("deploy/hetzner/bootstrap-vps.sh"));

        assertThat(envExample).contains("EVENING_CLOSING_ARTIFACT_SUCCESS_ENABLED=true");
        assertThat(bootstrap).contains("EVENING_CLOSING_ARTIFACT_SUCCESS_ENABLED=true");
    }
}
