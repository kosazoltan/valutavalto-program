package hu.puzzleir.valuta.config;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

@Configuration
@ConfigurationProperties(prefix = "nav.bridge")
@Getter
@Setter
public class NavBridgeProperties {
    private boolean simulatedSuccessEnabled = false;
}
