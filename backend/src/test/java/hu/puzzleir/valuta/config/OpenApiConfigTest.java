package hu.puzzleir.valuta.config;

import io.swagger.v3.oas.models.OpenAPI;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.boot.info.BuildProperties;

import java.util.Properties;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class OpenApiConfigTest {

    @SuppressWarnings("unchecked")
    private ObjectProvider<BuildProperties> providerOf(BuildProperties buildProperties) {
        ObjectProvider<BuildProperties> provider = mock(ObjectProvider.class);
        when(provider.getIfAvailable()).thenReturn(buildProperties);
        return provider;
    }

    @Test
    void versionComesFromBuildPropertiesWhenAvailable() {
        Properties props = new Properties();
        props.setProperty("version", "9.9.9-test");

        OpenAPI api = new OpenApiConfig(providerOf(new BuildProperties(props)))
                .customOpenAPI();

        assertThat(api.getInfo().getVersion()).isEqualTo("9.9.9-test");
    }

    @Test
    void missingBuildPropertiesFallsBackToDevWithoutThrowing() {
        OpenAPI api = new OpenApiConfig(providerOf(null)).customOpenAPI();

        assertThat(api.getInfo().getVersion()).isEqualTo("dev");
    }

    @Test
    void blankOrMissingVersionInBuildPropertiesFallsBackToDev() {
        // BuildProperties jelen van, de a 'version' property hiányzik -> getVersion() null
        // -> resolveVersion() isBlank/null guardja "dev"-re esik, NEM dob.
        OpenAPI api = new OpenApiConfig(providerOf(new BuildProperties(new Properties())))
                .customOpenAPI();

        assertThat(api.getInfo().getVersion()).isEqualTo("dev");
    }

    @Test
    void staticMetadataUnchanged() {
        OpenAPI api = new OpenApiConfig(providerOf(null)).customOpenAPI();

        assertThat(api.getInfo().getTitle()).isEqualTo("Valutaváltó ERP API");
        assertThat(api.getComponents().getSecuritySchemes()).containsKey("bearerAuth");
    }
}
