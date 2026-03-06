package hu.puzzleir.valuta.config;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

@Configuration
@ConfigurationProperties(prefix = "camera")
@Getter
@Setter
public class CameraProperties {
    private boolean enabled = true;
    private int fps = 5;
    private Resolution resolution = new Resolution();
    private int jpegQuality = 70;
    private int retentionDays = 50;
    private int segmentDurationMinutes = 60;
    private String localStoragePath = "C:/valuta/camera";
    private int uploadIntervalSeconds = 300;
    private Encryption encryption = new Encryption();

    @Getter @Setter
    public static class Resolution {
        private int width = 640;
        private int height = 480;
    }

    @Getter @Setter
    public static class Encryption {
        private boolean enabled = true;
        private String algorithm = "AES/GCM/NoPadding";
        private int keySize = 256;
    }
}
