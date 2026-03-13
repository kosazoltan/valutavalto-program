package hu.puzzleir.valuta.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.Instant;
import java.util.Map;

@RestController
@RequestMapping("/api/v1")
public class VersionController {

    private static final String BUILD_TIME = Instant.now().toString(); // app indulásakor rögzül

    @GetMapping("/version")
    public Map<String, String> getVersion() {
        return Map.of(
            "buildTime", BUILD_TIME,
            "version", getClass().getPackage().getImplementationVersion() != null
                ? getClass().getPackage().getImplementationVersion() : "dev"
        );
    }
}
