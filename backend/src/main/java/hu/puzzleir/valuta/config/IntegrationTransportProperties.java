package hu.puzzleir.valuta.config;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

import java.util.HashMap;
import java.util.Map;

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

        /** FS-15: cégkód (Company.code) → banki PV_AZONOSITO. Hiánya export-tiltás. */
        private Map<String, String> pvCodes = new HashMap<>();

        /** FS-15 prod-provisioning: vesszővel elválasztott cégkód=PV_AZONOSITO párok. */
        private String pvCodesEnv;
    }
}
