package hu.puzzleir.valuta.config;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

@Configuration
@ConfigurationProperties(prefix = "data-import")
@Getter
@Setter
public class DataImportProperties {
    private boolean simulatedSuccessEnabled = false;
}
