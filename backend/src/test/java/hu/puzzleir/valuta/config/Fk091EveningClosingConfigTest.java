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
    @DisplayName("FK-091: env nélkül az application.properties false default marad (prod/local profil)")
    void artifactSuccessEnabledDefaultsToFalseWithoutEnv() throws Exception {
        StandardEnvironment env = new StandardEnvironment();
        env.getPropertySources().addLast(
                new ResourcePropertySource("classpath:application.properties"));

        assertThat(env.getProperty("evening.closing.artifact-success-enabled", Boolean.class))
                .isFalse();
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
