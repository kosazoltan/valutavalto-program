package hu.puzzleir.valuta.config;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

@Configuration
@ConfigurationProperties(prefix = "integration.transport")
@Getter
@Setter
public class IntegrationTransportProperties {
    private String rootPath = System.getProperty("java.io.tmpdir") + "/valuta-integrations";
    private Camera camera = new Camera();
    private Sync sync = new Sync();
    private Darius darius = new Darius();

    @Getter @Setter
    public static class Camera {
        private String uploadDir = "camera-upload";
    }

    @Getter @Setter
    public static class Sync {
        private String dir = "branch-sync";
    }

    @Getter @Setter
    public static class Darius {
        private String outboxDir = "darius-outbox";
    }
}
